import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../providers/dictionary_provider.dart';
import '../providers/progress_provider.dart';
import '../services/gamification_service.dart';
import '../services/stats_service.dart';
import '../ui/widgets.dart';
import '../utils/dates.dart';

/// Streaks, accuracy, activity and category mastery, drawn with fl_chart.
class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();
    final dictionary = context.watch<DictionaryProvider>();
    final data = progress.progress;
    final stats = progress.stats;

    final activity = stats.recentActivity(data, progress.now);
    final mastery = stats.categoryMastery(
      dictionary.all,
      data,
      Categories.names,
    );
    final recentQuizzes = data.quizzes.length > 10
        ? data.quizzes.sublist(data.quizzes.length - 10)
        : data.quizzes;

    return SingleChildScrollView(
      child: ContentWidth(
        child: Padding(
          padding: pagePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress.error != null) ...[
                InlineError(message: progress.error!),
                const SizedBox(height: 12),
              ],
              _LevelCard(progress: progress),
              const SizedBox(height: 12),
              _MetricGrid(
                tiles: [
                  _Metric(
                    Icons.local_fire_department,
                    'Current streak',
                    '${progress.currentStreak} ${progress.currentStreak == 1 ? 'day' : 'days'}',
                    Colors.deepOrange,
                  ),
                  _Metric(
                    Icons.emoji_events_outlined,
                    'Best streak',
                    '${progress.longestStreak} ${progress.longestStreak == 1 ? 'day' : 'days'}',
                    Colors.amber.shade800,
                  ),
                  _Metric(
                    Icons.track_changes,
                    'Accuracy',
                    '${(data.accuracy * 100).round()}%',
                    Colors.green.shade700,
                  ),
                  _Metric(
                    Icons.quiz_outlined,
                    'Answers',
                    '${data.totalReviews}',
                    Theme.of(context).colorScheme.primary,
                  ),
                  _Metric(
                    Icons.lightbulb_outline,
                    'Learned',
                    '${stats.learnedCount(data)} terms',
                    Colors.teal,
                  ),
                  _Metric(
                    Icons.workspace_premium_outlined,
                    'Mastered',
                    '${stats.masteredCount(data)} terms',
                    Colors.purple,
                  ),
                  _Metric(
                    Icons.bolt,
                    'XP this week',
                    '${progress.weeklyXp}',
                    Colors.indigo,
                  ),
                  _Metric(
                    Icons.edit_note,
                    'Terms added',
                    '${data.wordsAdded}',
                    Colors.blueGrey,
                  ),
                ],
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 900;
                  final activityCard = _ChartCard(
                    title: 'Answers in the last 7 days',
                    semantics:
                        'Bar chart of answers per day. ${activity.map((a) => '${Dates.weekdayShort(a.date)} ${a.reviews}').join(', ')}.',
                    child: SizedBox(
                      height: 220,
                      child: _ActivityChart(activity: activity),
                    ),
                  );
                  final accuracyCard = _ChartCard(
                    title: 'Overall accuracy',
                    semantics:
                        '${data.totalCorrect} correct and ${data.totalIncorrect} incorrect answers.',
                    child: _AccuracyDonut(
                      correct: data.totalCorrect,
                      incorrect: data.totalIncorrect,
                    ),
                  );
                  final trendCard = _ChartCard(
                    title: 'Accuracy of recent sessions',
                    semantics:
                        'Line chart of session accuracy: ${recentQuizzes.map((q) => '${(q.accuracy * 100).round()}%').join(', ')}.',
                    child: SizedBox(
                      height: 220,
                      child: recentQuizzes.length < 2
                          ? const Center(
                              child: Text(
                                'Finish two practice sessions to see your trend.',
                                textAlign: TextAlign.center,
                              ),
                            )
                          : _TrendChart(
                              values: [
                                for (final q in recentQuizzes) q.accuracy * 100,
                              ],
                            ),
                    ),
                  );
                  final masteryCard = _ChartCard(
                    title: 'Category mastery',
                    semantics:
                        'Mastery by category: ${mastery.map((m) => '${m.category} ${(m.score * 100).round()}%').join(', ')}.',
                    child: _MasteryChart(mastery: mastery),
                  );

                  Widget pair(Widget a, int flexA, Widget b, int flexB) =>
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: flexA, child: a),
                            const SizedBox(width: 12),
                            Expanded(flex: flexB, child: b),
                          ],
                        ),
                      );

                  if (wide) {
                    return Column(
                      children: [
                        const SizedBox(height: 12),
                        pair(activityCard, 3, accuracyCard, 2),
                        const SizedBox(height: 12),
                        pair(trendCard, 2, masteryCard, 3),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const SizedBox(height: 12),
                      activityCard,
                      const SizedBox(height: 12),
                      accuracyCard,
                      const SizedBox(height: 12),
                      trendCard,
                      const SizedBox(height: 12),
                      masteryCard,
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

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.progress});

  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = progress.level;
    final next = GamificationService.xpForLevel(level + 1);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Semantics(
          container: true,
          label:
              'Level $level. ${progress.xp} experience points, ${next - progress.xp} to the next level.',
          child: ExcludeSemantics(
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.colorScheme.primary,
                  ),
                  child: Text(
                    '$level',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level $level',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.levelProgress,
                          minHeight: 10,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${progress.xp} XP · ${next - progress.xp} XP to level ${level + 1}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Metric {
  const _Metric(this.icon, this.label, this.value, this.color);

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.tiles});

  final List<_Metric> tiles;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 12.0;
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 4
            : 2;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in tiles)
              SizedBox(
                width: width,
                child: Semantics(
                  container: true,
                  label: '${m.label}: ${m.value}',
                  child: ExcludeSemantics(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Icon(m.icon, color: m.color, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      m.value,
                                      maxLines: 1,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    m.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    required this.semantics,
  });

  final String title;
  final String semantics;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            Semantics(
              container: true,
              label: '$title. $semantics',
              child: ExcludeSemantics(child: child),
            ),
          ],
        ),
      ),
    );
  }
}

FlTitlesData _titles({
  required Widget Function(double value, TitleMeta meta) bottom,
  double leftReserved = 36,
  double? leftInterval,
  String Function(double value)? leftLabel,
}) {
  const hidden = AxisTitles(sideTitles: SideTitles(showTitles: false));
  return FlTitlesData(
    topTitles: hidden,
    rightTitles: hidden,
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: leftReserved,
        interval: leftInterval,
        getTitlesWidget: (value, meta) => SideTitleWidget(
          meta: meta,
          child: Text(
            leftLabel?.call(value) ?? meta.formattedValue,
            style: const TextStyle(fontSize: 11),
          ),
        ),
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 32,
        getTitlesWidget: bottom,
      ),
    ),
  );
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart({required this.activity});

  final List<DayActivity> activity;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final maxValue = activity.fold<int>(0, (m, a) => math.max(m, a.reviews));
    final maxY = math.max(10, ((maxValue * 1.25) / 5).ceil() * 5).toDouble();
    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: _titles(
          leftInterval: maxY / 4,
          leftLabel: (v) => v.round().toString(),
          bottom: (value, meta) {
            final day = activity[value.toInt()].date;
            return SideTitleWidget(
              meta: meta,
              child: Text(
                Dates.weekdayShort(day),
                style: const TextStyle(fontSize: 12),
              ),
            );
          },
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final a = activity[group.x];
              return BarTooltipItem(
                '${Dates.weekdayShort(a.date)}: ${a.reviews}',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w700,
                ),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < activity.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: activity[i].reviews.toDouble(),
                  width: 22,
                  color: i == activity.length - 1
                      ? scheme.primary
                      : scheme.primary.withValues(alpha: 0.55),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _AccuracyDonut extends StatelessWidget {
  const _AccuracyDonut({required this.correct, required this.incorrect});

  final int correct;
  final int incorrect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = correct + incorrect;
    final green = Colors.green.shade600;
    final red = theme.colorScheme.error;
    final percent = total == 0 ? 0 : (correct / total * 100).round();
    return Column(
      children: [
        SizedBox(
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  centerSpaceRadius: 54,
                  sectionsSpace: total == 0 ? 0 : 3,
                  sections: total == 0
                      ? [
                          PieChartSectionData(
                            value: 1,
                            color: theme.colorScheme.surfaceContainerHighest,
                            showTitle: false,
                            radius: 22,
                          ),
                        ]
                      : [
                          PieChartSectionData(
                            value: correct.toDouble(),
                            color: green,
                            showTitle: false,
                            radius: 22,
                          ),
                          PieChartSectionData(
                            value: incorrect.toDouble(),
                            color: red,
                            showTitle: false,
                            radius: 22,
                          ),
                        ],
                ),
              ),
              Text(
                total == 0 ? '–' : '$percent%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _LegendDot(color: green, label: 'Correct ($correct)'),
            _LegendDot(color: red, label: 'Incorrect ($incorrect)'),
          ],
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: scheme.outlineVariant, strokeWidth: 1),
        ),
        titlesData: _titles(
          leftInterval: 25,
          leftLabel: (v) => '${v.round()}%',
          leftReserved: 44,
          bottom: (value, meta) {
            if (value != value.roundToDouble()) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(
                '${value.toInt() + 1}',
                style: const TextStyle(fontSize: 11),
              ),
            );
          },
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  'Session ${s.x.toInt() + 1}: ${s.y.round()}%',
                  TextStyle(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryChart extends StatelessWidget {
  const _MasteryChart({required this.mastery});

  final List<CategoryMastery> mastery;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              maxY: 100,
              alignment: BarChartAlignment.spaceAround,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: theme.colorScheme.outlineVariant,
                  strokeWidth: 1,
                ),
              ),
              titlesData: _titles(
                leftInterval: 25,
                leftReserved: 44,
                leftLabel: (v) => '${v.round()}%',
                bottom: (value, meta) {
                  final c = Categories.byName(mastery[value.toInt()].category);
                  return SideTitleWidget(
                    meta: meta,
                    child: Icon(c.icon, size: 18, color: c.color),
                  );
                },
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final m = mastery[group.x];
                    return BarTooltipItem(
                      '${m.category}\n${m.learned}/${m.total} learned',
                      TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    );
                  },
                ),
              ),
              barGroups: [
                for (var i = 0; i < mastery.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: mastery[i].score * 100,
                        width: 18,
                        color: Categories.byName(mastery[i].category).color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(5),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: 100,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 14,
          runSpacing: 6,
          children: [
            for (final m in mastery)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Categories.byName(m.category).icon,
                    size: 14,
                    color: Categories.byName(m.category).color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${m.category} ${(m.score * 100).round()}%',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}
