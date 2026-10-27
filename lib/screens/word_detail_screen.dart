import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/word.dart';
import '../services/firebase_service.dart';
import '../providers/firebase_auth_provider.dart';
import 'correction_suggestion_screen.dart';

class WordDetailScreen extends StatefulWidget {
  final Word word;

  const WordDetailScreen({
    Key? key,
    required this.word,
  }) : super(key: key);

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool _isFavorite = false;
  bool _isLoadingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.word.isFavorite;
    _checkFavorite();
  }

  Future<void> _checkFavorite() async {
    if (!_firebaseService.isLoggedIn || widget.word.id == null) return;
    
    setState(() => _isLoadingFavorite = true);
    try {
      final isFav = await _firebaseService.isFavorite(widget.word.id!);
      setState(() {
        _isFavorite = isFav;
        _isLoadingFavorite = false;
      });
    } catch (e) {
      setState(() => _isLoadingFavorite = false);
    }
  }

  Future<void> _toggleFavorite() async {
    if (!_firebaseService.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorilere eklemek için giriş yapmalısınız')),
      );
      return;
    }

    if (widget.word.id == null) return;

    setState(() => _isLoadingFavorite = true);
    try {
      await _firebaseService.toggleFavorite(widget.word.id!, !_isFavorite);
      setState(() {
        _isFavorite = !_isFavorite;
        _isLoadingFavorite = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı'),
          backgroundColor: _isFavorite ? AppColors.success : AppColors.warning,
        ),
      );
    } catch (e) {
      setState(() => _isLoadingFavorite = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isOwnedByCurrentUser = widget.word.isOwnedBy(_firebaseService.userId);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.word.term),
        elevation: 0,
        actions: [
          if (_firebaseService.isLoggedIn)
            IconButton(
              icon: _isLoadingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? AppColors.error : null,
                    ),
              onPressed: _toggleFavorite,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Term Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(AppConstants.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Terim',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  Text(
                    widget.word.term,
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.spacing12,
                      vertical: AppConstants.spacing6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius8),
                    ),
                    child: Text(
                      widget.word.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Definition Section
            Text(
              'Tanım',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: AppConstants.spacing12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppConstants.spacing16),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
              ),
              child: Text(
                widget.word.definition,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  height: 1.6,
                ),
              ),
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Info Section
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.category,
                    label: 'Kategori',
                    value: widget.word.category,
                  ),
                ),
                const SizedBox(width: AppConstants.spacing16),
                Expanded(
                  child: _buildInfoCard(
                    icon: Icons.calendar_today,
                    label: 'Eklenme Tarihi',
                    value: _formatDate(widget.word.createdAt),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Action Buttons
            Column(
              children: [
                // Düzeltme önerisi butonu (sadece sahibi değilse)
                if (!isOwnedByCurrentUser && _firebaseService.isLoggedIn)
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CorrectionSuggestionScreen(word: widget.word),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit_note),
                      label: const Text('Düzeltme Önerisi Gönder'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                  ),
                
                if (!isOwnedByCurrentUser && _firebaseService.isLoggedIn)
                  const SizedBox(height: AppConstants.spacing12),
                
                // Geri dön butonu
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Geri Dön'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: AppConstants.spacing8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }
}
