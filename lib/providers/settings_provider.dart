import 'package:flutter/material.dart';

import '../data/key_value_store.dart';

/// Device-level preferences (theme, onboarding, daily goal, speech rate).
/// Always stored locally, also in Firebase mode.
class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._store);

  final KeyValueStore _store;

  static const _themeKey = 'settings.theme';
  static const _onboardingKey = 'settings.onboardingDone';
  static const _goalKey = 'settings.dailyGoal';
  static const _rateKey = 'settings.speechRate';

  ThemeMode _themeMode = ThemeMode.system;
  bool _onboardingDone = false;
  int _dailyGoal = 20;
  double _speechRate = 0.5;

  ThemeMode get themeMode => _themeMode;
  bool get onboardingDone => _onboardingDone;

  /// Target number of answered questions per day.
  int get dailyGoal => _dailyGoal;

  /// Text-to-speech rate in the range 0.2..0.8.
  double get speechRate => _speechRate;

  static const List<int> dailyGoalOptions = [10, 20, 30, 50];

  void load() {
    final theme = _store.read(_themeKey);
    _themeMode = ThemeMode.values.firstWhere(
      (m) => m.name == theme,
      orElse: () => ThemeMode.system,
    );
    _onboardingDone = _store.read(_onboardingKey) == 'true';
    _dailyGoal = int.tryParse(_store.read(_goalKey) ?? '') ?? 20;
    _speechRate = (double.tryParse(_store.read(_rateKey) ?? '') ?? 0.5).clamp(
      0.2,
      0.8,
    );
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _store.write(_themeKey, mode.name);
  }

  Future<void> completeOnboarding() async {
    _onboardingDone = true;
    notifyListeners();
    await _store.write(_onboardingKey, 'true');
  }

  Future<void> setDailyGoal(int goal) async {
    _dailyGoal = goal;
    notifyListeners();
    await _store.write(_goalKey, goal.toString());
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.2, 0.8);
    notifyListeners();
    await _store.write(_rateKey, _speechRate.toString());
  }
}
