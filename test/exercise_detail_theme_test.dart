import 'dart:convert';

import 'package:body_calendar/core/theme/app_theme.dart';
import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_category.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_set.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
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
      expect(label.style?.color, theme.colorScheme.onSurface);
      await tester.tap(find.byKey(const ValueKey('exercise-rest-action-pill')));
      expect(tester.takeException(), isNull);
    }
    expect(taps, 2);
  });
}
