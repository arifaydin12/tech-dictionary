import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/user_ranking.dart';
import '../services/firebase_service.dart';
import '../providers/firebase_auth_provider.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  
  List<UserRanking> _dailyRankings = [];
  List<UserRanking> _weeklyRankings = [];
  List<UserRanking> _monthlyRankings = [];
  List<UserRanking> _totalRankings = [];
  UserRanking? _myRanking;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadRankings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRankings() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _firebaseService.getDailyRankings(),
        _firebaseService.getWeeklyRankings(),
        _firebaseService.getMonthlyRankings(),
        _firebaseService.getTotalRankings(),
        _firebaseService.getMyRanking(),
      ]);
      
      setState(() {
        _dailyRankings = results[0] as List<UserRanking>;
        _weeklyRankings = results[1] as List<UserRanking>;
        _monthlyRankings = results[2] as List<UserRanking>;
        _totalRankings = results[3] as List<UserRanking>;
        _myRanking = results[4] as UserRanking?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sıralama yüklenirken hata: $e')),
        );
      }
    }
  }

  List<UserRanking> _getCurrentRankings() {
    switch (_tabController.index) {
      case 0:
        return _dailyRankings;
      case 1:
        return _weeklyRankings;
      case 2:
        return _monthlyRankings;
      case 3:
        return _totalRankings;
      default:
        return [];
    }
  }

  int _getCurrentCount(UserRanking ranking) {
    switch (_tabController.index) {
      case 0:
        return ranking.dailyWordCount;
      case 1:
        return ranking.weeklyWordCount;
      case 2:
        return ranking.monthlyWordCount;
      case 3:
        return ranking.wordCount;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Sıralama'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Günlük'),
            Tab(text: 'Haftalık'),
            Tab(text: 'Aylık'),
            Tab(text: 'Toplam'),
          ],
          onTap: (_) => setState(() {}),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRankings,
              child: Column(
                children: [
                  // Kullanıcının kendi sıralaması
                  if (_myRanking != null)
                    _buildMyRankingCard(_myRanking!, isDark),
                  
                  // Sıralama listesi
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRankingList(_dailyRankings, isDark),
                        _buildRankingList(_weeklyRankings, isDark),
                        _buildRankingList(_monthlyRankings, isDark),
                        _buildRankingList(_totalRankings, isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMyRankingCard(UserRanking ranking, bool isDark) {
    final count = _getCurrentCount(ranking);
    final position = _getCurrentRankings().indexWhere((r) => r.userId == ranking.userId) + 1;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sıra numarası
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                position > 0 ? '#$position' : '-',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Kullanıcı bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ranking.userName,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count kelime',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          // İkon
          Icon(Icons.emoji_events, color: Colors.amber, size: 32),
        ],
      ),
    );
  }

  Widget _buildRankingList(List<UserRanking> rankings, bool isDark) {
    if (rankings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.leaderboard_outlined,
              size: 64,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz sıralama yok',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rankings.length,
      itemBuilder: (context, index) {
        final ranking = rankings[index];
        final position = index + 1;
        final count = _getCurrentCount(ranking);
        final isCurrentUser = ranking.userId == _firebaseService.userId;
        
        return _buildRankingItem(ranking, position, count, isCurrentUser, isDark);
      },
    );
  }

  Widget _buildRankingItem(
    UserRanking ranking,
    int position,
    int count,
    bool isCurrentUser,
    bool isDark,
  ) {
    Color medalColor;
    IconData medalIcon;
    
    if (position == 1) {
      medalColor = Colors.amber;
      medalIcon = Icons.looks_one;
    } else if (position == 2) {
      medalColor = Colors.grey.shade400;
      medalIcon = Icons.looks_two;
    } else if (position == 3) {
      medalColor = Colors.brown.shade400;
      medalIcon = Icons.looks_3;
    } else {
      medalColor = AppColors.textSecondary;
      medalIcon = Icons.circle;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primaryLight.withOpacity(0.3)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary, width: 2)
            : Border.all(
                color: isDark ? Colors.white24 : AppColors.border,
                width: 1,
              ),
      ),
      child: Row(
        children: [
          // Sıra numarası
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: position <= 3 ? medalColor.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: position <= 3
                  ? Icon(medalIcon, color: medalColor, size: 24)
                  : Text(
                      '$position',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primaryLight,
            backgroundImage: ranking.userPhotoUrl != null
                ? NetworkImage(ranking.userPhotoUrl!)
                : null,
            child: ranking.userPhotoUrl == null
                ? Text(
                    ranking.userName.isNotEmpty
                        ? ranking.userName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 16),
          // Kullanıcı bilgisi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        ranking.userName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Sen',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$count kelime',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

