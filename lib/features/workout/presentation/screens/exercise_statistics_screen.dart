import 'dart:convert';

import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseStatisticsScreen extends StatefulWidget {
  final String exerciseName;
  const ExerciseStatisticsScreen({super.key, required this.exerciseName});

  @override
  State<ExerciseStatisticsScreen> createState() =>
      _ExerciseStatisticsScreenState();
}

class _ExerciseStatisticsScreenState extends State<ExerciseStatisticsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, double> _dateToTotalWeight = {};
  Map<String, double> _dateToMaxWeight = {};
  Map<String, double> _dateToMax1RM = {};
  Map<String, int> _dateToOrder = {};
  Map<String, String> _dateToGroupLabel = {};
  Map<String, bool> _dateToIsGrouped = {};
  bool _loading = true;
  late TabController _tabController;
  _StatisticsPeriod _period = _StatisticsPeriod.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where(
          (k) => k.startsWith('exercise_sets_${widget.exerciseName}_'),
        );
    final dateToWeight = <String, double>{};
    final dateToMax = <String, double>{};
    final dateTo1RM = <String, double>{};
    final dateToOrder = <String, int>{};
    final dateToGroupLabel = <String, String>{};
    final dateToIsGrouped = <String, bool>{};

    for (final key in keys) {
      final dateStr = key.split('_').last;

      final workoutsKey = 'workouts_$dateStr';
      final workoutsJson = prefs.getStringList(workoutsKey) ?? [];
      int order = -1;
      String? groupLabel;
      for (int i = 0; i < workoutsJson.length; i++) {
        try {
          final workout = jsonDecode(workoutsJson[i]);
          if (workout['name'] == widget.exerciseName) {
            order = i + 1;
            final groupType = workout['groupType']?.toString();
            if (groupType != null && groupType.isNotEmpty) {
              final label = switch (groupType) {
                'superset' => '슈퍼세트',
                'compound' => '컴파운드 세트',
                _ => '그룹 운동',
              };
              final badge = workout['groupLabel']?.toString();
              groupLabel =
                  badge == null || badge.isEmpty ? label : '$label $badge';
              dateToIsGrouped[dateStr] = true;
            } else {
              dateToIsGrouped[dateStr] = false;
            }
            break;
          }
        } catch (_) {}
      }
      if (order != -1) {
        dateToOrder[dateStr] = order;
      }
      if (groupLabel != null) {
        dateToGroupLabel[dateStr] = groupLabel;
      }

      final setsJson = prefs.getStringList(key) ?? [];
      double total = 0.0;
      double maxWeight = 0.0;
      double max1RM = 0.0;
      for (final jsonStr in setsJson) {
        try {
          final set = jsonDecode(jsonStr);
          final weight = (set['weight'] is int)
              ? (set['weight'] as int).toDouble()
              : (set['weight'] is double)
                  ? set['weight'] as double
                  : double.tryParse(set['weight'].toString()) ?? 0.0;
          final reps = (set['reps'] is int)
              ? set['reps'] as int
              : int.tryParse(set['reps'].toString()) ?? 0;
          total += weight * reps;
          if (weight > maxWeight) maxWeight = weight;
          final oneRM = weight * (1 + reps / 30.0);
          if (oneRM > max1RM) max1RM = oneRM;
        } catch (_) {}
      }
      if (total > 0) dateToWeight[dateStr] = total;
      if (maxWeight > 0) dateToMax[dateStr] = maxWeight;
      if (max1RM > 0) dateTo1RM[dateStr] = max1RM;
    }

    if (!mounted) return;
    setState(() {
      _dateToTotalWeight = dateToWeight;
      _dateToMaxWeight = dateToMax;
      _dateToMax1RM = dateTo1RM;
      _dateToOrder = dateToOrder;
      _dateToGroupLabel = dateToGroupLabel;
      _dateToIsGrouped = dateToIsGrouped;
      _loading = false;
    });
  }

  String _formatWeight(double value) => '${value.toStringAsFixed(1)} kg';

  List<String> _filterDates(Iterable<String> source) {
    final dates = source.toList()..sort();
    if (_period == _StatisticsPeriod.all) return dates;
    final now = DateTime.now();
    final days = _period == _StatisticsPeriod.days7 ? 7 : 30;
    return dates.where((date) {
      final parsed = DateTime.tryParse(date);
      if (parsed == null) return false;
      return now.difference(parsed).inDays < days;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dates = _filterDates(_dateToTotalWeight.keys);
    final weights = dates.map((d) => _dateToTotalWeight[d] ?? 0.0).toList();
    final maxDates = _filterDates(_dateToMaxWeight.keys);
    final maxWeights = maxDates.map((d) => _dateToMaxWeight[d] ?? 0.0).toList();
    final oneRmDates = _filterDates(_dateToMax1RM.keys);
    final oneRmWeights =
        oneRmDates.map((d) => _dateToMax1RM[d] ?? 0.0).toList();
    final groupedCount = dates.where((d) => _dateToIsGrouped[d] == true).length;
    final singleCount = dates.where((d) => _dateToIsGrouped[d] != true).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} 통계'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Container(
              decoration: BoxDecoration(
                color: theme.dividerColor.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                tabs: const [
                  Tab(text: '전체 볼륨'),
                  Tab(text: '최고 무게'),
                  Tab(text: '1RM'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Column(
                      children: [
                        _PeriodFilterBar(
                          period: _period,
                          onChanged: (period) =>
                              setState(() => _period = period),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatSummaryCard(
                                title: '기록 일수',
                                value: '${dates.length}일',
                                subtitle: '이 운동 수행일',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatSummaryCard(
                                title: '그룹 수행',
                                value: '$groupedCount회',
                                subtitle: '슈퍼세트/컴파운드 포함',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatSummaryCard(
                                title: '최고 1RM',
                                value: oneRmWeights.isEmpty
                                    ? '-'
                                    : _formatWeight(
                                        oneRmWeights
                                            .reduce((a, b) => a > b ? a : b),
                                      ),
                                subtitle: '추정치',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        _CompareInfoCard(
                          title: '그룹 vs 단일 비교',
                          leftLabel: '그룹',
                          leftValue: '$groupedCount회',
                          rightLabel: '단일',
                          rightValue: '$singleCount회',
                          hint: groupedCount > singleCount
                              ? '이 기간엔 그룹 운동으로 더 자주 수행했어요.'
                              : singleCount > groupedCount
                                  ? '이 기간엔 단일 운동으로 더 자주 수행했어요.'
                                  : '그룹/단일 수행 비중이 비슷해요.',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildChartTab(
                          dates: dates,
                          values: weights,
                          title: '날짜별 총 볼륨',
                          emptyText: '해당 운동의 아직 기록이 없어요.',
                          formatter: _formatWeight,
                          color: AppColors.chartColors[1],
                        ),
                        _buildChartTab(
                          dates: maxDates,
                          values: maxWeights,
                          title: '날짜별 최고 세트 무게',
                          emptyText: '해당 운동의 아직 기록이 없어요.',
                          formatter: _formatWeight,
                          color: AppColors.chartColors[3],
                        ),
                        _buildChartTab(
                          dates: oneRmDates,
                          values: oneRmWeights,
                          title: '날짜별 최대 추정 1RM',
                          emptyText: '해당 운동의 아직 기록이 없어요.',
                          formatter: _formatWeight,
                          color: AppColors.chartColors[4],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChartTab({
    required List<String> dates,
    required List<double> values,
    required String title,
    required String emptyText,
    required String Function(double value) formatter,
    required Color color,
  }) {
    final theme = Theme.of(context);
    if (dates.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: values.length > 1
                            ? (values.reduce((a, b) => a > b ? a : b) / 4)
                                .clamp(1, double.infinity)
                            : 1,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: theme.dividerColor.withValues(alpha: 0.35),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) => SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                value.toStringAsFixed(0),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: dates.length > 6 ? 2 : 1,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= dates.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  dates[idx].substring(5),
                                  style: theme.textTheme.bodySmall,
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: theme.dividerColor.withValues(alpha: 0.6),
                        ),
                      ),
                      minX: 0,
                      maxX: (dates.length - 1).toDouble(),
                      minY: 0,
                      lineBarsData: [
                        LineChartBarData(
                          spots: [
                            for (int i = 0; i < values.length; i++)
                              FlSpot(i.toDouble(), values[i]),
                          ],
                          isCurved: true,
                          color: color,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, ___) =>
                                FlDotCirclePainter(
                              radius: 3.6,
                              color: color,
                              strokeWidth: 2,
                              strokeColor:
                                  theme.cardTheme.color ?? theme.cardColor,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = dates[spot.x.toInt()];
                              final order = _dateToOrder[date];
                              final group = _dateToGroupLabel[date];
                              final lines = [date, formatter(spot.y)];
                              if (order != null) lines.add('(${order}회차)');
                              if (group != null) lines.add(group);
                              return LineTooltipItem(
                                lines.join('\n'),
                                theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ) ??
                                    const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: dates.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                final date = dates[idx];
                final group = _dateToGroupLabel[date];
                final order = _dateToOrder[date];
                final subtitles = <String>[];
                if (order != null) subtitles.add('${order}회차 수행');
                if (group != null) subtitles.add(group);
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              date,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (subtitles.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitles.join(' · '),
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatter(values[idx]),
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

enum _StatisticsPeriod { days7, days30, all }

class _PeriodFilterBar extends StatelessWidget {
  final _StatisticsPeriod period;
  final ValueChanged<_StatisticsPeriod> onChanged;

  const _PeriodFilterBar({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SegmentedButton<_StatisticsPeriod>(
        segments: const [
          ButtonSegment(value: _StatisticsPeriod.days7, label: Text('7일')),
          ButtonSegment(value: _StatisticsPeriod.days30, label: Text('30일')),
          ButtonSegment(value: _StatisticsPeriod.all, label: Text('전체')),
        ],
        selected: {period},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}

class _CompareInfoCard extends StatelessWidget {
  final String title;
  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;
  final String hint;

  const _CompareInfoCard({
    required this.title,
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _CompareMetric(label: leftLabel, value: leftValue)),
              const SizedBox(width: 10),
              Expanded(
                  child: _CompareMetric(label: rightLabel, value: rightValue)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.7),
                ),
          ),
        ],
      ),
    );
  }
}

class _CompareMetric extends StatelessWidget {
  final String label;
  final String value;

  const _CompareMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatSummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.68),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withValues(alpha: 0.68),
                ),
          ),
        ],
      ),
    );
  }
}
