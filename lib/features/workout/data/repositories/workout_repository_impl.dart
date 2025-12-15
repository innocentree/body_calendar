import 'dart:convert';
import 'dart:io';

import 'package:body_calendar/features/workout/domain/models/workout.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final workoutsJson =
        workouts.map((workout) => jsonEncode(workout.toJson())).toList();
    await _prefs.setStringList(_workoutsKey, workoutsJson);
    await _backup();
  }

  Future<void> _backup() async {
    if (Platform.isAndroid) {
      if (await Permission.storage.request().isGranted) {
        try {
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            final backupDir = Directory('${directory.path}/body_calendar_backup');
            if (!await backupDir.exists()) {
              await backupDir.create(recursive: true);
            }
            final file = File('${backupDir.path}/prefs_backup.json');
            final allPrefs =
                _prefs.getKeys().fold<Map<String, dynamic>>({}, (map, key) {
              map[key] = _prefs.get(key);
              return map;
            });
            await file.writeAsString(jsonEncode(allPrefs));
          }
        } catch (e) {
          print('Error during auto backup: $e');
        }
      }
    }
  }

  @override
  Future<String> getWorkoutsJson() async {
    final workouts = await getWorkouts();
    final workoutsJson =
        workouts.map((workout) => jsonEncode(workout.toJson())).toList();
    return jsonEncode(workoutsJson);
  }

  @override
  Future<void> restoreWorkoutsFromJson(String jsonString) async {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    final List<String> workoutsJson = jsonList.cast<String>();
    await _prefs.setStringList(_workoutsKey, workoutsJson);
  }
}