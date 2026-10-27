import '../models/word.dart';

class AIService {
  // Basit kategori önerisi algoritması
  // Gerçek uygulamada ML modeli kullanılabilir
  
  static const Map<String, List<String>> categoryKeywords = {
    'Mobile': ['mobile', 'android', 'ios', 'flutter', 'react native', 'app', 'telefon'],
    'Backend': ['server', 'api', 'database', 'backend', 'rest', 'graphql', 'microservice'],
    'Frontend': ['frontend', 'ui', 'ux', 'react', 'vue', 'angular', 'html', 'css', 'javascript'],
    'Core': ['core', 'fundamental', 'basic', 'concept', 'principle'],
    'Dart': ['dart', 'flutter', 'language'],
    'Network': ['network', 'http', 'tcp', 'ip', 'protocol', 'internet'],
    'Database': ['database', 'sql', 'nosql', 'mongodb', 'mysql', 'postgresql'],
    'DevOps': ['devops', 'ci/cd', 'docker', 'kubernetes', 'deployment', 'infrastructure'],
    'Security': ['security', 'encryption', 'authentication', 'authorization', 'ssl', 'tls'],
    'AI': ['ai', 'machine learning', 'neural', 'deep learning', 'nlp', 'artificial intelligence'],
  };

  /// Kategori önerisi
  static String suggestCategory(String term, String definition) {
    final text = '$term $definition'.toLowerCase();
    final scores = <String, int>{};

    for (final entry in categoryKeywords.entries) {
      int score = 0;
      for (final keyword in entry.value) {
        if (text.contains(keyword)) {
          score += keyword.length; // Uzun kelimeler daha önemli
        }
      }
      scores[entry.key] = score;
    }

    if (scores.isEmpty) return 'Other';

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.first.value > 0 ? sorted.first.key : 'Other';
  }

  /// Benzer kelimeler bul
  static List<Word> findSimilarWords(String query, List<Word> words, {int limit = 5}) {
    final queryLower = query.toLowerCase();
    final scored = <Word, int>{};

    for (final word in words) {
      int score = 0;
      
      // Terim benzerliği
      if (word.term.toLowerCase().contains(queryLower)) {
        score += 10;
      }
      
      // Tanım benzerliği
      if (word.definition.toLowerCase().contains(queryLower)) {
        score += 5;
      }
      
      // Kategori benzerliği
      if (word.category.toLowerCase().contains(queryLower)) {
        score += 3;
      }
      
      if (score > 0) {
        scored[word] = score;
      }
    }

    final sorted = scored.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(limit).map((e) => e.key).toList();
  }

  /// İçerik önerileri (basit algoritma)
  static List<Word> suggestContent(List<Word> userWords, List<Word> allWords, {int limit = 5}) {
    // Kullanıcının en çok kullandığı kategorileri bul
    final categoryCounts = <String, int>{};
    for (var word in userWords) {
      categoryCounts[word.category] = (categoryCounts[word.category] ?? 0) + 1;
    }

    final topCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(3);

    // Bu kategorilerden kullanıcının görmediği kelimeleri öner
    final suggested = <Word>[];
    final userWordIds = userWords.map((w) => w.id).toSet();

    for (final category in topCategories.map((e) => e.key)) {
      final categoryWords = allWords
          .where((w) => w.category == category && !userWordIds.contains(w.id))
          .take(limit ~/ topCategories.length);
      suggested.addAll(categoryWords);
    }

    return suggested.take(limit).toList();
  }
}

