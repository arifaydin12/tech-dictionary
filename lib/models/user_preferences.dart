/// Kullanıcı tercihleri modeli
class UserPreferences {
  final String userId;

  // Tema ayarları
  final ThemePreference themeMode;
  final String primaryColor;
  final bool useDynamicColors;

  // Uygulama ayarları
  final String language;
  final bool notificationsEnabled;
  final bool soundEnabled;
  final bool vibrationEnabled;

  // İçerik ayarları
  final bool showDefinitions;
  final bool autoPlayPronunciation;
  final int wordsPerDay;
  final String defaultCategory;

  // Görünüm ayarları
  final double fontSize;
  final bool useCompactView;
  final bool showImages;

  // İstatistikler
  final int totalWordsLearned;
  final int currentStreak;
  final DateTime? lastActiveDate;

  final DateTime createdAt;
  final DateTime updatedAt;

  UserPreferences({
    required this.userId,
    this.themeMode = ThemePreference.system,
    this.primaryColor = '#6366F1', // Indigo
    this.useDynamicColors = false,
    this.language = 'tr',
    this.notificationsEnabled = true,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.showDefinitions = true,
    this.autoPlayPronunciation = false,
    this.wordsPerDay = 10,
    this.defaultCategory = 'Genel',
    this.fontSize = 16.0,
    this.useCompactView = false,
    this.showImages = true,
    this.totalWordsLearned = 0,
    this.currentStreak = 0,
    this.lastActiveDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Firestore'a kaydet
  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    // Tema
    'themeMode': themeMode.name,
    'primaryColor': primaryColor,
    'useDynamicColors': useDynamicColors,
    // Uygulama
    'language': language,
    'notificationsEnabled': notificationsEnabled,
    'soundEnabled': soundEnabled,
    'vibrationEnabled': vibrationEnabled,
    // İçerik
    'showDefinitions': showDefinitions,
    'autoPlayPronunciation': autoPlayPronunciation,
    'wordsPerDay': wordsPerDay,
    'defaultCategory': defaultCategory,
    // Görünüm
    'fontSize': fontSize,
    'useCompactView': useCompactView,
    'showImages': showImages,
    // İstatistikler
    'totalWordsLearned': totalWordsLearned,
    'currentStreak': currentStreak,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
    // Meta
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Firestore'dan oluştur
  factory UserPreferences.fromFirestore(Map<String, dynamic> data) {
    return UserPreferences(
      userId: data['userId'] as String,
      // Tema
      themeMode: ThemePreference.values.firstWhere(
        (e) => e.name == (data['themeMode'] as String? ?? 'system'),
        orElse: () => ThemePreference.system,
      ),
      primaryColor: data['primaryColor'] as String? ?? '#6366F1',
      useDynamicColors: data['useDynamicColors'] as bool? ?? false,
      // Uygulama
      language: data['language'] as String? ?? 'tr',
      notificationsEnabled: data['notificationsEnabled'] as bool? ?? true,
      soundEnabled: data['soundEnabled'] as bool? ?? true,
      vibrationEnabled: data['vibrationEnabled'] as bool? ?? true,
      // İçerik
      showDefinitions: data['showDefinitions'] as bool? ?? true,
      autoPlayPronunciation: data['autoPlayPronunciation'] as bool? ?? false,
      wordsPerDay: data['wordsPerDay'] as int? ?? 10,
      defaultCategory: data['defaultCategory'] as String? ?? 'Genel',
      // Görünüm
      fontSize: (data['fontSize'] as num?)?.toDouble() ?? 16.0,
      useCompactView: data['useCompactView'] as bool? ?? false,
      showImages: data['showImages'] as bool? ?? true,
      // İstatistikler
      totalWordsLearned: data['totalWordsLearned'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      lastActiveDate: data['lastActiveDate'] != null
          ? DateTime.parse(data['lastActiveDate'] as String)
          : null,
      // Meta
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Kopyala ve değiştir
  UserPreferences copyWith({
    String? userId,
    ThemePreference? themeMode,
    String? primaryColor,
    bool? useDynamicColors,
    String? language,
    bool? notificationsEnabled,
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? showDefinitions,
    bool? autoPlayPronunciation,
    int? wordsPerDay,
    String? defaultCategory,
    double? fontSize,
    bool? useCompactView,
    bool? showImages,
    int? totalWordsLearned,
    int? currentStreak,
    DateTime? lastActiveDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      primaryColor: primaryColor ?? this.primaryColor,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      showDefinitions: showDefinitions ?? this.showDefinitions,
      autoPlayPronunciation:
          autoPlayPronunciation ?? this.autoPlayPronunciation,
      wordsPerDay: wordsPerDay ?? this.wordsPerDay,
      defaultCategory: defaultCategory ?? this.defaultCategory,
      fontSize: fontSize ?? this.fontSize,
      useCompactView: useCompactView ?? this.useCompactView,
      showImages: showImages ?? this.showImages,
      totalWordsLearned: totalWordsLearned ?? this.totalWordsLearned,
      currentStreak: currentStreak ?? this.currentStreak,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// Tema tercihleri enum
enum ThemePreference {
  light, // Açık tema
  dark, // Koyu tema
  system, // Sistem ayarını takip et
}
