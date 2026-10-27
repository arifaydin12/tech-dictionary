import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social_interaction.dart';
import '../services/firebase_service.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Yorum ekle
  Future<void> addComment(Comment comment) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      await _firestore
          .collection('words')
          .doc(comment.wordId)
          .collection('comments')
          .add(comment.toFirestore());
    } catch (e) {
      print('Yorum ekleme hatası: $e');
      rethrow;
    }
  }

  /// Yorumları al
  Future<List<Comment>> getComments(String wordId) async {
    try {
      final snapshot = await _firestore
          .collection('words')
          .doc(wordId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();
      
      return snapshot.docs
          .map((doc) => Comment.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Yorum alma hatası: $e');
      return [];
    }
  }

  /// Yorumu beğen
  Future<void> likeComment(String wordId, String commentId) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      final commentRef = _firestore
          .collection('words')
          .doc(wordId)
          .collection('comments')
          .doc(commentId);
      
      await commentRef.update({
        'likes': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([_firebaseService.userId!]),
      });
    } catch (e) {
      print('Yorum beğenme hatası: $e');
      rethrow;
    }
  }

  /// Kelimeyi beğen
  Future<void> likeWord(String wordId) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      await _firestore
          .collection('words')
          .doc(wordId)
          .collection('likes')
          .doc(_firebaseService.userId!)
          .set({
        'userId': _firebaseService.userId!,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      // Kelime beğeni sayısını artır
      await _firestore.collection('words').doc(wordId).update({
        'likeCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Kelime beğenme hatası: $e');
      rethrow;
    }
  }

  /// Kelime beğenisini kaldır
  Future<void> unlikeWord(String wordId) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      await _firestore
          .collection('words')
          .doc(wordId)
          .collection('likes')
          .doc(_firebaseService.userId!)
          .delete();
      
      await _firestore.collection('words').doc(wordId).update({
        'likeCount': FieldValue.increment(-1),
      });
    } catch (e) {
      print('Beğeni kaldırma hatası: $e');
      rethrow;
    }
  }

  /// Kelime beğeni durumunu kontrol et
  Future<bool> isWordLiked(String wordId) async {
    if (!_firebaseService.isLoggedIn) return false;
    
    try {
      final doc = await _firestore
          .collection('words')
          .doc(wordId)
          .collection('likes')
          .doc(_firebaseService.userId!)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Kullanıcıyı takip et
  Future<void> followUser(String userId) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('following')
          .doc(userId)
          .set({
        'followingId': userId,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .doc(_firebaseService.userId!)
          .set({
        'followerId': _firebaseService.userId!,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Takip etme hatası: $e');
      rethrow;
    }
  }

  /// Takibi bırak
  Future<void> unfollowUser(String userId) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('following')
          .doc(userId)
          .delete();
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .doc(_firebaseService.userId!)
          .delete();
    } catch (e) {
      print('Takibi bırakma hatası: $e');
      rethrow;
    }
  }

  /// Takip durumunu kontrol et
  Future<bool> isFollowing(String userId) async {
    if (!_firebaseService.isLoggedIn) return false;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('following')
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Takipçi sayısını al
  Future<int> getFollowerCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('followers')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  /// Takip edilen sayısını al
  Future<int> getFollowingCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('following')
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}

