import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'config/app_theme.dart';
import 'config/constants.dart';
import 'providers/word_provider.dart';
import 'providers/firebase_auth_provider.dart';
import 'providers/user_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/error_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/correction_management_screen.dart';
import 'screens/quiz_screen.dart';
import 'screens/gamification_screen.dart';
import 'screens/advanced_stats_screen.dart';
import 'services/word_service.dart';
import 'services/firebase_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase'i firebase_options ile başlat
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase başarıyla başlatıldı');

    final wordService = WordService();
    await wordService.initializeHive();
    print('✓ Hive veritabanı başarıyla başlatıldı');

    // FirebaseService ve UserService singleton'larını initialize et
    final firebaseService = FirebaseService();
    final userService = UserService();

    runApp(
      MultiProvider(
        providers: [
          // Services
          Provider<WordService>(create: (_) => wordService),
          Provider<FirebaseService>(create: (_) => firebaseService),
          Provider<UserService>(create: (_) => userService),

          // Providers - Sırası önemli!
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
          ChangeNotifierProvider(create: (_) => WordProvider(wordService)),
        ],
        child: const MainApp(),
      ),
    );
  } catch (e) {
    print('❌ Başlangıç hatası: $e');
    // Fallback: Hata durumunda bile uygulamayı başlat
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => FirebaseAuthProvider()),
          ChangeNotifierProvider(create: (_) => UserProvider()),
        ],
        child: const MainApp(),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeProvider.themeMode,
      home: const OnboardingScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
        '/notifications': (context) => const NotificationScreen(),
        '/stats': (context) => const StatsScreen(),
        '/error': (context) => const ErrorScreen(),
        '/rankings': (context) => const RankingScreen(),
        '/corrections': (context) => const CorrectionManagementScreen(),
        '/quiz': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return QuizScreen(
            mode: args?['mode'] ?? QuizMode.multipleChoice,
            questionCount: args?['questionCount'] ?? 10,
          );
        },
        '/gamification': (context) => const GamificationScreen(),
        '/advanced_stats': (context) => const AdvancedStatsScreen(),
      },
    );
  }
}
