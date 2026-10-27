class LearningProgress {
  final String wordId;
  final String userId;
  final int reviewCount;
  final DateTime lastReviewed;
  final DateTime nextReview;
  final double easeFactor; // Spaced repetition için
  final int interval; // Gün cinsinden
  final bool isLearned;

  LearningProgress({
    required this.wordId,
    required this.userId,
    this.reviewCount = 0,
    DateTime? lastReviewed,
    DateTime? nextReview,
    this.easeFactor = 2.5,
    this.interval = 1,
    this.isLearned = false,
  }) : lastReviewed = lastReviewed ?? DateTime.now(),
       nextReview = nextReview ?? DateTime.now().add(const Duration(days: 1));

  /// Spaced repetition algoritması (SM-2 algoritması)
  LearningProgress review(bool isCorrect) {
    if (isCorrect) {
      final newEaseFactor = easeFactor + (0.1 - (5 - 4) * (0.08 + (5 - 4) * 0.02));
      final newInterval = reviewCount == 0
          ? 1
          : reviewCount == 1
              ? 6
              : (interval * newEaseFactor).round();
      
      return LearningProgress(
        wordId: wordId,
        userId: userId,
        reviewCount: reviewCount + 1,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now().add(Duration(days: newInterval)),
        easeFactor: newEaseFactor.clamp(1.3, 2.5),
        interval: newInterval,
        isLearned: reviewCount >= 5,
      );
    } else {
      // Yanlış cevap - baştan başla
      return LearningProgress(
        wordId: wordId,
        userId: userId,
        reviewCount: 0,
        lastReviewed: DateTime.now(),
        nextReview: DateTime.now().add(const Duration(days: 1)),
        easeFactor: 2.5,
        interval: 1,
        isLearned: false,
      );
    }
  }

  Map<String, dynamic> toFirestore() => {
    'wordId': wordId,
    'userId': userId,
    'reviewCount': reviewCount,
    'lastReviewed': lastReviewed.toIso8601String(),
    'nextReview': nextReview.toIso8601String(),
    'easeFactor': easeFactor,
    'interval': interval,
    'isLearned': isLearned,
  };

  factory LearningProgress.fromFirestore(Map<String, dynamic> json) {
    return LearningProgress(
      wordId: json['wordId'] as String,
      userId: json['userId'] as String,
      reviewCount: json['reviewCount'] as int? ?? 0,
      lastReviewed: json['lastReviewed'] != null
          ? DateTime.parse(json['lastReviewed'] as String)
          : DateTime.now(),
      nextReview: json['nextReview'] != null
          ? DateTime.parse(json['nextReview'] as String)
          : DateTime.now(),
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      interval: json['interval'] as int? ?? 1,
      isLearned: json['isLearned'] as bool? ?? false,
    );
  }
}

