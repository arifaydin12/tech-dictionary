class Badge {
  final String id;
  final String name;
  final String description;
  final String icon; // Emoji veya icon name
  final BadgeType type;
  final int requiredValue; // Gerekli değer (örn: 100 kelime)
  final DateTime? unlockedAt;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.requiredValue,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  Map<String, dynamic> toFirestore() => {
    'id': id,
    'name': name,
    'description': description,
    'icon': icon,
    'type': type.toString(),
    'requiredValue': requiredValue,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  factory Badge.fromFirestore(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      type: BadgeType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => BadgeType.wordCount,
      ),
      requiredValue: json['requiredValue'] as int,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
    );
  }
}

enum BadgeType {
  wordCount, // Kelime sayısı
  quizScore, // Quiz puanı
  streak, // Günlük kullanım serisi
  correction, // Düzeltme önerileri
  social, // Sosyal etkileşimler
  special, // Özel başarılar
}

class UserProgress {
  final String userId;
  int level;
  int xp;
  int totalXP;
  int wordsAdded;
  int quizzesCompleted;
  int currentStreak;
  int longestStreak;
  DateTime? lastActivityDate;
  List<String> unlockedBadges;

  UserProgress({
    required this.userId,
    this.level = 1,
    this.xp = 0,
    this.totalXP = 0,
    this.wordsAdded = 0,
    this.quizzesCompleted = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActivityDate,
    this.unlockedBadges = const [],
  });

  int get xpForNextLevel => level * 100;
  double get levelProgress => xp / xpForNextLevel;

  void addXP(int amount) {
    xp += amount;
    totalXP += amount;
    
    // Level up kontrolü
    while (xp >= xpForNextLevel) {
      xp -= xpForNextLevel;
      level++;
    }
  }

  void updateStreak() {
    final now = DateTime.now();
    if (lastActivityDate == null) {
      currentStreak = 1;
    } else {
      final daysDiff = now.difference(lastActivityDate!).inDays;
      if (daysDiff == 1) {
        currentStreak++;
      } else if (daysDiff > 1) {
        currentStreak = 1;
      }
    }
    
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
    
    lastActivityDate = now;
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'level': level,
    'xp': xp,
    'totalXP': totalXP,
    'wordsAdded': wordsAdded,
    'quizzesCompleted': quizzesCompleted,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActivityDate': lastActivityDate?.toIso8601String(),
    'unlockedBadges': unlockedBadges,
  };

  factory UserProgress.fromFirestore(Map<String, dynamic> json) {
    return UserProgress(
      userId: json['userId'] as String,
      level: json['level'] as int? ?? 1,
      xp: json['xp'] as int? ?? 0,
      totalXP: json['totalXP'] as int? ?? 0,
      wordsAdded: json['wordsAdded'] as int? ?? 0,
      quizzesCompleted: json['quizzesCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      lastActivityDate: json['lastActivityDate'] != null
          ? DateTime.parse(json['lastActivityDate'] as String)
          : null,
      unlockedBadges: List<String>.from(json['unlockedBadges'] as List? ?? []),
    );
  }
}

