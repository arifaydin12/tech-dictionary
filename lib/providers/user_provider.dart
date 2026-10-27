import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../models/user_preferences.dart';
import '../models/word.dart';
import '../services/user_service.dart';

/// User Provider - Kullanıcı verilerini yönetir
class UserProvider extends ChangeNotifier {
  final UserService _userService = UserService();

  UserProfile? _userProfile;
  UserPreferences? _userPreferences;
  List<Word> _favorites = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserProfile? get userProfile => _userProfile;
  UserPreferences? get userPreferences => _userPreferences;
  List<Word> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _userService.isLoggedIn;

  /// Loading durumunu ayarla
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Hata mesajını ayarla
  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  // ==================== PROFILE OPERATIONS ====================

  /// Kullanıcı profilini yükle
  Future<void> loadUserProfile() async {
    try {
      _setLoading(true);
      _setError(null);

      _userProfile = await _userService.getUserProfile();

      if (_userProfile != null) {
        debugPrint('✓ Profil yüklendi: ${_userProfile!.displayName}');
      }

      notifyListeners();
    } catch (e) {
      _setError('Profil yüklenemedi: ${e.toString()}');
      debugPrint('❌ Profil yükleme hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı profilini güncelle
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      _setLoading(true);
      _setError(null);

      await _userService.updateUserProfile(updates);

      // Profili yeniden yükle
      await loadUserProfile();

      debugPrint('✓ Profil güncellendi');
      return true;
    } catch (e) {
      _setError('Profil güncellenemedi: ${e.toString()}');
      debugPrint('❌ Profil güncelleme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı profilini oluştur
  Future<bool> createProfile(UserProfile profile) async {
    try {
      _setLoading(true);
      _setError(null);

      await _userService.createUserProfile(profile);
      _userProfile = profile;

      notifyListeners();
      debugPrint('✓ Profil oluşturuldu');
      return true;
    } catch (e) {
      _setError('Profil oluşturulamadı: ${e.toString()}');
      debugPrint('❌ Profil oluşturma hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ==================== PREFERENCES OPERATIONS ====================

  /// Kullanıcı tercihlerini yükle
  Future<void> loadUserPreferences() async {
    try {
      _setLoading(true);
      _setError(null);

      _userPreferences = await _userService.getUserPreferences();

      if (_userPreferences != null) {
        debugPrint('✓ Tercihler yüklendi');
      }

      notifyListeners();
    } catch (e) {
      _setError('Tercihler yüklenemedi: ${e.toString()}');
      debugPrint('❌ Tercihler yükleme hatası: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı tercihlerini güncelle
  Future<bool> updatePreferences(Map<String, dynamic> updates) async {
    try {
      _setError(null);

      await _userService.updateUserPreferences(updates);

      // Tercihleri yeniden yükle
      await loadUserPreferences();

      debugPrint('✓ Tercihler güncellendi');
      return true;
    } catch (e) {
      _setError('Tercihler güncellenemedi: ${e.toString()}');
      debugPrint('❌ Tercihler güncelleme hatası: $e');
      return false;
    }
  }

  /// Tema modunu güncelle
  Future<void> updateThemeMode(ThemePreference theme) async {
    await _userService.updateThemeMode(theme);
    await loadUserPreferences();
  }

  /// Dil ayarını güncelle
  Future<void> updateLanguage(String language) async {
    await _userService.updateLanguage(language);
    await loadUserPreferences();
  }

  /// Bildirim ayarlarını güncelle
  Future<void> updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) async {
    await _userService.updateNotificationSettings(
      enabled: enabled,
      sound: sound,
      vibration: vibration,
    );
    await loadUserPreferences();
  }

  // ==================== FAVORITES OPERATIONS ====================

  /// Favorileri yükle
  Future<void> loadFavorites() async {
    try {
      _setError(null);
      _favorites = await _userService.getAllFavorites();
      debugPrint('✓ ${_favorites.length} favori yüklendi');
      notifyListeners();
    } catch (e) {
      _setError('Favoriler yüklenemedi: ${e.toString()}');
      debugPrint('❌ Favoriler yükleme hatası: $e');
    }
  }

  /// Favorilere ekle
  Future<bool> addToFavorites(Word word) async {
    try {
      _setError(null);

      await _userService.addFavorite(word);

      // Yerel listeyi güncelle
      if (!_favorites.any((w) => w.id == word.id)) {
        _favorites.insert(0, word);
        notifyListeners();
      }

      debugPrint('✓ Favorilere eklendi: ${word.term}');
      return true;
    } catch (e) {
      _setError('Favorilere eklenemedi: ${e.toString()}');
      debugPrint('❌ Favorilere ekleme hatası: $e');
      return false;
    }
  }

  /// Favorilerden çıkar
  Future<bool> removeFromFavorites(String wordId) async {
    try {
      _setError(null);

      await _userService.removeFavorite(wordId);

      // Yerel listeden çıkar
      _favorites.removeWhere((w) => w.id == wordId);
      notifyListeners();

      debugPrint('✓ Favorilerden çıkarıldı');
      return true;
    } catch (e) {
      _setError('Favorilerden çıkarılamadı: ${e.toString()}');
      debugPrint('❌ Favorilerden çıkarma hatası: $e');
      return false;
    }
  }

  /// Favori durumunu değiştir (toggle)
  Future<bool> toggleFavorite(Word word) async {
    final isFav = await _userService.isFavorite(word.id ?? '');

    if (isFav) {
      return await removeFromFavorites(word.id!);
    } else {
      return await addToFavorites(word);
    }
  }

  /// Kelime favori mi kontrol et
  Future<bool> isFavorite(String wordId) async {
    return await _userService.isFavorite(wordId);
  }

  /// Favori sayısını al
  Future<int> getFavoriteCount() async {
    return await _userService.getFavoriteCount();
  }

  /// Favorileri stream olarak dinle
  Stream<List<Word>> watchFavorites() {
    return _userService.watchFavorites();
  }

  // ==================== STATISTICS ====================

  /// İstatistikleri güncelle
  Future<void> updateStatistics({int? wordsLearned, int? currentStreak}) async {
    await _userService.updateStatistics(
      wordsLearned: wordsLearned,
      currentStreak: currentStreak,
    );
    await loadUserPreferences();
  }

  /// Öğrenilen kelime sayısını artır
  Future<void> incrementWordsLearned([int count = 1]) async {
    await updateStatistics(wordsLearned: count);
  }

  /// Streak'i güncelle
  Future<void> updateStreak(int streak) async {
    await updateStatistics(currentStreak: streak);
  }

  // ==================== INITIALIZATION ====================

  /// Tüm kullanıcı verilerini yükle
  Future<void> initializeUserData() async {
    if (!_userService.isLoggedIn) {
      debugPrint('⚠️ Kullanıcı giriş yapmamış');
      return;
    }

    try {
      _setLoading(true);
      debugPrint('📱 Kullanıcı verileri yükleniyor...');

      // Paralel olarak yükle
      await Future.wait([
        loadUserProfile(),
        loadUserPreferences(),
        loadFavorites(),
      ]);

      // Son giriş tarihini güncelle
      await _userService.updateLastLogin();

      debugPrint('✓ Tüm kullanıcı verileri yüklendi');
    } catch (e) {
      debugPrint('❌ Veri yükleme hatası: $e');
      _setError('Veriler yüklenirken hata oluştu');
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı verilerini temizle (Çıkış yaparken)
  void clearUserData() {
    _userProfile = null;
    _userPreferences = null;
    _favorites = [];
    _errorMessage = null;
    notifyListeners();
    debugPrint('✓ Kullanıcı verileri temizlendi');
  }

  // ==================== DATA MANAGEMENT ====================

  /// Kullanıcı verilerini dışa aktar
  Future<Map<String, dynamic>?> exportUserData() async {
    try {
      _setLoading(true);
      final data = await _userService.exportUserData();
      debugPrint('✓ Veriler dışa aktarıldı');
      return data;
    } catch (e) {
      _setError('Veriler dışa aktarılamadı: ${e.toString()}');
      debugPrint('❌ Dışa aktarma hatası: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Kullanıcı verilerini sil
  Future<bool> deleteUserData() async {
    try {
      _setLoading(true);
      await _userService.deleteUserData();
      clearUserData();
      debugPrint('✓ Tüm veriler silindi');
      return true;
    } catch (e) {
      _setError('Veriler silinemedi: ${e.toString()}');
      debugPrint('❌ Veri silme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
