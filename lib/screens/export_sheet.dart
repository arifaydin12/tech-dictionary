import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app/dependencies.dart';
import '../models/word.dart';
import '../providers/auth_provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../services/export_service.dart';

enum ExportScope {
  all('All terms'),
  favourites('Favourites'),
  mine('My terms');

  const ExportScope(this.label);

  final String label;
}

Future<void> showExportSheet(
  BuildContext context, {
  ExportScope initialScope = ExportScope.all,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: (_) => _ExportSheet(initialScope: initialScope),
  );
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet({required this.initialScope});

  final ExportScope initialScope;

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  late ExportScope _scope = widget.initialScope;
  ExportFormat _format = ExportFormat.pdf;
  bool _busy = false;

  List<Word> _words(BuildContext context) {
    final dictionary = context.read<DictionaryProvider>();
    final progress = context.read<ProgressProvider>();
    final userId = context.read<AuthProvider>().user?.id;
    switch (_scope) {
      case ExportScope.all:
        return dictionary.all;
      case ExportScope.favourites:
        return [
          for (final w in dictionary.all)
            if (progress.isFavourite(w.id)) w,
        ];
      case ExportScope.mine:
        return [
          for (final w in dictionary.all)
            if (w.isOwnedBy(userId)) w,
        ];
    }
  }

  Future<void> _export() async {
    final words = _words(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    if (words.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text('There are no terms in "${_scope.label}".')),
      );
      return;
    }
    final export = context.read<AppDependencies>().export;
    setState(() => _busy = true);
    try {
      final bytes = await export.build(_format, words);
      final name = export.fileName(_format);
      await SharePlus.instance.share(
        ShareParams(
          title: 'Tech Dictionary',
          subject: 'Tech Dictionary export',
          files: [
            XFile.fromData(bytes, mimeType: _format.mimeType, name: name),
          ],
          fileNameOverrides: [name],
        ),
      );
      navigator.pop();
    } catch (e) {
      debugPrint('Export failed: $e');
      messenger.showSnackBar(
        const SnackBar(content: Text('The export could not be created.')),
      );
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = _words(context).length;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export dictionary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Text('What to export', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final s in ExportScope.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _scope == s,
                    onSelected: (_) => setState(() => _scope = s),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Format', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final f in ExportFormat.values)
                  ChoiceChip(
                    label: Text(f.label),
                    selected: _format == f,
                    onSelected: (_) => setState(() => _format = f),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '$count ${count == 1 ? 'term' : 'terms'} will be exported.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _export,
                icon: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.ios_share),
                label: Text(_busy ? 'Preparing…' : 'Export and share'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
