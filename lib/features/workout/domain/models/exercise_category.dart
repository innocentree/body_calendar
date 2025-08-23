import 'package:body_calendar/features/workout/domain/models/exercise.dart';

class ExerciseCategory {
  final String name;
  final List<Exercise> exercises;

  ExerciseCategory({required this.name, required this.exercises});

  factory ExerciseCategory.fromJson(Map<String, dynamic> json) {
    var exerciseList = json['exercises'] as List;
    List<Exercise> exercises = exerciseList.map((i) => Exercise.fromJson(i)).toList();

    return ExerciseCategory(
      name: json['name'],
      exercises: exercises,
    );
  }
}