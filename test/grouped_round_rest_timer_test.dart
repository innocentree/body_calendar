import 'dart:convert';

import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_set.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/grouped_exercise_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExerciseRepository implements ExerciseRepository {
  @override
  Future<Exercise?> getExerciseByName(String name) async => Exercise(
        name: name,
        imagePath: '',
        sets: 3,
        weight: 20,
        description: '',
      );

  @override
  Future<void> addCustomExercise(Exercise exercise) =>
      throw UnimplementedError();

  @override
  Future<void> deleteCustomExercise(String id) => throw UnimplementedError();

  @override
  Future<List<ExerciseCategory>> getExerciseCategories() =>
      throw UnimplementedError();

  @override
  Future<List<Exercise>> getCustomExercises() => throw UnimplementedError();
}

void main() {
  final selectedDate = DateTime(2026, 9, 17);
  final workouts = [
    WorkoutRecord(
      id: 1,
      name: '벤치 프레스',
      sets: 3,
      weight: 20,
      timestamp: selectedDate,
      sessionIndex: 1,
      groupId: 'group-a',
      groupType: 'superset',
      groupOrder: 0,
    ),
    WorkoutRecord(
      id: 2,
      name: '덤벨 플라이',
      sets: 3,
      weight: 10,
      timestamp: selectedDate,
      sessionIndex: 1,
      groupId: 'group-a',
      groupType: 'superset',
      groupOrder: 1,
    ),
  ];

  setUp(() async {
    await GetIt.I.reset();
    final sets = [
      ExerciseSet(
        weight: 20,
        reps: 10,
        restTime: const Duration(seconds: 5),
        isCompleted: true,
      ),
      ExerciseSet(
        weight: 20,
        reps: 10,
        restTime: const Duration(seconds: 7),
        isCompleted: true,
      ),
      ExerciseSet(
        weight: 20,
        reps: 10,
        restTime: const Duration(seconds: 9),
      ),
    ];
    SharedPreferences.setMockInitialValues({
      for (final workout in workouts)
        'exercise_sets_${workout.name}_2026-09-17':
            sets.map((set) => jsonEncode(set.toJson())).toList(),
    });
    final prefs = await SharedPreferences.getInstance();
    GetIt.I.registerSingleton<ExerciseRepository>(_FakeExerciseRepository());
    GetIt.I.registerSingleton<CloudSyncService>(CloudSyncService(prefs));
  });

  tearDown(() => GetIt.I.reset());

  testWidgets(
      'only the owning completed round shows the inline timer without shifting later content',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    for (final workout in workouts) {
      final key = 'exercise_sets_${workout.name}_2026-09-17';
      final sets = prefs
          .getStringList(key)!
          .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
          .toList();
      sets[1] = sets[1].copyWith(isCompleted: false);
      await prefs.setStringList(
        key,
        sets.map((set) => jsonEncode(set.toJson())).toList(),
      );
    }
    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final timerBloc = TimerBloc(ticker: const Ticker());
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 700),
              textScaler: TextScaler.linear(1.6),
            ),
            child: GroupedExerciseDetailScreen(
              workouts: workouts,
              selectedDate: selectedDate,
              recordDay: 1,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final secondRoundAction = find.byKey(const ValueKey('round-action-1'));
    await tester.scrollUntilVisible(
      secondRoundAction,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pump();
    final originalTop = tester.getTopLeft(secondRoundAction).dy;

    await tester.tap(find.byKey(const ValueKey('complete-round-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(timerBloc.state, isA<TimerRunInProgress>());
    expect(timerBloc.state.duration, 7);
    expect(
      timerBloc.ownerId,
      GroupedExerciseDetailScreen.timerOwnerId(
        groupId: 'group-a',
        selectedDate: selectedDate,
        roundIndex: 1,
      ),
    );
    expect(find.byKey(const ValueKey('round-rest-timer-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('round-rest-timer-0')), findsNothing);
    expect(tester.getTopLeft(secondRoundAction).dy, originalTop);
    for (final workout in workouts) {
      final saved = prefs
          .getStringList('exercise_sets_${workout.name}_2026-09-17')!
          .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
          .toList();
      expect(saved[1].isCompleted, isTrue);
    }

    await tester.tap(find.byKey(const ValueKey('round-timer-pause-resume')));
    await tester.pump();
    expect(timerBloc.state, isA<TimerRunPause>());

    await tester.tap(find.byKey(const ValueKey('round-timer-pause-resume')));
    await tester.pump();
    expect(timerBloc.state, isA<TimerRunInProgress>());

    await tester.tap(find.byKey(const ValueKey('round-timer-reset')));
    await tester.pump();
    expect(timerBloc.state, isA<TimerInitial>());
    expect(find.byKey(const ValueKey('round-completed-1')), findsOneWidget);
    expect(tester.getTopLeft(secondRoundAction).dy, originalTop);
  });

  testWidgets('a timer owned by another date does not appear in this group',
      (tester) async {
    final timerBloc = TimerBloc(ticker: const Ticker())
      ..add(TimerStarted(
        duration: 30,
        exerciseName: '다른 운동',
        selectedDate: selectedDate.add(const Duration(days: 1)),
        ownerId: GroupedExerciseDetailScreen.timerOwnerId(
          groupId: 'group-a',
          selectedDate: selectedDate.add(const Duration(days: 1)),
          roundIndex: 1,
        ),
      ));
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          home: GroupedExerciseDetailScreen(
            workouts: workouts,
            selectedDate: selectedDate,
            recordDay: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('round-completed-1')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.byKey(const ValueKey('round-rest-timer-1')), findsNothing);
    expect(find.byKey(const ValueKey('round-completed-1')), findsOneWidget);
    timerBloc.add(const TimerReset());
    await tester.pump();
  });

  test('zero-duration timers complete immediately and keep ownership',
      () async {
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    bloc.add(TimerStarted(
      duration: 0,
      exerciseName: '그룹',
      selectedDate: selectedDate,
      ownerId: 'owner',
    ));
    await Future<void>.delayed(Duration.zero);

    expect(bloc.state, isA<TimerRunComplete>());
    expect(bloc.ownerId, 'owner');
  });
}
