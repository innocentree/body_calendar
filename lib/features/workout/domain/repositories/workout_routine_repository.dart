import 'package:body_calendar/features/workout/domain/models/workout_routine.dart';

abstract class WorkoutRoutineRepository {
  Future<List<WorkoutRoutine>> getWorkoutRoutines();
  Future<void> addWorkoutRoutine(WorkoutRoutine routine);
  Future<void> deleteWorkoutRoutine(String id);
}
