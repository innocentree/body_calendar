import 'dart:convert';

import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_statistics_screen.dart';
import 'group_statistics_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<String> _exerciseNames = [];
  List<_GroupStatEntry> _groupEntries = [];

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
  }

  Future<void> _loadExerciseNames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workouts_'));
    final Set<String> names = {};
    final Map<String, _GroupStatEntry> groups = {};
    for (final key in keys) {
      final workoutsJson = prefs.getStringList(key) ?? [];
      final Map<String, List<Map<String, dynamic>>> groupedWorkouts = {};
      for (final jsonStr in workoutsJson) {
        try {
          final workout = jsonDecode(jsonStr);
          if (workout['name'] != null) {
            names.add(workout['name']);
          }
          final groupId = workout['groupId']?.toString();
          if (groupId != null && groupId.isNotEmpty) {
            groupedWorkouts.putIfAbsent(groupId, () => []).add(
                  Map<String, dynamic>.from(workout as Map),
                );
          }
        } catch (_) {}
      }

      for (final workouts in groupedWorkouts.values) {
        workouts.sort((a, b) => ((a['groupOrder'] ?? 0) as int)
            .compareTo((b['groupOrder'] ?? 0) as int));
        final signature = _buildGroupSignature(workouts);
        groups.putIfAbsent(
          signature,
          () => _GroupStatEntry(
            signature: signature,
            title: _buildGroupTitle(workouts),
            exerciseNames: workouts
                .map((workout) => workout['name']?.toString() ?? '')
                .where((name) => name.isNotEmpty)
                .toList(),
          ),
        );
      }
    }
    setState(() {
      _exerciseNames = names.toList()..sort();
      _groupEntries = groups.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
    });
  }

  String _buildGroupSignature(List<Map<String, dynamic>> workouts) {
    final type = workouts.first['groupType']?.toString() ?? 'group';
    final names =
        workouts.map((workout) => workout['name']?.toString() ?? '').join('::');
    return '$type::$names';
  }

  String _buildGroupTitle(List<Map<String, dynamic>> workouts) {
    final type = workouts.first['groupType']?.toString();
    final label = switch (type) {
      'superset' => '슈퍼세트',
      'compound' => '컴파운드 세트',
      _ => '그룹',
    };
    final names = workouts
        .map((workout) => workout['name']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .join(' · ');
    return '$label · $names';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('운동 통계'),
          ),
          body: _exerciseNames.isEmpty
              ? const Center(child: Text('기록된 운동 종목이 아직 없어요.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(24),
                        border:
                            Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '운동 통계',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '운동별 기록 흐름을 한눈에 살펴볼 수 있어요.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color
                                      ?.withValues(alpha: 0.68),
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_groupEntries.isNotEmpty) ...[
                      Text(
                        '그룹 운동 통계',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      ..._groupEntries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(60),
                              backgroundColor:
                                  Theme.of(context).cardTheme.color,
                              foregroundColor:
                                  Theme.of(context).textTheme.bodyLarge?.color,
                              elevation: 0,
                              alignment: Alignment.centerLeft,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              side: BorderSide(
                                  color: Theme.of(context).dividerColor),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GroupStatisticsScreen(
                                    groupSignature: entry.signature,
                                    title: entry.title,
                                    exerciseNames: entry.exerciseNames,
                                  ),
                                ),
                              );
                            },
                            child: Text(entry.title,
                                style: const TextStyle(fontSize: 16)),
                          ),
                        );
                      }),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      '개별 운동 통계',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    ..._exerciseNames.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: Theme.of(context).cardTheme.color,
                            foregroundColor:
                                Theme.of(context).textTheme.bodyLarge?.color,
                            elevation: 0,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            side: BorderSide(
                                color: Theme.of(context).dividerColor),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ExerciseStatisticsScreen(
                                    exerciseName: name),
                              ),
                            );
                          },
                          child:
                              Text(name, style: const TextStyle(fontSize: 16)),
                        ),
                      );
                    }),
                  ],
                ),
        ),
        const RestFabOverlay(),
      ],
    );
  }
}

class _GroupStatEntry {
  final String signature;
  final String title;
  final List<String> exerciseNames;

  const _GroupStatEntry({
    required this.signature,
    required this.title,
    required this.exerciseNames,
  });
}
