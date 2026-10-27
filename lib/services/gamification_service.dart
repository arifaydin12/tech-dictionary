import '../models/badge.dart';
import '../models/user_ranking.dart';
import '../services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GamificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseService _firebaseService = FirebaseService();

  // Varsayılan rozetler
  static final List<Badge> defaultBadges = [
    Badge(
      id: 'first_word',
      name: 'İlk Adım',
      description: 'İlk kelimenizi eklediniz!',
      icon: '🎯',
      type: BadgeType.wordCount,
      requiredValue: 1,
    ),
    Badge(
      id: 'word_collector_10',
      name: 'Kelime Toplayıcı',
      description: '10 kelime eklediniz!',
      icon: '📚',
      type: BadgeType.wordCount,
      requiredValue: 10,
    ),
    Badge(
      id: 'word_collector_50',
      name: 'Kelime Ustası',
      description: '50 kelime eklediniz!',
      icon: '📖',
      type: BadgeType.wordCount,
      requiredValue: 50,
    ),
    Badge(
      id: 'word_collector_100',
      name: 'Kelime Şampiyonu',
      description: '100 kelime eklediniz!',
      icon: '🏆',
      type: BadgeType.wordCount,
      requiredValue: 100,
    ),
    Badge(
      id: 'quiz_master',
      name: 'Quiz Ustası',
      description: '10 quiz tamamladınız!',
      icon: '🧠',
      type: BadgeType.quizScore,
      requiredValue: 10,
    ),
    Badge(
      id: 'perfect_score',
      name: 'Mükemmel Skor',
      description: 'Bir quiz\'de %100 başarı!',
      icon: '💯',
      type: BadgeType.quizScore,
      requiredValue: 100,
    ),
    Badge(
      id: 'streak_7',
      name: 'Haftalık Seri',
      description: '7 gün üst üste aktif!',
      icon: '🔥',
      type: BadgeType.streak,
      requiredValue: 7,
    ),
    Badge(
      id: 'streak_30',
      name: 'Aylık Seri',
      description: '30 gün üst üste aktif!',
      icon: '⭐',
      type: BadgeType.streak,
      requiredValue: 30,
    ),
    Badge(
      id: 'corrector',
      name: 'Düzeltme Ustası',
      description: '5 düzeltme önerisi gönderdiniz!',
      icon: '✏️',
      type: BadgeType.correction,
      requiredValue: 5,
    ),
    Badge(
      id: 'level_10',
      name: 'Seviye 10',
      description: '10. seviyeye ulaştınız!',
      icon: '🎖️',
      type: BadgeType.special,
      requiredValue: 10,
    ),
  ];

  /// Kullanıcı ilerlemesini al
  Future<UserProgress> getUserProgress(String userId) async {
    try {
      final doc = await _firestore
          .collection('userProgress')
          .doc(userId)
          .get();
      
      if (doc.exists) {
        return UserProgress.fromFirestore(doc.data()!);
      } else {
        // Yeni kullanıcı için varsayılan ilerleme oluştur
        final progress = UserProgress(userId: userId);
        await saveUserProgress(progress);
        return progress;
      }
    } catch (e) {
      print('İlerleme alma hatası: $e');
      return UserProgress(userId: userId);
    }
  }

  /// Kullanıcı ilerlemesini kaydet
  Future<void> saveUserProgress(UserProgress progress) async {
    try {
      await _firestore
          .collection('userProgress')
          .doc(progress.userId)
          .set(progress.toFirestore());
    } catch (e) {
      print('İlerleme kaydetme hatası: $e');
    }
  }

  /// Kelime eklendiğinde XP ve rozet kontrolü
  Future<void> onWordAdded(String userId) async {
    final progress = await getUserProgress(userId);
    progress.wordsAdded++;
    progress.addXP(10); // Her kelime için 10 XP
    progress.updateStreak();
    
    await saveUserProgress(progress);
    await checkBadges(progress);
  }

  /// Quiz tamamlandığında XP ve rozet kontrolü
  Future<void> onQuizCompleted(String userId, int score, double accuracy) async {
    final progress = await getUserProgress(userId);
    progress.quizzesCompleted++;
    progress.addXP(score ~/ 10); // Skorun 10'da biri kadar XP
    progress.updateStreak();
    
    await saveUserProgress(progress);
    await checkBadges(progress);
    
    // Mükemmel skor rozeti kontrolü
    if (accuracy >= 1.0) {
      await unlockBadge(userId, 'perfect_score');
    }
  }

  /// Rozet kontrolü ve kazanma
  Future<void> checkBadges(UserProgress progress) async {
    // Kelime sayısı rozetleri
    for (final badge in defaultBadges.where((b) => b.type == BadgeType.wordCount)) {
      if (progress.wordsAdded >= badge.requiredValue &&
          !progress.unlockedBadges.contains(badge.id)) {
        await unlockBadge(progress.userId, badge.id);
      }
    }
    
    // Quiz rozetleri
    for (final badge in defaultBadges.where((b) => b.type == BadgeType.quizScore)) {
      if (badge.id == 'quiz_master' &&
          progress.quizzesCompleted >= badge.requiredValue &&
          !progress.unlockedBadges.contains(badge.id)) {
        await unlockBadge(progress.userId, badge.id);
      }
    }
    
    // Seri rozetleri
    for (final badge in defaultBadges.where((b) => b.type == BadgeType.streak)) {
      if (progress.currentStreak >= badge.requiredValue &&
          !progress.unlockedBadges.contains(badge.id)) {
        await unlockBadge(progress.userId, badge.id);
      }
    }
    
    // Seviye rozetleri
    for (final badge in defaultBadges.where((b) => b.type == BadgeType.special)) {
      if (badge.id == 'level_10' &&
          progress.level >= badge.requiredValue &&
          !progress.unlockedBadges.contains(badge.id)) {
        await unlockBadge(progress.userId, badge.id);
      }
    }
  }

  /// Rozet kazan
  Future<void> unlockBadge(String userId, String badgeId) async {
    try {
      final badge = defaultBadges.firstWhere((b) => b.id == badgeId);
      final unlockedBadge = Badge(
        id: badge.id,
        name: badge.name,
        description: badge.description,
        icon: badge.icon,
        type: badge.type,
        requiredValue: badge.requiredValue,
        unlockedAt: DateTime.now(),
      );
      
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .doc(badgeId)
          .set(unlockedBadge.toFirestore());
      
      // Kullanıcı ilerlemesine ekle
      final progress = await getUserProgress(userId);
      if (!progress.unlockedBadges.contains(badgeId)) {
        progress.unlockedBadges.add(badgeId);
        progress.addXP(50); // Rozet için bonus XP
        await saveUserProgress(progress);
      }
      
      print('✓ Rozet kazanıldı: ${badge.name}');
    } catch (e) {
      print('Rozet kazanma hatası: $e');
    }
  }

  /// Kullanıcının tüm rozetlerini al
  Future<List<Badge>> getUserBadges(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('badges')
          .get();
      
      return snapshot.docs
          .map((doc) => Badge.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      print('Rozet alma hatası: $e');
      return [];
    }
  }

  /// Tüm rozetleri al
  List<Badge> getAllBadges() {
    return defaultBadges;
  }
}

