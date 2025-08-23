import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class ExerciseStatisticsScreen extends StatefulWidget {
  final String exerciseName;
  const ExerciseStatisticsScreen({super.key, required this.exerciseName});

  @override
  State<ExerciseStatisticsScreen> createState() => _ExerciseStatisticsScreenState();
}

class _ExerciseStatisticsScreenState extends State<ExerciseStatisticsScreen> with SingleTickerProviderStateMixin {
  Map<String, double> _dateToTotalWeight = {};
  Map<String, double> _dateToMaxWeight = {};
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
    final keys = prefs.getKeys().where((k) => k.startsWith('exercise_sets_${widget.exerciseName}_'));
    final Map<String, double> dateToWeight = {};
    final Map<String, double> dateToMax = {};
    for (final key in keys) {
      final dateStr = key.split('_').last;
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
      if (total > 0) {
        dateToWeight[dateStr] = total;
      }
      if (maxWeight > 0) {
        dateToMax[dateStr] = maxWeight;
      }
    }
    if (!mounted) return;
    setState(() {
      _dateToTotalWeight = dateToWeight;
      _dateToMaxWeight = dateToMax;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dates = _dateToTotalWeight.keys.toList()..sort();
    final weights = dates.map((d) => _dateToTotalWeight[d] ?? 0.0).toList();
    final maxDates = _dateToMaxWeight.keys.toList()..sort();
    final maxWeights = maxDates.map((d) => _dateToMaxWeight[d] ?? 0.0).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.exerciseName} 통계'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.deepPurple,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.deepPurple,
              tabs: const [
                Tab(text: '전체 수행 중량'),
                Tab(text: '최고 세트 무게'),
              ],
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 전체 수행 중량 탭
                _dateToTotalWeight.isEmpty
                    ? const Center(child: Text('해당 운동의 기록이 없습니다.'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('날짜별 총 무게(kg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 240,
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
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                                          return Text(dates[idx].substring(5), style: const TextStyle(fontSize: 10));
                                        },
                                        interval: 1,
                                        reservedSize: 32,
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  minX: 0,
                                  maxX: (dates.length - 1).toDouble(),
                                  minY: 0,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (int i = 0; i < weights.length; i++)
                                          FlSpot(i.toDouble(), weights[i]),
                                      ],
                                      isCurved: false,
                                      color: Colors.deepPurple,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: dates.length,
                                itemBuilder: (context, idx) {
                                  return ListTile(
                                    title: Text('${dates[idx]}'),
                                    trailing: Text('${weights[idx].toStringAsFixed(1)} kg'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                // 최고 세트 무게 탭
                _dateToMaxWeight.isEmpty
                    ? const Center(child: Text('해당 운동의 기록이 없습니다.'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('날짜별 최고 세트 무게(kg)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 240,
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
                                        getTitlesWidget: (value, meta) {
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= maxDates.length) return const SizedBox.shrink();
                                          return Text(maxDates[idx].substring(5), style: const TextStyle(fontSize: 10));
                                        },
                                        interval: 1,
                                        reservedSize: 32,
                                      ),
                                    ),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  ),
                                  borderData: FlBorderData(show: true),
                                  minX: 0,
                                  maxX: (maxDates.length - 1).toDouble(),
                                  minY: 0,
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: [
                                        for (int i = 0; i < maxWeights.length; i++)
                                          FlSpot(i.toDouble(), maxWeights[i]),
                                      ],
                                      isCurved: false,
                                      color: Colors.deepPurple,
                                      barWidth: 3,
                                      dotData: FlDotData(show: true),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: ListView.builder(
                                itemCount: maxDates.length,
                                itemBuilder: (context, idx) {
                                  return ListTile(
                                    title: Text('${maxDates[idx]}'),
                                    trailing: Text('${maxWeights[idx].toStringAsFixed(1)} kg'),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
              ],
            ),
    );
  }
} 