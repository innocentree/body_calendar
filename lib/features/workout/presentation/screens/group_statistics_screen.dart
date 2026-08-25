import 'dart:convert';

import 'package:body_calendar/core/theme/app_colors.dart';
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
  Map<String, bool> _dateToComparedSingleWin = {};
  _StatisticsPeriod _period = _StatisticsPeriod.all;

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
    final dateToComparedSingleWin = <String, bool>{};

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

        double singleVolume = 0.0;
        for (final workout in decoded) {
          final otherGroupId = workout['groupId']?.toString();
          final sameName =
              widget.exerciseNames.contains(workout['name']?.toString() ?? '');
          if (sameName && (otherGroupId == null || otherGroupId.isEmpty)) {
            final name = workout['name']?.toString();
            if (name == null || name.isEmpty) continue;
            final setsKey = 'exercise_sets_${name}_$dateStr';
            final setsJson = prefs.getStringList(setsKey) ?? [];
            for (final raw in setsJson) {
              try {
                final set = Map<String, dynamic>.from(jsonDecode(raw));
                if (set['isCompleted'] == true) {
                  final weight = (set['weight'] is int)
                      ? (set['weight'] as int).toDouble()
                      : (set['weight'] is double)
                          ? set['weight'] as double
                          : double.tryParse(set['weight'].toString()) ?? 0.0;
                  final reps = (set['reps'] is int)
                      ? set['reps'] as int
                      : int.tryParse(set['reps'].toString()) ?? 0;
                  singleVolume += weight * reps;
                }
              } catch (_) {}
            }
          }
        }
        dateToComparedSingleWin[dateStr] = totalVolume >= singleVolume;
      }
    }

    if (!mounted) return;
    setState(() {
      _dateToCompletedRounds = dateToRounds;
      _dateToVolume = dateToVolume;
      _dateToMax1RM = dateTo1RM;
      _dateToDurationSeconds = dateToDuration;
      _dateToSessionIndex = dateToSession;
      _dateToComparedSingleWin = dateToComparedSingleWin;
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
    final roundDates = _filterDates(_dateToCompletedRounds.keys);
    final roundValues =
        roundDates.map((d) => _dateToCompletedRounds[d] ?? 0).toList();
    final volumeDates = _filterDates(_dateToVolume.keys);
    final volumeValues =
        volumeDates.map((d) => _dateToVolume[d] ?? 0.0).toList();
    final oneRmDates = _filterDates(_dateToMax1RM.keys);
    final oneRmValues = oneRmDates.map((d) => _dateToMax1RM[d] ?? 0.0).toList();
    final durationDates = _filterDates(_dateToDurationSeconds.keys);
    final durationValues =
        durationDates.map((d) => _dateToDurationSeconds[d] ?? 0).toList();

    final bestRound =
        roundValues.isEmpty ? 0 : roundValues.reduce((a, b) => a > b ? a : b);
    final best1RM =
        oneRmValues.isEmpty ? 0.0 : oneRmValues.reduce((a, b) => a > b ? a : b);
    final longestDuration = durationValues.isEmpty
        ? 0
        : durationValues.reduce((a, b) => a > b ? a : b);
    final compareWins =
        roundDates.where((d) => _dateToComparedSingleWin[d] == true).length;
    final compareLosses =
        roundDates.where((d) => _dateToComparedSingleWin[d] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
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
                isScrollable: true,
                indicator: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                tabs: const [
                  Tab(text: '완료 라운드'),
                  Tab(text: '총 볼륨'),
                  Tab(text: '1RM'),
                  Tab(text: '수행 시간'),
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
                                title: '최고 라운드',
                                value: _formatRounds(bestRound),
                                subtitle: '하루 최고 기록',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _StatSummaryCard(
                                title: '최고 1RM',
                                value:
                                    best1RM == 0 ? '-' : _formatWeight(best1RM),
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
                        const SizedBox(height: 10),
                        _CompareInfoCard(
                          title: '그룹 vs 단일 볼륨 비교',
                          leftLabel: '그룹 우세',
                          leftValue: '$compareWins일',
                          rightLabel: '단일 우세',
                          rightValue: '$compareLosses일',
                          hint: compareWins > compareLosses
                              ? '같은 운동 조합 기준으로 그룹 수행 볼륨이 더 높은 날이 많아요.'
                              : compareLosses > compareWins
                                  ? '단일 수행 볼륨이 더 높은 날이 많아요.'
                                  : '그룹/단일 볼륨 우세가 비슷해요.',
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
                          color: AppColors.chartColors[1],
                        ),
                        _buildChartTab<double>(
                          dates: volumeDates,
                          values: volumeValues,
                          title: '날짜별 총 볼륨',
                          emptyText: '이 그룹의 기록이 아직 없어요.',
                          formatter: _formatWeight,
                          yValue: (value) => value,
                          color: AppColors.chartColors[4],
                        ),
                        _buildChartTab<double>(
                          dates: oneRmDates,
                          values: oneRmValues,
                          title: '날짜별 최대 추정 1RM',
                          emptyText: '이 그룹의 기록이 아직 없어요.',
                          formatter: _formatWeight,
                          yValue: (value) => value,
                          color: AppColors.chartColors[3],
                        ),
                        _buildChartTab<int>(
                          dates: durationDates,
                          values: durationValues,
                          title: '날짜별 수행 시간',
                          emptyText: '이 그룹의 기록이 아직 없어요.',
                          formatter: _formatDuration,
                          yValue: (value) => value.toDouble(),
                          color: AppColors.chartColors[0],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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

    final maxY = values
        .map(yValue)
        .fold<double>(0, (prev, value) => value > prev ? value : prev);

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
                        horizontalInterval: maxY <= 0
                            ? 1
                            : (maxY / 4).clamp(1, double.infinity),
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
                              final index = value.toInt();
                              if (index < 0 || index >= dates.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  dates[index].substring(5),
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
                              FlSpot(i.toDouble(), yValue(values[i])),
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
                          getTooltipItems: (spots) {
                            return spots.map((spot) {
                              final date = dates[spot.x.toInt()];
                              final session = _dateToSessionIndex[date];
                              return LineTooltipItem(
                                '$date\n${formatter(values[spot.x.toInt()])}${session != null ? '\n(${session}회차)' : ''}',
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
              itemBuilder: (context, index) {
                final date = dates[index];
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
                            if (_dateToSessionIndex[date] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${_dateToSessionIndex[date]}회차 수행',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatter(values[index]),
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
