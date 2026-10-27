import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/data/seed_words.dart';
import 'package:tech_dictionary/models/word.dart';
import 'package:tech_dictionary/services/search_service.dart';
import 'package:tech_dictionary/utils/text_utils.dart';

void main() {
  const search = SearchService();
  final words = SeedWords.all;

  List<String> terms(String query, {String? category}) => [
    for (final w in search.search(words, query, category: category)) w.term,
  ];

  group('TextUtils', () {
    test('levenshtein distance', () {
      expect(TextUtils.levenshtein('kitten', 'sitting'), 3);
      expect(TextUtils.levenshtein('', 'abc'), 3);
      expect(TextUtils.levenshtein('same', 'same'), 0);
      expect(TextUtils.levenshtein('abc', ''), 3);
    });

    test('normalize strips punctuation and case', () {
      expect(TextUtils.normalize('CI/CD'), 'cicd');
      expect(TextUtils.normalize('AI / ML'), 'aiml');
    });
  });

  group('SearchService', () {
    test('empty query lists everything alphabetically', () {
      final all = terms('');
      expect(all.length, words.length);
      final sorted = [...all]
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(all, sorted);
    });

    test('exact match ranks first', () {
      expect(terms('dns').first, 'DNS');
      expect(terms('Kubernetes').first, 'Kubernetes');
    });

    test('prefix matches rank above substring matches', () {
      final result = terms('data');
      final prefix = result.indexOf('Database');
      final substring = result.indexOf('Big O Notation');
      expect(prefix, isNonNegative);
      if (substring >= 0) expect(prefix, lessThan(substring));
      expect(result.take(4), contains('Database'));
    });

    test('tolerates typos', () {
      expect(terms('kubernets').first, 'Kubernetes');
      expect(terms('firwall').first, 'Firewall');
      expect(terms('recursoin').first, 'Recursion');
    });

    test('does not apply fuzzy matching to very short queries', () {
      expect(terms('zq'), isEmpty);
    });

    test('ignores punctuation in the query', () {
      expect(terms('ci cd').first, 'CI/CD');
      expect(terms('two factor').first, 'Two-Factor Authentication');
    });

    test('finds words through their definition', () {
      expect(terms('encrypts'), contains('Ransomware'));
    });

    test('can be limited to a category', () {
      final result = search.search(words, 'a', category: 'Networking');
      expect(result, isNotEmpty);
      expect(result.every((w) => w.category == 'Networking'), isTrue);
    });

    test('returns nothing for gibberish', () {
      expect(terms('qqqxxzzy'), isEmpty);
    });

    test('score is zero for a blank query', () {
      expect(
        search.score(
          const Word(id: 'x', term: 'Term', definition: 'd', category: 'Web'),
          '  ',
        ),
        0,
      );
    });
  });
}
