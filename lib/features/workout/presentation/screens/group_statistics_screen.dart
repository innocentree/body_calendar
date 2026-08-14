import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupStatisticsScreen extends StatefulWidget {
  final String groupSignature;
  final String title;
  final List<String> exerciseNames;

  const GroupStatisticsScreen({
    super.key,
    required this.groupSignature,
    required this.title,
    required this.exerciseNames,
  });

  @override
  State<GroupStatisticsScreen> createState() => _GroupStatisticsScreenState();
}

class _GroupStatisticsScreenState extends State<GroupStatisticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, int> _dateToCompletedRounds = {};
  Map<String, double> _dateToVolume = {};
  Map<String, double> _dateToMax1RM = {};
  Map<String, int> _dateToDurationSeconds = {};
  Map<String, int> _dateToSessionIndex = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutKeys = prefs.getKeys().where((k) => k.startsWith('workouts_'));

    final dateToRounds = <String, int>{};
    final dateToVolume = <String, double>{};
    final dateTo1RM = <String, double>{};
    final dateToDuration = <String, int>{};
    final dateToSession = <String, int>{};

    for (final key in workoutKeys) {
      final dateStr = key.replaceFirst('workouts_', '');
      final workoutsJson = prefs.getStringList(key) ?? [];
      final decoded = <Map<String, dynamic>>[];
      for (final item in workoutsJson) {
        try {
          decoded.add(Map<String, dynamic>.from(jsonDecode(item)));
        } catch (_) {}
      }

      final grouped = <String, List<Map<String, dynamic>>>{};
      for (final workout in decoded) {
        final groupId = workout['groupId']?.toString();
        if (groupId == null || groupId.isEmpty) continue;
        grouped.putIfAbsent(groupId, () => []).add(workout);
      }

      for (final entry in grouped.entries) {
        final workouts = entry.value
          ..sort((a, b) => ((a['groupOrder'] ?? 0) as int)
              .compareTo((b['groupOrder'] ?? 0) as int));
        final signature = _buildSignature(workouts);
        if (signature != widget.groupSignature) continue;

        var completedRounds = -1;
        var totalVolume = 0.0;
        var max1RM = 0.0;
        var totalDuration = 0;
        final sessionIndex =
            ((workouts.first['sessionIndex'] ?? 1) as num).toInt();

        for (final workout in workouts) {
          final name = workout['name']?.toString();
          if (name == null || name.isEmpty) continue;
          final setsKey = 'exercise_sets_${name}_$dateStr';
          final setsJson = prefs.getStringList(setsKey) ?? [];
          final completedForExercise = <int>{};
          for (var i = 0; i < setsJson.length; i++) {
            try {
              final set = Map<String, dynamic>.from(jsonDecode(setsJson[i]));
              if (set['isCompleted'] == true) {
                completedForExercise.add(i);
                final weight = (set['weight'] is int)
                    ? (set['weight'] as int).toDouble()
                    : (set['weight'] is double)
                        ? set['weight'] as double
                        : double.tryParse(set['weight'].toString()) ?? 0.0;
                final reps = (set['reps'] is int)
                    ? set['reps'] as int
                    : int.tryParse(set['reps'].toString()) ?? 0;
                totalVolume += weight * reps;
                final oneRM = weight * (1 + reps / 30.0);
                if (oneRM > max1RM) max1RM = oneRM;
                final startTime =
                    DateTime.tryParse(set['startTime']?.toString() ?? '');
                final endTime =
                    DateTime.tryParse(set['endTime']?.toString() ?? '');
                if (startTime != null && endTime != null) {
                  totalDuration += endTime.difference(startTime).inSeconds;
                } else {
                  totalDuration += ((set['restTime'] ?? 0) as num).toInt();
                }
              }
            } catch (_) {}
          }
          if (completedRounds == -1) {
            completedRounds = completedForExercise.length;
          } else {
            completedRounds = completedForExercise.length < completedRounds
                ? completedForExercise.length
                : completedRounds;
          }
        }

        dateToRounds[dateStr] = completedRounds < 0 ? 0 : completedRounds;
        dateToVolume[dateStr] = totalVolume;
        if (max1RM > 0) dateTo1RM[dateStr] = max1RM;
        dateToDuration[dateStr] = totalDuration;
        dateToSession[dateStr] = sessionIndex;
      }
    }

    if (!mounted) return;
    setState(() {
      _dateToCompletedRounds = dateToRounds;
      _dateToVolume = dateToVolume;
      _dateToMax1RM = dateTo1RM;
      _dateToDurationSeconds = dateToDuration;
      _dateToSessionIndex = dateToSession;
      _loading = false;
    });
  }

  static String _buildSignature(List<Map<String, dynamic>> workouts) {
    final sorted = [...workouts]..sort((a, b) => ((a['groupOrder'] ?? 0) as int)
        .compareTo((b['groupOrder'] ?? 0) as int));
    final type = sorted.first['groupType']?.toString() ?? 'group';
    final names = sorted.map((w) => w['name']?.toString() ?? '').join('::');
    return '$type::$names';
  }

  String _formatWeight(double value) => '${value.toStringAsFixed(1)} kg';
  String _formatRounds(int value) => '$value라운드';
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remain = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remain.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final roundDates = _dateToCompletedRounds.keys.toList()..sort();
    final roundValues =
        roundDates.map((d) => _dateToCompletedRounds[d] ?? 0).toList();
    final volumeDates = _dateToVolume.keys.toList()..sort();
    final volumeValues =
        volumeDates.map((d) => _dateToVolume[d] ?? 0.0).toList();
    final oneRmDates = _dateToMax1RM.keys.toList()..sort();
    final oneRmValues = oneRmDates.map((d) => _dateToMax1RM[d] ?? 0.0).toList();
    final durationDates = _dateToDurationSeconds.keys.toList()..sort();
    final durationValues =
        durationDates.map((d) => _dateToDurationSeconds[d] ?? 0).toList();

    final bestRound =
        roundValues.isEmpty ? 0 : roundValues.reduce((a, b) => a > b ? a : b);
    final best1RM =
        oneRmValues.isEmpty ? 0.0 : oneRmValues.reduce((a, b) => a > b ? a : b);
    final longestDuration = durationValues.isEmpty
        ? 0
        : durationValues.reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '완료 라운드'),
            Tab(text: '총 볼륨'),
            Tab(text: '1RM'),
            Tab(text: '수행 시간'),
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
                          title: '최고 라운드',
                          value: _formatRounds(bestRound),
                          subtitle: '하루 최고 기록',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatSummaryCard(
                          title: '최고 1RM',
                          value: best1RM == 0 ? '-' : _formatWeight(best1RM),
                          subtitle: '그룹 내 최고 세트 기준',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _StatSummaryCard(
                          title: '최장 수행',
                          value: _formatDuration(longestDuration),
                          subtitle: '완료 세트 합산',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildChartTab<int>(
                        dates: roundDates,
                        values: roundValues,
                        title: '날짜별 완료 라운드',
                        emptyText: '이 그룹의 기록이 아직 없어요.',
                        formatter: _formatRounds,
                        yValue: (value) => value.toDouble(),
                        color: Colors.deepPurple,
                      ),
                      _buildChartTab<double>(
                        dates: volumeDates,
                        values: volumeValues,
                        title: '날짜별 총 볼륨',
                        emptyText: '이 그룹의 기록이 아직 없어요.',
                        formatter: _formatWeight,
                        yValue: (value) => value,
                        color: Colors.orange,
                      ),
                      _buildChartTab<double>(
                        dates: oneRmDates,
                        values: oneRmValues,
                        title: '날짜별 최대 추정 1RM',
                        emptyText: '이 그룹의 기록이 아직 없어요.',
                        formatter: _formatWeight,
                        yValue: (value) => value,
                        color: Colors.teal,
                      ),
                      _buildChartTab<int>(
                        dates: durationDates,
                        values: durationValues,
                        title: '날짜별 수행 시간',
                        emptyText: '이 그룹의 기록이 아직 없어요.',
                        formatter: _formatDuration,
                        yValue: (value) => value.toDouble(),
                        color: Colors.redAccent,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChartTab<T>({
    required List<String> dates,
    required List<T> values,
    required String title,
    required String emptyText,
    required String Function(T value) formatter,
    required double Function(T value) yValue,
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
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                        final index = value.toInt();
                        if (index < 0 || index >= dates.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          dates[index].substring(5),
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
                        FlSpot(i.toDouble(), yValue(values[i])),
                    ],
                    isCurved: false,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (spots) {
                      return spots.map((spot) {
                        final date = dates[spot.x.toInt()];
                        final session = _dateToSessionIndex[date];
                        return LineTooltipItem(
                          '$date\n${formatter(values[spot.x.toInt()])}${session != null ? '\n(${session}회차)' : ''}',
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
              itemBuilder: (context, index) {
                final date = dates[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(date),
                  subtitle: _dateToSessionIndex[date] != null
                      ? Text('${_dateToSessionIndex[date]}회차 수행')
                      : null,
                  trailing: Text(formatter(values[index])),
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
