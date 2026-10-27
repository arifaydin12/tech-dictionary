import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';
import '../config/constants.dart';
import '../models/word.dart';
import '../providers/word_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/firebase_auth_provider.dart';
import '../widgets/custom_widgets.dart';
import '../services/firebase_service.dart';
import '../services/gamification_service.dart';
import 'add_word_screen.dart';
import 'word_detail_screen.dart';
import 'quiz_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];

  void _updateSuggestions(String query, List<Word> words) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final terms = words.map((w) => w.term).toList();
    final suggestions = <String>[];
    for (final term in terms) {
      if (term.toLowerCase().contains(query.toLowerCase())) {
        suggestions.add(term);
      }
    }
    setState(() => _suggestions = suggestions.take(5).toList());
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<WordProvider>().initialize());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<WordProvider>(
        builder: (context, wordProvider, _) {
          return CustomScrollView(
            slivers: [
              // App Header
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).cardColor,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.brightness_6, size: 22),
                    tooltip: 'Tema',
                    onPressed: () => Provider.of<ThemeProvider>(
                      context,
                      listen: false,
                    ).toggleTheme(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.account_circle, size: 22),
                    tooltip: 'Profil',
                    onPressed: () {
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(
                          AppConstants.borderRadius20,
                        ),
                        bottomRight: Radius.circular(
                          AppConstants.borderRadius20,
                        ),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppConstants.spacing24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Tech Dictionary',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(color: Colors.white),
                                    ),
                                    const SizedBox(
                                      height: AppConstants.spacing4,
                                    ),
                                    Text(
                                      '${wordProvider.totalWords} teknik terim',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                    if (wordProvider.favoriteCount > 0)
                                      Positioned(
                                        top: 5,
                                        right: 5,
                                        child: Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColors.error,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${wordProvider.favoriteCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Search and Filters
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacing16,
                  ),
                  child: Column(
                    children: [
                      // Search Bar
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacing16,
                        ),
                        child: Column(
                          children: [
                            TextField(
                              controller: _searchController,
                              onChanged: (value) {
                                wordProvider.search(value);
                                _updateSuggestions(value, wordProvider.words);
                              },
                              decoration: InputDecoration(
                                hintText: 'Terim ara...',
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.primary,
                                ),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          wordProvider.search('');
                                        },
                                      )
                                    : null,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppConstants.spacing16,
                                  vertical: AppConstants.spacing12,
                                ),
                              ),
                            ),
                            if (_suggestions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).cardColor,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _suggestions.length,
                                  itemBuilder: (context, index) {
                                    final suggestion = _suggestions[index];
                                    return ListTile(
                                      title: Text(suggestion),
                                      onTap: () {
                                        _searchController.text = suggestion;
                                        wordProvider.search(suggestion);
                                        setState(() => _suggestions = []);
                                      },
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppConstants.spacing16),

                      // Categories
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.spacing16,
                        ),
                        child: Row(
                          children: List.generate(
                            wordProvider.categories.length,
                            (index) {
                              final category = wordProvider.categories[index];
                              return Padding(
                                padding: const EdgeInsets.only(
                                  right: AppConstants.spacing8,
                                ),
                                child: CategoryChip(
                                  label: category,
                                  isSelected:
                                      wordProvider.selectedCategory == category,
                                  onTap: () {
                                    wordProvider.setSelectedCategory(category);
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Words List
              if (wordProvider.words.isEmpty)
                SliverFillRemaining(
                  child: EmptyState(
                    icon: '🔍',
                    title: 'Sonuç Bulunamadı',
                    subtitle:
                        'Aradığınız terim bulunamadı. Farklı bir arama deneyin.',
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final word = wordProvider.words[index];
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: WordCard(
                        term: word.term,
                        definition: word.definition,
                        category: word.category,
                        isFavorite: word.isFavorite,
                        onFavoriteTap: () {
                          wordProvider.toggleFavorite(word);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                word.isFavorite
                                    ? 'Favorilere eklendi'
                                    : 'Favorilerden çıkarıldı',
                              ),
                              backgroundColor: word.isFavorite
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          );
                        },
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WordDetailScreen(word: word),
                            ),
                          );
                        },
                        onEditTap: word.isOwnedBy(context.read<FirebaseAuthProvider>().firebaseService.userId)
                            ? () {
                                Navigator.pushNamed(
                                  context,
                                  '/edit_word',
                                  arguments: word,
                                );
                              }
                            : null,
                      ),
                    );
                  }, childCount: wordProvider.words.length),
                ),

              // Bottom padding
              SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          );
        },
      ),

      // Floating Action Buttons
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Quiz butonu
          FloatingActionButton(
            heroTag: 'quiz',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) => _buildQuizOptions(context),
              );
            },
            backgroundColor: AppColors.accent,
            child: const Icon(Icons.quiz),
          ),
          const SizedBox(height: 12),
          // Gamification butonu
          FloatingActionButton(
            heroTag: 'gamification',
            onPressed: () {
              Navigator.pushNamed(context, '/gamification');
            },
            backgroundColor: AppColors.warning,
            child: const Icon(Icons.emoji_events),
          ),
          const SizedBox(height: 12),
          // Ana buton - Terim Ekle
          FloatingActionButton.extended(
            heroTag: 'add_word',
            onPressed: () async {
              final newWord = await Navigator.push<Word>(
                context,
                MaterialPageRoute(builder: (context) => const AddWordScreen()),
              );

              if (newWord != null) {
                final wordProvider = context.read<WordProvider>();
                await wordProvider.addWord(newWord);
                
                // Gamification: Kelime eklendi
                final firebaseService = FirebaseService();
                if (firebaseService.isLoggedIn) {
                  final gamificationService = GamificationService();
                  await gamificationService.onWordAdded(firebaseService.userId!);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Terim başarıyla eklendi'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              }
            },
            backgroundColor: AppColors.secondary,
            label: const Text('Terim Ekle'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOptions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacing24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quiz Modu Seçin',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: AppConstants.spacing24),
          _buildQuizOption(
            context,
            title: 'Çoktan Seçmeli',
            description: '4 seçenekli sorular',
            icon: Icons.quiz,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/quiz',
                arguments: {
                  'mode': QuizMode.multipleChoice,
                  'questionCount': 10,
                },
              );
            },
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildQuizOption(
            context,
            title: 'Doğru/Yanlış',
            description: 'Hızlı test modu',
            icon: Icons.check_circle_outline,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                '/quiz',
                arguments: {
                  'mode': QuizMode.trueFalse,
                  'questionCount': 10,
                },
              );
            },
          ),
          const SizedBox(height: AppConstants.spacing12),
          _buildQuizOption(
            context,
            title: 'Gelişmiş İstatistikler',
            description: 'Grafikler ve analizler',
            icon: Icons.bar_chart,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/advanced_stats');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuizOption(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.spacing16),
        decoration: BoxDecoration(
          color: AppColors.primaryLight.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: AppConstants.spacing16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
