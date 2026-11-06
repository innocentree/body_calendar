import 'package:body_calendar/features/workout/domain/models/workout_group_type.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/presentation/workout_group_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('legacy and canonical group types share set workout behavior', () {
    for (final storedType in [
      null,
      'group',
      WorkoutGroupType.legacySuperset,
      WorkoutGroupType.legacyCompound,
      WorkoutGroupType.setWorkout,
    ]) {
      expect(
        WorkoutGroupType.behaviorFor(storedType),
        WorkoutGroupBehavior.setWorkout,
      );
      expect(workoutGroupDisplayLabel(storedType), '세트 운동');
      expect(
        WorkoutGroupType.statisticsKey(storedType),
        WorkoutGroupType.setWorkout,
      );
    }
  });

  test('legacy stored values round-trip without destructive migration', () {
    for (final storedType in [
      WorkoutGroupType.legacySuperset,
      WorkoutGroupType.legacyCompound,
    ]) {
      final record = WorkoutRecord.fromJson({
        'id': 1,
        'name': '벤치 프레스',
        'imagePath': '',
        'sets': 3,
        'weight': 20.0,
        'timestamp': '2026-09-17T00:00:00.000',
        'sessionIndex': 1,
        'groupId': 'legacy-group',
        'groupType': storedType,
        'groupOrder': 0,
      });

      expect(record.groupBehavior, WorkoutGroupBehavior.setWorkout);
      expect(record.toJson()['groupType'], storedType);
      expect(
        WorkoutGroupType.statisticsKey(record.groupType),
        WorkoutGroupType.setWorkout,
      );
    }
  });

  test('new set workouts use the canonical stored value', () {
    final record = WorkoutRecord(
      id: 1,
      name: '벤치 프레스',
      sets: 3,
      weight: 20,
      timestamp: DateTime(2026, 9, 17),
      sessionIndex: 1,
      groupId: 'new-group',
      groupType: WorkoutGroupType.setWorkout,
      groupOrder: 0,
    );

    expect(record.groupBehavior, WorkoutGroupBehavior.setWorkout);
    expect(record.toJson()['groupType'], 'set');
    expect(
      WorkoutGroupType.statisticsKey(record.groupType),
      WorkoutGroupType.setWorkout,
    );
  });
}
