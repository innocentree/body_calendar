import 'package:body_calendar/core/navigation/app_navigator.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
import 'package:body_calendar/features/workout/presentation/screens/grouped_exercise_detail_screen.dart';
import 'package:flutter/material.dart';

Future<T?> navigateToWorkoutDetail<T>({
  required BuildContext context,
  required WorkoutDetailTarget target,
  required Route<T> Function(RouteSettings settings) routeBuilder,
  AppNavigatorObserver? observer,
}) {
  final navigator = Navigator.of(context);
  final routeObserver = observer ?? appNavigatorObserver;

  if (routeObserver.tracks(navigator)) {
    final existing = routeObserver.routeForTarget(target);
    if (existing != null && existing.isActive) {
      navigator.popUntil((route) => identical(route, existing));
      return Future<T?>.value();
    }

    final staleDetail = routeObserver.firstDetailRoute;
    if (staleDetail != null) {
      final baseRoute = routeObserver.routeBefore(staleDetail);
      return navigator.pushAndRemoveUntil<T>(
        routeBuilder(target.routeSettings),
        (route) => baseRoute != null && identical(route, baseRoute),
      );
    }
  }

  return navigator.push<T>(routeBuilder(target.routeSettings));
}

Future<void> openExerciseDetail({
  required BuildContext context,
  required String exerciseName,
  required DateTime selectedDate,
  required int initialWeight,
  required int initialSets,
  int recordDay = 0,
  AppNavigatorObserver? observer,
}) async {
  final target = WorkoutDetailTarget.exercise(
    exerciseName: exerciseName,
    selectedDate: selectedDate,
  );
  await navigateToWorkoutDetail<void>(
    context: context,
    target: target,
    observer: observer,
    routeBuilder: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => ExerciseDetailScreen(
        exerciseName: exerciseName,
        selectedDate: selectedDate,
        initialWeight: initialWeight,
        initialSets: initialSets,
        recordDay: recordDay,
      ),
    ),
  );
}

Future<void> openGroupedExerciseDetail({
  required BuildContext context,
  required List<WorkoutRecord> workouts,
  required DateTime selectedDate,
  required int recordDay,
  AppNavigatorObserver? observer,
}) async {
  if (workouts.isEmpty) return;
  final first = workouts.first;
  final groupId =
      first.groupId ?? workouts.map((workout) => workout.id).join('-');
  final target = WorkoutDetailTarget.group(
    groupId: groupId,
    sessionIndex: first.sessionIndex,
    selectedDate: selectedDate,
  );
  await navigateToWorkoutDetail<void>(
    context: context,
    target: target,
    observer: observer,
    routeBuilder: (settings) => MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => GroupedExerciseDetailScreen(
        workouts: workouts,
        selectedDate: selectedDate,
        recordDay: recordDay,
      ),
    ),
  );
}
