import 'dart:math' as math;

import '../models/card_state.dart';
import '../utils/dates.dart';

/// How well the learner recalled a word, in the SM-2 0..5 scale.
class Quality {
  const Quality._();

  static const int blackout = 0;
  static const int wrong = 1;
  static const int hard = 3;
  static const int good = 4;
  static const int perfect = 5;
}

/// A small implementation of the SM-2 spaced-repetition algorithm.
///
/// * A recall of quality >= 3 counts as success. The first success schedules
///   the next review in 1 day, the second in 6 days and later ones in
///   `previous interval * ease` days (with the ease updated by this answer).
/// * A failed recall resets the repetition count and brings the card back the
///   next day.
/// * The ease factor moves with the quality of every answer and never drops
///   below [CardState.minEase].
class SpacedRepetition {
  const SpacedRepetition._();

  /// Returns the new state of [card] after an answer of [quality] (0..5) given
  /// at [now].
  static CardState review(CardState card, int quality, DateTime now) {
    final q = quality.clamp(0, 5);
    final success = q >= 3;

    // The ease factor is updated first, so that better answers also grow the
    // next interval more than worse ones.
    final penalty = 5 - q;
    final ease = math.max(
      CardState.minEase,
      card.ease + 0.1 - penalty * (0.08 + penalty * 0.02),
    );

    int repetitions;
    int interval;
    var lapses = card.lapses;

    if (success) {
      if (card.repetitions == 0) {
        interval = 1;
      } else if (card.repetitions == 1) {
        interval = 6;
      } else {
        interval = math.max(1, (card.intervalDays * ease).round());
      }
      repetitions = card.repetitions + 1;
    } else {
      if (card.repetitions >= 2) lapses++;
      repetitions = 0;
      interval = 1;
    }

    return card.copyWith(
      repetitions: repetitions,
      ease: ease,
      intervalDays: interval,
      due: Dates.addDays(Dates.dayStart(now), interval),
      lastReviewed: now,
      correct: card.correct + (success ? 1 : 0),
      incorrect: card.incorrect + (success ? 0 : 1),
      lapses: lapses,
    );
  }
}
