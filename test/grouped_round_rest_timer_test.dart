import 'dart:convert';

import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_set.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
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

class _RouteObserver extends NavigatorObserver {
  final pushedNames = <String?>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedNames.add(route.settings.name);
    super.didPush(route, previousRoute);
  }
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
      'the single header action completes the current round and keeps its timer visible',
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

    final headerAction = find.byKey(const ValueKey('header-round-action'));
    expect(headerAction, findsOneWidget);
    expect(
        find.byKey(const ValueKey('complete-current-round-1')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('complete-current-round-0')), findsNothing);
    expect(
        find.byKey(const ValueKey('complete-current-round-2')), findsNothing);
    expect(find.byKey(const ValueKey('round-action-0')), findsNothing);
    expect(find.byKey(const ValueKey('round-action-1')), findsNothing);
    expect(find.byKey(const ValueKey('round-action-2')), findsNothing);
    final originalRect = tester.getRect(headerAction);

    await tester.tap(find.byKey(const ValueKey('complete-current-round-1')));
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
    expect(
      timerBloc.groupNavigationContext,
      const GroupTimerNavigationContext(
        groupId: 'group-a',
        sessionIndex: 1,
        recordDay: 1,
      ),
    );
    expect(find.byKey(const ValueKey('header-round-rest-timer-1')),
        findsOneWidget);
    expect(find.text('3/3'), findsOneWidget);
    expect(tester.getRect(headerAction), originalRect);
    final gauge = find.byKey(const ValueKey('round-timer-gauge'));
    final initialGaugeWidth = tester.getSize(gauge).width;
    expect(initialGaugeWidth, tester.getSize(headerAction).width);
    await tester.pump(const Duration(seconds: 1));
    final decreasedGaugeWidth = tester.getSize(gauge).width;
    expect(decreasedGaugeWidth, lessThan(initialGaugeWidth));
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
    final pausedGaugeWidth = tester.getSize(gauge).width;
    await tester.pump(const Duration(seconds: 2));
    expect(tester.getSize(gauge).width, pausedGaugeWidth);

    await tester.tap(find.byKey(const ValueKey('round-timer-pause-resume')));
    await tester.pump();
    expect(timerBloc.state, isA<TimerRunInProgress>());

    await tester.tap(find.byKey(const ValueKey('round-timer-reset')));
    await tester.pump();
    expect(timerBloc.state, isA<TimerInitial>());
    expect(
        find.byKey(const ValueKey('complete-current-round-2')), findsOneWidget);
    expect(tester.getRect(headerAction), originalRect);
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

    expect(
        find.byKey(const ValueKey('header-round-rest-timer-1')), findsNothing);
    expect(
        find.byKey(const ValueKey('complete-current-round-2')), findsOneWidget);
    timerBloc.add(const TimerReset());
    await tester.pump();
  });

  testWidgets('very narrow timer actions stack without overflow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final timerBloc = TimerBloc(ticker: const Ticker())
      ..add(TimerStarted(
        duration: 10800,
        exerciseName: '그룹',
        selectedDate: selectedDate,
        ownerId: GroupedExerciseDetailScreen.timerOwnerId(
          groupId: 'group-a',
          selectedDate: selectedDate,
          roundIndex: 1,
        ),
      ));
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 700),
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
    final action = find.byKey(const ValueKey('header-round-action'));
    final status = find.byKey(const ValueKey('header-round-status'));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(action).width, greaterThan(120));
    expect(
      tester.getTopRight(status).dx,
      closeTo(
        tester
            .getTopRight(
              find.byKey(const ValueKey('header-action-status-row')),
            )
            .dx,
        0.01,
      ),
    );
    expect(tester.getTopLeft(action).dy, tester.getTopLeft(status).dy);
    timerBloc.add(const TimerReset());
    await tester.pump();
  });

  for (final width in [400.0, 320.0]) {
    testWidgets(
        'exercise cards fill the round content without per-round actions at ${width.toInt()}px',
        (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final timerBloc = TimerBloc(ticker: const Ticker());
      addTearDown(timerBloc.close);

      await tester.pumpWidget(
        BlocProvider.value(
          value: timerBloc,
          child: MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(width, 700)),
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

      final card = find.byKey(
        const ValueKey('exercise-round-card-0-1'),
      );
      await tester.scrollUntilVisible(
        card,
        300,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();

      final round = find.byKey(const ValueKey('round-container-0'));
      final secondCard = find.byKey(
        const ValueKey('exercise-round-card-0-2'),
      );
      final roundRect = tester.getRect(round);
      final cardRect = tester.getRect(card);

      expect(tester.takeException(), isNull);
      expect(cardRect.left, closeTo(roundRect.left + 16, 1.01));
      expect(cardRect.right, closeTo(roundRect.right - 16, 1.01));
      expect(tester.getRect(secondCard).right, closeTo(cardRect.right, 0.01));
      expect(find.byKey(const ValueKey('round-action-0')), findsNothing);
      expect(cardRect.width, greaterThan(width - 100));
    });
  }

  testWidgets('rest FAB opens the stored owning group in group order',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final unrelatedWorkouts = [
      WorkoutRecord(
        id: 3,
        name: '스쿼트',
        sets: 3,
        weight: 40,
        timestamp: selectedDate,
        sessionIndex: 1,
        groupId: 'other-group',
        groupOrder: 0,
      ),
      WorkoutRecord(
        id: 4,
        name: '데드리프트',
        sets: 3,
        weight: 60,
        timestamp: selectedDate,
        sessionIndex: 2,
        groupId: 'group-a',
        groupOrder: 0,
      ),
    ];
    await prefs.setStringList(
      'workouts_2026-09-17',
      [...workouts.reversed, ...unrelatedWorkouts]
          .map((workout) => jsonEncode(workout.toJson()))
          .toList(),
    );
    final timerBloc = TimerBloc(ticker: const Ticker())
      ..add(TimerStarted(
        duration: 30,
        exerciseName: '벤치 프레스 · 덤벨 플라이',
        selectedDate: selectedDate,
        ownerId: 'group:group-a:2026-09-17:round:1',
        groupNavigationContext: GroupTimerNavigationContext(
          groupId: 'group-a',
          sessionIndex: 1,
          recordDay: 4,
        ),
      ));
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [RestFabOverlay()])),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rest-fab-overlay')));
    await tester.pumpAndSettle();

    final screen = tester.widget<GroupedExerciseDetailScreen>(
      find.byType(GroupedExerciseDetailScreen),
    );
    expect(screen.workouts.map((workout) => workout.id), [1, 2]);
    expect(screen.selectedDate, selectedDate);
    expect(screen.recordDay, 4);
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    timerBloc.add(const TimerReset());
    await tester.pump();
  });

  testWidgets('rest FAB keeps solo timers on the exercise detail route',
      (tester) async {
    final routeObserver = _RouteObserver();
    final timerBloc = TimerBloc(ticker: const Ticker())
      ..add(TimerStarted(
        duration: 30,
        exerciseName: '벤치 프레스',
        selectedDate: selectedDate,
      ));
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          navigatorObservers: [routeObserver],
          home: const Scaffold(body: Stack(children: [RestFabOverlay()])),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('rest-fab-overlay')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('rest-fab-overlay')));
    await tester.pump(const Duration(milliseconds: 500));

    expect(routeObserver.pushedNames.last, '/exercise_detail');
    expect(find.byType(GroupedExerciseDetailScreen), findsNothing);
    timerBloc.add(const TimerReset());
    await tester.pump();
  });

  testWidgets('rest FAB stays put when its group was deleted', (tester) async {
    final timerBloc = TimerBloc(ticker: const Ticker())
      ..add(TimerStarted(
        duration: 30,
        exerciseName: '삭제된 그룹',
        selectedDate: selectedDate,
        groupNavigationContext: GroupTimerNavigationContext(
          groupId: 'deleted-group',
          sessionIndex: 1,
          recordDay: 1,
        ),
      ));
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: const MaterialApp(
          home: Scaffold(body: Stack(children: [RestFabOverlay()])),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('rest-fab-overlay')));
    await tester.pumpAndSettle();

    expect(find.byType(GroupedExerciseDetailScreen), findsNothing);
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    expect(find.text('이 그룹 운동을 찾을 수 없어요.'), findsOneWidget);
    expect(find.byKey(const ValueKey('rest-fab-overlay')), findsOneWidget);
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

  test('solo starts and resets clear group navigation metadata', () async {
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    bloc.add(TimerStarted(
      duration: 0,
      exerciseName: '그룹',
      selectedDate: selectedDate,
      groupNavigationContext: const GroupTimerNavigationContext(
        groupId: 'group-a',
        sessionIndex: 1,
        recordDay: 1,
      ),
    ));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.groupNavigationContext, isNotNull);

    bloc.add(TimerStarted(
      duration: 0,
      exerciseName: '단독',
      selectedDate: selectedDate,
    ));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.groupNavigationContext, isNull);

    bloc.add(TimerStarted(
      duration: 0,
      exerciseName: '그룹',
      selectedDate: selectedDate,
      groupNavigationContext: const GroupTimerNavigationContext(
        groupId: 'group-a',
        sessionIndex: 1,
        recordDay: 1,
      ),
    ));
    await Future<void>.delayed(Duration.zero);
    bloc.add(const TimerReset());
    await Future<void>.delayed(Duration.zero);
    expect(bloc.groupNavigationContext, isNull);
  });
}
