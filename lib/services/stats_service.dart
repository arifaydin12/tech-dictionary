import '../models/card_state.dart';
import '../models/user_progress.dart';
import '../models/word.dart';
import '../utils/dates.dart';

/// Mastery numbers for one category.
class CategoryMastery {
  const CategoryMastery({
    required this.category,
    required this.total,
    required this.learned,
    required this.mastered,
  });

  final String category;
  final int total;
  final int learned;
  final int mastered;

  /// 0..1 score: mastered words count fully, learned words count half.
  double get score =>
      total == 0 ? 0 : ((mastered + (learned - mastered) * 0.5) / total);
}

/// A day with its number of answered questions.
class DayActivity {
  const DayActivity(this.date, this.reviews);

  final DateTime date;
  final int reviews;
}

/// Pure functions that derive the numbers shown on the statistics screen.
class StatsService {
  const StatsService();

  /// Answered questions for each of the last [days] days, oldest first.
  List<DayActivity> recentActivity(
    UserProgress progress,
    DateTime now, {
    int days = 7,
  }) {
    final today = Dates.dayStart(now);
    return [
      for (var i = days - 1; i >= 0; i--)
        DayActivity(
          Dates.addDays(today, -i),
          progress.reviewsByDay[Dates.key(Dates.addDays(today, -i))] ?? 0,
        ),
    ];
  }

  List<CategoryMastery> categoryMastery(
    List<Word> words,
    UserProgress progress,
    List<String> categories,
  ) {
    return [
      for (final category in categories)
        _mastery(
          category,
          words.where((w) => w.category == category),
          progress.cards,
        ),
    ];
  }

  CategoryMastery _mastery(
    String category,
    Iterable<Word> words,
    Map<String, CardState> cards,
  ) {
    var total = 0;
    var learned = 0;
    var mastered = 0;
    for (final word in words) {
      total++;
      final card = cards[word.id];
      if (card == null) continue;
      if (card.isMastered) {
        mastered++;
        learned++;
      } else if (card.isLearned) {
        learned++;
      }
    }
    return CategoryMastery(
      category: category,
      total: total,
      learned: learned,
      mastered: mastered,
    );
  }

  /// Number of studied words that are due for review today.
  int dueCount(List<Word> words, UserProgress progress, DateTime now) {
    var count = 0;
    for (final word in words) {
      final card = progress.cards[word.id];
      if (card != null && !card.isNew && card.isDue(now)) count++;
    }
    return count;
  }

  int learnedCount(UserProgress progress) =>
      progress.cards.values.where((c) => c.isLearned).length;

  int masteredCount(UserProgress progress) =>
      progress.cards.values.where((c) => c.isMastered).length;

  /// XP earned in the week that contains [now] (Monday to Sunday).
  int weeklyXp(UserProgress progress, DateTime now) {
    final start = Dates.weekStart(now);
    var total = 0;
    for (var i = 0; i < 7; i++) {
      total += progress.xpByDay[Dates.key(Dates.addDays(start, i))] ?? 0;
    }
    return total;
  }
}
