import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/community_provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/session_controller.dart';
import '../providers/settings_provider.dart';
import '../screens/auth_screen.dart';
import '../screens/home_shell.dart';
import '../screens/onboarding_screen.dart';
import '../services/quiz_service.dart';
import '../services/speech_service.dart';
import '../ui/app_theme.dart';
import 'dependencies.dart';

/// Root widget. Creates the providers from [dependencies] and shows
/// onboarding, sign-in or the main shell depending on the state.
class TechDictionaryApp extends StatefulWidget {
  const TechDictionaryApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<TechDictionaryApp> createState() => _TechDictionaryAppState();
}

class _TechDictionaryAppState extends State<TechDictionaryApp> {
  late final SettingsProvider _settings;
  late final AuthProvider _auth;
  late final DictionaryProvider _dictionary;
  late final ProgressProvider _progress;
  late final CommunityProvider _community;
  late final SessionController _session;

  @override
  void initState() {
    super.initState();
    final deps = widget.dependencies;
    _settings = SettingsProvider(deps.store)..load();
    _auth = AuthProvider(deps.auth);
    _dictionary = DictionaryProvider(deps.words, clock: deps.clock);
    _progress = ProgressProvider(
      deps.progress,
      community: deps.community,
      clock: deps.clock,
    );
    _community = CommunityProvider(deps.community, clock: deps.clock);
    _session = SessionController(
      auth: _auth,
      dictionary: _dictionary,
      progress: _progress,
      community: _community,
    );
    _auth.init();
  }

  @override
  void dispose() {
    _session.dispose();
    _settings.dispose();
    _auth.dispose();
    _dictionary.dispose();
    _progress.dispose();
    _community.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDependencies>.value(value: widget.dependencies),
        Provider<Speaker>.value(value: widget.dependencies.speaker),
        Provider<QuizService>(create: (_) => QuizService()),
        ChangeNotifierProvider<SettingsProvider>.value(value: _settings),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<DictionaryProvider>.value(value: _dictionary),
        ChangeNotifierProvider<ProgressProvider>.value(value: _progress),
        ChangeNotifierProvider<CommunityProvider>.value(value: _community),
        ChangeNotifierProvider<SessionController>.value(value: _session),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          title: AppConfig.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          builder: (context, child) => _DemoBannerFrame(
            show: widget.dependencies.demoMode,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const _RootGate(),
        ),
      ),
    );
  }
}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final session = context.watch<SessionController>();

    Widget child;
    if (auth.initialising) {
      child = const _Splash(key: ValueKey('splash'));
    } else if (!settings.onboardingDone) {
      child = const OnboardingScreen(key: ValueKey('onboarding'));
    } else if (!auth.isSignedIn) {
      child = const AuthScreen(key: ValueKey('auth'));
    } else if (session.status != SessionStatus.ready) {
      child = const _Splash(key: ValueKey('loading'), message: 'Loading…');
    } else {
      child = const HomeShell(key: ValueKey('home'));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Adds the "Demo mode" banner above every screen in demo mode.
class _DemoBannerFrame extends StatelessWidget {
  const _DemoBannerFrame({required this.show, required this.child});

  final bool show;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!show) return child;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final background = dark ? const Color(0xFF4A3A00) : const Color(0xFFFFF1C2);
    final foreground = dark ? const Color(0xFFFFE08A) : const Color(0xFF5C4400);
    return Column(
      children: [
        Material(
          color: background,
          child: SafeArea(
            bottom: false,
            child: Semantics(
              label: 'Demo mode. Data is stored only in this browser.',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.science_outlined,
                        size: 14,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: ExcludeSemantics(
                        child: Text(
                          MediaQuery.sizeOf(context).width < 600
                              ? 'Demo mode · data stays on this device'
                              : 'Demo mode · data stays on this device · '
                                    'community members are fictional',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: foreground,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}
