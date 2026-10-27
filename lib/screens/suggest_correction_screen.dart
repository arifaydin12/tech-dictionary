import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/word.dart';
import '../providers/community_provider.dart';
import '../ui/widgets.dart';

/// Lets a user propose a better definition for someone else's term.
class SuggestCorrectionScreen extends StatefulWidget {
  const SuggestCorrectionScreen({super.key, required this.word});

  final Word word;

  @override
  State<SuggestCorrectionScreen> createState() =>
      _SuggestCorrectionScreenState();
}

class _SuggestCorrectionScreenState extends State<SuggestCorrectionScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _definition = TextEditingController(
    text: widget.word.definition,
  );
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _definition.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    final community = context.read<CommunityProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await community.suggestCorrection(
        word: widget.word,
        definition: _definition.text,
        note: _note.text,
      );
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Suggestion sent to ${widget.word.authorName ?? 'the author'}',
          ),
        ),
      );
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Suggest a correction')),
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
                  Text(
                    widget.word.term,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The author, ${widget.word.authorName ?? 'a member'}, '
                    'can accept or reject your suggestion.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    InlineError(message: _error!),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _definition,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: 600,
                    decoration: const InputDecoration(
                      labelText: 'Suggested definition',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.length < 10) {
                        return 'The definition must be at least 10 characters.';
                      }
                      if (value == widget.word.definition.trim()) {
                        return 'Change the definition before sending.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _note,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      labelText: 'Why? (optional)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                    label: const Text('Send suggestion'),
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
