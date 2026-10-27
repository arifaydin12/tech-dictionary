import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/user_progress.dart';
import '../utils/dates.dart';

/// A badge that unlocks when [value] reaches [target].
class BadgeDef {
  const BadgeDef({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.target,
    required this.value,
  });

  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int target;
  final int Function(UserProgress progress) value;
}

/// XP levels, streaks and badges.
class GamificationService {
  const GamificationService();

  static final List<BadgeDef> badges = [
    BadgeDef(
      id: 'first_steps',
      title: 'First Steps',
      description: 'Answer your first question.',
      icon: Icons.flag_outlined,
      target: 1,
      value: (p) => p.totalReviews,
    ),
    BadgeDef(
      id: 'bookworm',
      title: 'Bookworm',
      description: 'Answer 100 questions.',
      icon: Icons.menu_book_outlined,
      target: 100,
      value: (p) => p.totalReviews,
    ),
    BadgeDef(
      id: 'scholar',
      title: 'Scholar',
      description: 'Answer 500 questions.',
      icon: Icons.school_outlined,
      target: 500,
      value: (p) => p.totalReviews,
    ),
    BadgeDef(
      id: 'quiz_rookie',
      title: 'Quiz Rookie',
      description: 'Finish 5 practice sessions.',
      icon: Icons.quiz_outlined,
      target: 5,
      value: (p) => p.quizzes.length,
    ),
    BadgeDef(
      id: 'perfectionist',
      title: 'Perfectionist',
      description: 'Finish a session of 5+ questions with no mistakes.',
      icon: Icons.verified_outlined,
      target: 1,
      value: (p) =>
          p.quizzes.where((q) => q.total >= 5 && q.correct == q.total).length,
    ),
    BadgeDef(
      id: 'streak_3',
      title: 'On a Roll',
      description: 'Practise 3 days in a row.',
      icon: Icons.local_fire_department_outlined,
      target: 3,
      value: (p) => longestStreak(p.reviewsByDay),
    ),
    BadgeDef(
      id: 'streak_7',
      title: 'Week Warrior',
      description: 'Practise 7 days in a row.',
      icon: Icons.whatshot_outlined,
      target: 7,
      value: (p) => longestStreak(p.reviewsByDay),
    ),
    BadgeDef(
      id: 'learner',
      title: 'Quick Learner',
      description: 'Learn 25 terms (two correct answers in a row).',
      icon: Icons.lightbulb_outline,
      target: 25,
      value: (p) => p.cards.values.where((c) => c.isLearned).length,
    ),
    BadgeDef(
      id: 'master',
      title: 'Term Master',
      description: 'Master 5 terms (review interval of 3+ weeks).',
      icon: Icons.workspace_premium_outlined,
      target: 5,
      value: (p) => p.cards.values.where((c) => c.isMastered).length,
    ),
    BadgeDef(
      id: 'contributor',
      title: 'Contributor',
      description: 'Add your first term to the dictionary.',
      icon: Icons.edit_note,
      target: 1,
      value: (p) => p.wordsAdded,
    ),
    BadgeDef(
      id: 'author',
      title: 'Author',
      description: 'Add 5 terms to the dictionary.',
      icon: Icons.history_edu_outlined,
      target: 5,
      value: (p) => p.wordsAdded,
    ),
    BadgeDef(
      id: 'collector',
      title: 'Collector',
      description: 'Mark 10 favourites.',
      icon: Icons.favorite_border,
      target: 10,
      value: (p) => p.favourites.length,
    ),
    BadgeDef(
      id: 'level_5',
      title: 'Level 5',
      description: 'Reach level 5.',
      icon: Icons.military_tech_outlined,
      target: 5,
      value: (p) => levelForXp(p.xp),
    ),
  ];

  static BadgeDef? badgeById(String id) {
    for (final b in badges) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Level for a total XP amount: level n starts at `60 * (n - 1)^2` XP.
  static int levelForXp(int xp) => math.sqrt(math.max(0, xp) / 60).floor() + 1;

  static int xpForLevel(int level) => 60 * (level - 1) * (level - 1);

  /// Progress through the current level in the range 0..1.
  static double levelProgress(int xp) {
    final level = levelForXp(xp);
    final start = xpForLevel(level);
    final end = xpForLevel(level + 1);
    return ((xp - start) / (end - start)).clamp(0.0, 1.0);
  }

  /// Consecutive active days ending today. A streak stays alive until the end
  /// of the day after the last activity, so it is not lost before the learner
  /// had a chance to practise today.
  static int currentStreak(Map<String, int> activityByDay, DateTime now) {
    bool active(DateTime d) => (activityByDay[Dates.key(d)] ?? 0) > 0;

    var day = Dates.dayStart(now);
    if (!active(day)) day = Dates.addDays(day, -1);
    var streak = 0;
    while (active(day)) {
      streak++;
      day = Dates.addDays(day, -1);
    }
    return streak;
  }

  static int longestStreak(Map<String, int> activityByDay) {
    final days =
        activityByDay.entries
            .where((e) => e.value > 0)
            .map((e) => Dates.parseKey(e.key))
            .whereType<DateTime>()
            .toList()
          ..sort();
    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final day in days) {
      if (previous != null && Dates.addDays(previous, 1) == day) {
        run++;
      } else {
        run = 1;
      }
      longest = math.max(longest, run);
      previous = day;
    }
    return longest;
  }

  /// Unlocks every badge whose target has been reached and returns the badges
  /// that were unlocked by this call.
  List<BadgeDef> unlockEarned(UserProgress progress, DateTime now) {
    final unlocked = <BadgeDef>[];
    for (final badge in badges) {
      if (progress.badges.containsKey(badge.id)) continue;
      if (badge.value(progress) >= badge.target) {
        progress.badges[badge.id] = now;
        unlocked.add(badge);
      }
    }
    return unlocked;
  }
}
