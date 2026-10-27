import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word.dart';
import '../config/constants.dart';

class WordService {
  static const String _storageKey = 'words_list';
  late SharedPreferences _prefs;
  List<Word> _words = [];

  Future<void> initializeHive() async {
    _prefs = await SharedPreferences.getInstance();
    _loadWordsFromStorage();
    
    // İlk kez uygulamayı açtığında dummy data ekle
    if (_words.isEmpty) {
      await _addDummyData();
    }
  }

  Future<void> _addDummyData() async {
    for (var wordData in DummyWords.words) {
      final word = Word(
        term: wordData['term']!,
        definition: wordData['definition']!,
        category: wordData['category']!,
      );
      _words.add(word);
    }
    await _saveWordsToStorage();
  }

  void _loadWordsFromStorage() {
    final jsonString = _prefs.getString(_storageKey);
    if (jsonString != null) {
      try {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _words = decoded.map((e) => Word.fromJson(e as Map<String, dynamic>)).toList();
      } catch (e) {
        _words = [];
      }
    }
  }

  Future<void> _saveWordsToStorage() async {
    final jsonString = jsonEncode(_words.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, jsonString);
  }

  // CRUD Operations
  Future<void> addWord(Word word) async {
    _words.add(word);
    await _saveWordsToStorage();
  }

  Future<void> deleteWord(int index) async {
    if (index >= 0 && index < _words.length) {
      _words.removeAt(index);
      await _saveWordsToStorage();
    }
  }

  Future<void> toggleFavorite(int index) async {
    if (index >= 0 && index < _words.length) {
      _words[index].isFavorite = !_words[index].isFavorite;
      await _saveWordsToStorage();
    }
  }

  // Get Operations
  List<Word> getAllWords() => _words;

  List<Word> getFavoriteWords() =>
      _words.where((word) => word.isFavorite).toList();

  List<Word> getWordsByCategory(String category) =>
      _words.where((word) => word.category == category).toList();

  List<Word> searchWords(String query) {
    if (query.isEmpty) return getAllWords();
    return _words
        .where((word) => word.searchableText.contains(query.toLowerCase()))
        .toList();
  }

  List<String> getAllCategories() {
    final categories = <String>{};
    for (var word in _words) {
      categories.add(word.category);
    }
    return categories.toList()..sort();
  }

  int getTotalWords() => _words.length;
}
