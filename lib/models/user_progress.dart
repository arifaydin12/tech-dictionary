import 'card_state.dart';
import 'quiz.dart';

/// Everything the app remembers about one user's learning. Stored as a single
/// JSON document by a [ProgressRepository].
class UserProgress {
  UserProgress({
    Map<String, CardState>? cards,
    Set<String>? favourites,
    List<QuizResult>? quizzes,
    Map<String, int>? reviewsByDay,
    Map<String, int>? xpByDay,
    Map<String, DateTime>? badges,
    this.xp = 0,
    this.wordsAdded = 0,
  }) : cards = cards ?? {},
       favourites = favourites ?? {},
       quizzes = quizzes ?? [],
       reviewsByDay = reviewsByDay ?? {},
       xpByDay = xpByDay ?? {},
       badges = badges ?? {};

  /// Spaced-repetition state keyed by word id.
  final Map<String, CardState> cards;
  final Set<String> favourites;

  /// Finished sessions in chronological order (oldest first).
  final List<QuizResult> quizzes;

  /// Number of answered questions per calendar day (`yyyy-MM-dd`).
  final Map<String, int> reviewsByDay;

  /// Experience points earned per calendar day.
  final Map<String, int> xpByDay;

  /// Unlocked badge ids and the time they were unlocked.
  final Map<String, DateTime> badges;

  int xp;
  int wordsAdded;

  int get totalReviews => reviewsByDay.values.fold(0, (a, b) => a + b);

  int get totalCorrect => cards.values.fold(0, (a, c) => a + c.correct);

  int get totalIncorrect => cards.values.fold(0, (a, c) => a + c.incorrect);

  /// Overall answer accuracy in the range 0..1 (0 when nothing answered).
  double get accuracy {
    final total = totalCorrect + totalIncorrect;
    return total == 0 ? 0 : totalCorrect / total;
  }

  Map<String, dynamic> toJson() => {
    'cards': [for (final c in cards.values) c.toJson()],
    'favourites': favourites.toList()..sort(),
    'quizzes': [for (final q in quizzes) q.toJson()],
    'reviewsByDay': reviewsByDay,
    'xpByDay': xpByDay,
    'badges': {
      for (final e in badges.entries) e.key: e.value.toIso8601String(),
    },
    'xp': xp,
    'wordsAdded': wordsAdded,
  };

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(String key) {
      final raw = json[key];
      if (raw is! Map) return {};
      return {
        for (final e in raw.entries) e.key as String: (e.value as num).toInt(),
      };
    }

    final cardList = json['cards'];
    final quizList = json['quizzes'];
    final badgeMap = json['badges'];
    final favList = json['favourites'];

    return UserProgress(
      cards: {
        if (cardList is List)
          for (final c in cardList)
            (c as Map<String, dynamic>)['wordId'] as String: CardState.fromJson(
              c,
            ),
      },
      favourites: {
        if (favList is List)
          for (final f in favList) f as String,
      },
      quizzes: [
        if (quizList is List)
          for (final q in quizList)
            QuizResult.fromJson(q as Map<String, dynamic>),
      ],
      reviewsByDay: intMap('reviewsByDay'),
      xpByDay: intMap('xpByDay'),
      badges: {
        if (badgeMap is Map)
          for (final e in badgeMap.entries)
            if (DateTime.tryParse(e.value as String) != null)
              e.key as String: DateTime.parse(e.value as String),
      },
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      wordsAdded: (json['wordsAdded'] as num?)?.toInt() ?? 0,
    );
  }
}
