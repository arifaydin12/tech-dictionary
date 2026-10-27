import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/data/demo_seed.dart';
import 'package:tech_dictionary/data/key_value_store.dart';
import 'package:tech_dictionary/data/seed_words.dart';
import 'package:tech_dictionary/models/app_user.dart';
import 'package:tech_dictionary/models/community.dart';
import 'package:tech_dictionary/models/quiz.dart';
import 'package:tech_dictionary/providers/community_provider.dart';
import 'package:tech_dictionary/providers/dictionary_provider.dart';
import 'package:tech_dictionary/providers/progress_provider.dart';
import 'package:tech_dictionary/repositories/local_repositories.dart';
import 'package:tech_dictionary/repositories/repositories.dart';
import 'package:tech_dictionary/services/export_service.dart';
import 'package:tech_dictionary/services/quiz_service.dart';

void main() {
  final now = DateTime(2026, 3, 10, 12);
  DateTime clock() => now;
  const user = AppUser(id: 'u1', displayName: 'Test User');

  group('ProgressProvider', () {
    late MemoryStore store;
    late ProgressProvider provider;

    setUp(() async {
      store = MemoryStore();
      provider = ProgressProvider(
        LocalProgressRepository(store, clock: clock),
        clock: clock,
      );
      await provider.load(user);
    });

    test('starts empty', () {
      expect(provider.xp, 0);
      expect(provider.level, 1);
      expect(provider.currentStreak, 0);
      expect(provider.progress.cards, isEmpty);
    });

    test('recording answers updates cards, activity and XP', () {
      final word = SeedWords.all.first;
      provider.beginSession();
      provider.recordAnswer(
        word,
        QuizService().multipleChoice(isCorrect: true),
      );
      provider.recordAnswer(
        SeedWords.all[1],
        QuizService().multipleChoice(isCorrect: false),
      );

      expect(provider.cardFor(word.id)!.correct, 1);
      expect(provider.cardFor(SeedWords.all[1].id)!.incorrect, 1);
      expect(provider.todayReviews, 2);
      expect(provider.xp, 12);
      expect(provider.currentStreak, 1);
    });

    test('finishing a session stores the result, bonus and badges', () async {
      provider.beginSession();
      for (var i = 0; i < 5; i++) {
        provider.recordAnswer(
          SeedWords.all[i],
          QuizService().multipleChoice(isCorrect: true),
        );
      }
      final summary = await provider.finishSession(
        mode: QuizMode.multipleChoice,
        total: 5,
        correct: 5,
        bonusXp: 25,
      );
      expect(summary.xpEarned, 50 + 25);
      expect(summary.accuracy, 1);
      expect(
        summary.newBadges.map((b) => b.id),
        containsAll(['first_steps', 'perfectionist']),
      );
      expect(provider.progress.quizzes.length, 1);
      expect(summary.leveledUpTo, 2);
    });

    test('progress persists and can be reloaded', () async {
      final word = SeedWords.all.first;
      provider.recordAnswer(word, QuizService().typed(AnswerMatch.exact));
      await provider.toggleFavourite(word.id);
      await provider.finishSession(
        mode: QuizMode.typing,
        total: 1,
        correct: 1,
        bonusXp: 0,
      );

      final reloaded = ProgressProvider(
        LocalProgressRepository(store, clock: clock),
        clock: clock,
      );
      await reloaded.load(user);
      expect(reloaded.isFavourite(word.id), isTrue);
      expect(reloaded.cardFor(word.id)!.correct, 1);
      expect(reloaded.xp, 15);
    });

    test('favourites toggle on and off', () async {
      await provider.toggleFavourite('w1');
      expect(provider.isFavourite('w1'), isTrue);
      await provider.toggleFavourite('w1');
      expect(provider.isFavourite('w1'), isFalse);
    });

    test('reset clears everything', () async {
      provider.recordAnswer(
        SeedWords.all.first,
        QuizService().multipleChoice(isCorrect: true),
      );
      await provider.resetProgress();
      expect(provider.xp, 0);
      expect(provider.progress.cards, isEmpty);
    });

    test('keeps only the most recent sessions', () async {
      for (var i = 0; i < ProgressProvider.maxStoredQuizzes + 5; i++) {
        await provider.finishSession(
          mode: QuizMode.flashcards,
          total: 1,
          correct: i % 2,
          bonusXp: 0,
        );
      }
      expect(
        provider.progress.quizzes.length,
        ProgressProvider.maxStoredQuizzes,
      );
    });

    test('the demo guest starts with a believable history', () async {
      final demo = ProgressProvider(
        LocalProgressRepository(
          MemoryStore(),
          seedDemoHistory: true,
          clock: clock,
        ),
        clock: clock,
      );
      await demo.load(
        const AppUser(id: DemoSeed.guestId, displayName: 'Guest'),
      );
      expect(demo.currentStreak, greaterThanOrEqualTo(3));
      expect(demo.progress.quizzes, isNotEmpty);
      expect(demo.progress.badges, isNotEmpty);
      expect(demo.level, greaterThan(1));
    });
  });

  group('DictionaryProvider', () {
    late DictionaryProvider provider;

    setUp(() async {
      provider = DictionaryProvider(
        LocalWordRepository(MemoryStore(), clock: clock),
        clock: clock,
      );
      await provider.load();
    });

    test('combines built-in and community words', () {
      expect(
        provider.all.length,
        SeedWords.all.length + provider.communityWords.length,
      );
      expect(provider.communityWords, isNotEmpty);
    });

    test('search and category filters apply together', () {
      provider.setCategory('Networking');
      expect(provider.visible.every((w) => w.category == 'Networking'), isTrue);
      provider.setQuery('dns');
      expect(provider.visible.first.term, 'DNS');
      provider.setQuery('');
      provider.setCategory(null);
      expect(provider.visible.length, provider.all.length);
    });

    test('word of the day is stable within a day and changes daily', () {
      final a = provider.wordOfTheDay(DateTime(2026, 3, 10, 8));
      final b = provider.wordOfTheDay(DateTime(2026, 3, 10, 22));
      final c = provider.wordOfTheDay(DateTime(2026, 3, 11, 8));
      expect(a, b);
      expect(a, isNot(c));
    });

    test('validation rejects duplicates and too short definitions', () {
      expect(provider.validateTerm(''), isNotNull);
      expect(provider.validateTerm('dns'), contains('already'));
      expect(provider.validateTerm('Brand New Term'), isNull);
      expect(provider.validateDefinition('short'), isNotNull);
      expect(
        provider.validateDefinition('A perfectly good definition.'),
        isNull,
      );
    });

    test('adding, editing and deleting a word', () async {
      final added = await provider.addWord(
        author: user,
        term: 'Edge Computing',
        definition: 'Processing data close to where it is produced.',
        category: 'Cloud',
        example: ' ',
      );
      expect(provider.byId(added.id)!.term, 'Edge Computing');
      expect(added.example, isNull);
      expect(provider.byId(added.id)!.isOwnedBy('u1'), isTrue);
      expect(provider.byId(added.id)!.isOwnedBy('other'), isFalse);

      await provider.updateWord(
        added,
        term: 'Edge Computing',
        definition:
            'Running computation near the data source instead of in a distant data centre.',
        category: 'Cloud',
        example: 'A camera detects objects on the device itself.',
      );
      expect(provider.byId(added.id)!.example, isNotNull);

      await provider.deleteWord(added);
      expect(provider.byId(added.id), isNull);
    });

    test('adding a duplicate throws a readable error', () async {
      expect(
        () => provider.addWord(
          author: user,
          term: 'Kubernetes',
          definition: 'Something long enough to pass.',
          category: 'Cloud',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('related words share the category', () {
      final dns = provider.all.firstWhere((w) => w.term == 'DNS');
      final related = provider.related(dns);
      expect(related, isNotEmpty);
      expect(
        related.every((w) => w.category == 'Networking' && w.id != dns.id),
        isTrue,
      );
    });
  });

  group('CommunityProvider', () {
    late CommunityProvider provider;

    setUp(() async {
      provider = CommunityProvider(
        LocalCommunityRepository(MemoryStore(), clock: clock),
        clock: clock,
      );
      await provider.load(
        const AppUser(
          id: DemoSeed.guestId,
          displayName: 'Guest',
          isGuest: true,
        ),
      );
    });

    test('ranking is sorted by XP and includes the user', () {
      const own = RankingEntry(
        userId: DemoSeed.guestId,
        displayName: 'Guest',
        totalXp: 2500,
        weeklyXp: 10,
        streak: 3,
        wordsAdded: 1,
      );
      final all = provider.ranking(RankingPeriod.allTime, own);
      expect(all.first.entry.displayName, 'Nora Kim');
      expect(all[1].isYou, isTrue);
      expect(all[1].rank, 2);
      final xps = all.map((r) => r.xp).toList();
      expect([...xps]..sort((a, b) => b.compareTo(a)), xps);

      final week = provider.ranking(RankingPeriod.week, own);
      // 10 weekly XP is below every fictional member, so the user is last.
      expect(week.last.isYou, isTrue);
      expect(week.last.xp, 10);
    });

    test('stale weekly XP is ignored', () {
      final stale = RankingEntry(
        userId: 'x',
        displayName: 'Old',
        totalXp: 50,
        weeklyXp: 999,
        streak: 0,
        wordsAdded: 0,
        weekStart: DateTime(2026, 1, 5),
      );
      expect(stale.weeklyXpFor(DateTime(2026, 3, 9)), 0);
      expect(stale.weeklyXpFor(DateTime(2026, 1, 5)), 999);
    });

    test('seeded corrections are visible to their owner and proposer', () {
      expect(provider.incoming.single.wordTerm, 'Idempotency');
      expect(provider.sent.single.wordTerm, 'Monorepo');
      expect(provider.pendingIncoming, 1);
    });

    test('accepting a correction updates its status', () async {
      await provider.resolve(
        provider.incoming.single,
        CorrectionStatus.accepted,
      );
      expect(provider.incoming.single.status, CorrectionStatus.accepted);
      expect(provider.pendingIncoming, 0);
    });

    test('cannot suggest changes to built-in or own words', () async {
      final builtIn = SeedWords.all.first;
      expect(
        () => provider.suggestCorrection(
          word: builtIn,
          definition: 'A different definition.',
        ),
        throwsA(isA<RepositoryException>()),
      );
      final own = DemoSeed.communityWords(
        now,
      ).firstWhere((w) => w.authorId == DemoSeed.guestId);
      expect(
        () => provider.suggestCorrection(
          word: own,
          definition: 'A different definition.',
        ),
        throwsA(isA<RepositoryException>()),
      );
    });

    test('suggesting a correction for someone else\'s word works', () async {
      final theirs = DemoSeed.communityWords(
        now,
      ).firstWhere((w) => w.id == 'community-feature-flag');
      await provider.suggestCorrection(
        word: theirs,
        definition:
            'A runtime switch that enables or disables a feature without a deployment.',
        note: 'Shorter.',
      );
      expect(provider.sent.length, 2);
      expect(provider.sent.first.wordTerm, 'Feature Flag');
    });
  });

  group('ExportService', () {
    const export = ExportService();
    final words = SeedWords.all.take(3).toList();

    test('csv escapes quotes and has a header', () {
      final csv = export.toCsv([
        words.first.copyWith(definition: 'He said "hi", then left.'),
      ]);
      expect(csv.split('\r\n').first, 'Term,Category,Definition');
      expect(csv, contains('"He said ""hi"", then left."'));
    });

    test('markdown groups by category', () {
      final md = export.toMarkdown(words);
      expect(md, startsWith('# Tech Dictionary'));
      expect(md, contains('## Hardware'));
      expect(md, contains('- **CPU**'));
    });

    test('every format produces bytes', () async {
      for (final format in ExportFormat.values) {
        final bytes = await export.build(format, words);
        expect(bytes, isNotEmpty, reason: format.name);
      }
      final pdf = await export.build(ExportFormat.pdf, words);
      expect(String.fromCharCodes(pdf.take(4)), '%PDF');
    });
  });
}
