import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_preferences.dart';
import '../models/user_profile.dart';
import '../models/word.dart';

/// User Service - Kullanıcı verilerini Firebase'de yönetir
class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Mevcut kullanıcı ID'si
  String? get currentUserId => _auth.currentUser?.uid;

  /// Kullanıcı giriş yapmış mı?
  bool get isLoggedIn => _auth.currentUser != null;

  // ==================== USER PROFILE ====================

  /// Kullanıcı profili oluştur
  Future<void> createUserProfile(UserProfile profile) async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(profile.toFirestore());
      debugPrint('✓ Kullanıcı profili oluşturuldu: ${profile.displayName}');
    } catch (e) {
      debugPrint('❌ Profil oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı profilini al
  Future<UserProfile?> getUserProfile([String? userId]) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null) return null;

      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;

      return UserProfile.fromFirestore(doc.data()!);
    } catch (e) {
      print('❌ Profil alma hatası: $e');
      return null;
    }
  }

  /// Kullanıcı profilini güncelle
  Future<void> updateUserProfile(Map<String, dynamic> updates) async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('users').doc(currentUserId).update(updates);
      debugPrint('✓ Profil güncellendi');
    } catch (e) {
      debugPrint('❌ Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Son giriş tarihini güncelle
  Future<void> updateLastLogin() async {
    if (!isLoggedIn) return;

    try {
      await _firestore.collection('users').doc(currentUserId).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('❌ Son giriş güncelleme hatası: $e');
    }
  }

  // ==================== USER PREFERENCES ====================

  /// Kullanıcı tercihlerini oluştur
  Future<void> createUserPreferences(UserPreferences preferences) async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('preferences')
          .set(preferences.toFirestore());
      debugPrint('✓ Kullanıcı tercihleri oluşturuldu');
    } catch (e) {
      debugPrint('❌ Tercihler oluşturma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı tercihlerini al
  Future<UserPreferences?> getUserPreferences() async {
    if (!isLoggedIn) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('preferences')
          .get();

      if (!doc.exists) {
        // Varsayılan tercihler oluştur
        final defaultPrefs = UserPreferences(userId: currentUserId!);
        await createUserPreferences(defaultPrefs);
        return defaultPrefs;
      }

      return UserPreferences.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('❌ Tercihler alma hatası: $e');
      return null;
    }
  }

  /// Kullanıcı tercihlerini güncelle
  Future<void> updateUserPreferences(Map<String, dynamic> updates) async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      updates['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('preferences')
          .update(updates);
      debugPrint('✓ Tercihler güncellendi');
    } catch (e) {
      debugPrint('❌ Tercihler güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Tema modunu güncelle
  Future<void> updateThemeMode(ThemePreference theme) async {
    await updateUserPreferences({'themeMode': theme.name});
  }

  /// Dil ayarını güncelle
  Future<void> updateLanguage(String language) async {
    await updateUserPreferences({'language': language});
  }

  /// Bildirim ayarını güncelle
  Future<void> updateNotificationSettings({
    bool? enabled,
    bool? sound,
    bool? vibration,
  }) async {
    final updates = <String, dynamic>{};
    if (enabled != null) updates['notificationsEnabled'] = enabled;
    if (sound != null) updates['soundEnabled'] = sound;
    if (vibration != null) updates['vibrationEnabled'] = vibration;

    if (updates.isNotEmpty) {
      await updateUserPreferences(updates);
    }
  }

  // ==================== FAVORITES ====================

  /// Favorilere ekle
  Future<void> addFavorite(Word word) async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      // Word'ü favoriler koleksiyonuna ekle
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(word.id)
          .set({
            ...word.toFirestore(),
            'favoritedAt': DateTime.now().toIso8601String(),
          });

      debugPrint('✓ Favorilere eklendi: ${word.term}');
    } catch (e) {
      debugPrint('❌ Favorilere ekleme hatası: $e');
      rethrow;
    }
  }

  /// Favorilerden çıkar
  Future<void> removeFavorite(String wordId) async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(wordId)
          .delete();

      debugPrint('✓ Favorilerden çıkarıldı');
    } catch (e) {
      debugPrint('❌ Favorilerden çıkarma hatası: $e');
      rethrow;
    }
  }

  /// Favori mi kontrol et
  Future<bool> isFavorite(String wordId) async {
    if (!isLoggedIn) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .doc(wordId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('❌ Favori kontrolü hatası: $e');
      return false;
    }
  }

  /// Tüm favorileri al
  Future<List<Word>> getAllFavorites() async {
    if (!isLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .orderBy('favoritedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Word.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Favorileri alma hatası: $e');
      return [];
    }
  }

  /// Favori sayısını al
  Future<int> getFavoriteCount() async {
    if (!isLoggedIn) return 0;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ Favori sayısı alma hatası: $e');
      return 0;
    }
  }

  /// Favorileri stream olarak dinle
  Stream<List<Word>> watchFavorites() {
    if (!isLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('favorites')
        .orderBy('favoritedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Word.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // ==================== USER WORDS ====================

  /// Kullanıcı kelimelerini al
  Future<List<Word>> getUserWords() async {
    if (!isLoggedIn) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('words')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => Word.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('❌ Kelimeleri alma hatası: $e');
      return [];
    }
  }

  /// Kullanıcı kelimelerini stream olarak dinle
  Stream<List<Word>> watchUserWords() {
    if (!isLoggedIn) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('words')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Word.fromFirestore(doc.data(), doc.id))
              .toList();
        });
  }

  // ==================== STATISTICS ====================

  /// İstatistikleri güncelle
  Future<void> updateStatistics({int? wordsLearned, int? currentStreak}) async {
    if (!isLoggedIn) return;

    try {
      final updates = <String, dynamic>{
        'updatedAt': DateTime.now().toIso8601String(),
        'lastActiveDate': DateTime.now().toIso8601String(),
      };

      if (wordsLearned != null) {
        updates['totalWordsLearned'] = FieldValue.increment(wordsLearned);
      }
      if (currentStreak != null) {
        updates['currentStreak'] = currentStreak;
      }

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .doc('preferences')
          .update(updates);

      debugPrint('✓ İstatistikler güncellendi');
    } catch (e) {
      debugPrint('❌ İstatistik güncelleme hatası: $e');
    }
  }

  // ==================== BULK OPERATIONS ====================

  /// Tüm kullanıcı verilerini sil (Hesap silme)
  Future<void> deleteUserData() async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      final batch = _firestore.batch();

      // Favorileri sil
      final favorites = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('favorites')
          .get();
      for (final doc in favorites.docs) {
        batch.delete(doc.reference);
      }

      // Kelimeleri sil
      final words = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('words')
          .get();
      for (final doc in words.docs) {
        batch.delete(doc.reference);
      }

      // Ayarları sil
      final settings = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('settings')
          .get();
      for (final doc in settings.docs) {
        batch.delete(doc.reference);
      }

      // Kullanıcı belgesini sil
      batch.delete(_firestore.collection('users').doc(currentUserId));

      await batch.commit();
      debugPrint('✓ Tüm kullanıcı verileri silindi');
    } catch (e) {
      debugPrint('❌ Veri silme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı verilerini dışa aktar
  Future<Map<String, dynamic>> exportUserData() async {
    if (!isLoggedIn) throw Exception('Kullanıcı giriş yapmamış');

    try {
      final profile = await getUserProfile();
      final preferences = await getUserPreferences();
      final words = await getUserWords();
      final favorites = await getAllFavorites();

      return {
        'profile': profile?.toFirestore(),
        'preferences': preferences?.toFirestore(),
        'words': words.map((w) => w.toFirestore()).toList(),
        'favorites': favorites.map((w) => w.toFirestore()).toList(),
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Veri dışa aktarma hatası: $e');
      rethrow;
    }
  }
}
