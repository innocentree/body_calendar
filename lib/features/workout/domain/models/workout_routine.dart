import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:uuid/uuid.dart';

class WorkoutRoutine {
  final String id;
  final String name;
  final List<Exercise> exercises;

  WorkoutRoutine({
    String? id,
    required this.name,
    required this.exercises,
  }) : id = id ?? const Uuid().v4();

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };
  }
}
