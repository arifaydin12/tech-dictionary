import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/learning_progress.dart';
import '../services/firebase_service.dart';

class LearningService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  /// Öğrenme ilerlemesini kaydet
  Future<void> saveProgress(LearningProgress progress) async {
    if (!_firebaseService.isLoggedIn) throw Exception('Giriş yapılmadı');
    
    try {
      await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('learningProgress')
          .doc(progress.wordId)
          .set(progress.toFirestore());
    } catch (e) {
      print('İlerleme kaydetme hatası: $e');
      rethrow;
    }
  }

  /// İlerlemeyi al
  Future<LearningProgress?> getProgress(String wordId) async {
    if (!_firebaseService.isLoggedIn) return null;
    
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('learningProgress')
          .doc(wordId)
          .get();
      
      if (doc.exists) {
        return LearningProgress.fromFirestore(doc.data()!);
      }
      return null;
    } catch (e) {
      print('İlerleme alma hatası: $e');
      return null;
    }
  }

  /// Tekrar edilmesi gereken kelimeleri al
  Future<List<String>> getWordsToReview() async {
    if (!_firebaseService.isLoggedIn) return [];
    
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('learningProgress')
          .where('nextReview', isLessThanOrEqualTo: now.toIso8601String())
          .get();
      
      return snapshot.docs.map((doc) => doc.data()['wordId'] as String).toList();
    } catch (e) {
      print('Tekrar kelimeleri alma hatası: $e');
      return [];
    }
  }

  /// Öğrenilen kelimeleri al
  Future<List<String>> getLearnedWords() async {
    if (!_firebaseService.isLoggedIn) return [];
    
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_firebaseService.userId!)
          .collection('learningProgress')
          .where('isLearned', isEqualTo: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()['wordId'] as String).toList();
    } catch (e) {
      print('Öğrenilen kelimeleri alma hatası: $e');
      return [];
    }
  }
}

