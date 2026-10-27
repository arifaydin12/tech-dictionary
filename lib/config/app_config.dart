/// Compile-time configuration.
///
/// Demo mode is switched on with `--dart-define=DEMO_MODE=true`. In demo mode
/// Firebase is never initialised and every repository is backed by local
/// storage and seeded data, so the app runs with zero configuration.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Tech Dictionary';

  static const bool demoMode = bool.fromEnvironment('DEMO_MODE');
}
