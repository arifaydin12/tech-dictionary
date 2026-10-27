import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tech_dictionary/app/app.dart';
import 'package:tech_dictionary/app/dependencies.dart';
import 'package:tech_dictionary/data/key_value_store.dart';
import 'package:tech_dictionary/data/seed_words.dart';
import 'package:tech_dictionary/models/word.dart';
import 'package:tech_dictionary/services/speech_service.dart';
import 'package:tech_dictionary/ui/widgets.dart';

late SilentSpeaker speaker;

Future<void> pumpApp(
  WidgetTester tester, {
  Size size = const Size(1000, 900),
  bool signIn = true,
  MemoryStore? store,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  speaker = SilentSpeaker();
  final deps = AppDependencies.demo(
    store ?? MemoryStore(),
    speaker: speaker,
    clock: () => DateTime(2026, 3, 10, 12),
  );
  await tester.pumpWidget(TechDictionaryApp(dependencies: deps));
  await tester.pumpAndSettle();

  if (signIn) {
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue as guest'));
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
  }
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(
    find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is NavigationBar || w is NavigationRail,
      ),
      matching: find.text(label),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('onboarding, guest sign-in and the demo banner', (tester) async {
    await pumpApp(tester, signIn: false);
    expect(find.text('Learn the language of IT'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Practise the smart way'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();

    expect(find.text('Continue as guest'), findsOneWidget);
    expect(find.textContaining('demo mode'), findsWidgets);
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();

    expect(find.text('Tech Dictionary'), findsWidgets);
    expect(find.textContaining('Demo mode'), findsOneWidget);
    expect(find.text('WORD OF THE DAY'), findsOneWidget);
    expect(find.textContaining('All terms ('), findsOneWidget);
  });

  testWidgets('onboarding is skipped once completed', (tester) async {
    final store = MemoryStore();
    await pumpApp(tester, store: store);
    // A second launch with the same storage goes straight to the home screen.
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, store: store, signIn: false);
    expect(find.text('Learn the language of IT'), findsNothing);
    expect(find.text('WORD OF THE DAY'), findsOneWidget);
  });

  testWidgets('search finds terms despite typos and shows empty state', (
    tester,
  ) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'kubernets');
    await tester.pumpAndSettle();
    expect(find.textContaining('Results ('), findsOneWidget);
    expect(find.text('Kubernetes'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'qqqxxzzy');
    await tester.pumpAndSettle();
    expect(find.text('No matching terms'), findsOneWidget);
  });

  testWidgets('category chips filter the list', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Networking'));
    await tester.pumpAndSettle();
    final count = SeedWords.all.where((w) => w.category == 'Networking').length;
    expect(find.text('Results ($count)'), findsOneWidget);
  });

  testWidgets('word detail, pronunciation and favourites', (tester) async {
    await pumpApp(tester);
    await tester.enterText(find.byType(TextField).first, 'firewall');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Firewall').first);
    await tester.pumpAndSettle();

    expect(find.text('DEFINITION'), findsOneWidget);
    expect(find.text('Related terms'), findsOneWidget);
    expect(find.textContaining('Review status:'), findsOneWidget);

    await tester.tap(find.byTooltip('Pronounce'));
    await tester.pump();
    expect(speaker.spoken, ['Firewall']);

    await tester.tap(find.byTooltip('Add to favourites'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Remove from favourites'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await openTab(tester, 'Favourites');
    expect(find.text('Firewall'), findsWidgets);
    expect(find.text('6 favourite terms'), findsOneWidget);
  });

  testWidgets('adding a term from the form', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Add term'));
    await tester.pumpAndSettle();

    // Validation first.
    await tester.tap(find.text('Add term'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a term.'), findsOneWidget);
    expect(find.textContaining('at least 10 characters'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Term'),
      'Edge Computing',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Definition'),
      'Processing data close to where it is produced instead of in a data centre.',
    );
    await tester.tap(find.text('Add term'));
    await tester.pumpAndSettle();

    expect(find.text('Term added to the dictionary'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'edge computing');
    await tester.pumpAndSettle();
    expect(find.text('Edge Computing'), findsOneWidget);
  });

  testWidgets('a multiple choice session ends with a result screen', (
    tester,
  ) async {
    await pumpApp(tester);
    await openTab(tester, 'Practice');
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<int>),
        matching: find.text('5'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start').first);
    await tester.pumpAndSettle();

    for (var i = 1; i <= 5; i++) {
      expect(find.text('Question $i of 5'), findsOneWidget);
      await tapVisible(tester, find.byKey(const ValueKey('option-0')));
      await tapVisible(tester, find.text(i == 5 ? 'Finish' : 'Next'));
    }

    expect(find.text('Practise again'), findsOneWidget);
    expect(find.textContaining('XP'), findsWidgets);
    await tapVisible(tester, find.text('Done'));
    expect(find.text('Choose a mode'), findsOneWidget);
  });

  testWidgets('typing mode checks the answer', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Practice');
    await tester.tap(find.text('Start').at(2));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'definitely wrong');
    await tester.tap(find.text('Check'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Not quite. The answer is'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('flashcards reveal the answer and offer four grades', (
    tester,
  ) async {
    await pumpApp(tester);
    await openTab(tester, 'Practice');
    await tester.tap(find.text('Start').at(1));
    await tester.pumpAndSettle();

    expect(find.text('Tap to reveal the definition'), findsOneWidget);
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();
    for (final grade in ['Again', 'Hard', 'Good', 'Easy']) {
      expect(find.text(grade), findsOneWidget);
    }
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    expect(find.text('Question 2 of 10'), findsOneWidget);
  });

  testWidgets('statistics screen draws the charts', (tester) async {
    await pumpApp(tester);
    await openTab(tester, 'Progress');
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.byType(BarChart), findsWidgets);
    expect(find.byType(PieChart), findsOneWidget);
    expect(find.text('Answers in the last 7 days'), findsOneWidget);

    await tester.tap(find.text('Badges'));
    await tester.pumpAndSettle();
    expect(find.textContaining('badges unlocked'), findsOneWidget);
  });

  testWidgets('ranking lists the fictional members and the user', (
    tester,
  ) async {
    await pumpApp(tester);
    await openTab(tester, 'Community');
    expect(find.text('Nora Kim'), findsOneWidget);
    expect(find.textContaining('(you)'), findsOneWidget);
  });

  testWidgets('settings can switch to dark mode and sign out', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);

    await tester.tap(find.text('Leave demo'));
    await tester.pumpAndSettle();
    expect(find.text('Continue as guest'), findsOneWidget);
  });

  group('no layout exceptions on any screen size', () {
    const sizes = {
      'phone': Size(390, 844),
      'small phone': Size(320, 640),
      'tablet': Size(820, 1180),
      'desktop': Size(1440, 900),
    };
    for (final entry in sizes.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpApp(tester, size: entry.value);
        for (final tab in [
          'Dictionary',
          'Favourites',
          'Practice',
          'Progress',
          'Community',
        ]) {
          await openTab(tester, tab);
          expect(
            tester.takeException(),
            isNull,
            reason: '$tab on ${entry.key}',
          );
        }
        await openTab(tester, 'Progress');
        await tester.tap(find.text('Badges'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byTooltip('Settings'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('WordTile shows term, definition and handles taps', (
    tester,
  ) async {
    var tapped = 0;
    var favourited = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 160,
            child: WordTile(
              word: const Word(
                id: 'x',
                term: 'Sample',
                definition: 'A sample definition.',
                category: 'Web',
              ),
              isFavourite: false,
              onTap: () => tapped++,
              onToggleFavourite: () => favourited++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Sample'), findsOneWidget);
    expect(find.text('A sample definition.'), findsOneWidget);
    await tester.tap(find.text('Sample'));
    await tester.tap(find.byTooltip('Add Sample to favourites'));
    expect(tapped, 1);
    expect(favourited, 1);
  });
}
