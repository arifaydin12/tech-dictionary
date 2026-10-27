import 'package:flutter/material.dart';
import '../models/word.dart';
import '../services/word_service.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';
import '../services/search_service.dart';

class WordProvider extends ChangeNotifier {
  final WordService _wordService;
  final SearchService _searchService = SearchService();
  List<Word> _words = [];
  List<Word> _filteredWords = [];
  List<String> _categories = [];
  String _selectedCategory = 'Tümü';
  String _searchQuery = '';

  WordProvider(this._wordService);

  // Getters
  List<Word> get words => _filteredWords;
  List<String> get categories => ['Tümü', ..._categories];
  String get selectedCategory => _selectedCategory;
  int get totalWords => _wordService.getTotalWords();
  int get favoriteCount => _words.where((w) => w.isFavorite).length;

  // Initialize
  Future<void> initialize() async {
    await _loadWords();
    _loadCategories();
  }

  Future<void> _loadWords() async {
    final firebaseService = FirebaseService();

    // Önce Firebase'den paylaşılan kelimeleri yükle
    if (firebaseService.isLoggedIn) {
      try {
        final sharedWords = await firebaseService.getAllSharedWords();

        // Kullanıcının favorilerini kontrol et
        final favoriteWords = await firebaseService.getFavoriteWords();
        final favoriteIds = favoriteWords.map((w) => w.id).toSet();

        // Favori durumunu güncelle
        for (var word in sharedWords) {
          word.isFavorite = favoriteIds.contains(word.id);
        }

        _words = sharedWords;
        _searchService.initialize(_words);
        _applyFilters();
        return;
      } catch (e) {
        debugPrint('⚠️ Firebase kelimeleri yüklenemedi: $e');
      }
    }

    // Fallback: Local kelimeleri yükle
    _words = _wordService.getAllWords();
    _searchService.initialize(_words);
    _applyFilters();
  }

  void _loadCategories() {
    _categories = _wordService.getAllCategories();
    notifyListeners();
  }

  // Filter Operations
  void setSelectedCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// AI ile kategori önerisi
  String suggestCategory(String term, String definition) {
    return AIService.suggestCategory(term, definition);
  }

  /// Benzer kelimeler bul
  List<Word> findSimilarWords(String query, {int limit = 5}) {
    return AIService.findSimilarWords(query, _words, limit: limit);
  }

  /// İçerik önerileri
  List<Word> getContentSuggestions({int limit = 5}) {
    final userWords = _words.where((w) => w.userId != null).toList();
    return AIService.suggestContent(userWords, _words, limit: limit);
  }

  /// Fuzzy search
  List<Word> fuzzySearch(String query) {
    return _searchService.fuzzySearch(query);
  }

  void _applyFilters() {
    _filteredWords = _words;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredWords = _filteredWords
          .where(
            (word) => word.searchableText.contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    // Apply category filter
    if (_selectedCategory != 'Tümü') {
      _filteredWords = _filteredWords
          .where((word) => word.category == _selectedCategory)
          .toList();
    }

    notifyListeners();
  }

  // CRUD Operations
  Future<void> addWord(Word word) async {
    final firebaseService = FirebaseService();

    // Firebase'e ekle (eğer giriş yapılmışsa)
    if (firebaseService.isLoggedIn) {
      try {
        final wordId = await firebaseService.saveWord(word);
        word = word.copyWith(id: wordId);
        debugPrint('✓ Kelime Firebase\'e kaydedildi: ${word.term}');
      } catch (e) {
        debugPrint('⚠️ Kelime Firebase\'e kaydedilemedi: $e');
        // Hata olsa bile local'e ekle
        await _wordService.addWord(word);
      }
    } else {
      // Local'e ekle
      await _wordService.addWord(word);
    }

    await _loadWords();
  }

  Future<void> deleteWord(Word word) async {
    final index = _words.indexOf(word);
    if (index != -1) {
      await _wordService.deleteWord(index);
      _loadWords();
    }
  }

  Future<void> toggleFavorite(Word word) async {
    final firebaseService = FirebaseService();

    // Firebase'de favori durumunu güncelle
    if (firebaseService.isLoggedIn && word.id != null) {
      try {
        final newFavoriteState = !word.isFavorite;
        await firebaseService.toggleFavorite(word.id!, newFavoriteState);
        word.isFavorite = newFavoriteState;
        debugPrint('✓ Favori durumu güncellendi: ${word.term}');
      } catch (e) {
        debugPrint('⚠️ Favori güncellenemedi: $e');
        return;
      }
    } else {
      // Local fallback
      final index = _words.indexOf(word);
      if (index != -1) {
        await _wordService.toggleFavorite(index);
      }
    }

    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'Tümü';
    _searchQuery = '';
    _applyFilters();
  }
}
