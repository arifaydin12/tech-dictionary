import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../services/search_service.dart';
import '../ui/widgets.dart';
import 'dictionary_tab.dart';
import 'export_sheet.dart';

/// The user's favourite words.
class FavouritesTab extends StatelessWidget {
  const FavouritesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final dictionary = context.watch<DictionaryProvider>();
    final progress = context.watch<ProgressProvider>();
    final favourites = const SearchService().search([
      for (final w in dictionary.all)
        if (progress.isFavourite(w.id)) w,
    ], '');

    if (favourites.isEmpty) {
      return const EmptyState(
        icon: Icons.favorite_border,
        title: 'No favourites yet',
        message: 'Tap the heart on any term to keep it here for quick access.',
      );
    }

    return ContentWidth(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: pagePadding(context, bottom: 8),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${favourites.length} favourite '
                      '${favourites.length == 1 ? 'term' : 'terms'}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => showExportSheet(
                      context,
                      initialScope: ExportScope.favourites,
                    ),
                    icon: const Icon(Icons.ios_share, size: 18),
                    label: const Text('Export'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: pagePadding(context, top: 8, bottom: 24),
            sliver: SliverGrid.builder(
              gridDelegate: wordGridDelegate,
              itemCount: favourites.length,
              itemBuilder: (context, i) {
                final word = favourites[i];
                return WordTile(
                  key: ValueKey(word.id),
                  word: word,
                  isFavourite: true,
                  onTap: () => openWord(context, word),
                  onToggleFavourite: () => toggleFavourite(context, word),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
