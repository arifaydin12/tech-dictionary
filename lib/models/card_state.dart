import '../utils/dates.dart';

/// Spaced-repetition state of one word for one user (SM-2 style).
class CardState {
  const CardState({
    required this.wordId,
    this.repetitions = 0,
    this.ease = 2.5,
    this.intervalDays = 0,
    this.due,
    this.lastReviewed,
    this.correct = 0,
    this.incorrect = 0,
    this.lapses = 0,
  });

  final String wordId;

  /// Consecutive successful reviews.
  final int repetitions;

  /// Ease factor; never drops below [minEase].
  final double ease;

  /// Current interval in days until the next review.
  final int intervalDays;

  /// Day on which the card is next due. `null` for a card never reviewed.
  final DateTime? due;
  final DateTime? lastReviewed;
  final int correct;
  final int incorrect;

  /// Number of times a learned card was forgotten.
  final int lapses;

  static const double minEase = 1.3;

  /// A card whose interval has reached this many days counts as mastered.
  static const int masteredIntervalDays = 21;

  bool get isNew => lastReviewed == null;
  bool get isMastered => intervalDays >= masteredIntervalDays;

  /// Learned = answered correctly at least twice in a row.
  bool get isLearned => repetitions >= 2;

  int get reviews => correct + incorrect;

  bool isDue(DateTime now) =>
      due != null && !Dates.dayStart(due!).isAfter(Dates.dayStart(now));

  CardState copyWith({
    int? repetitions,
    double? ease,
    int? intervalDays,
    DateTime? due,
    DateTime? lastReviewed,
    int? correct,
    int? incorrect,
    int? lapses,
  }) {
    return CardState(
      wordId: wordId,
      repetitions: repetitions ?? this.repetitions,
      ease: ease ?? this.ease,
      intervalDays: intervalDays ?? this.intervalDays,
      due: due ?? this.due,
      lastReviewed: lastReviewed ?? this.lastReviewed,
      correct: correct ?? this.correct,
      incorrect: incorrect ?? this.incorrect,
      lapses: lapses ?? this.lapses,
    );
  }

  Map<String, dynamic> toJson() => {
    'wordId': wordId,
    'repetitions': repetitions,
    'ease': ease,
    'intervalDays': intervalDays,
    'due': due?.toIso8601String(),
    'lastReviewed': lastReviewed?.toIso8601String(),
    'correct': correct,
    'incorrect': incorrect,
    'lapses': lapses,
  };

  factory CardState.fromJson(Map<String, dynamic> json) {
    DateTime? date(String key) {
      final v = json[key];
      return v is String ? DateTime.tryParse(v) : null;
    }

    return CardState(
      wordId: json['wordId'] as String,
      repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
      ease: (json['ease'] as num?)?.toDouble() ?? 2.5,
      intervalDays: (json['intervalDays'] as num?)?.toInt() ?? 0,
      due: date('due'),
      lastReviewed: date('lastReviewed'),
      correct: (json['correct'] as num?)?.toInt() ?? 0,
      incorrect: (json['incorrect'] as num?)?.toInt() ?? 0,
      lapses: (json['lapses'] as num?)?.toInt() ?? 0,
    );
  }
}
