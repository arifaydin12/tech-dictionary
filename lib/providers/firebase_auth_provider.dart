import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/word_service.dart';

/// Firebase Authentication Provider
class FirebaseAuthProvider extends ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();
  final WordService _wordService = WordService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;
  FirebaseService get firebaseService => _firebaseService;

  // Setter for loading state
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  FirebaseAuthProvider() {
    _currentUser = _firebaseService.currentUser;
  }

  /// Local kelimeleri Firebase'e senkronize et
  Future<void> _syncLocalWordsToFirebase() async {
    try {
      debugPrint('📤 Local kelimeleri Firebase\'e sinkronize ediliyor...');
      final localWords = _wordService.getAllWords();

      for (final word in localWords) {
        await _firebaseService.saveWord(word);
        debugPrint('✓ Kelime sinkronize edildi: ${word.term}');
      }
      debugPrint(
        '✓ Tüm kelimeleri Firebase\'e sinkronize edildi (${localWords.length} kelime)',
      );
    } catch (e) {
      debugPrint('❌ Sinkronizasyon hatası: $e');
    }
  }

  /// Kaydol
  Future<bool> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _firebaseService.signUp(
        email,
        password,
        displayName: displayName,
      );
      _currentUser = user;

      // Kayıt sonrası kullanıcı verilerini oluştur
      if (user != null) {
        // Firestore'da user profile oluştur
        await _firebaseService.updateUserProfile({
          'email': user.email,
          'displayName': displayName ?? user.email!.split('@')[0],
          'photoURL': user.photoURL,
          'accountType': 'email',
          'isEmailVerified': user.emailVerified,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });

        // Local kelimeleri sinkronize et
        await _syncLocalWordsToFirebase();

        debugPrint('✓ Kullanıcı başarıyla kaydedildi ve profil oluşturuldu');
      }

      notifyListeners();
      return user != null;
    } catch (e) {
      // Hata mesajını Exception'dan çıkar
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = errorMessage;
      debugPrint('❌ Provider kayıt hatası: $errorMessage');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Giriş yap
  Future<bool> login(String email, String password) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _firebaseService.login(email, password);
      _currentUser = user;

      // Giriş sonrası local kelimeleri sinkronize et
      if (user != null) {
        await _syncLocalWordsToFirebase();
      }

      notifyListeners();
      return user != null;
    } catch (e) {
      // Hata mesajını Exception'dan çıkar
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = errorMessage;
      debugPrint('❌ Provider giriş hatası: $errorMessage');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Google ile giriş yap
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final user = await _firebaseService.signInWithGoogle();
      _currentUser = user;

      // Giriş sonrası local kelimeleri sinkronize et
      if (user != null) {
        await _syncLocalWordsToFirebase();
      }

      notifyListeners();
      return user != null;
    } catch (e) {
      // Hata mesajını Exception'dan çıkar
      final errorMessage = e.toString().replaceFirst('Exception: ', '');
      _errorMessage = errorMessage;
      debugPrint('❌ Provider Google giriş hatası: $errorMessage');
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      await _firebaseService.logout();
      _currentUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Çıkış hatası: ${e.toString()}';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Kullanıcı profil güncelle
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _firebaseService.updateUserProfile(data);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Profil güncelleme hatası: ${e.toString()}';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
