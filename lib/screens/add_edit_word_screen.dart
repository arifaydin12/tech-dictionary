import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../models/word.dart';
import '../providers/auth_provider.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../ui/widgets.dart';

/// Form for adding a new term, or editing one of the user's own terms.
class AddEditWordScreen extends StatefulWidget {
  const AddEditWordScreen({super.key, this.word, this.initialTerm});

  /// The word being edited, or `null` to add a new one.
  final Word? word;

  /// Pre-filled term when adding.
  final String? initialTerm;

  @override
  State<AddEditWordScreen> createState() => _AddEditWordScreenState();
}

class _AddEditWordScreenState extends State<AddEditWordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _term;
  late final TextEditingController _definition;
  late final TextEditingController _example;
  late String _category;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.word != null;

  @override
  void initState() {
    super.initState();
    final w = widget.word;
    _term = TextEditingController(text: w?.term ?? widget.initialTerm ?? '');
    _definition = TextEditingController(text: w?.definition ?? '');
    _example = TextEditingController(text: w?.example ?? '');
    _category = w?.category ?? Categories.software.name;
  }

  @override
  void dispose() {
    _term.dispose();
    _definition.dispose();
    _example.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dictionary = context.read<DictionaryProvider>();
    final progress = context.read<ProgressProvider>();
    final user = context.read<AuthProvider>().user;
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (user == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_editing) {
        await dictionary.updateWord(
          widget.word!,
          term: _term.text,
          definition: _definition.text,
          category: _category,
          example: _example.text,
        );
        messenger.showSnackBar(const SnackBar(content: Text('Term updated')));
      } else {
        await dictionary.addWord(
          author: user,
          term: _term.text,
          definition: _definition.text,
          category: _category,
          example: _example.text,
        );
        final badges = await progress.noteWordAdded();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              badges.isEmpty
                  ? 'Term added to the dictionary'
                  : 'Term added. Badge unlocked: '
                        '${badges.map((b) => b.title).join(', ')}',
            ),
          ),
        );
      }
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dictionary = context.read<DictionaryProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_editing ? 'Edit term' : 'Add a term')),
      body: SingleChildScrollView(
        child: ContentWidth(
          maxWidth: 640,
          child: Padding(
            padding: pagePadding(context),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    InlineError(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _term,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Term'),
                    validator: (v) => dictionary.validateTerm(
                      v ?? '',
                      excludeId: widget.word?.id,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c in Categories.all)
                        DropdownMenuItem(
                          value: c.name,
                          child: Row(
                            children: [
                              Icon(c.icon, size: 18, color: c.color),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                        setState(() => _category = v ?? _category),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _definition,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 600,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Definition',
                      alignLabelWithHint: true,
                      helperText: 'One or two clear sentences.',
                    ),
                    validator: (v) => dictionary.validateDefinition(v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _example,
                    minLines: 2,
                    maxLines: 4,
                    maxLength: 300,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Example (optional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_editing ? 'Save changes' : 'Add term'),
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
