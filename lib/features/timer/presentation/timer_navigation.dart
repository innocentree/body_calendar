import 'dart:async';
import 'dart:convert';

import 'package:body_calendar/core/navigation/app_navigator.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/presentation/navigation/workout_detail_navigation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> navigateToRunningTimer(
  BuildContext context,
  TimerBloc bloc, {
  AppNavigatorObserver? observer,
}) async {
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
    unawaited(openGroupedExerciseDetail(
      context: context,
      workouts: workouts,
      selectedDate: selectedDate,
      recordDay: groupContext.recordDay,
      observer: observer,
    ));
    return;
  }

  unawaited(openExerciseDetail(
    context: context,
    exerciseName: exerciseName,
    selectedDate: selectedDate,
    initialWeight: 0,
    initialSets: 1,
    observer: observer,
  ));
}
