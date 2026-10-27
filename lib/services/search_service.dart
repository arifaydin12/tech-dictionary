import 'package:fuzzy/fuzzy.dart';
import '../models/word.dart';

class SearchService {
  late Fuzzy<Word> _fuzzy;

  void initialize(List<Word> words) {
    _fuzzy = Fuzzy<Word>(
      words,
      options: FuzzyOptions(
        keys: [
          WeightedKey(name: 'term', getter: (word) => word.term, weight: 0.7),
          WeightedKey(
            name: 'definition',
            getter: (word) => word.definition,
            weight: 0.3,
          ),
          WeightedKey(
            name: 'category',
            getter: (word) => word.category,
            weight: 0.1,
          ),
        ],
        threshold: 0.3, // 0.0 = exact match, 1.0 = match anything
      ),
    );
  }

  /// Fuzzy search
  List<Word> fuzzySearch(String query) {
    if (query.isEmpty) return [];

    final results = _fuzzy.search(query);
    return results.map((r) => r.item).toList();
  }

  /// Gelişmiş filtreleme
  List<Word> advancedSearch({
    String? query,
    List<String>? categories,
    DateTime? startDate,
    DateTime? endDate,
    bool? isFavorite,
    String? userId,
    List<Word> words = const [],
  }) {
    var filtered = words;

    // Metin araması
    if (query != null && query.isNotEmpty) {
      filtered = fuzzySearch(query);
    }

    // Kategori filtresi
    if (categories != null && categories.isNotEmpty) {
      filtered = filtered
          .where((w) => categories.contains(w.category))
          .toList();
    }

    // Tarih filtresi
    if (startDate != null) {
      filtered = filtered.where((w) => w.createdAt.isAfter(startDate)).toList();
    }
    if (endDate != null) {
      filtered = filtered.where((w) => w.createdAt.isBefore(endDate)).toList();
    }

    // Favori filtresi
    if (isFavorite != null) {
      filtered = filtered.where((w) => w.isFavorite == isFavorite).toList();
    }

    // Kullanıcı filtresi
    if (userId != null) {
      filtered = filtered.where((w) => w.userId == userId).toList();
    }

    return filtered;
  }
}
