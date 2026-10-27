import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/badge.dart' as models;
import '../services/gamification_service.dart';
import '../services/firebase_service.dart';
import '../providers/firebase_auth_provider.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  final GamificationService _gamificationService = GamificationService();
  final FirebaseService _firebaseService = FirebaseService();
  
  models.UserProgress? _progress;
  List<models.Badge> _userBadges = [];
  List<models.Badge> _allBadges = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!_firebaseService.isLoggedIn) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _gamificationService.getUserProgress(_firebaseService.userId!),
        _gamificationService.getUserBadges(_firebaseService.userId!),
        Future.value(_gamificationService.getAllBadges()),
      ]);

      setState(() {
        _progress = results[0] as models.UserProgress;
        _userBadges = results[1] as List<models.Badge>;
        _allBadges = results[2] as List<models.Badge>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_firebaseService.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gamification')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              Text(
                'Giriş yapmanız gerekiyor',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Gamification'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.spacing16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İlerleme kartı
              if (_progress != null) _buildProgressCard(_progress!),
              
              const SizedBox(height: AppConstants.spacing24),
              
              // Rozetler başlığı
              Text(
                'Rozetler',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: AppConstants.spacing16),
              
              // Rozetler grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _allBadges.length,
                itemBuilder: (context, index) {
                  final badge = _allBadges[index];
                  final isUnlocked = _userBadges.any((b) => b.id == badge.id);
                  
                  return _buildBadgeCard(badge, isUnlocked, _progress);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard(models.UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Seviye ve XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seviye ${progress.level}',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.totalXP} Toplam XP',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${progress.level}',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacing24),
          
          // XP çubuğu
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.xp} / ${progress.xpForNextLevel} XP',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    'Seviye ${progress.level + 1}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.levelProgress,
                  minHeight: 12,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppConstants.spacing24),
          
          // İstatistikler
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Kelime', '${progress.wordsAdded}', Icons.book),
              _buildStatItem('Quiz', '${progress.quizzesCompleted}', Icons.quiz),
              _buildStatItem('Seri', '${progress.currentStreak}', Icons.local_fire_department),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(models.Badge badge, bool isUnlocked, models.UserProgress? progress) {
    final progressValue = _getBadgeProgress(badge, progress);
    final progressPercent = progressValue / badge.requiredValue;

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.success.withOpacity(0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? AppColors.success : AppColors.border,
          width: isUnlocked ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Rozet ikonu
          Text(
            badge.icon,
            style: const TextStyle(fontSize: 40),
          ),
          const SizedBox(height: 8),
          
          // Rozet adı
          Text(
            badge.name,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // İlerleme
          if (!isUnlocked && progress != null)
            Column(
              children: [
                Text(
                  '$progressValue / ${badge.requiredValue}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent > 1 ? 1 : progressPercent,
                    minHeight: 4,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          
          if (isUnlocked)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Kazanıldı',
                style: GoogleFonts.poppins(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getBadgeProgress(models.Badge badge, models.UserProgress? progress) {
    if (progress == null) return 0;
    
    switch (badge.type) {
      case models.BadgeType.wordCount:
        return progress.wordsAdded;
      case models.BadgeType.quizScore:
        return progress.quizzesCompleted;
      case models.BadgeType.streak:
        return progress.currentStreak;
      case models.BadgeType.correction:
        return 0; // TODO: Düzeltme sayısı
      case models.BadgeType.social:
        return 0; // TODO: Sosyal etkileşimler
      case models.BadgeType.special:
        return progress.level;
    }
  }
}

