import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExerciseStatisticsPopup extends StatefulWidget {
  final String exerciseName;
  const ExerciseStatisticsPopup({super.key, required this.exerciseName});

  @override
  State<ExerciseStatisticsPopup> createState() => _ExerciseStatisticsPopupState();
}

class _ExerciseStatisticsPopupState extends State<ExerciseStatisticsPopup> {
  Map<String, double> _dateToTotalWeight = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('exercise_sets_${widget.exerciseName}_'));
    final Map<String, double> dateToWeight = {};
    for (final key in keys) {
      final dateStr = key.split('_').last;
      final setsJson = prefs.getStringList(key) ?? [];
      double total = 0.0;
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
        } catch (_) {}
      }
      if (total > 0) {
        dateToWeight[dateStr] = total;
      }
    }
    if (!mounted) return;
    setState(() {
      _dateToTotalWeight = dateToWeight;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Sort dates
    final dates = _dateToTotalWeight.keys.toList()..sort();
    // Get last 7 records for better visibility in popup, or all if less than 7
    final displayDates = dates.length > 7 ? dates.sublist(dates.length - 7) : dates;
    final weights = displayDates.map((d) => _dateToTotalWeight[d] ?? 0.0).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Match app theme approx
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.exerciseName} 볼륨 추이',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : displayDates.isEmpty
                      ? const Center(child: Text('기록이 없습니다.', style: TextStyle(color: Colors.grey)))
                      : LineChart(
                          LineChartData(
                            gridData: FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx < 0 || idx >= displayDates.length) return const SizedBox.shrink();
                                    // Show date like '1/8'
                                    try {
                                      final date = DateTime.parse(displayDates[idx]);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Text(
                                          '${date.month}/${date.day}',
                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                        ),
                                      );
                                    } catch (_) {
                                      return const SizedBox.shrink();
                                    }
                                  },
                                  interval: 1,
                                  reservedSize: 24,
                                ),
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            minX: 0,
                            maxX: (displayDates.length - 1).toDouble(),
                            minY: 0,
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < weights.length; i++)
                                    FlSpot(i.toDouble(), weights[i]),
                                ],
                                isCurved: true,
                                color:Colors.deepPurpleAccent,
                                barWidth: 3,
                                dotData: FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: Colors.deepPurpleAccent.withOpacity(0.2),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                tooltipBgColor: Colors.black87,
                                getTooltipItems: (touchedSpots) {
                                  return touchedSpots.map((spot) {
                                    return LineTooltipItem(
                                      '${spot.y.toStringAsFixed(0)} kg',
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
            const Text(
              '최근 7회 기록',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
