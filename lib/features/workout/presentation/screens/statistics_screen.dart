import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'exercise_statistics_screen.dart';
import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';

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
              ? const Center(child: Text('운동 기록이 있는 종목이 없습니다.'))
              : ListView.builder(
                  itemCount: _exerciseNames.length,
                  itemBuilder: (context, idx) {
                    final name = _exerciseNames[idx];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExerciseStatisticsScreen(exerciseName: name),
                            ),
                          );
                        },
                        child: Text(name, style: const TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                ),
        ),
        RestFabOverlay(),
      ],
    );
  }
} 