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

  test('previous set workouts keep their group when copied to a new session',
      () {
    final copiedAt = DateTime(2026, 11, 19, 12);

    for (final storedType in [
      WorkoutGroupType.setWorkout,
      WorkoutGroupType.legacySuperset,
      WorkoutGroupType.legacyCompound,
    ]) {
      final source = [
        WorkoutRecord(
          id: 1,
          name: '벤치 프레스',
          sets: 3,
          weight: 60,
          timestamp: DateTime(2026, 11, 12),
          sessionIndex: 1,
          equipment: '바벨',
          bodyPart: '가슴',
          groupId: 'source-group',
          groupType: storedType,
          groupLabel: 'A',
          groupOrder: 0,
        ),
        WorkoutRecord(
          id: 2,
          name: '덤벨 플라이',
          sets: 3,
          weight: 12,
          timestamp: DateTime(2026, 11, 12),
          sessionIndex: 1,
          equipment: '덤벨',
          bodyPart: '가슴',
          groupId: 'source-group',
          groupType: storedType,
          groupLabel: 'A',
          groupOrder: 1,
        ),
      ];

      final copied = copyWorkoutRecordsToSession(
        records: source,
        sessionIndex: 2,
        timestamp: copiedAt,
      );

      expect(copied, hasLength(2));
      expect(copied.map((workout) => workout.groupId).toSet(), hasLength(1));
      expect(copied.first.groupId, isNot('source-group'));
      expect(
        copied.map((workout) => workout.groupType).toSet(),
        {WorkoutGroupType.setWorkout},
      );
      expect(copied.map((workout) => workout.groupOrder), [0, 1]);
      expect(copied.map((workout) => workout.groupLabel), ['A', 'A']);
      expect(copied.map((workout) => workout.sessionIndex), [2, 2]);
      expect(copied.map((workout) => workout.bodyPart), ['가슴', '가슴']);
    }
  });

  test('copying previous workouts does not merge separate groups or solo work',
      () {
    WorkoutRecord record(String name, {String? groupId}) => WorkoutRecord(
          id: name.hashCode,
          name: name,
          sets: 3,
          weight: 20,
          timestamp: DateTime(2026, 11, 12),
          sessionIndex: 1,
          groupId: groupId,
          groupType: groupId == null ? null : WorkoutGroupType.setWorkout,
        );

    final copied = copyWorkoutRecordsToSession(
      records: [
        record('그룹 A 1', groupId: 'group-a'),
        record('그룹 A 2', groupId: 'group-a'),
        record('단독 운동'),
        record('그룹 B 1', groupId: 'group-b'),
        record('그룹 B 2', groupId: 'group-b'),
      ],
      sessionIndex: 1,
      timestamp: DateTime(2026, 11, 19),
    );

    expect(copied[0].groupId, copied[1].groupId);
    expect(copied[3].groupId, copied[4].groupId);
    expect(copied[0].groupId, isNot(copied[3].groupId));
    expect(copied[2].isGrouped, isFalse);
    expect(copied[2].groupType, isNull);
  });
}
