import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/card_state.dart';
import '../models/quiz.dart';
import '../models/word.dart';
import '../providers/auth_provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/speech_service.dart';
import '../ui/widgets.dart';
import '../utils/dates.dart';
import 'add_edit_word_screen.dart';
import 'dictionary_tab.dart';
import 'quiz_session_screen.dart';
import 'suggest_correction_screen.dart';

/// Full details of one term, with text-to-speech, favourites and the
/// learner's review status.
class WordDetailScreen extends StatelessWidget {
  const WordDetailScreen({super.key, required this.wordId});

  final String wordId;

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final progress = context.watch<ProgressProvider>();
    final userId = context.watch<AuthProvider>().user?.id;
    final word = dictionary.byId(wordId);

    if (word == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const EmptyState(
          icon: Icons.search_off,
          title: 'Term not found',
          message: 'This term may have been deleted.',
        ),
      );
    }

    final isOwner = word.isOwnedBy(userId);
    final theme = Theme.of(context);
    final favourite = progress.isFavourite(word.id);
    final related = dictionary.related(word);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Term'),
        actions: [
          IconButton(
            tooltip: favourite ? 'Remove from favourites' : 'Add to favourites',
            onPressed: () => toggleFavourite(context, word),
            icon: Icon(
              favourite ? Icons.favorite : Icons.favorite_border,
              color: favourite ? Colors.redAccent : null,
            ),
          ),
          if (isOwner)
            PopupMenuButton<String>(
              tooltip: 'More actions',
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AddEditWordScreen(word: word),
                    ),
                  );
                } else if (value == 'delete') {
                  _confirmDelete(context, word);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit term')),
                PopupMenuItem(value: 'delete', child: Text('Delete term')),
              ],
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentWidth(
          maxWidth: 760,
          child: Padding(
            padding: pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CategoryLabel(category: word.category, dense: false),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Semantics(
                        header: true,
                        child: Text(
                          word.term,
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 36,
                          ),
                        ),
                      ),
                    ),
                    _SpeakButton(text: word.term),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DEFINITION',
                          style: theme.textTheme.labelSmall?.copyWith(
                            letterSpacing: 1,
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          word.definition,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            height: 1.5,
                          ),
                        ),
                        if (word.example != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'EXAMPLE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              letterSpacing: 1,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            word.example!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                await Clipboard.setData(
                                  ClipboardData(
                                    text: '${word.term}: ${word.definition}',
                                  ),
                                );
                                if (context.mounted) {
                                  showMessage(context, 'Copied to clipboard');
                                }
                              },
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text('Copy'),
                            ),
                            _SpeakButton(
                              text: '${word.term}. ${word.definition}',
                              label: 'Read definition aloud',
                              withLabel: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ReviewStatus(
                  card: progress.cardFor(word.id),
                  now: progress.now,
                ),
                if (!word.isBuiltIn) ...[
                  const SizedBox(height: 16),
                  _Author(word: word, isOwner: isOwner),
                ],
                if (related.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Related terms',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in related)
                        ActionChip(
                          label: Text(r.term),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WordDetailScreen(wordId: r.id),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => QuizSessionScreen(
                        mode: QuizMode.multipleChoice,
                        questionCount: 10,
                        category: word.category,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.school_outlined),
                  label: Text('Practise ${word.category} terms'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Word word) async {
    final dictionary = context.read<DictionaryProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete term?'),
        content: Text('"${word.term}" will be removed from the dictionary.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await dictionary.deleteWord(word);
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }
}

class _SpeakButton extends StatelessWidget {
  const _SpeakButton({
    required this.text,
    this.label = 'Pronounce',
    this.withLabel = false,
  });

  final String text;
  final String label;
  final bool withLabel;

  @override
  Widget build(BuildContext context) {
    final speaker = context.read<Speaker>();
    final rate = context.watch<SettingsProvider>().speechRate;
    void speak() => speaker.speak(text, rate: rate);
    if (withLabel) {
      return TextButton.icon(
        onPressed: speak,
        icon: const Icon(Icons.volume_up_outlined, size: 18),
        label: const Text('Listen'),
      );
    }
    return IconButton.filledTonal(
      tooltip: label,
      onPressed: speak,
      icon: const Icon(Icons.volume_up),
    );
  }
}

class _ReviewStatus extends StatelessWidget {
  const _ReviewStatus({required this.card, required this.now});

  final CardState? card;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = card;
    String status;
    String detail;
    IconData icon;
    if (c == null || c.isNew) {
      status = 'New';
      detail = 'You have not practised this term yet.';
      icon = Icons.fiber_new_outlined;
    } else {
      if (c.isMastered) {
        status = 'Mastered';
        icon = Icons.workspace_premium_outlined;
      } else if (c.isLearned) {
        status = 'Learned';
        icon = Icons.check_circle_outline;
      } else {
        status = 'Learning';
        icon = Icons.autorenew;
      }
      final due = c.due;
      final days = due == null
          ? 0
          : Dates.dayStart(due).difference(Dates.dayStart(now)).inDays;
      final when = days <= 0
          ? 'due today'
          : days == 1
          ? 'due tomorrow'
          : 'due in $days days';
      detail =
          '${c.correct} correct, ${c.incorrect} incorrect. Next review $when.';
    }
    return Card(
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text('Review status: $status'),
        subtitle: Text(detail),
      ),
    );
  }
}

class _Author extends StatelessWidget {
  const _Author({required this.word, required this.isOwner});

  final Word word;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = word.createdAt;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Community term by '
                    '${isOwner ? 'you' : (word.authorName ?? 'a member')}'
                    '${created != null ? ' · ${Dates.readable(created)}' : ''}',
                  ),
                ),
              ],
            ),
            if (!isOwner && word.authorId != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SuggestCorrectionScreen(word: word),
                    ),
                  ),
                  icon: const Icon(Icons.rate_review_outlined, size: 18),
                  label: const Text('Suggest a correction'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
