import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/word.dart';

/// Screen-width classes used for responsive layouts.
enum ScreenSize {
  compact,
  medium,
  expanded;

  static ScreenSize of(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) return ScreenSize.compact;
    if (width < 1000) return ScreenSize.medium;
    return ScreenSize.expanded;
  }
}

/// Centres [child] and limits its width on large screens.
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = 1100});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Horizontal page padding that grows slightly with the screen size.
EdgeInsets pagePadding(
  BuildContext context, {
  double top = 16,
  double bottom = 24,
}) {
  final horizontal = ScreenSize.of(context) == ScreenSize.compact ? 16.0 : 24.0;
  return EdgeInsets.fromLTRB(horizontal, top, horizontal, bottom);
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(
                child: Icon(icon, size: 56, color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (action != null) ...[const SizedBox(height: 20), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      message: message,
      action: onRetry == null
          ? null
          : FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
    );
  }
}

/// A slim banner for non-fatal errors at the top of a screen.
class InlineError extends StatelessWidget {
  const InlineError({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: scheme.onErrorContainer),
              ),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Small coloured label with the category icon and name.
class CategoryLabel extends StatelessWidget {
  const CategoryLabel({super.key, required this.category, this.dense = true});

  final String category;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final meta = Categories.byName(category);
    final color = Theme.of(context).brightness == Brightness.dark
        ? Color.lerp(meta.color, Colors.white, 0.45)!
        : meta.color;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 8 : 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: dense ? 13 : 15, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              meta.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: dense ? 12 : 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A word in a list or grid.
class WordTile extends StatelessWidget {
  const WordTile({
    super.key,
    required this.word,
    required this.isFavourite,
    required this.onTap,
    required this.onToggleFavourite,
  });

  final Word word;
  final bool isFavourite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            word.term,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (!word.isBuiltIn) ...[
                          const SizedBox(width: 6),
                          Tooltip(
                            message: 'Community term',
                            excludeFromSemantics: true,
                            child: Icon(
                              Icons.group_outlined,
                              size: 16,
                              color: theme.colorScheme.outline,
                              semanticLabel: 'Community term',
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.definition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CategoryLabel(category: word.category),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavourite
                    ? 'Remove ${word.term} from favourites'
                    : 'Add ${word.term} to favourites',
                onPressed: onToggleFavourite,
                icon: Icon(
                  isFavourite ? Icons.favorite : Icons.favorite_border,
                  color: isFavourite ? Colors.redAccent : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid delegate for [WordTile]s: one column on phones, more on wide screens.
const SliverGridDelegate wordGridDelegate =
    SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 520,
      mainAxisExtent: 140,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
    );

void showMessage(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
