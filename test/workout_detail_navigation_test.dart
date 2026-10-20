import 'dart:async';
import 'dart:convert';

import 'package:body_calendar/core/navigation/app_navigator.dart';
import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/timer/presentation/timer_navigation.dart';
import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_set.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/presentation/navigation/workout_detail_navigation.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
import 'package:body_calendar/features/workout/presentation/screens/grouped_exercise_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExerciseRepository implements ExerciseRepository {
  _FakeExerciseRepository({this.delayedExercise});

  final Future<Exercise?>? delayedExercise;

  @override
  Future<Exercise?> getExerciseByName(String name) =>
      delayedExercise ??
      Future.value(Exercise(
        name: name,
        imagePath: '',
        sets: 5,
        weight: 20,
        description: '',
      ));

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

class _NavigationHome extends StatelessWidget {
  const _NavigationHome({required this.observer, required this.date});

  final AppNavigatorObserver observer;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const ValueKey('open-exercise-a'),
          onPressed: () => unawaited(openExerciseDetail(
            context: context,
            exerciseName: '벤치 프레스',
            selectedDate: date,
            initialWeight: 20,
            initialSets: 5,
            observer: observer,
          )),
          child: const Text('운동 열기'),
        ),
      ),
    );
  }
}

class _RefreshProbe extends StatefulWidget {
  const _RefreshProbe({
    required this.observer,
    required this.date,
    required this.setsKey,
  });

  final AppNavigatorObserver observer;
  final DateTime date;
  final String setsKey;

  @override
  State<_RefreshProbe> createState() => _RefreshProbeState();
}

class _RefreshProbeState extends State<_RefreshProbe> with RouteAware {
  String _progress = 'loading';

  @override
  void initState() {
    super.initState();
    unawaited(_reload());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<dynamic>) {
      widget.observer.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    unawaited(_reload());
  }

  Future<void> _reload() async {
    final prefs = await SharedPreferences.getInstance();
    final sets = (prefs.getStringList(widget.setsKey) ?? const [])
        .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
        .toList();
    if (!mounted) return;
    setState(() {
      _progress = '${sets.where((set) => set.isCompleted).length} / '
          '${sets.length}';
    });
  }

  @override
  void dispose() {
    widget.observer.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(_progress, key: const ValueKey('refresh-progress')),
          ElevatedButton(
            key: const ValueKey('refresh-open-a'),
            onPressed: () => unawaited(openExerciseDetail(
              context: context,
              exerciseName: '벤치 프레스',
              selectedDate: widget.date,
              initialWeight: 20,
              initialSets: 5,
              observer: widget.observer,
            )),
            child: const Text('A 열기'),
          ),
        ],
      ),
    );
  }
}

void main() {
  final selectedDate = DateTime(2026, 10, 20);
  const exerciseName = '벤치 프레스';
  const setsKey = 'exercise_sets_벤치 프레스_2026-10-20';

  List<String> encodedSets({int completed = 3}) => List.generate(
        5,
        (index) => jsonEncode(ExerciseSet(
          weight: 20,
          reps: 10,
          restTime: Duration.zero,
          isCompleted: index < completed,
        ).toJson()),
      );

  Future<void> registerServices({Future<Exercise?>? delayedExercise}) async {
    final prefs = await SharedPreferences.getInstance();
    GetIt.I.registerSingleton<ExerciseRepository>(
      _FakeExerciseRepository(delayedExercise: delayedExercise),
    );
    GetIt.I.registerSingleton<CloudSyncService>(CloudSyncService(prefs));
  }

  Future<void> pumpApp(
    WidgetTester tester,
    TimerBloc bloc,
    AppNavigatorObserver observer,
  ) async {
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          navigatorObservers: [observer],
          home: _NavigationHome(observer: observer, date: selectedDate),
        ),
      ),
    );
  }

  setUp(() async {
    await GetIt.I.reset();
    SharedPreferences.setMockInitialValues({
      setsKey: encodedSets(),
      'recorded_dates_$exerciseName': ['2026-10-20'],
    });
  });

  tearDown(() => GetIt.I.reset());

  testWidgets(
      'timer navigation reuses the same detail through dialogs and one back returns home',
      (tester) async {
    await registerServices();
    final observer = AppNavigatorObserver();
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    await pumpApp(tester, bloc, observer);

    await tester.tap(find.byKey(const ValueKey('open-exercise-a')));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);

    bloc.add(TimerStarted(
      duration: 30,
      exerciseName: exerciseName,
      selectedDate: selectedDate,
    ));
    await tester.pump();
    await navigateToRunningTimer(
      tester.element(find.byType(ExerciseDetailScreen)),
      bloc,
      observer: observer,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);

    unawaited(showDialog<void>(
      context: tester.element(find.byType(ExerciseDetailScreen)),
      builder: (context) => const AlertDialog(
        key: ValueKey('detail-dialog'),
        title: Text('상세 대화상자'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail-dialog')), findsOneWidget);

    await navigateToRunningTimer(
      tester.element(find.byType(ExerciseDetailScreen)),
      bloc,
      observer: observer,
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('detail-dialog')), findsNothing);
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(setsKey, encodedSets(completed: 5));
    await navigateToRunningTimer(
      tester.element(find.byType(ExerciseDetailScreen)),
      bloc,
      observer: observer,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    bloc.add(const TimerReset());
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-exercise-a')), findsOneWidget);
    expect(find.byType(ExerciseDetailScreen), findsNothing);

    final saved = prefs
        .getStringList(setsKey)!
        .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
        .toList();
    expect(saved.where((set) => set.isCompleted), hasLength(5));
  });

  testWidgets(
      'different exercise, date, and group targets replace stale detail',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final groupWorkouts = [
      WorkoutRecord(
        id: 11,
        name: '스쿼트',
        sets: 3,
        weight: 40,
        timestamp: selectedDate,
        sessionIndex: 2,
        groupId: 'legs',
        groupOrder: 0,
      ),
      WorkoutRecord(
        id: 12,
        name: '런지',
        sets: 3,
        weight: 20,
        timestamp: selectedDate,
        sessionIndex: 2,
        groupId: 'legs',
        groupOrder: 1,
      ),
    ];
    await prefs.setStringList(
      'workouts_2026-10-20',
      groupWorkouts.map((workout) => jsonEncode(workout.toJson())).toList(),
    );
    await registerServices();
    final observer = AppNavigatorObserver();
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    await pumpApp(tester, bloc, observer);

    await tester.tap(find.byKey(const ValueKey('open-exercise-a')));
    await tester.pumpAndSettle();
    final firstContext = tester.element(find.byType(ExerciseDetailScreen));
    unawaited(openExerciseDetail(
      context: firstContext,
      exerciseName: exerciseName,
      selectedDate: DateTime(2026, 10, 21),
      initialWeight: 20,
      initialSets: 5,
      observer: observer,
    ));
    await tester.pumpAndSettle();
    final differentDate = tester.widget<ExerciseDetailScreen>(
      find.byType(ExerciseDetailScreen),
    );
    expect(differentDate.exerciseName, exerciseName);
    expect(differentDate.selectedDate, DateTime(2026, 10, 21));

    unawaited(openExerciseDetail(
      context: tester.element(find.byType(ExerciseDetailScreen)),
      exerciseName: '덤벨 플라이',
      selectedDate: DateTime(2026, 10, 21),
      initialWeight: 10,
      initialSets: 3,
      observer: observer,
    ));
    await tester.pumpAndSettle();
    final differentExercise = tester.widget<ExerciseDetailScreen>(
      find.byType(ExerciseDetailScreen),
    );
    expect(differentExercise.exerciseName, '덤벨 플라이');
    expect(differentExercise.selectedDate, DateTime(2026, 10, 21));

    bloc.add(TimerStarted(
      duration: 30,
      exerciseName: '스쿼트 · 런지',
      selectedDate: selectedDate,
      groupNavigationContext: const GroupTimerNavigationContext(
        groupId: 'legs',
        sessionIndex: 2,
        recordDay: 1,
      ),
    ));
    await tester.pump();
    await navigateToRunningTimer(
      tester.element(find.byType(ExerciseDetailScreen)),
      bloc,
      observer: observer,
    );
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseDetailScreen), findsNothing);
    final group = tester.widget<GroupedExerciseDetailScreen>(
      find.byType(GroupedExerciseDetailScreen),
    );
    expect(group.workouts.map((workout) => workout.id), [11, 12]);
    expect(group.selectedDate, selectedDate);

    bloc.add(const TimerReset());
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open-exercise-a')), findsOneWidget);
    expect(find.byType(GroupedExerciseDetailScreen), findsNothing);
  });

  testWidgets(
      'rapid back during initial detail load does not set state after dispose',
      (tester) async {
    final exerciseCompleter = Completer<Exercise?>();
    await registerServices(delayedExercise: exerciseCompleter.future);
    final observer = AppNavigatorObserver();
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    await pumpApp(tester, bloc, observer);

    await tester.tap(find.byKey(const ValueKey('open-exercise-a')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(ExerciseDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    exerciseCompleter.complete(Exercise(
      name: exerciseName,
      imagePath: '',
      sets: 5,
      weight: 20,
      description: '',
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('open-exercise-a')), findsOneWidget);
  });

  testWidgets('base route refreshes after a replacement detail is popped',
      (tester) async {
    const replacementSetsKey = 'exercise_sets_덤벨 플라이_2026-10-20';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(replacementSetsKey, encodedSets());
    await registerServices();
    final observer = AppNavigatorObserver();
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: bloc,
        child: MaterialApp(
          navigatorObservers: [observer],
          home: _RefreshProbe(
            observer: observer,
            date: selectedDate,
            setsKey: replacementSetsKey,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('3 / 5'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('refresh-open-a')));
    await tester.pumpAndSettle();
    unawaited(openExerciseDetail(
      context: tester.element(find.byType(ExerciseDetailScreen)),
      exerciseName: '덤벨 플라이',
      selectedDate: selectedDate,
      initialWeight: 10,
      initialSets: 5,
      observer: observer,
    ));
    await tester.pumpAndSettle();

    await prefs.setStringList(
      replacementSetsKey,
      encodedSets(completed: 5),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('refresh-progress')), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget);
    expect(find.byType(ExerciseDetailScreen), findsNothing);
  });
}
