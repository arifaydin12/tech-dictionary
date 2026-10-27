import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/word.dart';
import '../widgets/custom_widgets.dart';
import '../services/firebase_service.dart';
import '../providers/word_provider.dart';
import 'package:provider/provider.dart';

class AddWordScreen extends StatefulWidget {
  const AddWordScreen({super.key});

  @override
  State<AddWordScreen> createState() => _AddWordScreenState();
}

class _AddWordScreenState extends State<AddWordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _termController = TextEditingController();
  final _definitionController = TextEditingController();
  String _selectedCategory = 'Other';
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
  void dispose() {
    _termController.dispose();
    _definitionController.dispose();
    super.dispose();
  }

  void _handleAddWord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final firebaseService = FirebaseService();
        String? userId;
        String? createdBy;
        
        if (firebaseService.isLoggedIn) {
          userId = firebaseService.userId;
          final user = firebaseService.currentUser;
          createdBy = user?.displayName ?? user?.email?.split('@')[0] ?? 'Bilinmeyen';
        }

        final newWord = Word(
          term: _termController.text.trim(),
          definition: _definitionController.text.trim(),
          category: _selectedCategory,
          userId: userId,
          createdBy: createdBy,
        );

        if (mounted) {
          Navigator.pop(context, newWord);
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Hata: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Yeni Terim Ekle'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: AppColors.primary),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: Text(
                        'Teknik teriminizi açıkça ve öz bir şekilde tanımlayın.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Term Field
              CustomTextField(
                label: 'Terim (İngilizce)',
                hint: 'ör: Flutter',
                controller: _termController,
                prefixIcon: Icons.text_fields,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Terim boş olamaz';
                  }
                  if (value!.length < 2) {
                    return 'Terim en az 2 karakter olmalı';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Category Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kategori',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: AppConstants.spacing8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories
                        .map((category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.category),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.spacing16,
                        vertical: AppConstants.spacing12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Definition Field
              CustomTextField(
                label: 'Tanım / Açıklama',
                hint: 'Teriminizi detaylı bir şekilde tanımlayın...',
                controller: _definitionController,
                maxLines: 5,
                prefixIcon: Icons.description,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Tanım boş olamaz';
                  }
                  if (value!.length < 10) {
                    return 'Tanım en az 10 karakter olmalı';
                  }
                  return null;
                },
                onChanged: (value) {
                  // AI kategori önerisi
                  if (value.isNotEmpty && _termController.text.isNotEmpty) {
                    final wordProvider = Provider.of<WordProvider>(context, listen: false);
                    final suggestedCategory = wordProvider.suggestCategory(
                      _termController.text,
                      value,
                    );
                    if (mounted && suggestedCategory != _selectedCategory) {
                      setState(() {
                        _selectedCategory = suggestedCategory;
                      });
                    }
                  }
                },
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('İptal Et'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing16),
                  Expanded(
                    child: GradientButton(
                      label: 'Terim Ekle',
                      onPressed: _handleAddWord,
                      isLoading: _isLoading,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
