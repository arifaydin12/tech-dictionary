import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/progress_provider.dart';
import '../services/gamification_service.dart';
import '../ui/widgets.dart';
import '../utils/dates.dart';

/// Grid of all badges, unlocked and locked.
class BadgesView extends StatelessWidget {
  const BadgesView({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final unlocked = progress.progress.badges;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: ContentWidth(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${unlocked.length} of ${GamificationService.badges.length} badges unlocked',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 12.0;
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 600
                      ? 3
                      : 2;
                  final width =
                      (constraints.maxWidth - gap * (columns - 1)) / columns;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final badge in GamificationService.badges)
                        SizedBox(
                          width: width,
                          child: _BadgeCard(
                            badge: badge,
                            unlockedAt: unlocked[badge.id],
                            value: badge.value(progress.progress),
                          ),
                        ),
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

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.badge,
    required this.unlockedAt,
    required this.value,
  });

  final BadgeDef badge;
  final DateTime? unlockedAt;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isUnlocked = unlockedAt != null;
    final shown = value > badge.target ? badge.target : value;

    return Semantics(
      container: true,
      label: isUnlocked
          ? '${badge.title}, unlocked. ${badge.description}'
          : '${badge.title}, locked, $shown of ${badge.target}. ${badge.description}',
      child: ExcludeSemantics(
        child: Card(
          color: isUnlocked ? scheme.tertiaryContainer : null,
          child: SizedBox(
            height: 186,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isUnlocked
                          ? scheme.tertiary
                          : scheme.surfaceContainerHighest,
                    ),
                    child: Icon(
                      isUnlocked ? badge.icon : Icons.lock_outline,
                      color: isUnlocked
                          ? scheme.onTertiary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    badge.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      badge.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  if (isUnlocked)
                    Text(
                      'Unlocked ${Dates.readable(unlockedAt!)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: shown / badge.target,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$shown / ${badge.target}',
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
