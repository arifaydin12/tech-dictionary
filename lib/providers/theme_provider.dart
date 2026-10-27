import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preferences.dart';
import '../services/user_service.dart';

/// Theme Provider - Tema yönetimi ve Firebase senkronizasyonu
class ThemeProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;
  bool _isLoggedIn = false;

  ThemeMode get themeMode => _themeMode;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeProvider() {
    _loadThemeFromLocal();
  }

  /// Local storage'dan tema yükle
  Future<void> _loadThemeFromLocal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeName = prefs.getString('themeMode') ?? 'system';

      _themeMode = _stringToThemeMode(themeName);
      _isInitialized = true;
      notifyListeners();

      debugPrint('✓ Tema local storage\'dan yüklendi: $themeName');
    } catch (e) {
      debugPrint('❌ Tema yükleme hatası: $e');
    }
  }

  /// Firebase'den tema yükle (Kullanıcı giriş yaptıysa)
  Future<void> loadThemeFromFirebase() async {
    if (!_userService.isLoggedIn) {
      debugPrint('⚠️ Kullanıcı giriş yapmamış, tema Firebase\'den yüklenemedi');
      return;
    }

    try {
      final preferences = await _userService.getUserPreferences();

      if (preferences != null) {
        _themeMode = _preferenceToThemeMode(preferences.themeMode);
        _isLoggedIn = true;

        // Local storage'ı da güncelle
        await _saveThemeToLocal(_themeMode);

        notifyListeners();
        debugPrint(
          '✓ Tema Firebase\'den yüklendi: ${preferences.themeMode.name}',
        );
      }
    } catch (e) {
      debugPrint('❌ Firebase tema yükleme hatası: $e');
    }
  }

  /// Temayı local storage'a kaydet
  Future<void> _saveThemeToLocal(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('themeMode', _themeModeToString(mode));
      debugPrint('✓ Tema local storage\'a kaydedildi');
    } catch (e) {
      debugPrint('❌ Tema kaydetme hatası: $e');
    }
  }

  /// Temayı Firebase'e kaydet (Kullanıcı giriş yaptıysa)
  Future<void> _saveThemeToFirebase(ThemePreference preference) async {
    if (!_userService.isLoggedIn) {
      debugPrint('⚠️ Kullanıcı giriş yapmamış, tema Firebase\'e kaydedilemedi');
      return;
    }

    try {
      await _userService.updateThemeMode(preference);
      _isLoggedIn = true;
      debugPrint('✓ Tema Firebase\'e kaydedildi: ${preference.name}');
    } catch (e) {
      debugPrint('❌ Firebase tema kaydetme hatası: $e');
    }
  }

  /// Temayı değiştir (Toggle: Light -> Dark -> System)
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.system);
        break;
      case ThemeMode.system:
        await setThemeMode(ThemeMode.light);
        break;
    }
  }

  /// Tema modunu ayarla
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    // Local storage'a kaydet
    await _saveThemeToLocal(mode);

    // Firebase'e kaydet
    final preference = _themeModeToPreference(mode);
    if (_userService.isLoggedIn) {
      await _saveThemeToFirebase(preference);
    }

    debugPrint('✓ Tema değiştirildi: ${_themeModeToString(mode)}');
  }

  /// Açık temaya geç
  Future<void> setLightTheme() async {
    await setThemeMode(ThemeMode.light);
  }

  /// Koyu temaya geç
  Future<void> setDarkTheme() async {
    await setThemeMode(ThemeMode.dark);
  }

  /// Sistem temasını takip et
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }

  /// Kullanıcı giriş yaptığında çağrılır
  Future<void> onUserLogin() async {
    await loadThemeFromFirebase();
  }

  /// Kullanıcı çıkış yaptığında çağrılır
  Future<void> onUserLogout() async {
    _isLoggedIn = false;
    // Local tema ayarı korunur
    debugPrint('✓ Tema ayarları Firebase bağlantısı kesildi');
  }

  /// Kullanıcı verileri ile senkronize et
  Future<void> syncWithUserPreferences(UserPreferences preferences) async {
    final mode = _preferenceToThemeMode(preferences.themeMode);
    if (_themeMode != mode) {
      _themeMode = mode;
      await _saveThemeToLocal(mode);
      notifyListeners();
      debugPrint('✓ Tema kullanıcı tercihleriyle senkronize edildi');
    }
  }

  // Helper methods

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  ThemeMode _stringToThemeMode(String str) {
    switch (str) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.system;
    }
  }

  ThemePreference _themeModeToPreference(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return ThemePreference.light;
      case ThemeMode.dark:
        return ThemePreference.dark;
      case ThemeMode.system:
        return ThemePreference.system;
    }
  }

  ThemeMode _preferenceToThemeMode(ThemePreference preference) {
    switch (preference) {
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
      case ThemePreference.system:
        return ThemeMode.system;
    }
  }

  /// Tema bilgilerini al
  Map<String, dynamic> getThemeInfo() {
    return {
      'currentMode': _themeModeToString(_themeMode),
      'isLoggedIn': _isLoggedIn,
      'isInitialized': _isInitialized,
      'isDarkMode': isDarkMode,
      'isLightMode': isLightMode,
      'isSystemMode': isSystemMode,
    };
  }
}
