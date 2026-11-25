import 'dart:convert';

import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:body_calendar/core/theme/app_theme.dart';
import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/core/widgets/horizontal_dial_picker.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_set.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeExerciseRepository implements ExerciseRepository {
  @override
  Future<Exercise?> getExerciseByName(String name) async => Exercise(
        name: name,
        imagePath: '',
        sets: 1,
        weight: 28,
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
  TestWidgetsFlutterBinding.ensureInitialized();
  const exerciseName = '인클라인 프레스: 덤벨';
  const setsKey = 'exercise_sets_인클라인 프레스: 덤벨_2026-09-28';

  Future<SharedPreferences> pumpExerciseDetail(
    WidgetTester tester,
    List<ExerciseSet> sets,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      setsKey: sets.map((set) => jsonEncode(set.toJson())).toList(),
    });
    final prefs = await SharedPreferences.getInstance();
    GetIt.I.registerSingleton<CloudSyncService>(CloudSyncService(prefs));
    final timerBloc = TimerBloc(ticker: const Ticker());
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExerciseDetailScreen(
            exerciseName: exerciseName,
            selectedDate: DateTime(2026, 9, 28),
            initialWeight: 20,
            initialSets: sets.length,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return prefs;
  }

  setUp(() async {
    await GetIt.I.reset();
    final set = ExerciseSet(
      weight: 28,
      reps: 10,
      restTime: const Duration(seconds: 70),
    );
    SharedPreferences.setMockInitialValues({
      'exercise_sets_인클라인 프레스: 덤벨_2026-09-28': [
        jsonEncode(set.toJson()),
      ],
    });
    GetIt.I.registerSingleton<ExerciseRepository>(_FakeExerciseRepository());
  });

  tearDown(() => GetIt.I.reset());

  testWidgets(
      'light set editor uses visible semantic foreground colors at 320px',
      (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerBloc = TimerBloc(ticker: const Ticker());
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExerciseDetailScreen(
            exerciseName: '인클라인 프레스: 덤벨',
            selectedDate: DateTime(2026, 9, 28),
            initialWeight: 28,
            initialSets: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addSetAction = find.ancestor(
      of: find.text('세트 추가'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    expect(addSetAction, findsOneWidget);
    expect(tester.widget<FilledButton>(addSetAction).onPressed, isNotNull);

    await tester.tap(find.text('28.0kg × 10회'));
    await tester.pumpAndSettle();

    final scheme = AppTheme.lightTheme.colorScheme;
    for (final key in [
      'set-editor-weight-label-0',
      'set-editor-weight-value-0',
      'set-editor-rest-label-0',
      'set-editor-rest-value-0',
    ]) {
      final text = tester.widget<Text>(find.byKey(ValueKey(key)));
      expect(text.style?.color, scheme.onSurface, reason: key);
      expect(text.style?.color, isNot(Colors.white), reason: key);
    }

    for (final key in [
      'set-editor-weight-remove-0',
      'set-editor-rest-remove-0',
    ]) {
      final icon = tester.widget<Icon>(find.byKey(ValueKey(key)));
      expect(icon.color, scheme.onSurface, reason: key);
      expect(icon.color, isNot(Colors.white), reason: key);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('dial scope actions commit the edited weight and reps directly',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final sets = [
      ExerciseSet(
        weight: 28,
        reps: 10,
        restTime: const Duration(seconds: 70),
        isCompleted: true,
      ),
      ExerciseSet(
        weight: 28,
        reps: 10,
        restTime: const Duration(seconds: 70),
      ),
      ExerciseSet(
        weight: 28,
        reps: 10,
        restTime: const Duration(seconds: 70),
      ),
    ];
    SharedPreferences.setMockInitialValues({
      'exercise_sets_인클라인 프레스: 덤벨_2026-09-28':
          sets.map((set) => jsonEncode(set.toJson())).toList(),
    });
    final prefs = await SharedPreferences.getInstance();
    final timerBloc = TimerBloc(ticker: const Ticker());
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExerciseDetailScreen(
            exerciseName: '인클라인 프레스: 덤벨',
            selectedDate: DateTime(2026, 9, 28),
            initialWeight: 28,
            initialSets: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'initial set list');
    await tester.tap(find.text('28.0kg × 10회').at(1));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'expanded set editor');

    await tester.tap(
      find.byKey(const ValueKey('set-editor-weight-value-1')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'weight dial');
    final weightDial = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(HorizontalDialPicker),
    );
    await tester.drag(
      find.descendant(
        of: weightDial,
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(-200, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dialog-apply-remaining-sets')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'weight propagation');

    var saved = prefs
        .getStringList('exercise_sets_인클라인 프레스: 덤벨_2026-09-28')!
        .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
        .toList();
    expect(saved[0].weight, 28);
    expect(saved[1].weight, greaterThan(28));
    expect(saved[2].weight, saved[1].weight);

    await tester.tap(
      find.byKey(const ValueKey('set-editor-reps-value-1')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'reps dial');
    final repsDial = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(HorizontalDialPicker),
    );
    await tester.drag(
      find.descendant(
        of: repsDial,
        matching: find.byType(SingleChildScrollView),
      ),
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('dialog-apply-all-sets')),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'reps propagation');

    saved = prefs
        .getStringList('exercise_sets_인클라인 프레스: 덤벨_2026-09-28')!
        .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
        .toList();
    expect(saved.map((set) => set.reps).toSet(), hasLength(1));
    expect(saved.first.reps, greaterThan(10));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'deleting an expanded fourth set keeps the shifted fifth set editable',
      (tester) async {
    final sets = List.generate(
      5,
      (index) => ExerciseSet(
        weight: 20 + index.toDouble(),
        reps: 10,
        restTime: Duration.zero,
      ),
    );
    final prefs = await pumpExerciseDetail(tester, sets);

    for (var setNumber = 1; setNumber <= 3; setNumber++) {
      await tester.tap(find.text('$setNumber번 세트 완료'));
      await tester.pumpAndSettle();
    }

    final fourthSet = find.text('23.0kg × 10회');
    await tester.scrollUntilVisible(
      fourthSet,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fourthSet);
    await tester.pumpAndSettle();
    final fourthTile = find.ancestor(
      of: fourthSet,
      matching: find.byType(ExpansionTile),
    );
    final fourthDelete = find.descendant(
      of: fourthTile,
      matching: find.byIcon(Icons.delete),
    );
    await tester.tap(fourthDelete);
    await tester.pumpAndSettle();

    expect(find.text('23.0kg × 10회'), findsNothing);
    expect(find.text('24.0kg × 10회'), findsOneWidget);
    final savedSets = prefs
        .getStringList(setsKey)!
        .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
        .toList();
    expect(savedSets.map((set) => set.weight), [20, 21, 22, 24]);
    expect(savedSets.map((set) => set.isCompleted), [true, true, true, false]);
    final shiftedLastSet = find.text('24.0kg × 10회');
    await tester.ensureVisible(shiftedLastSet);
    await tester.tap(shiftedLastSet);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('set-editor-weight-label-3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('set-editor-reps-value-3')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('set-editor-weight-label-3')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting an earlier set keeps the logical current set selected',
      (tester) async {
    final sets = List.generate(
      5,
      (index) => ExerciseSet(
        weight: 20 + index.toDouble(),
        reps: 10,
        restTime: Duration.zero,
        isCompleted: index < 3,
      ),
    );
    final prefs = await pumpExerciseDetail(tester, sets);

    final secondSet = find.text('21.0kg × 10회');
    final secondTile = find.ancestor(
      of: secondSet,
      matching: find.byType(ExpansionTile),
    );
    await tester.tap(find.descendant(
      of: secondTile,
      matching: find.byIcon(Icons.delete),
    ));
    await tester.pumpAndSettle();

    expect(find.text('3번 세트 완료'), findsOneWidget);
    await tester.tap(find.text('3번 세트 완료'));
    await tester.pumpAndSettle();

    final savedSets = prefs
        .getStringList(setsKey)!
        .map((raw) => ExerciseSet.fromJson(jsonDecode(raw)))
        .toList();
    expect(savedSets.map((set) => set.weight), [20, 22, 23, 24]);
    expect(savedSets.map((set) => set.isCompleted), [true, true, true, false]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('gradient add action remains keyboard activatable',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final timerBloc = TimerBloc(ticker: const Ticker());
    addTearDown(timerBloc.close);

    await tester.pumpWidget(
      BlocProvider.value(
        value: timerBloc,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: ExerciseDetailScreen(
            exerciseName: '인클라인 프레스: 덤벨',
            selectedDate: DateTime(2026, 9, 28),
            initialWeight: 28,
            initialSets: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.ancestor(
      of: find.text('세트 추가'),
      matching: find.byWidgetPredicate((widget) => widget is FilledButton),
    );
    final label = find.descendant(of: action, matching: find.text('세트 추가'));
    Focus.of(tester.element(label)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getStringList(
        'exercise_sets_인클라인 프레스: 덤벨_2026-09-28',
      ),
      hasLength(2),
    );
  });

  testWidgets('rest action uses one exact pill clip in light and dark themes',
      (tester) async {
    tester.view.physicalSize = const Size(320, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var taps = 0;

    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      await tester.pumpWidget(
        MaterialApp(
          key: ValueKey(theme.brightness),
          theme: theme,
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ExerciseRestActionPill(
                isRunning: true,
                duration: 35,
                initialDuration: 70,
                allCompleted: false,
                currentSetIndex: 2,
                onPressed: () => taps++,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final material = tester.widget<Material>(
        find.byKey(const ValueKey('exercise-rest-action-pill')),
      );
      expect(
          material.borderRadius, const BorderRadius.all(Radius.circular(28)));
      expect(material.clipBehavior, Clip.antiAlias);
      expect(material.color, theme.colorScheme.surfaceContainerHighest);
      expect(
          find.byKey(const ValueKey('exercise-rest-progress')), findsOneWidget);
      final progress = tester.widget<TweenAnimationBuilder<double>>(
        find.byKey(const ValueKey('exercise-rest-progress')),
      );
      expect(progress.tween.end, 0.5);
      await tester.pump(const Duration(seconds: 1));
      final pillSize = tester.getSize(
        find.byKey(const ValueKey('exercise-rest-action-pill')),
      );
      final progressFill = find.descendant(
        of: find.byKey(const ValueKey('exercise-rest-progress')),
        matching: find.byType(ColoredBox),
      );
      final progressSize = tester.getSize(progressFill);
      expect(progressSize.height, 56);
      expect(progressSize.width, closeTo(pillSize.width * 0.5, 0.1));

      final label = tester.widget<Text>(find.text('휴식 완료'));
      expect(label.style?.color, Colors.white);
      await tester.tap(find.byKey(const ValueKey('exercise-rest-action-pill')));
      expect(tester.takeException(), isNull);
    }
    expect(taps, 2);
  });

  testWidgets('running rest action keeps contrast at every gauge position',
      (tester) async {
    tester.view.physicalSize = const Size(320, 160);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    double contrastRatio(Color foreground, Color background) {
      final foregroundLuminance = foreground.computeLuminance();
      final backgroundLuminance = background.computeLuminance();
      final lighter = foregroundLuminance > backgroundLuminance
          ? foregroundLuminance
          : backgroundLuminance;
      final darker = foregroundLuminance > backgroundLuminance
          ? backgroundLuminance
          : foregroundLuminance;
      return (lighter + 0.05) / (darker + 0.05);
    }

    const initialDuration = 70;
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final expectedGradient =
          AppColors.primaryGradientFor(theme.brightness).colors;
      for (final duration in [0, 7, 35, 63, 70]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('${theme.brightness}-$duration'),
            theme: theme,
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: ExerciseRestActionPill(
                  isRunning: true,
                  duration: duration,
                  initialDuration: initialDuration,
                  allCompleted: false,
                  currentSetIndex: 0,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        final background = tester.widget<DecoratedBox>(
          find.byKey(const ValueKey('exercise-rest-running-background')),
        );
        final gradient = (background.decoration as BoxDecoration).gradient!
            as LinearGradient;
        expect(gradient.colors, expectedGradient);
        for (final color in gradient.colors) {
          expect(
            contrastRatio(Colors.white, color),
            greaterThan(4.5),
            reason:
                '${theme.brightness}, ${duration / initialDuration} progress',
          );
        }

        final label = tester.widget<Text>(find.text('휴식 완료'));
        expect(label.style?.color, Colors.white);
        final progress = tester.widget<TweenAnimationBuilder<double>>(
          find.byKey(const ValueKey('exercise-rest-progress')),
        );
        expect(progress.tween.end, duration / initialDuration);
        expect(tester.takeException(), isNull);
      }
    }
  });
}
