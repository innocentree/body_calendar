import 'dart:convert';

import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
import 'package:body_calendar/features/workout/presentation/screens/grouped_exercise_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> navigateToRunningTimer(
  BuildContext context,
  TimerBloc bloc,
) async {
  final exerciseName = bloc.exerciseName;
  final selectedDate = bloc.selectedDate;
  if (exerciseName == null || selectedDate == null) return;

  final groupContext = bloc.groupNavigationContext;
  if (groupContext != null) {
    final prefs = await SharedPreferences.getInstance();
    final date = DateFormat('yyyy-MM-dd').format(selectedDate);
    final stored = prefs.getStringList('workouts_$date') ?? const [];
    final workouts = <WorkoutRecord>[];
    try {
      workouts.addAll(
        stored.map((raw) => WorkoutRecord.fromJson(jsonDecode(raw))).where(
              (workout) =>
                  workout.groupId == groupContext.groupId &&
                  workout.sessionIndex == groupContext.sessionIndex,
            ),
      );
    } catch (_) {
      workouts.clear();
    }
    workouts.sort(
      (a, b) => (a.groupOrder ?? 0).compareTo(b.groupOrder ?? 0),
    );
    if (!context.mounted) return;
    if (workouts.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('이 그룹 운동을 찾을 수 없어요.')),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GroupedExerciseDetailScreen(
          workouts: workouts,
          selectedDate: selectedDate,
          recordDay: groupContext.recordDay,
        ),
        settings: const RouteSettings(name: '/grouped_exercise_detail'),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (context) => ExerciseDetailScreen(
        exerciseName: exerciseName,
        selectedDate: selectedDate,
        initialWeight: 0,
        initialSets: 1,
      ),
      settings: const RouteSettings(name: '/exercise_detail'),
    ),
  );
}
