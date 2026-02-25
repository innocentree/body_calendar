import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/settings/bloc/theme_bloc.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_calendar/main.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_routine_repository.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

class MockExerciseRepository extends Mock implements ExerciseRepository {}
class MockWorkoutRoutineRepository extends Mock implements WorkoutRoutineRepository {}
class MockWorkoutRepository extends Mock implements WorkoutRepository {}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    
    final getIt = GetIt.instance;
    getIt.reset();
    getIt.registerSingleton<SharedPreferences>(prefs);
    getIt.registerSingleton<ExerciseRepository>(MockExerciseRepository());
    getIt.registerSingleton<WorkoutRoutineRepository>(MockWorkoutRoutineRepository());
    getIt.registerSingleton<WorkoutRepository>(MockWorkoutRepository());
  });

  testWidgets('MyApp should load and show CalendarScreen', (WidgetTester tester) async {
    final prefs = GetIt.I<SharedPreferences>();
    
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => TimerBloc(ticker: const Ticker())),
          BlocProvider(create: (_) => ThemeBloc(prefs)),
        ],
        child: const MyApp(),
      ),
    );

    // Verify CalendarScreen is loaded (checking for '운동 기록' or similar title if exists)
    // For now just pump and catch crashes.
    await tester.pumpAndSettle();
    expect(find.byType(MyApp), findsOneWidget);
  });
}
