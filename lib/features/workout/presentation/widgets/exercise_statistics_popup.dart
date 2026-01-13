import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

enum ExerciseStatisticType {
  volume,
  maxWeight,
  oneRM,
}

class ExerciseStatisticsPopup extends StatefulWidget {
  final String exerciseName;
  final ExerciseStatisticType type;
  
  const ExerciseStatisticsPopup({
    super.key, 
    required this.exerciseName,
    this.type = ExerciseStatisticType.volume,
  });

  @override
  State<ExerciseStatisticsPopup> createState() => _ExerciseStatisticsPopupState();
}

class _ExerciseStatisticsPopupState extends State<ExerciseStatisticsPopup> {
  Map<String, double> _dateToValue = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('exercise_sets_${widget.exerciseName}_'));
    final Map<String, double> dateToValue = {};
    
    for (final key in keys) {
      final dateStr = key.split('_').last;
      final setsJson = prefs.getStringList(key) ?? [];
      double dailyValue = 0.0;
      
      // Calculate based on type
      if (widget.type == ExerciseStatisticType.volume) {
        double totalVolume = 0.0;
        for (final jsonStr in setsJson) {
           final set = _parseSet(jsonStr);
           if (set != null) {
              totalVolume += set.weight * set.reps;
           }
        }
        dailyValue = totalVolume;
      } else if (widget.type == ExerciseStatisticType.maxWeight) {
        double maxWeight = 0.0;
        for (final jsonStr in setsJson) {
           final set = _parseSet(jsonStr);
           if (set != null) {
              if (set.weight > maxWeight) maxWeight = set.weight;
           }
        }
        dailyValue = maxWeight;
      } else if (widget.type == ExerciseStatisticType.oneRM) {
        double max1RM = 0.0;
        for (final jsonStr in setsJson) {
           final set = _parseSet(jsonStr);
           if (set != null) {
              final oneRM = set.weight * (1 + set.reps / 30.0);
              if (oneRM > max1RM) max1RM = oneRM;
           }
        }
        dailyValue = max1RM;
      }

      if (dailyValue > 0) {
        dateToValue[dateStr] = dailyValue;
      }
    }
    
    if (!mounted) return;
    setState(() {
      _dateToValue = dateToValue;
      _loading = false;
    });
  }

  _SimpleSet? _parseSet(String jsonStr) {
    try {
      final set = jsonDecode(jsonStr);
      final weight = (set['weight'] is int)
          ? (set['weight'] as int).toDouble()
          : (set['weight'] is double)
              ? set['weight']
              : double.tryParse(set['weight'].toString()) ?? 0.0;
      final reps = set['reps'] ?? 0;
      final repsInt = (reps is int ? reps : int.tryParse(reps.toString()) ?? 0);
      return _SimpleSet(weight, repsInt);
    } catch (_) {
      return null;
    }
  }

  String get _title {
    switch (widget.type) {
      case ExerciseStatisticType.volume: return '${widget.exerciseName} 볼륨 추이';
      case ExerciseStatisticType.maxWeight: return '${widget.exerciseName} 최대 무게 추이';
      case ExerciseStatisticType.oneRM: return '${widget.exerciseName} 1RM 추이';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort dates
    final dates = _dateToValue.keys.toList()..sort();
    // Get last 7 records for better visibility in popup, or all if less than 7
    final displayDates = dates.length > 7 ? dates.sublist(dates.length - 7) : dates;
    final values = displayDates.map((d) => _dateToValue[d] ?? 0.0).toList();

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
              _title,
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
                            // Ensure Y axis starts at 0 or appropriate min for better visualization
                            // minY: (values.reduce(min) * 0.8), // Custom min if needed
                            lineBarsData: [
                              LineChartBarData(
                                spots: [
                                  for (int i = 0; i < values.length; i++)
                                    FlSpot(i.toDouble(), values[i]),
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
                                      '${spot.y.toStringAsFixed(1)} kg',
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

class _SimpleSet {
  final double weight;
  final int reps;
  _SimpleSet(this.weight, this.reps);
}
