import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/word.dart';
import '../models/correction_suggestion.dart';
import '../services/firebase_service.dart';
import '../providers/firebase_auth_provider.dart';

class CorrectionSuggestionScreen extends StatefulWidget {
  final Word word;

  const CorrectionSuggestionScreen({
    super.key,
    required this.word,
  });

  @override
  State<CorrectionSuggestionScreen> createState() => _CorrectionSuggestionScreenState();
}

class _CorrectionSuggestionScreenState extends State<CorrectionSuggestionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  final _definitionController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Mobile',
    'Backend',
    'Frontend',
    'Core',
    'Dart',
    'Network',
    'Database',
    'DevOps',
    'Security',
    'AI',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _termController.text = widget.word.term;
    _definitionController.text = widget.word.definition;
    _selectedCategory = widget.word.category;
  }

  @override
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitSuggestion() async {
    if (!_formKey.currentState!.validate()) return;
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen düzeltme nedenini belirtin')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = FirebaseService();
      if (!firebaseService.isLoggedIn) {
        throw Exception('Giriş yapmanız gerekiyor');
      }

      final user = firebaseService.currentUser;
      final suggestion = CorrectionSuggestion(
        wordId: widget.word.id!,
        wordTerm: widget.word.term,
        suggestedTerm: _termController.text.trim(),
        suggestedDefinition: _definitionController.text.trim(),
        suggestedCategory: _selectedCategory,
        suggestedBy: firebaseService.userId!,
        suggestedByName: user?.displayName ?? user?.email?.split('@')[0] ?? 'Bilinmeyen',
        reason: _reasonController.text.trim(),
      );

      await firebaseService.addCorrectionSuggestion(suggestion);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Düzeltme önerisi başarıyla gönderildi'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Düzeltme Önerisi'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bilgi kartı
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: Text(
                        'Kelime sahibi önerinizi inceleyip kabul edebilir veya reddedebilir.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Mevcut kelime bilgisi
              Text(
                'Mevcut Kelime',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppConstants.spacing8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : AppColors.background,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.word.term,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacing8),
                    Text(
                      widget.word.definition,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Önerilen terim
              TextFormField(
                controller: _termController,
                decoration: InputDecoration(
                  labelText: 'Önerilen Terim',
                  prefixIcon: const Icon(Icons.text_fields),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                  ),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Terim boş olamaz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Kategori
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
                },
                validator: (value) {
                  if (value == null) {
                    return 'Kategori seçiniz';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Önerilen tanım
              TextFormField(
                controller: _definitionController,
                decoration: InputDecoration(
                  labelText: 'Önerilen Tanım',
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                  ),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Tanım boş olamaz';
                  }
                  if (value!.length < 10) {
                    return 'Tanım en az 10 karakter olmalı';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Düzeltme nedeni
              TextFormField(
                controller: _reasonController,
                decoration: InputDecoration(
                  labelText: 'Düzeltme Nedeni *',
                  hintText: 'Neden bu düzeltmeyi öneriyorsunuz?',
                  prefixIcon: const Icon(Icons.edit_note),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                  ),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Lütfen düzeltme nedenini belirtin';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Gönder butonu
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitSuggestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Öneriyi Gönder',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

