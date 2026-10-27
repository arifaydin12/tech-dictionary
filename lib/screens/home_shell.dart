import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../providers/community_provider.dart';
import '../providers/progress_provider.dart';
import '../ui/widgets.dart';
import 'add_edit_word_screen.dart';
import 'community_tab.dart';
import 'dictionary_tab.dart';
import 'favourites_tab.dart';
import 'practice_tab.dart';
import 'progress_tab.dart';
import 'settings_screen.dart';

class _Destination {
  const _Destination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Main navigation: bottom bar on phones, rail on tablets and desktops.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _destinations = [
    _Destination('Dictionary', Icons.menu_book_outlined, Icons.menu_book),
    _Destination('Favourites', Icons.favorite_border, Icons.favorite),
    _Destination('Practice', Icons.school_outlined, Icons.school),
    _Destination('Progress', Icons.insights_outlined, Icons.insights),
    _Destination('Community', Icons.groups_outlined, Icons.groups),
  ];

  int _index = 0;

  void goTo(int index) => setState(() => _index = index);

  Widget _body() {
    switch (_index) {
      case 0:
        return DictionaryTab(onOpenPractice: () => goTo(2));
      case 1:
        return const FavouritesTab();
      case 2:
        return const PracticeTab();
      case 3:
        return const ProgressTab();
      default:
        return const CommunityTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = ScreenSize.of(context);
    final useRail = size != ScreenSize.compact;
    final progress = context.watch<ProgressProvider>();
    final pending = context.select<CommunityProvider, int>(
      (c) => c.pendingIncoming,
    );

    final title = _index == 0 ? AppConfig.appName : _destinations[_index].label;

    Widget destinationIcon(int i, {required bool selected}) {
      final d = _destinations[i];
      final icon = Icon(selected ? d.selectedIcon : d.icon);
      if (i == 4 && pending > 0) {
        return Badge.count(count: pending, child: icon);
      }
      return icon;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Semantics(
            label: '${progress.currentStreak} day streak',
            child: Tooltip(
              message: 'Current streak',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.deepOrange,
                      size: 22,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${progress.currentStreak}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: useRail
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                NavigationRail(
                  selectedIndex: _index,
                  onDestinationSelected: goTo,
                  extended: size == ScreenSize.expanded,
                  labelType: size == ScreenSize.expanded
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: [
                    for (var i = 0; i < _destinations.length; i++)
                      NavigationRailDestination(
                        icon: destinationIcon(i, selected: false),
                        selectedIcon: destinationIcon(i, selected: true),
                        label: Text(_destinations[i].label),
                      ),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _body()),
              ],
            )
          : _body(),
      bottomNavigationBar: useRail
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: goTo,
              destinations: [
                for (var i = 0; i < _destinations.length; i++)
                  NavigationDestination(
                    icon: destinationIcon(i, selected: false),
                    selectedIcon: destinationIcon(i, selected: true),
                    label: _destinations[i].label,
                  ),
              ],
            ),
      floatingActionButton: _index == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const AddEditWordScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add term'),
            )
          : null,
    );
  }
}
