import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/models/card_state.dart';
import 'package:tech_dictionary/services/spaced_repetition.dart';

void main() {
  final now = DateTime(2026, 3, 10, 15, 30);
  final today = DateTime(2026, 3, 10);

  group('SpacedRepetition.review', () {
    test('first successful review schedules 1 day', () {
      final card = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        Quality.good,
        now,
      );
      expect(card.repetitions, 1);
      expect(card.intervalDays, 1);
      expect(card.due, DateTime(2026, 3, 11));
      expect(card.correct, 1);
      expect(card.incorrect, 0);
      expect(card.lastReviewed, now);
    });

    test('second successful review schedules 6 days', () {
      var card = const CardState(wordId: 'a');
      card = SpacedRepetition.review(card, Quality.good, now);
      card = SpacedRepetition.review(card, Quality.good, now);
      expect(card.repetitions, 2);
      expect(card.intervalDays, 6);
      expect(card.due, DateTime(2026, 3, 16));
    });

    test('later intervals grow by the ease factor', () {
      var card = const CardState(wordId: 'a');
      for (var i = 0; i < 3; i++) {
        card = SpacedRepetition.review(card, Quality.good, now);
      }
      // quality 4 keeps the ease at 2.5: 6 * 2.5 = 15.
      expect(card.intervalDays, 15);
      card = SpacedRepetition.review(card, Quality.good, now);
      expect(card.intervalDays, 38); // 15 * 2.5 = 37.5, rounded up
    });

    test('better answers schedule longer intervals', () {
      var card = const CardState(wordId: 'a');
      card = SpacedRepetition.review(card, Quality.good, now);
      card = SpacedRepetition.review(card, Quality.good, now);
      expect(card.intervalDays, 6);

      int next(int quality) =>
          SpacedRepetition.review(card, quality, now).intervalDays;
      expect(next(Quality.hard), 14); // 6 * 2.36
      expect(next(Quality.good), 15); // 6 * 2.5
      expect(next(Quality.perfect), 16); // 6 * 2.6
      expect(next(Quality.wrong), 1);
    });

    test('a failed review resets repetitions and returns tomorrow', () {
      var card = const CardState(wordId: 'a');
      for (var i = 0; i < 3; i++) {
        card = SpacedRepetition.review(card, Quality.good, now);
      }
      card = SpacedRepetition.review(card, Quality.wrong, now);
      expect(card.repetitions, 0);
      expect(card.intervalDays, 1);
      expect(card.due, DateTime(2026, 3, 11));
      expect(card.incorrect, 1);
      expect(card.lapses, 1);
    });

    test('forgetting a card that was never learned is not a lapse', () {
      final card = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        Quality.wrong,
        now,
      );
      expect(card.lapses, 0);
    });

    test('perfect answers raise the ease, hard answers lower it', () {
      final easy = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        Quality.perfect,
        now,
      );
      final hard = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        Quality.hard,
        now,
      );
      expect(easy.ease, closeTo(2.6, 1e-9));
      expect(hard.ease, closeTo(2.36, 1e-9));
    });

    test('ease never drops below the minimum', () {
      var card = const CardState(wordId: 'a');
      for (var i = 0; i < 30; i++) {
        card = SpacedRepetition.review(card, Quality.blackout, now);
      }
      expect(card.ease, CardState.minEase);
    });

    test('quality is clamped to 0..5', () {
      final high = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        99,
        now,
      );
      final low = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        -4,
        now,
      );
      expect(high.correct, 1);
      expect(low.incorrect, 1);
    });
  });

  group('CardState', () {
    test('isDue compares calendar days', () {
      final card = CardState(wordId: 'a', due: today, lastReviewed: now);
      expect(card.isDue(DateTime(2026, 3, 10, 0, 1)), isTrue);
      expect(card.isDue(DateTime(2026, 3, 9, 23, 59)), isFalse);
      expect(card.isDue(DateTime(2026, 3, 12)), isTrue);
    });

    test('a card without a due date is never due', () {
      expect(const CardState(wordId: 'a').isDue(now), isFalse);
    });

    test('mastered after a three week interval', () {
      expect(
        const CardState(wordId: 'a', intervalDays: 20).isMastered,
        isFalse,
      );
      expect(const CardState(wordId: 'a', intervalDays: 21).isMastered, isTrue);
    });

    test('survives a JSON round trip', () {
      final card = SpacedRepetition.review(
        const CardState(wordId: 'a'),
        Quality.perfect,
        now,
      );
      final copy = CardState.fromJson(card.toJson());
      expect(copy.wordId, 'a');
      expect(copy.ease, card.ease);
      expect(copy.intervalDays, card.intervalDays);
      expect(copy.due, card.due);
      expect(copy.correct, card.correct);
    });
  });
}
