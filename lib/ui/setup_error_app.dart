import 'package:flutter/material.dart';

import '../config/app_config.dart';
import 'app_theme.dart';

/// Shown when the app starts in Firebase mode without a working Firebase
/// configuration. Explains how to configure Firebase or use demo mode.
class SetupErrorApp extends StatelessWidget {
  const SetupErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConfig.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Firebase is not configured',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This build is running in Firebase mode, but '
                      'lib/firebase_options.dart still contains placeholder '
                      'values.',
                    ),
                    const SizedBox(height: 16),
                    const Text('To use your own Firebase project, run:'),
                    const SizedBox(height: 8),
                    const _Code('flutterfire configure'),
                    const SizedBox(height: 16),
                    const Text('To try the app without Firebase, run:'),
                    const SizedBox(height: 8),
                    const _Code('flutter run --dart-define=DEMO_MODE=true'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Code extends StatelessWidget {
  const _Code(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SelectableText(
        text,
        style: const TextStyle(fontFamily: 'monospace'),
      ),
    );
  }
}
