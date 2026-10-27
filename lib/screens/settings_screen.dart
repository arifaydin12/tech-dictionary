import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/dependencies.dart';
import '../config/app_config.dart';
import '../providers/auth_provider.dart';
import '../providers/progress_provider.dart';
import '../providers/settings_provider.dart';
import '../services/speech_service.dart';
import '../ui/widgets.dart';
import 'export_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();
    final demo = context.read<AppDependencies>().demoMode;
    final theme = Theme.of(context);
    final user = auth.user;

    Widget section(String title, List<Widget> children) => Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: ContentWidth(
          maxWidth: 680,
          child: Padding(
            padding: pagePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                section('Account', [
                  ListTile(
                    leading: CircleAvatar(child: Text(user?.initials ?? '?')),
                    title: Text(user?.displayName ?? 'Not signed in'),
                    subtitle: Text(
                      user == null
                          ? ''
                          : user.isGuest
                          ? 'Guest (demo mode)'
                          : (user.email ?? ''),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: Text(
                      user?.isGuest == true ? 'Leave demo' : 'Sign out',
                    ),
                    onTap: () async {
                      final navigator = Navigator.of(context);
                      await context.read<AuthProvider>().signOut();
                      navigator.popUntil((route) => route.isFirst);
                    },
                  ),
                ]),
                section('Appearance', [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Theme'),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<ThemeMode>(
                            segments: const [
                              ButtonSegment(
                                value: ThemeMode.system,
                                icon: Icon(Icons.brightness_auto),
                                label: Text('System'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.light,
                                icon: Icon(Icons.light_mode_outlined),
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: ThemeMode.dark,
                                icon: Icon(Icons.dark_mode_outlined),
                                label: Text('Dark'),
                              ),
                            ],
                            selected: {settings.themeMode},
                            onSelectionChanged: (s) =>
                                settings.setThemeMode(s.first),
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                section('Learning', [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Daily goal (answers per day)'),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final goal
                                in SettingsProvider.dailyGoalOptions)
                              ChoiceChip(
                                label: Text('$goal'),
                                selected: settings.dailyGoal == goal,
                                onSelected: (_) => settings.setDailyGoal(goal),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        const Text('Speech rate'),
                        Expanded(
                          child: Slider(
                            value: settings.speechRate,
                            min: 0.2,
                            max: 0.8,
                            divisions: 6,
                            label: settings.speechRate.toStringAsFixed(1),
                            semanticFormatterCallback: (v) =>
                                'Speech rate ${v.toStringAsFixed(1)}',
                            onChanged: settings.setSpeechRate,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Test speech',
                          icon: const Icon(Icons.volume_up_outlined),
                          onPressed: () => context.read<Speaker>().speak(
                            'Tech Dictionary',
                            rate: settings.speechRate,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
                section('Data', [
                  ListTile(
                    leading: const Icon(Icons.ios_share),
                    title: const Text('Export dictionary'),
                    subtitle: const Text('PDF, CSV or Markdown'),
                    onTap: () => showExportSheet(context),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    title: const Text('Reset my progress'),
                    subtitle: const Text(
                      'Clears XP, streaks, badges, favourites and review '
                      'schedules.',
                    ),
                    onTap: () => _confirmReset(context),
                  ),
                ]),
                section('About', [
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: const Text(AppConfig.appName),
                    subtitle: Text(
                      demo
                          ? 'Version 1.0.0 · demo mode (no Firebase)'
                          : 'Version 1.0.0 · Firebase mode',
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context) async {
    final progress = context.read<ProgressProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset progress?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await progress.resetProgress();
    messenger.showSnackBar(const SnackBar(content: Text('Progress reset')));
  }
}
