import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseStatisticsScreen extends StatefulWidget {
  final String exerciseName;
  const ExerciseStatisticsScreen({super.key, required this.exerciseName});

  @override
  State<ExerciseStatisticsScreen> createState() => _ExerciseStatisticsScreenState();
}

class _ExerciseStatisticsScreenState extends State<ExerciseStatisticsScreen>
    with SingleTickerProviderStateMixin {
  Map<String, double> _dateToTotalWeight = {};
  Map<String, double> _dateToMaxWeight = {};
  Map<String, int> _dateToOrder = {};
  bool _loading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    final Map<String, double> dateToWeight = {};
    final Map<String, double> dateToMax = {};
    final Map<String, int> dateToOrder = {};

    for (final key in keys) {
      final dateStr = key.split('_').last;
      final workoutsKey = 'workouts_$dateStr';
      final workoutsJson = prefs.getStringList(workoutsKey) ?? [];
      int order = -1;
      for (int i = 0; i < workoutsJson.length; i++) {
        try {
          final workout = jsonDecode(workoutsJson[i]);
          if (workout['name'] == widget.exerciseName) {
            order = i + 1;
            break;
          }
        } catch (_) {}
      }
      if (order != -1) {
        dateToOrder[dateStr] = order;
      }

      final setsJson = prefs.getStringList(key) ?? [];
      double total = 0.0;
      double maxWeight = 0.0;
      for (final jsonStr in setsJson) {
        try {
          final set = jsonDecode(jsonStr);
          final weight = (set['weight'] is int)
              ? (set['weight'] as int).toDouble()
              : (set['weight'] is double)
                  ? set['weight']
                  : double.tryParse(set['weight'].toString()) ?? 0.0;
          final reps = set['reps'] ?? 0;
          total += weight * (reps is int ? reps : int.tryParse(reps.toString()) ?? 0);
          if (weight > maxWeight) maxWeight = weight;
        } catch (_) {}
      }
      if (total > 0) dateToWeight[dateStr] = total;
      if (maxWeight > 0) dateToMax[dateStr] = maxWeight;
    }

    if (!mounted) return;
    setState(() {
      _dateToTotalWeight = dateToWeight;
      _dateToMaxWeight = dateToMax;
      _dateToOrder = dateToOrder;
      _loading = false;
    });
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.exerciseName} 전적판',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            '날짜별 최고 기록과 누적 성장을 한눈에 확인해보세요.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.68),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartTab({
    required BuildContext context,
    required List<String> dates,
    required List<double> values,
    required String title,
    required String unit,
    required Color color,
  }) {
    if (dates.isEmpty) {
      return const Center(child: Text('해당 운동의 아직 기록이 없어요.'));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeaderCard(context),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 240,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: values.isEmpty ? 1 : (values.reduce((a, b) => a > b ? a : b) / 4).clamp(1, double.infinity),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.white.withValues(alpha: 0.08),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
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
                            interval: 1,
                            reservedSize: 32,
                          ),
                        ),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
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
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: color.withValues(alpha: 0.16),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.black87,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date = dates[spot.x.toInt()];
                              final order = _dateToOrder[date];
                              return LineTooltipItem(
                                '$date\n${spot.y.toStringAsFixed(1)} $unit${order != null ? '\n(${order}회차)' : ''}',
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
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: dates.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, idx) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.bolt_rounded, size: 18, color: color),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(dates[idx], style: const TextStyle(fontWeight: FontWeight.w700)),
                            if (_dateToOrder[dates[idx]] != null)
                              Text('${_dateToOrder[dates[idx]]}회차 클리어', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                          ],
                        ),
                      ),
                      Text('${values[idx].toStringAsFixed(1)} $unit'),
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

  @override
  Widget build(BuildContext context) {
    final dates = _dateToTotalWeight.keys.toList()..sort();
    final weights = dates.map((d) => _dateToTotalWeight[d] ?? 0.0).toList();
    final maxDates = _dateToMaxWeight.keys.toList()..sort();
    final maxWeights = maxDates.map((d) => _dateToMaxWeight[d] ?? 0.0).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} 전적'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
                  ),
                ),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '누적 중량'),
                  Tab(text: '최고 세트'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildChartTab(
                  context: context,
                  dates: dates,
                  values: weights,
                  title: '누적 중량 그래프',
                  unit: 'kg',
                  color: const Color(0xFF4BC2FF),
                ),
                _buildChartTab(
                  context: context,
                  dates: maxDates,
                  values: maxWeights,
                  title: '최고 세트 그래프',
                  unit: 'kg',
                  color: const Color(0xFF74F0B2),
                ),
              ],
            ),
    );
  }
}
