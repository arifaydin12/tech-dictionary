import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/word.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/session_controller.dart';
import '../providers/settings_provider.dart';
import '../ui/widgets.dart';
import 'add_edit_word_screen.dart';
import 'word_detail_screen.dart';

/// Home tab: search, category filter, word of the day and the word list.
class DictionaryTab extends StatefulWidget {
  const DictionaryTab({super.key, required this.onOpenPractice});

  final VoidCallback onOpenPractice;

  @override
  State<DictionaryTab> createState() => _DictionaryTabState();
}

class _DictionaryTabState extends State<DictionaryTab> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(
      text: context.read<DictionaryProvider>().query,
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);
    final browsing =
        dictionary.query.trim().isEmpty && dictionary.category == null;
    final words = dictionary.visible;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: ContentWidth(
            child: Padding(
              padding: pagePadding(context, bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (dictionary.error != null) ...[
                    InlineError(
                      message: dictionary.error!,
                      onRetry: () => context.read<SessionController>().reload(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _search,
                    textInputAction: TextInputAction.search,
                    onChanged: dictionary.setQuery,
                    decoration: InputDecoration(
                      hintText: 'Search terms, e.g. "kubernetes"',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: dictionary.query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _search.clear();
                                dictionary.setQuery('');
                              },
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _CategoryChip(
                          label: 'All',
                          icon: Icons.apps,
                          selected: dictionary.category == null,
                          onSelected: () => dictionary.setCategory(null),
                        ),
                        for (final c in Categories.all)
                          _CategoryChip(
                            label: c.name,
                            icon: c.icon,
                            selected: dictionary.category == c.name,
                            onSelected: () => dictionary.setCategory(
                              dictionary.category == c.name ? null : c.name,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (browsing) ...[
                    const SizedBox(height: 16),
                    _Highlights(onOpenPractice: widget.onOpenPractice),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    browsing
                        ? 'All terms (${words.length})'
                        : 'Results (${words.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (dictionary.loading)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (words.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              icon: Icons.search_off,
              title: 'No matching terms',
              message: dictionary.query.trim().isEmpty
                  ? 'There are no terms in this category yet.'
                  : 'Nothing matches "${dictionary.query.trim()}". '
                        'Check the spelling or add it yourself.',
              action: OutlinedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add a term'),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        AddEditWordScreen(initialTerm: dictionary.query.trim()),
                  ),
                ),
              ),
            ),
          )
        else
          SliverLayoutBuilder(
            builder: (context, constraints) {
              // Keep the grid aligned with the centred header on wide screens.
              final extra = (constraints.crossAxisExtent - 1100) / 2;
              final base = ScreenSize.of(context) == ScreenSize.compact
                  ? 16.0
                  : 24.0;
              final side = base + (extra > 0 ? extra : 0);
              return SliverPadding(
                padding: EdgeInsets.fromLTRB(side, 0, side, 96),
                sliver: SliverGrid.builder(
                  gridDelegate: wordGridDelegate,
                  itemCount: words.length,
                  itemBuilder: (context, i) {
                    final word = words[i];
                    return WordTile(
                      key: ValueKey(word.id),
                      word: word,
                      isFavourite: progress.isFavourite(word.id),
                      onTap: () => openWord(context, word),
                      onToggleFavourite: () => toggleFavourite(context, word),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}

void openWord(BuildContext context, Word word) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => WordDetailScreen(wordId: word.id)),
  );
}

Future<void> toggleFavourite(BuildContext context, Word word) async {
  final progress = context.read<ProgressProvider>();
  final adding = !progress.isFavourite(word.id);
  final messenger = ScaffoldMessenger.of(context);
  final badges = await progress.toggleFavourite(word.id);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          badges.isNotEmpty
              ? 'Badge unlocked: ${badges.map((b) => b.title).join(', ')}'
              : adding
              ? '${word.term} added to favourites'
              : '${word.term} removed from favourites',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

/// Word of the day and the review summary.
class _Highlights extends StatelessWidget {
  const _Highlights({required this.onOpenPractice});

  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final progress = context.watch<ProgressProvider>();
    final goal = context.watch<SettingsProvider>().dailyGoal;
    final word = dictionary.wordOfTheDay(progress.now);
    final due = progress.stats.dueCount(
      dictionary.all,
      progress.progress,
      progress.now,
    );

    final wotd = word == null
        ? const SizedBox.shrink()
        : _WordOfTheDay(word: word);
    final review = _ReviewCard(
      due: due,
      todayReviews: progress.todayReviews,
      goal: goal,
      onOpenPractice: onOpenPractice,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 760) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: wotd),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: review),
              ],
            ),
          );
        }
        return Column(children: [wotd, const SizedBox(height: 12), review]);
      },
    );
  }
}

class _WordOfTheDay extends StatelessWidget {
  const _WordOfTheDay({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onColor = scheme.onPrimary;
    return Semantics(
      container: true,
      label: 'Word of the day: ${word.term}',
      child: Material(
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                HSLColor.fromColor(scheme.primary)
                    .withHue(
                      (HSLColor.fromColor(scheme.primary).hue + 40) % 360,
                    )
                    .toColor(),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: InkWell(
            onTap: () => openWord(context, word),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.wb_sunny_outlined, size: 18, color: onColor),
                      const SizedBox(width: 6),
                      Text(
                        'WORD OF THE DAY',
                        style: TextStyle(
                          color: onColor.withValues(alpha: 0.9),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    word.term,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onColor,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    word.definition,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: onColor.withValues(alpha: 0.92),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          word.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: onColor.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Read more',
                        style: TextStyle(
                          color: onColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(Icons.arrow_forward, size: 16, color: onColor),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.due,
    required this.todayReviews,
    required this.goal,
    required this.onOpenPractice,
  });

  final int due;
  final int todayReviews;
  final int goal;
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final done = (todayReviews / goal).clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Today',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              due == 0
                  ? 'Nothing due for review'
                  : '$due ${due == 1 ? 'term is' : 'terms are'} due for review',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: 'Daily goal: $todayReviews of $goal answers',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: done, minHeight: 8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$todayReviews / $goal answers today',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonalIcon(
                onPressed: onOpenPractice,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Practise now'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
