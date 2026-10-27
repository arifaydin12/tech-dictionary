class AppConstants {
  // App Info
  static const String appName = 'Tech Dictionary';
  static const String appVersion = '1.0.0';
  
  // Timeouts
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  
  // Spacing
  static const double spacing4 = 4;
  static const double spacing6 = 6;
  static const double spacing8 = 8;
  static const double spacing12 = 12;
  static const double spacing16 = 16;
  static const double spacing20 = 20;
  static const double spacing24 = 24;
  static const double spacing32 = 32;
  
  // Border Radius
  static const double borderRadius8 = 8;
  static const double borderRadius12 = 12;
  static const double borderRadius16 = 16;
  static const double borderRadius20 = 20;
}

class CategoryIcons {
  static const Map<String, String> icons = {
    'Mobile': '📱',
    'Backend': '🔙',
    'Frontend': '🎨',
    'Core': '⚙️',
    'Dart': '🎯',
    'Network': '🌐',
    'Database': '🗄️',
    'DevOps': '🚀',
    'Security': '🔐',
    'AI': '🤖',
    'Other': '📚',
  };
}

class DummyWords {
  static final List<Map<String, String>> words = [
    {
      'term': 'Flutter',
      'definition': 'Google tarafından geliştirilen, iOS, Android, Web ve Desktop için yazılmış uygulamalar oluşturan açık kaynaklı UI framework\'ü.',
      'category': 'Mobile'
    },
    {
      'term': 'Widget',
      'definition': 'Flutter\'da kullanıcı arayüzünün temel yapı taşı. Her şey widget\'tir; butonlardan düzenlemelere kadar.',
      'category': 'Core'
    },
    {
      'term': 'Dart',
      'definition': 'Google tarafından geliştirilmiş, nesne yönelimli ve type-safe bir programlama dili.',
      'category': 'Dart'
    },
    {
      'term': 'API',
      'definition': 'Uygulama Programlama Arayüzü. Yazılımlar arası iletişimi sağlayan kurallar ve protokoller seti.',
      'category': 'Backend'
    },
    {
      'term': 'Async',
      'definition': 'Eşzamansız programlama. Kodun bloklenmeden uzun işlemlerin çalışmasını sağlar.',
      'category': 'Dart'
    },
    {
      'term': 'State',
      'definition': 'Widget\'in zamanla değişebilen verisi. State değiştiğinde UI rebuild edilir.',
      'category': 'Core'
    },
    {
      'term': 'Build',
      'definition': 'Widget\'in UI\'ını oluşturan method. State değiştiğinde build() yeniden çalışır.',
      'category': 'Core'
    },
    {
      'term': 'Context',
      'definition': 'Widget ağacında bir widget\'in konumunu temsil eden nesne. Navigator ve Theme gibi değerlere erişmek için kullanılır.',
      'category': 'Core'
    },
  ];
}
