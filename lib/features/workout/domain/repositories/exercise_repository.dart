import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';

abstract class ExerciseRepository {
  Future<List<ExerciseCategory>> getExerciseCategories();

  Future<List<Exercise>> getCustomExercises();

  Future<void> addCustomExercise(Exercise exercise);

  Future<void> deleteCustomExercise(String id);
}
