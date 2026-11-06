import 'package:body_calendar/features/workout/domain/models/workout_group_type.dart';
import 'package:flutter/material.dart';

const Color workoutGroupAccentColor = Color(0xFF32ADE6);

String workoutGroupDisplayLabel(String? storedType) {
  switch (WorkoutGroupType.behaviorFor(storedType)) {
    case WorkoutGroupBehavior.setWorkout:
      return '세트 운동';
  }
}
