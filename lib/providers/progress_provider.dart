import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/card_state.dart';
import '../models/community.dart';
import '../models/quiz.dart';
import '../models/user_progress.dart';
import '../models/word.dart';
import '../repositories/repositories.dart';
import '../services/gamification_service.dart';
import '../services/quiz_service.dart';
import '../services/spaced_repetition.dart';
import '../services/stats_service.dart';
import '../utils/dates.dart';

/// What a finished practice session earned.
class SessionSummary {
  const SessionSummary({
    required this.total,
    required this.correct,
    required this.xpEarned,
    required this.bonusXp,
    required this.newBadges,
    required this.leveledUpTo,
  });

  final int total;
  final int correct;

  /// XP for the answers, including [bonusXp].
  final int xpEarned;
  final int bonusXp;
  final List<BadgeDef> newBadges;

  /// The new level when the session caused a level-up, otherwise `null`.
  final int? leveledUpTo;

  double get accuracy => total == 0 ? 0 : correct / total;
}

/// The signed-in user's learning progress: spaced-repetition cards,
/// favourites, XP, streaks, quiz history and badges.
class ProgressProvider extends ChangeNotifier {
  ProgressProvider(
    this._repository, {
    CommunityRepository? community,
    GamificationService gamification = const GamificationService(),
    this.stats = const StatsService(),
    DateTime Function()? clock,
  }) : _community = community,
       _gamification = gamification,
       _clock = clock ?? DateTime.now;

  final ProgressRepository _repository;
  final CommunityRepository? _community;
  final GamificationService _gamification;
  final StatsService stats;
  final DateTime Function() _clock;

  static const int maxStoredQuizzes = 100;

  AppUser? _user;
  UserProgress _progress = UserProgress();
  bool _loading = false;
  bool _dirty = false;
  String? _error;
  int _sessionXp = 0;

  UserProgress get progress => _progress;
  bool get loading => _loading;
  String? get error => _error;
  DateTime get now => _clock();

  Future<void> load(AppUser user) async {
    _user = user;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _progress = await _repository.load(user.id);
      // Make sure badges that are already earned are recorded.
      _gamification.unlockEarned(_progress, _clock());
    } on RepositoryException catch (e) {
      _progress = UserProgress();
      _error = e.message;
    } catch (e) {
      debugPrint('Failed to load progress: $e');
      _progress = UserProgress();
      _error = 'Your progress could not be loaded.';
    }
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _user = null;
    _progress = UserProgress();
    _dirty = false;
    _error = null;
    notifyListeners();
  }

  // ------------------------------------------------------------ derived

  int get level => GamificationService.levelForXp(_progress.xp);
  double get levelProgress => GamificationService.levelProgress(_progress.xp);
  int get xp => _progress.xp;

  int get currentStreak =>
      GamificationService.currentStreak(_progress.reviewsByDay, _clock());

  int get longestStreak =>
      GamificationService.longestStreak(_progress.reviewsByDay);

  int get todayReviews => _progress.reviewsByDay[Dates.key(_clock())] ?? 0;

  int get weeklyXp => stats.weeklyXp(_progress, _clock());

  bool isFavourite(String wordId) => _progress.favourites.contains(wordId);

  CardState? cardFor(String wordId) => _progress.cards[wordId];

  RankingEntry? ownRankingEntry() {
    final user = _user;
    if (user == null) return null;
    return RankingEntry(
      userId: user.id,
      displayName: user.displayName,
      totalXp: _progress.xp,
      weeklyXp: weeklyXp,
      streak: currentStreak,
      wordsAdded: _progress.wordsAdded,
      weekStart: Dates.weekStart(_clock()),
    );
  }

  // ------------------------------------------------------------ mutations

  /// Adds or removes a favourite. Returns badges unlocked by the change.
  Future<List<BadgeDef>> toggleFavourite(String wordId) async {
    if (!_progress.favourites.remove(wordId)) {
      _progress.favourites.add(wordId);
    }
    final badges = _gamification.unlockEarned(_progress, _clock());
    notifyListeners();
    await _save();
    return badges;
  }

  /// Call after the user added a word to the dictionary.
  Future<List<BadgeDef>> noteWordAdded() async {
    _progress.wordsAdded++;
    final badges = _gamification.unlockEarned(_progress, _clock());
    notifyListeners();
    await _save();
    return badges;
  }

  /// Records one answered question: updates the word's SM-2 card, today's
  /// activity and XP. Persisted by [finishSession] or [flush].
  void recordAnswer(Word word, AnswerOutcome outcome) {
    final now = _clock();
    final card = _progress.cards[word.id] ?? CardState(wordId: word.id);
    _progress.cards[word.id] = SpacedRepetition.review(
      card,
      outcome.quality,
      now,
    );
    final key = Dates.key(now);
    _progress.reviewsByDay[key] = (_progress.reviewsByDay[key] ?? 0) + 1;
    _addXp(outcome.xp, now);
    _sessionXp += outcome.xp;
    _dirty = true;
    notifyListeners();
  }

  void _addXp(int amount, DateTime now) {
    final key = Dates.key(now);
    _progress.xp += amount;
    _progress.xpByDay[key] = (_progress.xpByDay[key] ?? 0) + amount;
  }

  /// Marks the start of a session so that [finishSession] can report its XP.
  void beginSession() => _sessionXp = 0;

  Future<SessionSummary> finishSession({
    required QuizMode mode,
    required int total,
    required int correct,
    required int bonusXp,
    String? category,
  }) async {
    final now = _clock();
    final levelBefore = level;
    if (total > 0) {
      _progress.quizzes.add(
        QuizResult(
          date: now,
          mode: mode,
          total: total,
          correct: correct,
          category: category,
        ),
      );
      if (_progress.quizzes.length > maxStoredQuizzes) {
        _progress.quizzes.removeRange(
          0,
          _progress.quizzes.length - maxStoredQuizzes,
        );
      }
    }
    if (bonusXp > 0) _addXp(bonusXp, now);
    final earned = _sessionXp + bonusXp;
    _sessionXp = 0;
    final badges = _gamification.unlockEarned(_progress, now);
    final levelAfter = level;
    _dirty = true;
    notifyListeners();
    await _save();
    return SessionSummary(
      total: total,
      correct: correct,
      xpEarned: earned,
      bonusXp: bonusXp,
      newBadges: badges,
      leveledUpTo: levelAfter > levelBefore ? levelAfter : null,
    );
  }

  /// Deletes all learning progress of the current user.
  Future<void> resetProgress() async {
    _progress = UserProgress();
    _sessionXp = 0;
    notifyListeners();
    await _save();
  }

  /// Persists unsaved answers, for example when a session is abandoned.
  Future<void> flush() async {
    if (!_dirty) return;
    _gamification.unlockEarned(_progress, _clock());
    await _save();
  }

  Future<void> _save() async {
    final user = _user;
    if (user == null) return;
    try {
      await _repository.save(user.id, _progress);
      _dirty = false;
      _error = null;
    } on RepositoryException catch (e) {
      _error = e.message;
      notifyListeners();
      return;
    } catch (e) {
      debugPrint('Failed to save progress: $e');
      _error = 'Your progress could not be saved.';
      notifyListeners();
      return;
    }
    final entry = ownRankingEntry();
    final community = _community;
    if (entry != null && community != null) {
      try {
        await community.publishRanking(entry);
      } catch (e) {
        debugPrint('Could not publish ranking: $e');
      }
    }
  }
}
