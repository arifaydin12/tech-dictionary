class UserRanking {
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final int wordCount;
  final int dailyWordCount;
  final int weeklyWordCount;
  final int monthlyWordCount;
  final DateTime lastUpdated;

  UserRanking({
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.wordCount,
    required this.dailyWordCount,
    required this.weeklyWordCount,
    required this.monthlyWordCount,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  factory UserRanking.fromFirestore(Map<String, dynamic> json, String docId) {
    return UserRanking(
      userId: docId,
      userName: json['userName'] as String? ?? 'Bilinmeyen',
      userPhotoUrl: json['userPhotoUrl'] as String?,
      wordCount: (json['wordCount'] as num?)?.toInt() ?? 0,
      dailyWordCount: (json['dailyWordCount'] as num?)?.toInt() ?? 0,
      weeklyWordCount: (json['weeklyWordCount'] as num?)?.toInt() ?? 0,
      monthlyWordCount: (json['monthlyWordCount'] as num?)?.toInt() ?? 0,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userName': userName,
    'userPhotoUrl': userPhotoUrl,
    'wordCount': wordCount,
    'dailyWordCount': dailyWordCount,
    'weeklyWordCount': weeklyWordCount,
    'monthlyWordCount': monthlyWordCount,
    'lastUpdated': lastUpdated.toIso8601String(),
  };
}

