import 'package:flutter/foundation.dart';

import '../data/seed_words.dart';
import '../models/app_user.dart';
import '../models/word.dart';
import '../repositories/repositories.dart';
import '../services/search_service.dart';
import '../utils/dates.dart';

/// The dictionary: built-in terms plus community terms, with search and
/// category filtering.
class DictionaryProvider extends ChangeNotifier {
  DictionaryProvider(
    this._repository, {
    SearchService search = const SearchService(),
    DateTime Function()? clock,
  }) : _search = search,
       _clock = clock ?? DateTime.now;

  final WordRepository _repository;
  final SearchService _search;
  final DateTime Function() _clock;

  List<Word> _community = [];
  bool _loading = false;
  String? _error;
  String _query = '';
  String? _category;

  List<Word> _all = SeedWords.all;
  List<Word> _visible = SeedWords.all;

  bool get loading => _loading;
  String? get error => _error;
  String get query => _query;
  String? get category => _category;

  /// Built-in and community words.
  List<Word> get all => _all;

  /// Words matching the current query and category, best match first.
  List<Word> get visible => _visible;

  List<Word> get communityWords => _community;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _community = await _repository.fetchCommunityWords();
    } on RepositoryException catch (e) {
      _community = [];
      _error = e.message;
    } catch (e) {
      debugPrint('Failed to load words: $e');
      _community = [];
      _error = 'The dictionary could not be loaded.';
    }
    _rebuild();
    _loading = false;
    notifyListeners();
  }

  void clear() {
    _community = [];
    _query = '';
    _category = null;
    _error = null;
    _rebuild();
    notifyListeners();
  }

  void _rebuild() {
    _all = [...SeedWords.all, ..._community];
    _visible = _search.search(_all, _query, category: _category);
  }

  void setQuery(String value) {
    if (value == _query) return;
    _query = value;
    _rebuild();
    notifyListeners();
  }

  void setCategory(String? value) {
    if (value == _category) return;
    _category = value;
    _rebuild();
    notifyListeners();
  }

  Word? byId(String id) {
    for (final w in _all) {
      if (w.id == id) return w;
    }
    return null;
  }

  /// A word that changes once a day but is the same for the whole day.
  Word? wordOfTheDay([DateTime? now]) {
    if (_all.isEmpty) return null;
    final day = Dates.dayStart(now ?? _clock());
    final index =
        (day.year * 372 + day.month * 31 + day.day) % SeedWords.all.length;
    return SeedWords.all[index];
  }

  /// Other words from the same category, used as "related terms".
  List<Word> related(Word word, {int limit = 4}) {
    final same = _all
        .where((w) => w.category == word.category && w.id != word.id)
        .toList();
    if (same.isEmpty) return const [];
    // Deterministic rotation so related terms differ from word to word.
    final start =
        word.term.codeUnits.fold<int>(0, (a, b) => a + b) % same.length;
    return [
      for (var i = 0; i < same.length && i < limit; i++)
        same[(start + i) % same.length],
    ];
  }

  /// Returns an error message, or `null` when the input is acceptable.
  String? validate(String term, String definition, {String? excludeId}) =>
      validateTerm(term, excludeId: excludeId) ??
      validateDefinition(definition);

  String? validateTerm(String term, {String? excludeId}) {
    final t = term.trim();
    if (t.isEmpty) return 'Enter a term.';
    if (t.length > 60) return 'The term must be at most 60 characters.';
    final lower = t.toLowerCase();
    final duplicate = _all.any(
      (w) => w.id != excludeId && w.term.toLowerCase() == lower,
    );
    if (duplicate) return '"$t" is already in the dictionary.';
    return null;
  }

  String? validateDefinition(String definition) {
    final d = definition.trim();
    if (d.length < 10) return 'The definition must be at least 10 characters.';
    if (d.length > 600) {
      return 'The definition must be at most 600 characters.';
    }
    return null;
  }

  Future<Word> addWord({
    required AppUser author,
    required String term,
    required String definition,
    required String category,
    String? example,
  }) async {
    final problem = validate(term, definition);
    if (problem != null) throw RepositoryException(problem);
    final trimmedExample = example?.trim();
    final word = await _repository.addWord(
      Word(
        id: '',
        term: term.trim(),
        definition: definition.trim(),
        category: category,
        example: (trimmedExample == null || trimmedExample.isEmpty)
            ? null
            : trimmedExample,
      ),
      author,
    );
    _community = [..._community, word];
    _rebuild();
    notifyListeners();
    return word;
  }

  Future<void> updateWord(
    Word word, {
    required String term,
    required String definition,
    required String category,
    String? example,
  }) async {
    final problem = validate(term, definition, excludeId: word.id);
    if (problem != null) throw RepositoryException(problem);
    final trimmedExample = example?.trim();
    final updated = word.copyWith(
      term: term.trim(),
      definition: definition.trim(),
      category: category,
      example: trimmedExample,
      clearExample: trimmedExample == null || trimmedExample.isEmpty,
    );
    await _repository.updateWord(updated);
    _community = [for (final w in _community) w.id == word.id ? updated : w];
    _rebuild();
    notifyListeners();
  }

  Future<void> deleteWord(Word word) async {
    await _repository.deleteWord(word.id);
    _community = [
      for (final w in _community)
        if (w.id != word.id) w,
    ];
    _rebuild();
    notifyListeners();
  }
}
