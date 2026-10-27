import 'package:flutter/material.dart';

import 'badges_view.dart';
import 'stats_view.dart';

/// Statistics and badges in two tabs.
class ProgressTab extends StatelessWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Statistics'),
              Tab(text: 'Badges'),
            ],
          ),
          Expanded(child: TabBarView(children: [StatsView(), BadgesView()])),
        ],
      ),
    );
  }
}
