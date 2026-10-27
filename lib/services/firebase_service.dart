import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/word.dart';
import '../models/correction_suggestion.dart';
import '../models/user_ranking.dart';

/// Firebase Service sınıfı - tüm Firebase işlemleri burada yönetilir
class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();

  factory FirebaseService() {
    return _instance;
  }

  FirebaseService._internal() {
    // Firebase instances'ları başlat
    _auth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;
    _storage = FirebaseStorage.instance;
    _initialized = true;
  }

  // Firebase instances - late olarak tanımla
  late final FirebaseAuth _auth;
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;
  late bool _initialized = false;

  // Getters
  User? get currentUser => _initialized ? _auth.currentUser : null;
  bool get isLoggedIn => _initialized && _auth.currentUser != null;
  String? get userEmail => _initialized ? _auth.currentUser?.email : null;
  String? get userId => _initialized ? _auth.currentUser?.uid : null;

  /// Firebase Auth hatalarını Türkçe mesajlara çevir
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Şifre çok zayıf. En az 6 karakter kullanın.';
      case 'email-already-in-use':
        return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email':
        return 'Geçersiz e-posta adresi.';
      case 'user-not-found':
        return 'Kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış.';
      case 'too-many-requests':
        return 'Çok fazla deneme yaptınız. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'network-request-failed':
        return 'Ağ bağlantısı hatası. İnternet bağlantınızı kontrol edin.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Kullanıcı kaydı (Sign Up)
  Future<User?> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    try {
      debugPrint('📝 Kayıt başlıyor: $email');
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✓ Auth kaydı başarılı: ${result.user?.uid}');

      // Kullanıcı adını Firebase Auth'a kaydet
      if (displayName != null && displayName.isNotEmpty) {
        await result.user?.updateDisplayName(displayName);
        await result.user?.reload(); // Kullanıcıyı yeniden yükle
        debugPrint('✓ Display name güncellendi: $displayName');
      }

      // Firestore'a kullanıcı bilgilerini kaydet
      if (result.user?.uid != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'displayName': displayName ?? email.split('@')[0],
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        });
        debugPrint('✓ Firestore kaydı başarılı: ${result.user!.uid}');
      }

      // Güncellenmiş kullanıcıyı döndür
      return _auth.currentUser;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auth Kayıt hatası: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Firestore Kayıt hatası: $e');
      throw Exception(
        'Kayıt sırasında bir hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  /// Kullanıcı girişi (Login)
  Future<User?> login(String email, String password) async {
    try {
      debugPrint('🔓 Giriş deneniyor: $email');
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint('✓ Giriş başarılı: ${result.user?.uid}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Giriş hatası: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Giriş genel hatası: $e');
      throw Exception(
        'Giriş sırasında bir hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  /// Google ile Giriş (Sign In with Google)
  Future<User?> signInWithGoogle() async {
    try {
      debugPrint('🔓 Google ile giriş deneniyor...');

      // Google Sign In yapılandırması (Emulator'da forceCodeForRefreshToken kullan)
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('❌ Google giriş iptal edildi');
        return null;
      }

      debugPrint('✓ Google hesabı seçildi: ${googleUser.email}');

      // Google authentication'ı al (emulator'da retry yapabilir)
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint('⚠️ Google authentication retry: $e');
        // Emulator'da bazen timeout olabilir, tekrar dene
        await Future.delayed(const Duration(seconds: 1));
        googleAuth = await googleUser.authentication;
      }

      if (googleAuth.accessToken == null || googleAuth.idToken == null) {
        debugPrint('❌ Google token alınamadı');
        return null;
      }

      // Firebase'e Google credential'ı ile giriş yap
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final result = await _auth.signInWithCredential(credential);
      debugPrint('✓ Firebase Google giriş başarılı: ${result.user?.uid}');

      // Firestore'a kullanıcı bilgilerini kaydet (yeni kullanıcı ise)
      if (result.user?.uid != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(result.user!.uid)
            .get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(result.user!.uid).set({
            'email': result.user!.email,
            'displayName': result.user!.displayName,
            'photoURL': result.user!.photoURL,
            'createdAt': DateTime.now().toIso8601String(),
            'updatedAt': DateTime.now().toIso8601String(),
          });
          debugPrint('✓ Yeni Google kullanıcı Firestore\'a kaydedildi');
        } else {
          debugPrint('✓ Var olan Google kullanıcı giriş yaptı');
        }
      }

      return result.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Firebase Google giriş hatası: ${e.code} - ${e.message}');
      throw Exception(_getAuthErrorMessage(e.code));
    } catch (e) {
      debugPrint('❌ Google giriş genel hatası: $e');
      throw Exception(
        'Google ile giriş sırasında bir hata oluştu. Lütfen tekrar deneyin.',
      );
    }
  }

  /// Çıkış
  Future<void> logout() async {
    try {
      await _auth.signOut();
      // Google Sign In de çıkış yap
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      debugPrint('✓ Çıkış başarılı');
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
      rethrow;
    }
  }

  /// Kelimeleri Firestore'a kaydet (paylaşılan koleksiyona)
  Future<String> saveWord(Word word) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final wordData = word.toFirestore();
      wordData['userId'] = userId;
      wordData['createdBy'] =
          currentUser?.displayName ??
          currentUser?.email?.split('@')[0] ??
          'Bilinmeyen';

      // Paylaşılan kelimeler koleksiyonuna ekle
      final docRef = await _firestore.collection('words').add(wordData);

      // Kullanıcının kendi kelimelerine de ekle
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('myWords')
          .doc(docRef.id)
          .set(wordData);

      // Sıralama güncelle
      await _updateUserRanking();

      debugPrint('✓ Kelime kaydedildi: ${word.term}');
      return docRef.id;
    } catch (e) {
      debugPrint('Kelime kaydetme hatası: $e');
      rethrow;
    }
  }

  /// Tüm paylaşılan kelimeleri al
  Future<List<Word>> getAllSharedWords() async {
    try {
      final snapshot = await _firestore
          .collection('words')
          .orderBy('createdAt', descending: true)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      return snapshot.docs
          .map((doc) {
            try {
              return Word.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('⚠️ Kelime parse hatası (${doc.id}): $e');
              return null;
            }
          })
          .whereType<Word>()
          .toList();
    } catch (e) {
      debugPrint('Paylaşılan kelimeleri alma hatası: $e');
      // Hata durumunda boş liste döndür, uygulama çalışmaya devam etsin
      return [];
    }
  }

  /// Kullanıcının kelimeleri al
  Future<List<Word>> getUserWords() async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('words')
          .get();
      return snapshot.docs
          .map((doc) => Word.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Kelimeleri alma hatası: $e');
      rethrow;
    }
  }

  /// Kelime güncelle (sadece sahibi güncelleyebilir)
  Future<void> updateWord(Word word) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    if (word.userId != userId)
      throw Exception('Bu kelimeyi düzenleme yetkiniz yok');

    try {
      final wordData = word.toFirestore();

      // Paylaşılan kelimeyi güncelle
      await _firestore.collection('words').doc(word.id).update(wordData);

      // Kullanıcının kendi kelimesini güncelle
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('myWords')
          .doc(word.id)
          .update(wordData);

      debugPrint('✓ Kelime güncellendi: ${word.term}');
    } catch (e) {
      debugPrint('Kelime güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Kelime sil (sadece sahibi silebilir)
  Future<void> deleteWord(String wordId) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');

    try {
      // Kelime sahibini kontrol et
      final wordDoc = await _firestore.collection('words').doc(wordId).get();
      if (!wordDoc.exists) throw Exception('Kelime bulunamadı');

      final wordData = wordDoc.data();
      if (wordData?['userId'] != userId) {
        throw Exception('Bu kelimeyi silme yetkiniz yok');
      }

      // Paylaşılan kelimeyi sil
      await _firestore.collection('words').doc(wordId).delete();

      // Kullanıcının kendi kelimesini sil
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('myWords')
          .doc(wordId)
          .delete();

      // Sıralama güncelle
      await _updateUserRanking();

      debugPrint('✓ Kelime silindi');
    } catch (e) {
      debugPrint('Kelime silme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının kendi kelimelerini al
  Future<List<Word>> getMyWords() async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('myWords')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => Word.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Kelimeleri alma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı bazlı favori ekle/çıkar
  Future<void> toggleFavorite(String wordId, bool isFavorite) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      if (isFavorite) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(wordId)
            .set({
              'wordId': wordId,
              'addedAt': DateTime.now().toIso8601String(),
            });
      } else {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favorites')
            .doc(wordId)
            .delete();
      }
      debugPrint('✓ Favori güncellendi');
    } catch (e) {
      debugPrint('Favori güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının favori kelimelerini al
  Future<List<Word>> getFavoriteWords() async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .get();

      if (favoritesSnapshot.docs.isEmpty) return [];

      final wordIds = favoritesSnapshot.docs.map((doc) => doc.id).toList();
      final words = <Word>[];

      for (final wordId in wordIds) {
        final wordDoc = await _firestore.collection('words').doc(wordId).get();
        if (wordDoc.exists) {
          words.add(Word.fromFirestore(wordDoc.data()!, wordDoc.id));
        }
      }

      return words;
    } catch (e) {
      debugPrint('Favori kelimeleri alma hatası: $e');
      rethrow;
    }
  }

  /// Kelimenin favori olup olmadığını kontrol et
  Future<bool> isFavorite(String wordId) async {
    if (!isLoggedIn) return false;
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc(wordId)
          .get();
      return doc.exists;
    } catch (e) {
      debugPrint('Favori kontrol hatası: $e');
      return false;
    }
  }

  /// Avatar resmini yükle
  Future<String> uploadAvatar(String filePath) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final ref = _storage.ref('avatars/$userId.jpg');
      // Gerçek uygulamada File kullanılır
      // await ref.putFile(File(filePath));
      // Placeholder URL döndür (demonstration)
      final url = await ref.getDownloadURL();
      debugPrint('✓ Avatar yüklendi');
      return url;
    } catch (e) {
      debugPrint('Avatar yükleme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı profil bilgisi güncelle
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      data['updatedAt'] = DateTime.now().toIso8601String();
      await _firestore.collection('users').doc(userId).update(data);
      debugPrint('✓ Profil güncellendi');
    } catch (e) {
      debugPrint('Profil güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcı profil bilgisini al
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      return doc.data();
    } catch (e) {
      debugPrint('Profil alma hatası: $e');
      rethrow;
    }
  }

  // ========== Düzeltme Önerileri ==========

  /// Düzeltme önerisi ekle
  Future<void> addCorrectionSuggestion(CorrectionSuggestion suggestion) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      await _firestore
          .collection('correctionSuggestions')
          .add(suggestion.toFirestore());
      debugPrint('✓ Düzeltme önerisi eklendi');
    } catch (e) {
      debugPrint('Düzeltme önerisi ekleme hatası: $e');
      rethrow;
    }
  }

  /// Kelime sahibinin düzeltme önerilerini al
  Future<List<CorrectionSuggestion>> getCorrectionSuggestions(
    String wordId,
  ) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      final snapshot = await _firestore
          .collection('correctionSuggestions')
          .where('wordId', isEqualTo: wordId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => CorrectionSuggestion.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Düzeltme önerilerini alma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının kelimelerine gelen tüm düzeltme önerilerini al
  Future<List<CorrectionSuggestion>> getMyWordCorrections() async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      // Önce kullanıcının kelimelerini al
      final myWordsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('myWords')
          .get();

      if (myWordsSnapshot.docs.isEmpty) return [];

      final wordIds = myWordsSnapshot.docs.map((doc) => doc.id).toList();
      final suggestions = <CorrectionSuggestion>[];

      for (final wordId in wordIds) {
        final snapshot = await _firestore
            .collection('correctionSuggestions')
            .where('wordId', isEqualTo: wordId)
            .where('status', isEqualTo: 'pending')
            .get();

        suggestions.addAll(
          snapshot.docs.map(
            (doc) => CorrectionSuggestion.fromFirestore(doc.data(), doc.id),
          ),
        );
      }

      suggestions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return suggestions;
    } catch (e) {
      debugPrint('Düzeltme önerilerini alma hatası: $e');
      rethrow;
    }
  }

  /// Düzeltme önerisini kabul et
  Future<void> acceptCorrection(String suggestionId, Word updatedWord) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      // Öneriyi al
      final suggestionDoc = await _firestore
          .collection('correctionSuggestions')
          .doc(suggestionId)
          .get();

      if (!suggestionDoc.exists) throw Exception('Öneri bulunamadı');

      final suggestion = CorrectionSuggestion.fromFirestore(
        suggestionDoc.data()!,
        suggestionId,
      );

      // Kelimeyi güncelle
      await updateWord(updatedWord);

      // Öneriyi kabul edildi olarak işaretle
      await _firestore
          .collection('correctionSuggestions')
          .doc(suggestionId)
          .update({'status': 'accepted'});

      debugPrint('✓ Düzeltme önerisi kabul edildi');
    } catch (e) {
      debugPrint('Düzeltme önerisi kabul hatası: $e');
      rethrow;
    }
  }

  /// Düzeltme önerisini reddet
  Future<void> rejectCorrection(String suggestionId) async {
    if (!isLoggedIn) throw Exception('Giriş yapılmadı');
    try {
      await _firestore
          .collection('correctionSuggestions')
          .doc(suggestionId)
          .update({'status': 'rejected'});
      debugPrint('✓ Düzeltme önerisi reddedildi');
    } catch (e) {
      debugPrint('Düzeltme önerisi reddetme hatası: $e');
      rethrow;
    }
  }

  // ========== Sıralama Sistemi ==========

  /// Kullanıcı sıralamasını güncelle
  Future<void> _updateUserRanking() async {
    if (!isLoggedIn) return;

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      // Kullanıcının kelimelerini al
      final myWordsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('myWords')
          .get();

      final allWords = myWordsSnapshot.docs;
      final totalCount = allWords.length;

      // Günlük sayı
      final dailyCount = allWords.where((doc) {
        final createdAt = DateTime.parse(doc.data()['createdAt'] as String);
        return createdAt.isAfter(startOfDay);
      }).length;

      // Haftalık sayı
      final weeklyCount = allWords.where((doc) {
        final createdAt = DateTime.parse(doc.data()['createdAt'] as String);
        return createdAt.isAfter(startOfWeek);
      }).length;

      // Aylık sayı
      final monthlyCount = allWords.where((doc) {
        final createdAt = DateTime.parse(doc.data()['createdAt'] as String);
        return createdAt.isAfter(startOfMonth);
      }).length;

      // Sıralama verisini güncelle
      await _firestore.collection('rankings').doc(userId).set({
        'userName':
            currentUser?.displayName ??
            currentUser?.email?.split('@')[0] ??
            'Bilinmeyen',
        'userPhotoUrl': currentUser?.photoURL,
        'wordCount': totalCount,
        'dailyWordCount': dailyCount,
        'weeklyWordCount': weeklyCount,
        'monthlyWordCount': monthlyCount,
        'lastUpdated': now.toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('✓ Sıralama güncellendi');
    } catch (e) {
      debugPrint('Sıralama güncelleme hatası: $e');
    }
  }

  /// Günlük sıralamayı al
  Future<List<UserRanking>> getDailyRankings({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .orderBy('dailyWordCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserRanking.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Günlük sıralama alma hatası: $e');
      rethrow;
    }
  }

  /// Haftalık sıralamayı al
  Future<List<UserRanking>> getWeeklyRankings({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .orderBy('weeklyWordCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserRanking.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Haftalık sıralama alma hatası: $e');
      rethrow;
    }
  }

  /// Aylık sıralamayı al
  Future<List<UserRanking>> getMonthlyRankings({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .orderBy('monthlyWordCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserRanking.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Aylık sıralama alma hatası: $e');
      rethrow;
    }
  }

  /// Toplam sıralamayı al
  Future<List<UserRanking>> getTotalRankings({int limit = 100}) async {
    try {
      final snapshot = await _firestore
          .collection('rankings')
          .orderBy('wordCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => UserRanking.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Toplam sıralama alma hatası: $e');
      rethrow;
    }
  }

  /// Kullanıcının sıralamasını al
  Future<UserRanking?> getMyRanking() async {
    if (!isLoggedIn) return null;
    try {
      final doc = await _firestore.collection('rankings').doc(userId).get();
      if (!doc.exists) return null;
      return UserRanking.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Kullanıcı sıralaması alma hatası: $e');
      return null;
    }
  }
}
