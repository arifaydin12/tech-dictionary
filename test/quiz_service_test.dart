import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/models/card_state.dart';
import 'package:tech_dictionary/models/quiz.dart';
import 'package:tech_dictionary/models/word.dart';
import 'package:tech_dictionary/services/quiz_service.dart';
import 'package:tech_dictionary/services/spaced_repetition.dart';

Word word(String term, String category) => Word(
  id: 'id-$term',
  term: term,
  definition: 'Definition of $term goes here.',
  category: category,
);

void main() {
  final now = DateTime(2026, 3, 10, 12);
  final today = DateTime(2026, 3, 10);
  late QuizService quiz;

  setUp(() => quiz = QuizService(random: Random(1)));

  final words = [
    word('Alpha', 'Software'),
    word('Bravo', 'Software'),
    word('Charlie', 'Software'),
    word('Delta', 'Software'),
    word('Echo', 'Networking'),
    word('Foxtrot', 'Networking'),
    word('Golf', 'Security'),
  ];

  group('selectWords', () {
    test('puts due cards first, then new words, then later cards', () {
      final cards = {
        'id-Alpha': CardState(
          wordId: 'id-Alpha',
          due: today.subtract(const Duration(days: 3)),
          lastReviewed: now,
        ),
        'id-Bravo': CardState(
          wordId: 'id-Bravo',
          due: today.add(const Duration(days: 5)),
          lastReviewed: now,
        ),
      };
      final picked = quiz.selectWords(
        words: words,
        cards: cards,
        count: 3,
        now: now,
      );
      expect(picked.length, 3);
      expect(picked.map((w) => w.term), contains('Alpha'));
      expect(picked.map((w) => w.term), isNot(contains('Bravo')));
    });

    test('falls back to cards due later when nothing else is left', () {
      final cards = {
        for (final w in words)
          w.id: CardState(
            wordId: w.id,
            due: today.add(const Duration(days: 4)),
            lastReviewed: now,
          ),
      };
      final picked = quiz.selectWords(
        words: words,
        cards: cards,
        count: 4,
        now: now,
      );
      expect(picked.length, 4);
    });

    test('filters by category and never exceeds the pool', () {
      final picked = quiz.selectWords(
        words: words,
        cards: const {},
        count: 10,
        now: now,
        category: 'Networking',
      );
      expect(picked.map((w) => w.term).toSet(), {'Echo', 'Foxtrot'});
    });

    test('most overdue cards are chosen before less overdue ones', () {
      final cards = {
        'id-Alpha': CardState(
          wordId: 'id-Alpha',
          due: today.subtract(const Duration(days: 1)),
          lastReviewed: now,
        ),
        'id-Bravo': CardState(
          wordId: 'id-Bravo',
          due: today.subtract(const Duration(days: 9)),
          lastReviewed: now,
        ),
        'id-Charlie': CardState(
          wordId: 'id-Charlie',
          due: today.subtract(const Duration(days: 5)),
          lastReviewed: now,
        ),
      };
      final picked = quiz.selectWords(
        words: words.take(3).toList(),
        cards: cards,
        count: 2,
        now: now,
      );
      expect(picked.map((w) => w.term).toSet(), {'Bravo', 'Charlie'});
    });
  });

  group('buildQuestions', () {
    test('multiple choice has four unique options including the answer', () {
      final questions = quiz.buildQuestions(
        selected: words.take(4).toList(),
        allWords: words,
        mode: QuizMode.multipleChoice,
      );
      for (final q in questions) {
        expect(q.options.length, 4);
        expect(q.options.toSet().length, 4);
        expect(q.options.where((o) => o == q.word.term).length, 1);
      }
    });

    test('distractors prefer the same category', () {
      final questions = quiz.buildQuestions(
        selected: [words[0]],
        allWords: words,
        mode: QuizMode.multipleChoice,
      );
      final options = questions.single.options.toSet();
      expect(options, {'Alpha', 'Bravo', 'Charlie', 'Delta'});
    });

    test('works with fewer than four words in total', () {
      final few = words.take(2).toList();
      final q = quiz
          .buildQuestions(
            selected: [few.first],
            allWords: few,
            mode: QuizMode.multipleChoice,
          )
          .single;
      expect(q.options.toSet(), {'Alpha', 'Bravo'});
    });

    test('other modes have no options', () {
      final q = quiz
          .buildQuestions(
            selected: [words.first],
            allWords: words,
            mode: QuizMode.typing,
          )
          .single;
      expect(q.options, isEmpty);
    });
  });

  group('checkTyped', () {
    test('ignores case, spaces and punctuation', () {
      expect(quiz.checkTyped('ci cd', 'CI/CD'), AnswerMatch.exact);
      expect(quiz.checkTyped('  kubernetes ', 'Kubernetes'), AnswerMatch.exact);
      expect(
        quiz.checkTyped(
          'two factor authentication',
          'Two-Factor Authentication',
        ),
        AnswerMatch.exact,
      );
    });

    test('accepts one typo for longer terms', () {
      expect(quiz.checkTyped('Kubernetis', 'Kubernetes'), AnswerMatch.close);
      expect(quiz.checkTyped('Kubernets', 'Kubernetes'), AnswerMatch.close);
    });

    test('does not accept typos for short terms', () {
      expect(quiz.checkTyped('DNZ', 'DNS'), AnswerMatch.wrong);
      expect(quiz.checkTyped('CPI', 'CPU'), AnswerMatch.wrong);
    });

    test('rejects wrong and empty answers', () {
      expect(quiz.checkTyped('Docker', 'Kubernetes'), AnswerMatch.wrong);
      expect(quiz.checkTyped('   ', 'Kubernetes'), AnswerMatch.wrong);
    });
  });

  group('scoring', () {
    test('multiple choice', () {
      final right = quiz.multipleChoice(isCorrect: true);
      final wrong = quiz.multipleChoice(isCorrect: false);
      expect(right.correct, isTrue);
      expect(right.quality, Quality.good);
      expect(right.xp, 10);
      expect(wrong.correct, isFalse);
      expect(wrong.quality, Quality.wrong);
      expect(wrong.xp, lessThan(right.xp));
    });

    test('typed answers: exact beats close beats wrong', () {
      final exact = quiz.typed(AnswerMatch.exact);
      final close = quiz.typed(AnswerMatch.close);
      final wrong = quiz.typed(AnswerMatch.wrong);
      expect(exact.xp, greaterThan(close.xp));
      expect(close.xp, greaterThan(wrong.xp));
      expect(exact.correct && close.correct, isTrue);
      expect(wrong.correct, isFalse);
      expect(close.quality, Quality.hard);
    });

    test('flashcard grades map to SM-2 qualities', () {
      expect(quiz.flashcard(FlashcardGrade.again).correct, isFalse);
      expect(quiz.flashcard(FlashcardGrade.again).quality, Quality.wrong);
      expect(quiz.flashcard(FlashcardGrade.hard).quality, Quality.hard);
      expect(quiz.flashcard(FlashcardGrade.good).quality, Quality.good);
      expect(quiz.flashcard(FlashcardGrade.easy).quality, Quality.perfect);
      expect(quiz.flashcard(FlashcardGrade.easy).correct, isTrue);
    });

    test('session bonus rewards accuracy and needs five questions', () {
      expect(quiz.sessionBonus(total: 4, correct: 4), 0);
      expect(quiz.sessionBonus(total: 10, correct: 10), 25);
      expect(quiz.sessionBonus(total: 10, correct: 8), 15);
      expect(quiz.sessionBonus(total: 10, correct: 5), 5);
    });
  });
}
