import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/quiz.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../ui/widgets.dart';
import 'quiz_session_screen.dart';

/// Choose how to practise: mode, category and number of questions.
class PracticeTab extends StatefulWidget {
  const PracticeTab({super.key});

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  String? _category;
  int _count = 10;

  void _start(QuizMode mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizSessionScreen(
          mode: mode,
          category: _category,
          questionCount: _count,
        ),
      ),
    );
  }

  static IconData _iconFor(QuizMode mode) => switch (mode) {
    QuizMode.multipleChoice => Icons.checklist_rtl,
    QuizMode.flashcards => Icons.style_outlined,
    QuizMode.typing => Icons.keyboard_alt_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    final pool = _category == null
        ? dictionary.all
        : dictionary.all.where((w) => w.category == _category).toList();
    final due = progress.stats.dueCount(pool, progress.progress, progress.now);
    final fresh = pool
        .where((w) => progress.cardFor(w.id)?.isNew ?? true)
        .length;

    return SingleChildScrollView(
      child: ContentWidth(
        maxWidth: 900,
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.event_repeat,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              due == 0
                                  ? 'No terms are due right now'
                                  : '$due ${due == 1 ? 'term is' : 'terms are'} due for review',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Each session starts with the terms you are about to '
                        'forget, then adds new ones ($fresh not studied yet). '
                        'Answers schedule the next review with spaced '
                        'repetition.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String?>(
                              initialValue: _category,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('All categories'),
                                ),
                                for (final c in Categories.all)
                                  DropdownMenuItem(
                                    value: c.name,
                                    child: Text(c.name),
                                  ),
                              ],
                              onChanged: (v) => setState(() => _category = v),
                            ),
                          ),
                          Semantics(
                            label: 'Number of questions',
                            child: SegmentedButton<int>(
                              segments: const [
                                ButtonSegment(value: 5, label: Text('5')),
                                ButtonSegment(value: 10, label: Text('10')),
                                ButtonSegment(value: 20, label: Text('20')),
                              ],
                              selected: {_count},
                              showSelectedIcon: false,
                              onSelectionChanged: (s) =>
                                  setState(() => _count = s.first),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Choose a mode',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final cards = [
                    for (final mode in QuizMode.values)
                      _ModeCard(
                        mode: mode,
                        icon: _iconFor(mode),
                        onStart: () => _start(mode),
                      ),
                  ];
                  if (constraints.maxWidth >= 640) {
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, card) in cards.indexed) ...[
                            if (i > 0) const SizedBox(width: gap),
                            Expanded(child: card),
                          ],
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (final (i, card) in cards.indexed) ...[
                        if (i > 0) const SizedBox(height: gap),
                        card,
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.mode,
    required this.icon,
    required this.onStart,
  });

  final QuizMode mode;
  final IconData icon;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onStart,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
              ),
              const SizedBox(height: 14),
              Text(
                mode.label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                mode.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Semantics(
                button: true,
                label: 'Start ${mode.label} practice',
                excludeSemantics: true,
                child: FilledButton.tonal(
                  onPressed: onStart,
                  child: const Text('Start'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
