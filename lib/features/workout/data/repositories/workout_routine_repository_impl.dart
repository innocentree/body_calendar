import 'dart:convert';
import 'package:body_calendar/features/workout/domain/models/workout_routine.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_routine_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkoutRoutineRepositoryImpl implements WorkoutRoutineRepository {
  final SharedPreferences _prefs;
  static const String _routinesKey = 'workout_routines';

  WorkoutRoutineRepositoryImpl(this._prefs);

  @override
  Future<List<WorkoutRoutine>> getWorkoutRoutines() async {
    final routinesJson = _prefs.getStringList(_routinesKey) ?? [];
    return routinesJson
        .map((jsonString) => WorkoutRoutine.fromJson(json.decode(jsonString)))
        .toList();
  }

  @override
  Future<void> addWorkoutRoutine(WorkoutRoutine routine) async {
    final routines = await getWorkoutRoutines();
    routines.add(routine);
    await _saveRoutines(routines);
  }

  @override
  Future<void> deleteWorkoutRoutine(String id) async {
    final routines = await getWorkoutRoutines();
    routines.removeWhere((routine) => routine.id == id);
    await _saveRoutines(routines);
  }

  Future<void> _saveRoutines(List<WorkoutRoutine> routines) async {
    final routinesJson = routines
        .map((routine) => json.encode(routine.toJson()))
        .toList();
    await _prefs.setStringList(_routinesKey, routinesJson);
  }

  @override
  Future<String> getRoutinesJson() async {
    final routines = await getWorkoutRoutines();
    final routinesJson =
        routines.map((routine) => jsonEncode(routine.toJson())).toList();
    return jsonEncode(routinesJson);
  }

  @override
  Future<void> restoreRoutinesFromJson(String jsonString) async {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    final List<String> routinesJson = jsonList.cast<String>();
    await _prefs.setStringList(_routinesKey, routinesJson);
  }
}
