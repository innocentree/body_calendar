import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/ios_widgets.dart';

enum ExerciseStatisticType {
  volume,
  maxWeight,
  oneRM,
  maxReps,
  totalReps,
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
  State<ExerciseStatisticsPopup> createState() =>
      _ExerciseStatisticsPopupState();
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
    final keys = prefs
        .getKeys()
        .where((k) => k.startsWith('exercise_sets_${widget.exerciseName}_'));
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
      } else if (widget.type == ExerciseStatisticType.maxReps) {
        int maxReps = 0;
        for (final jsonStr in setsJson) {
          final set = _parseSet(jsonStr);
          if (set != null && set.reps > maxReps) {
            maxReps = set.reps;
          }
        }
        dailyValue = maxReps.toDouble();
      } else if (widget.type == ExerciseStatisticType.totalReps) {
        int totalReps = 0;
        for (final jsonStr in setsJson) {
          final set = _parseSet(jsonStr);
          if (set != null) {
            totalReps += set.reps;
          }
        }
        dailyValue = totalReps.toDouble();
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
      case ExerciseStatisticType.volume:
        return '${widget.exerciseName} 볼륨 추이';
      case ExerciseStatisticType.maxWeight:
        return '${widget.exerciseName} 최대 무게 추이';
      case ExerciseStatisticType.oneRM:
        return '${widget.exerciseName} 1RM 추이';
      case ExerciseStatisticType.maxReps:
        return '${widget.exerciseName} 최대 횟수 추이';
      case ExerciseStatisticType.totalReps:
        return '${widget.exerciseName} 총 횟수 추이';
    }
  }

  String get _valueUnit {
    switch (widget.type) {
      case ExerciseStatisticType.maxReps:
      case ExerciseStatisticType.totalReps:
        return '회';
      case ExerciseStatisticType.volume:
      case ExerciseStatisticType.maxWeight:
      case ExerciseStatisticType.oneRM:
        return 'kg';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort dates
    final dates = _dateToValue.keys.toList()..sort();
    // Get last 7 records for better visibility in popup, or all if less than 7
    final displayDates =
        dates.length > 7 ? dates.sublist(dates.length - 7) : dates;
    final values = displayDates.map((d) => _dateToValue[d] ?? 0.0).toList();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: context.appGroupedSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: const IosModalHandle(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
                  decoration: BoxDecoration(
                    color: context.appElevatedSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : displayDates.isEmpty
                          ? Center(
                              child: Text(
                                '아직 기록이 없어요.',
                                style:
                                    TextStyle(color: context.appSecondaryText),
                              ),
                            )
                          : LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  topTitles: AxisTitles(
                                      sideTitles:
                                          SideTitles(showTitles: false)),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        final idx = value.toInt();
                                        if (idx < 0 ||
                                            idx >= displayDates.length) {
                                          return const SizedBox.shrink();
                                        }
                                        // Show date like '1/8'
                                        try {
                                          final date =
                                              DateTime.parse(displayDates[idx]);
                                          return Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '${date.month}/${date.day}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall
                                                    ?.color,
                                              ),
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
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    barWidth: 3,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(
                                      show: true,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.18),
                                    ),
                                  ),
                                ],
                                lineTouchData: LineTouchData(
                                  touchTooltipData: LineTouchTooltipData(
                                    tooltipBgColor:
                                        Theme.of(context).cardTheme.color ??
                                            AppColors.customSurface,
                                    getTooltipItems: (touchedSpots) {
                                      return touchedSpots.map((spot) {
                                        return LineTooltipItem(
                                          widget.type ==
                                                      ExerciseStatisticType
                                                          .totalReps ||
                                                  widget.type ==
                                                      ExerciseStatisticType
                                                          .maxReps
                                              ? '${spot.y.toInt()} $_valueUnit'
                                              : '${spot.y.toStringAsFixed(1)} $_valueUnit',
                                          TextStyle(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.color,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        );
                                      }).toList();
                                    },
                                  ),
                                ),
                              ),
                            ),
                ),
                const SizedBox(height: 14),
                Text(
                  '최근 7회 기록',
                  style: TextStyle(
                    color: context.appSecondaryText,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
