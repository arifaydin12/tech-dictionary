import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/data/demo_seed.dart';
import 'package:tech_dictionary/data/seed_words.dart';
import 'package:tech_dictionary/models/category.dart';

void main() {
  final words = SeedWords.all;

  test('ships a starter dictionary of at least 120 terms', () {
    expect(words.length, greaterThanOrEqualTo(120));
  });

  test('ids and terms are unique', () {
    expect(words.map((w) => w.id).toSet().length, words.length);
    expect(words.map((w) => w.term.toLowerCase()).toSet().length, words.length);
  });

  test('every term has a valid category and a real definition', () {
    for (final w in words) {
      expect(Categories.names, contains(w.category), reason: w.term);
      expect(w.definition.length, greaterThan(40), reason: w.term);
      expect(w.definition.trim(), endsWith('.'), reason: w.term);
      expect(w.isBuiltIn, isTrue);
    }
  });

  test('every category has at least 12 terms', () {
    for (final c in Categories.names) {
      expect(
        words.where((w) => w.category == c).length,
        greaterThanOrEqualTo(12),
        reason: c,
      );
    }
  });

  test('content is plain English (ASCII only)', () {
    final nonAscii = RegExp(r'[^\x00-\x7F]');
    for (final w in words) {
      expect(
        '${w.term} ${w.definition}'.contains(nonAscii),
        isFalse,
        reason: w.term,
      );
    }
  });

  test('slug builds stable ids', () {
    expect(SeedWords.slug('CI/CD'), 'ci-cd');
    expect(SeedWords.slug('AI & ML'), 'ai-and-ml');
    expect(words.first.id, startsWith('builtin-'));
  });

  test('demo seed references only existing words', () {
    final ids = words.map((w) => w.id).toSet();
    final progress = DemoSeed.progress(DateTime(2026, 3, 10));
    expect(progress.cards.keys.every(ids.contains), isTrue);
    expect(progress.favourites.every(ids.contains), isTrue);
    expect(progress.badges, isNotEmpty);
    expect(progress.xp, greaterThan(0));
  });
}
