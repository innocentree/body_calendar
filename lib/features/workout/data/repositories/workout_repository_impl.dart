import 'package:body_calendar/features/workout/domain/models/workout.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class WorkoutRepositoryImpl implements WorkoutRepository {
  final SharedPreferences _prefs;
  static const String _workoutsKey = 'workouts';

  WorkoutRepositoryImpl(this._prefs);

  @override
  Future<List<Workout>> getWorkouts() async {
    final workoutsJson = _prefs.getStringList(_workoutsKey) ?? [];
    return workoutsJson
        .map((json) => Workout.fromJson(jsonDecode(json)))
        .toList();
  }

  @override
  Future<void> addWorkout(Workout workout) async {
    final workouts = await getWorkouts();
    workouts.add(workout);
    await _saveWorkouts(workouts);
  }

  @override
  Future<void> updateWorkout(Workout workout) async {
    final workouts = await getWorkouts();
    final index = workouts.indexWhere((w) => w.id == workout.id);
    if (index != -1) {
      workouts[index] = workout;
      await _saveWorkouts(workouts);
    }
  }

  @override
  Future<void> deleteWorkout(String id) async {
    final workouts = await getWorkouts();
    workouts.removeWhere((workout) => workout.id == id);
    await _saveWorkouts(workouts);
  }

  Future<void> _saveWorkouts(List<Workout> workouts) async {
    final workoutsJson = workouts
        .map((workout) => jsonEncode(workout.toJson()))
        .toList();
    await _prefs.setStringList(_workoutsKey, workoutsJson);
  }
} 