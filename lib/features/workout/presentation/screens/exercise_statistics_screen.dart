import 'dart:convert';

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
  bool _loading = true;
  late TabController _tabController;

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
      _loading = false;
    });
  }

  String _formatWeight(double value) => '${value.toStringAsFixed(1)} kg';

  @override
  Widget build(BuildContext context) {
    final dates = _dateToTotalWeight.keys.toList()..sort();
    final weights = dates.map((d) => _dateToTotalWeight[d] ?? 0.0).toList();
    final maxDates = _dateToMaxWeight.keys.toList()..sort();
    final maxWeights = maxDates.map((d) => _dateToMaxWeight[d] ?? 0.0).toList();
    final oneRmDates = _dateToMax1RM.keys.toList()..sort();
    final oneRmWeights =
        oneRmDates.map((d) => _dateToMax1RM[d] ?? 0.0).toList();
    final groupedCount = _dateToGroupLabel.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} 통계'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '전체 볼륨'),
            Tab(text: '최고 무게'),
            Tab(text: '1RM'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
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
                                  oneRmWeights.reduce((a, b) => a > b ? a : b),
                                ),
                          subtitle: '추정치',
                        ),
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
                        color: Colors.deepPurple,
                      ),
                      _buildChartTab(
                        dates: maxDates,
                        values: maxWeights,
                        title: '날짜별 최고 세트 무게',
                        emptyText: '해당 운동의 아직 기록이 없어요.',
                        formatter: _formatWeight,
                        color: Colors.teal,
                      ),
                      _buildChartTab(
                        dates: oneRmDates,
                        values: oneRmWeights,
                        title: '날짜별 최대 추정 1RM',
                        emptyText: '해당 운동의 아직 기록이 없어요.',
                        formatter: _formatWeight,
                        color: Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
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
    if (dates.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          dates[idx].substring(5),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: true),
                minX: 0,
                maxX: (dates.length - 1).toDouble(),
                minY: 0,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < values.length; i++)
                        FlSpot(i.toDouble(), values[i]),
                    ],
                    isCurved: false,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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
                          const TextStyle(color: Colors.white),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: dates.length,
              itemBuilder: (context, idx) {
                final date = dates[idx];
                final group = _dateToGroupLabel[date];
                final order = _dateToOrder[date];
                final subtitles = <String>[];
                if (order != null) subtitles.add('${order}회차 수행');
                if (group != null) subtitles.add(group);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(date),
                  subtitle:
                      subtitles.isEmpty ? null : Text(subtitles.join(' · ')),
                  trailing: Text(formatter(values[idx])),
                );
              },
            ),
          ),
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
