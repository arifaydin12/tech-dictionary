import '../models/word.dart';
import '../utils/text_utils.dart';

/// Typo-tolerant dictionary search.
///
/// Ranking, best first: exact term, term prefix, term substring, fuzzy match on
/// a word of the term (small edit distance) and finally matches in the
/// definition.
class SearchService {
  const SearchService();

  List<Word> search(List<Word> words, String query, {String? category}) {
    final pool = category == null
        ? words
        : words.where((w) => w.category == category).toList();

    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return [...pool]
        ..sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    }

    final scored = <(Word, double)>[];
    for (final word in pool) {
      final s = score(word, trimmed);
      if (s > 0) scored.add((word, s));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0
          ? byScore
          : a.$1.term.toLowerCase().compareTo(b.$1.term.toLowerCase());
    });
    return [for (final e in scored) e.$1];
  }

  /// Relevance of [word] for [query]; 0 means no match.
  double score(Word word, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return 0;

    final term = word.term.toLowerCase();
    if (term == q) return 100;
    if (TextUtils.normalize(term) == TextUtils.normalize(q) &&
        TextUtils.normalize(q).isNotEmpty) {
      return 95;
    }
    if (term.startsWith(q)) return 80;
    if (term.contains(q)) return 65;

    final queryTokens = TextUtils.tokens(q);
    if (queryTokens.isEmpty) return 0;
    final termTokens = TextUtils.tokens(term);
    final definition = word.definition.toLowerCase();

    var total = 0.0;
    var matched = 0;
    for (final token in queryTokens) {
      var best = 0.0;
      for (final t in termTokens) {
        if (t.startsWith(token)) {
          best = best < 60 ? 60 : best;
        } else {
          final allowed = _allowedEdits(token);
          if (allowed > 0) {
            final d = TextUtils.levenshtein(token, t);
            if (d <= allowed) {
              final fuzzy = 50.0 - d * 10;
              best = best < fuzzy ? fuzzy : best;
            }
          }
        }
      }
      if (best == 0 && token.length >= 3 && definition.contains(token)) {
        best = 20;
      }
      if (best > 0) {
        matched++;
        total += best;
      }
    }
    if (matched == 0) return 0;
    // Prefer words matching every query token.
    final coverage = matched / queryTokens.length;
    return total / queryTokens.length * coverage;
  }

  static int _allowedEdits(String token) {
    if (token.length <= 3) return 0;
    if (token.length <= 6) return 1;
    return 2;
  }
}
