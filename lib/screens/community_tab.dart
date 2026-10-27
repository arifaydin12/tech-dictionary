import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/community.dart';
import '../providers/community_provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/session_controller.dart';
import '../ui/widgets.dart';
import '../utils/dates.dart';
import 'word_detail_screen.dart';

/// Leaderboard and correction suggestions.
class CommunityTab extends StatelessWidget {
  const CommunityTab({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = context.select<CommunityProvider, int>(
      (c) => c.pendingIncoming,
    );
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Ranking'),
              Tab(text: pending > 0 ? 'Corrections ($pending)' : 'Corrections'),
            ],
          ),
          const Expanded(
            child: TabBarView(children: [_RankingView(), _CorrectionsView()]),
          ),
        ],
      ),
    );
  }
}

class _RankingView extends StatefulWidget {
  const _RankingView();

  @override
  State<_RankingView> createState() => _RankingViewState();
}

class _RankingViewState extends State<_RankingView> {
  RankingPeriod _period = RankingPeriod.week;

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final progress = context.watch<ProgressProvider>();
    final theme = Theme.of(context);

    if (community.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (community.error != null) {
      return ErrorState(
        message: community.error!,
        onRetry: () => context.read<SessionController>().reload(),
      );
    }

    final rows = community.ranking(_period, progress.ownRankingEntry());
    if (rows.isEmpty) {
      return const EmptyState(
        icon: Icons.leaderboard_outlined,
        title: 'No one on the board yet',
        message: 'Practise to earn XP and be the first on the leaderboard.',
      );
    }

    return SingleChildScrollView(
      child: ContentWidth(
        maxWidth: 760,
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<RankingPeriod>(
                segments: [
                  for (final p in RankingPeriod.values)
                    ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {_period},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _period = s.first),
              ),
              const SizedBox(height: 16),
              for (final row in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RankRow(row: row),
                ),
              const SizedBox(height: 8),
              Text(
                'XP is earned by answering questions and finishing sessions.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row});

  final RankedEntry row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final medal = switch (row.rank) {
      1 => const Color(0xFFD4A017),
      2 => const Color(0xFF9AA0A6),
      3 => const Color(0xFFB87333),
      _ => null,
    };
    final name = row.isYou
        ? '${row.entry.displayName} (you)'
        : row.entry.displayName;
    return Semantics(
      container: true,
      label:
          'Rank ${row.rank}, $name, ${row.xp} XP, ${row.entry.streak} day streak',
      child: ExcludeSemantics(
        child: Card(
          color: row.isYou ? scheme.primaryContainer : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: medal != null
                      ? Icon(Icons.emoji_events, color: medal)
                      : Text(
                          '${row.rank}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: scheme.secondaryContainer,
                  foregroundColor: scheme.onSecondaryContainer,
                  child: Text(_initials(row.entry.displayName)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${row.entry.streak}-day streak · '
                        '${row.entry.wordsAdded} '
                        '${row.entry.wordsAdded == 1 ? 'term' : 'terms'} added',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${row.xp} XP',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    return (parts.first[0] + (parts.length > 1 ? parts[1][0] : ''))
        .toUpperCase();
  }
}

class _CorrectionsView extends StatelessWidget {
  const _CorrectionsView();

  @override
  Widget build(BuildContext context) {
    final community = context.watch<CommunityProvider>();
    final theme = Theme.of(context);

    if (community.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (community.error != null) {
      return ErrorState(
        message: community.error!,
        onRetry: () => context.read<SessionController>().reload(),
      );
    }
    if (community.incoming.isEmpty && community.sent.isEmpty) {
      return const EmptyState(
        icon: Icons.rate_review_outlined,
        title: 'No corrections yet',
        message:
            'Open a term written by another member and choose "Suggest a '
            'correction", or wait for suggestions on your own terms.',
      );
    }

    return SingleChildScrollView(
      child: ContentWidth(
        maxWidth: 760,
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Suggestions for your terms',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (community.incoming.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Nobody has suggested a change to your terms.'),
                ),
              for (final c in community.incoming)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _IncomingCard(correction: c),
                ),
              const SizedBox(height: 12),
              Text(
                'Your suggestions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (community.sent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('You have not suggested any corrections yet.'),
                ),
              for (final c in community.sent)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _SentCard(correction: c),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final CorrectionStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (label, color) = switch (status) {
      CorrectionStatus.pending => ('Pending', scheme.tertiary),
      CorrectionStatus.accepted => ('Accepted', Colors.green.shade700),
      CorrectionStatus.rejected => ('Rejected', scheme.error),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _IncomingCard extends StatelessWidget {
  const _IncomingCard({required this.correction});

  final Correction correction;

  Future<void> _resolve(BuildContext context, bool accept) async {
    final community = context.read<CommunityProvider>();
    final dictionary = context.read<DictionaryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (accept) {
        final word = dictionary.byId(correction.wordId);
        if (word == null) {
          throw Exception('The term no longer exists.');
        }
        await dictionary.updateWord(
          word,
          term: word.term,
          definition: correction.proposedDefinition,
          category: word.category,
          example: word.example,
        );
      }
      await community.resolve(
        correction,
        accept ? CorrectionStatus.accepted : CorrectionStatus.rejected,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            accept
                ? 'Suggestion accepted. "${correction.wordTerm}" was updated.'
                : 'Suggestion rejected.',
          ),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dictionary = context.watch<DictionaryProvider>();
    final word = dictionary.byId(correction.wordId);
    final pending = correction.status == CorrectionStatus.pending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    correction.wordTerm,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(correction.status),
              ],
            ),
            Text(
              '${correction.proposerName} · ${Dates.readable(correction.createdAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            if (word != null) ...[
              Text('Current', style: theme.textTheme.labelMedium),
              const SizedBox(height: 2),
              Text(word.definition),
              const SizedBox(height: 10),
            ],
            Text(
              'Suggested',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(correction.proposedDefinition),
            if (correction.note != null) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${correction.note}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (pending) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () => _resolve(context, true),
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _resolve(context, false),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                  ),
                  if (word != null)
                    TextButton(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => WordDetailScreen(wordId: word.id),
                        ),
                      ),
                      child: const Text('View term'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentCard extends StatelessWidget {
  const _SentCard({required this.correction});

  final Correction correction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    correction.wordTerm,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _StatusChip(correction.status),
              ],
            ),
            Text(
              Dates.readable(correction.createdAt),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(correction.proposedDefinition),
          ],
        ),
      ),
    );
  }
}
