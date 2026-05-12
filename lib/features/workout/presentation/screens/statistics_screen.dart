import 'dart:convert';

import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'exercise_statistics_screen.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<String> _exerciseNames = [];

  @override
  void initState() {
    super.initState();
    _loadExerciseNames();
  }

  Future<void> _loadExerciseNames() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workouts_'));
    final Set<String> names = {};
    for (final key in keys) {
      final workoutsJson = prefs.getStringList(key) ?? [];
      for (final jsonStr in workoutsJson) {
        try {
          final workout = jsonDecode(jsonStr);
          if (workout['name'] != null) {
            names.add(workout['name']);
          }
        } catch (_) {}
      }
    }
    setState(() {
      _exerciseNames = names.toList()..sort();
    });
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
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '전적 보드',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '종목별 로그와 성장 흐름을 전적판처럼 살펴볼 수 있어요.',
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
                    ),
                    const SizedBox(height: 16),
                    ..._exerciseNames.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: Theme.of(context).cardTheme.color,
                            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                            elevation: 0,
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            side: BorderSide(color: Theme.of(context).dividerColor),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ExerciseStatisticsScreen(exerciseName: name),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.sports_martial_arts_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
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
