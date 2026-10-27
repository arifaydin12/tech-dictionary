import 'dart:math';

import '../models/card_state.dart';
import '../models/quiz.dart';
import '../models/word.dart';
import '../utils/text_utils.dart';
import 'spaced_repetition.dart';

/// How a flashcard was rated by the learner.
enum FlashcardGrade {
  again('Again', Quality.wrong, false),
  hard('Hard', Quality.hard, true),
  good('Good', Quality.good, true),
  easy('Easy', Quality.perfect, true);

  const FlashcardGrade(this.label, this.quality, this.correct);

  final String label;
  final int quality;
  final bool correct;
}

/// Outcome of one answered question: whether it counts as correct, the SM-2
/// quality it maps to and the XP awarded.
class AnswerOutcome {
  const AnswerOutcome({
    required this.correct,
    required this.quality,
    required this.xp,
  });

  final bool correct;
  final int quality;
  final int xp;
}

/// Question selection, answer checking and scoring.
class QuizService {
  QuizService({Random? random}) : _random = random ?? Random();

  final Random _random;

  static const int optionCount = 4;

  /// Picks up to [count] words to practise, most urgent first:
  /// 1. cards that are due (most overdue first),
  /// 2. words never studied,
  /// 3. cards due soonest.
  /// The returned list is shuffled so the order is not predictable.
  List<Word> selectWords({
    required List<Word> words,
    required Map<String, CardState> cards,
    required int count,
    required DateTime now,
    String? category,
  }) {
    final pool = category == null
        ? words
        : words.where((w) => w.category == category).toList();

    final due = <(Word, CardState)>[];
    final fresh = <Word>[];
    final later = <(Word, CardState)>[];
    for (final word in pool) {
      final card = cards[word.id];
      if (card == null || card.isNew) {
        fresh.add(word);
      } else if (card.isDue(now)) {
        due.add((word, card));
      } else {
        later.add((word, card));
      }
    }

    int byDue((Word, CardState) a, (Word, CardState) b) =>
        a.$2.due!.compareTo(b.$2.due!);
    due.sort(byDue);
    later.sort(byDue);
    fresh.shuffle(_random);

    final ordered = <Word>[
      for (final e in due) e.$1,
      ...fresh,
      for (final e in later) e.$1,
    ];
    final picked = ordered.take(count).toList()..shuffle(_random);
    return picked;
  }

  /// Builds the questions for [selected] words. Multiple-choice distractors
  /// come from the same category first, then from the rest of [allWords].
  List<QuizQuestion> buildQuestions({
    required List<Word> selected,
    required List<Word> allWords,
    required QuizMode mode,
  }) {
    return [
      for (final word in selected)
        QuizQuestion(
          word: word,
          mode: mode,
          options: mode == QuizMode.multipleChoice
              ? _options(word, allWords)
              : const [],
        ),
    ];
  }

  List<String> _options(Word word, List<Word> allWords) {
    final seen = <String>{word.term.toLowerCase()};
    final sameCategory = <String>[];
    final others = <String>[];
    for (final other in allWords) {
      if (other.id == word.id) continue;
      if (!seen.add(other.term.toLowerCase())) continue;
      (other.category == word.category ? sameCategory : others).add(other.term);
    }
    sameCategory.shuffle(_random);
    others.shuffle(_random);
    final distractors = [
      ...sameCategory,
      ...others,
    ].take(optionCount - 1).toList();
    return [word.term, ...distractors]..shuffle(_random);
  }

  /// Compares a typed answer with the expected [term].
  ///
  /// Case, spaces and punctuation are ignored. For terms of six or more
  /// characters a single typo still counts as [AnswerMatch.close].
  AnswerMatch checkTyped(String input, String term) {
    final a = TextUtils.normalize(input);
    final b = TextUtils.normalize(term);
    if (a.isEmpty) return AnswerMatch.wrong;
    if (a == b) return AnswerMatch.exact;
    if (b.length >= 6 && TextUtils.levenshtein(a, b) <= 1) {
      return AnswerMatch.close;
    }
    return AnswerMatch.wrong;
  }

  AnswerOutcome multipleChoice({required bool isCorrect}) => AnswerOutcome(
    correct: isCorrect,
    quality: isCorrect ? Quality.good : Quality.wrong,
    xp: isCorrect ? 10 : 2,
  );

  AnswerOutcome typed(AnswerMatch match) {
    switch (match) {
      case AnswerMatch.exact:
        return const AnswerOutcome(
          correct: true,
          quality: Quality.perfect,
          xp: 15,
        );
      case AnswerMatch.close:
        return const AnswerOutcome(correct: true, quality: Quality.hard, xp: 8);
      case AnswerMatch.wrong:
        return const AnswerOutcome(
          correct: false,
          quality: Quality.wrong,
          xp: 2,
        );
    }
  }

  AnswerOutcome flashcard(FlashcardGrade grade) {
    final xp = switch (grade) {
      FlashcardGrade.again => 2,
      FlashcardGrade.hard => 6,
      FlashcardGrade.good => 10,
      FlashcardGrade.easy => 12,
    };
    return AnswerOutcome(
      correct: grade.correct,
      quality: grade.quality,
      xp: xp,
    );
  }

  /// Bonus XP for finishing a session of at least five questions.
  int sessionBonus({required int total, required int correct}) {
    if (total < 5) return 0;
    final accuracy = correct / total;
    if (accuracy == 1) return 25;
    if (accuracy >= 0.8) return 15;
    return 5;
  }
}
