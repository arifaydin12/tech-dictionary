import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/models/card_state.dart';
import 'package:tech_dictionary/models/quiz.dart';
import 'package:tech_dictionary/models/user_progress.dart';
import 'package:tech_dictionary/services/gamification_service.dart';
import 'package:tech_dictionary/services/stats_service.dart';
import 'package:tech_dictionary/utils/dates.dart';

void main() {
  final now = DateTime(2026, 3, 10, 12);

  Map<String, int> activity(List<int> daysAgo) => {
    for (final d in daysAgo) Dates.key(Dates.addDays(now, -d)): 5,
  };

  group('levels', () {
    test('level thresholds', () {
      expect(GamificationService.levelForXp(0), 1);
      expect(GamificationService.levelForXp(59), 1);
      expect(GamificationService.levelForXp(60), 2);
      expect(GamificationService.levelForXp(239), 2);
      expect(GamificationService.levelForXp(240), 3);
      expect(GamificationService.levelForXp(960), 5);
      expect(GamificationService.xpForLevel(5), 960);
    });

    test('level progress is between 0 and 1', () {
      expect(GamificationService.levelProgress(0), 0);
      expect(GamificationService.levelProgress(150), closeTo(0.5, 1e-9));
      expect(GamificationService.levelProgress(60), 0);
    });
  });

  group('streaks', () {
    test('counts consecutive days ending today', () {
      expect(GamificationService.currentStreak(activity([0, 1, 2]), now), 3);
    });

    test('streak survives until the end of the next day', () {
      expect(GamificationService.currentStreak(activity([1, 2, 3]), now), 3);
    });

    test('streak is lost after a missed day', () {
      expect(GamificationService.currentStreak(activity([2, 3, 4]), now), 0);
    });

    test('a gap ends the streak', () {
      expect(GamificationService.currentStreak(activity([0, 1, 3, 4]), now), 2);
    });

    test('no activity means no streak', () {
      expect(GamificationService.currentStreak({}, now), 0);
    });

    test('longest streak finds the best run', () {
      expect(
        GamificationService.longestStreak(activity([0, 1, 3, 4, 5, 6, 9])),
        4,
      );
      expect(GamificationService.longestStreak({}), 0);
    });

    test('days with zero activity do not count', () {
      final map = {Dates.key(now): 0};
      expect(GamificationService.currentStreak(map, now), 0);
      expect(GamificationService.longestStreak(map), 0);
    });

    test('streaks work across month boundaries', () {
      final march1 = DateTime(2026, 3, 1, 9);
      final map = {'2026-02-27': 1, '2026-02-28': 1, '2026-03-01': 1};
      expect(GamificationService.currentStreak(map, march1), 3);
    });
  });

  group('badges', () {
    const service = GamificationService();

    test('nothing unlocked for a new user', () {
      final progress = UserProgress();
      expect(service.unlockEarned(progress, now), isEmpty);
      expect(progress.badges, isEmpty);
    });

    test('first answer unlocks First Steps once', () {
      final progress = UserProgress(reviewsByDay: {Dates.key(now): 1});
      final first = service.unlockEarned(progress, now);
      expect(first.map((b) => b.id), ['first_steps']);
      expect(progress.badges.keys, contains('first_steps'));
      expect(service.unlockEarned(progress, now), isEmpty);
    });

    test('perfect session needs five questions', () {
      final shortRun = UserProgress(
        quizzes: [
          QuizResult(date: now, mode: QuizMode.typing, total: 3, correct: 3),
        ],
      );
      expect(
        service.unlockEarned(shortRun, now).map((b) => b.id),
        isNot(contains('perfectionist')),
      );

      final perfect = UserProgress(
        quizzes: [
          QuizResult(date: now, mode: QuizMode.typing, total: 5, correct: 5),
        ],
      );
      expect(
        service.unlockEarned(perfect, now).map((b) => b.id),
        contains('perfectionist'),
      );
    });

    test('streak and favourite badges', () {
      final progress = UserProgress(
        reviewsByDay: activity([0, 1, 2]),
        favourites: {for (var i = 0; i < 10; i++) 'w$i'},
      );
      final ids = service.unlockEarned(progress, now).map((b) => b.id);
      expect(ids, containsAll(['streak_3', 'collector']));
      expect(ids, isNot(contains('streak_7')));
    });

    test('learned and mastered counts come from card state', () {
      final progress = UserProgress(
        cards: {
          for (var i = 0; i < 5; i++)
            'w$i': CardState(
              wordId: 'w$i',
              repetitions: 5,
              intervalDays: 30,
              lastReviewed: now,
              due: now,
            ),
        },
      );
      final ids = service.unlockEarned(progress, now).map((b) => b.id);
      expect(ids, contains('master'));
      expect(ids, isNot(contains('learner')));
    });

    test('badge ids are unique', () {
      final ids = GamificationService.badges.map((b) => b.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(GamificationService.badgeById('streak_7'), isNotNull);
      expect(GamificationService.badgeById('nope'), isNull);
    });
  });

  group('StatsService', () {
    const stats = StatsService();

    test('recent activity covers the requested days, oldest first', () {
      final progress = UserProgress(
        reviewsByDay: {Dates.key(now): 7, Dates.key(Dates.addDays(now, -2)): 3},
      );
      final days = stats.recentActivity(progress, now);
      expect(days.length, 7);
      expect(days.last.reviews, 7);
      expect(days[days.length - 3].reviews, 3);
      expect(days.first.date, DateTime(2026, 3, 4));
    });

    test('weekly XP only counts the current week (Monday to Sunday)', () {
      // 10 March 2026 is a Tuesday; the week starts on Monday the 9th.
      final progress = UserProgress(
        xpByDay: {
          '2026-03-08': 100, // previous Sunday
          '2026-03-09': 20,
          '2026-03-10': 30,
        },
      );
      expect(stats.weeklyXp(progress, now), 50);
    });
  });
}
