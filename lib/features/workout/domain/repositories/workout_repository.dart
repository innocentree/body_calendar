import 'package:body_calendar/features/workout/domain/models/workout.dart';

abstract class WorkoutRepository {
  Future<List<Workout>> getWorkouts();
  Future<void> addWorkout(Workout workout);
  Future<void> updateWorkout(Workout workout);
  Future<void> deleteWorkout(String id);
  Future<String> getWorkoutsJson();
  Future<void> restoreWorkoutsFromJson(String jsonString);
} 