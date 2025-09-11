import 'dart:convert';

import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class ExerciseRepositoryImpl implements ExerciseRepository {
  final SharedPreferences _prefs;
  static const String _customExercisesKey = 'custom_exercises';

  ExerciseRepositoryImpl(this._prefs);

  @override
  Future<List<ExerciseCategory>> getExerciseCategories() async {
    final jsonString = await rootBundle.loadString('assets/data/exercises.json');
    final Map<String, dynamic> data = json.decode(jsonString);

    return data.entries.map((entry) {
      return ExerciseCategory.fromJson(entry.value as Map<String, dynamic>);
    }).toList();
  }

  @override
  Future<List<Exercise>> getCustomExercises() async {
    final jsonStringList = _prefs.getStringList(_customExercisesKey) ?? [];
    return jsonStringList
        .map((jsonString) => Exercise.fromJson(json.decode(jsonString)))
        .toList();
  }

  @override
  Future<void> addCustomExercise(Exercise exercise) async {
    final customExercises = await getCustomExercises();
    customExercises.add(exercise);
    await _saveCustomExercises(customExercises);
  }

  @override
  Future<void> deleteCustomExercise(String id) async {
    final customExercises = await getCustomExercises();
    customExercises.removeWhere((exercise) => exercise.id == id);
    await _saveCustomExercises(customExercises);
  }

  Future<void> _saveCustomExercises(List<Exercise> exercises) async {
    final jsonStringList = exercises
        .map((exercise) => json.encode(exercise.toJson()))
        .toList();
    await _prefs.setStringList(_customExercisesKey, jsonStringList);
  }

  @override
  Future<Exercise?> getExerciseByName(String name) async {
    final categories = await getExerciseCategories();
    for (final category in categories) {
      for (final exercise in category.exercises) {
        if (exercise.name == name) {
          return exercise;
        }
        for (final variation in exercise.variations) {
          if (variation.name == name) {
            return variation;
          }
        }
      }
    }
    final customExercises = await getCustomExercises();
    for (final exercise in customExercises) {
      if (exercise.name == name) {
        return exercise;
      }
    }
    return null;
  }
}
