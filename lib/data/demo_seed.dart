import '../models/card_state.dart';
import '../models/community.dart';
import '../models/user_progress.dart';
import '../models/word.dart';
import '../models/quiz.dart';
import '../services/gamification_service.dart';
import '../utils/dates.dart';
import 'seed_words.dart';

/// Fictional data used in demo mode so every screen has something to show.
/// None of these people exist.
class DemoSeed {
  const DemoSeed._();

  static const String guestId = 'demo-guest';
  static const String guestName = 'Guest';

  static const List<RankingEntry> rankings = [
    RankingEntry(
      userId: 'demo-nora',
      displayName: 'Nora Kim',
      totalXp: 2840,
      weeklyXp: 410,
      streak: 21,
      wordsAdded: 4,
    ),
    RankingEntry(
      userId: 'demo-leo',
      displayName: 'Leo Martins',
      totalXp: 2310,
      weeklyXp: 365,
      streak: 12,
      wordsAdded: 6,
    ),
    RankingEntry(
      userId: 'demo-aiko',
      displayName: 'Aiko Tanaka',
      totalXp: 1975,
      weeklyXp: 290,
      streak: 9,
      wordsAdded: 2,
    ),
    RankingEntry(
      userId: 'demo-samir',
      displayName: 'Samir Haddad',
      totalXp: 1620,
      weeklyXp: 180,
      streak: 4,
      wordsAdded: 1,
    ),
    RankingEntry(
      userId: 'demo-elena',
      displayName: 'Elena Petrova',
      totalXp: 1210,
      weeklyXp: 240,
      streak: 6,
      wordsAdded: 3,
    ),
    RankingEntry(
      userId: 'demo-marco',
      displayName: 'Marco Rossi',
      totalXp: 880,
      weeklyXp: 95,
      streak: 2,
      wordsAdded: 0,
    ),
    RankingEntry(
      userId: 'demo-priya',
      displayName: 'Priya Nair',
      totalXp: 640,
      weeklyXp: 130,
      streak: 3,
      wordsAdded: 1,
    ),
    RankingEntry(
      userId: 'demo-jonas',
      displayName: 'Jonas Weber',
      totalXp: 330,
      weeklyXp: 40,
      streak: 1,
      wordsAdded: 0,
    ),
  ];

  /// Community words written by fictional users, plus one by the guest.
  static List<Word> communityWords(DateTime now) => [
    Word(
      id: 'community-monorepo',
      term: 'Monorepo',
      category: 'Software',
      definition:
          'A single version-control repository that holds the code of many projects or services, which makes sharing code and making cross-project changes easier.',
      authorId: 'demo-leo',
      authorName: 'Leo Martins',
      createdAt: Dates.addDays(now, -12),
    ),
    Word(
      id: 'community-feature-flag',
      term: 'Feature Flag',
      category: 'Software',
      definition:
          'A switch in the code that turns a feature on or off at runtime without deploying again, used for gradual rollouts and experiments.',
      authorId: 'demo-nora',
      authorName: 'Nora Kim',
      createdAt: Dates.addDays(now, -9),
    ),
    Word(
      id: 'community-vector-database',
      term: 'Vector Database',
      category: 'Databases',
      definition:
          'A database that stores embeddings, which are numerical representations of text or images, and finds the most similar items by distance.',
      authorId: 'demo-aiko',
      authorName: 'Aiko Tanaka',
      createdAt: Dates.addDays(now, -6),
    ),
    Word(
      id: 'community-idempotency',
      term: 'Idempotency',
      category: 'Programming',
      definition:
          'A property of an operation: running it several times has the same effect as running it once, for example a PUT request.',
      example: 'Retrying an idempotent payment request never charges twice.',
      authorId: guestId,
      authorName: guestName,
      createdAt: Dates.addDays(now, -2),
    ),
  ];

  static List<Correction> corrections(DateTime now) => [
    Correction(
      id: 'correction-1',
      wordId: 'community-idempotency',
      wordTerm: 'Idempotency',
      ownerId: guestId,
      proposerId: 'demo-aiko',
      proposerName: 'Aiko Tanaka',
      proposedDefinition:
          'A property of an operation: applying it once or many times leaves the system in the same state. HTTP GET, PUT and DELETE are meant to be idempotent.',
      note: 'Added the HTTP methods that are defined as idempotent.',
      createdAt: Dates.addDays(now, -1),
    ),
    Correction(
      id: 'correction-2',
      wordId: 'community-monorepo',
      wordTerm: 'Monorepo',
      ownerId: 'demo-leo',
      proposerId: guestId,
      proposerName: guestName,
      proposedDefinition:
          'A single repository that stores the code of many projects, often with shared tooling for building and testing them together.',
      note: 'Mentions shared tooling.',
      createdAt: Dates.addDays(now, -3),
    ),
  ];

  /// A believable learning history for the demo guest: about 40 studied terms,
  /// a 5-day streak, a few finished sessions and a handful of badges.
  static UserProgress progress(DateTime now) {
    final progress = UserProgress();
    final today = Dates.dayStart(now);
    final builtIn = SeedWords.all;

    // Cards: every third built-in word, in three maturity tiers.
    var n = 0;
    for (var i = 0; i < builtIn.length; i += 3) {
      final word = builtIn[i];
      final tier = n % 4;
      n++;
      switch (tier) {
        case 0: // mastered
          progress.cards[word.id] = CardState(
            wordId: word.id,
            repetitions: 5,
            ease: 2.6,
            intervalDays: 24 + (n % 5) * 3,
            due: Dates.addDays(today, 12 + n % 9),
            lastReviewed: Dates.addDays(today, -(n % 4)),
            correct: 9,
            incorrect: 1,
          );
        case 1: // learned
          progress.cards[word.id] = CardState(
            wordId: word.id,
            repetitions: 3,
            ease: 2.4,
            intervalDays: 6 + n % 7,
            due: Dates.addDays(today, n % 5 - 2),
            lastReviewed: Dates.addDays(today, -(2 + n % 5)),
            correct: 5,
            incorrect: 2,
          );
        case 2: // learning
          progress.cards[word.id] = CardState(
            wordId: word.id,
            repetitions: 1,
            ease: 2.2,
            intervalDays: 1,
            due: Dates.addDays(today, n % 3 - 1),
            lastReviewed: Dates.addDays(today, -1 - n % 3),
            correct: 2,
            incorrect: 3,
            lapses: 1,
          );
        default: // studied once
          progress.cards[word.id] = CardState(
            wordId: word.id,
            repetitions: 2,
            ease: 2.5,
            intervalDays: 6,
            due: Dates.addDays(today, n % 6 - 1),
            lastReviewed: Dates.addDays(today, -3),
            correct: 3,
            incorrect: 1,
          );
      }
    }

    // Activity: active today and the 4 days before (streak of 5), a gap, then
    // a longer earlier run.
    const reviews = [18, 24, 15, 31, 22, 0, 20, 27, 19, 14, 26, 21];
    for (var d = 0; d < reviews.length; d++) {
      if (reviews[d] == 0) continue;
      final key = Dates.key(Dates.addDays(today, -d));
      progress.reviewsByDay[key] = reviews[d];
      progress.xpByDay[key] = reviews[d] * 8;
    }
    progress.xp = progress.xpByDay.values.fold(0, (a, b) => a + b) + 40;

    // Quiz history, oldest first, with accuracy improving over time.
    const history = [
      (QuizMode.multipleChoice, 10, 6, 11),
      (QuizMode.flashcards, 12, 8, 10),
      (QuizMode.multipleChoice, 10, 7, 8),
      (QuizMode.typing, 8, 4, 7),
      (QuizMode.multipleChoice, 10, 8, 4),
      (QuizMode.flashcards, 15, 12, 3),
      (QuizMode.typing, 8, 6, 2),
      (QuizMode.multipleChoice, 10, 9, 0),
    ];
    for (final (mode, total, correct, daysAgo) in history) {
      progress.quizzes.add(
        QuizResult(
          date: Dates.addDays(today, -daysAgo).add(const Duration(hours: 18)),
          mode: mode,
          total: total,
          correct: correct,
        ),
      );
    }

    progress.wordsAdded = 1;
    for (final id in [
      'builtin-dns',
      'builtin-kubernetes',
      'builtin-encryption',
      'builtin-neural-network',
      'builtin-big-o-notation',
    ]) {
      progress.favourites.add(id);
    }

    const GamificationService().unlockEarned(progress, now);
    return progress;
  }
}
