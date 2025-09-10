import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/settings/bloc/theme_bloc.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/presentation/screens/calendar_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io' show Platform;
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/data/repositories/exercise_repository_impl.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_routine_repository.dart';
import 'package:body_calendar/features/workout/data/repositories/workout_routine_repository_impl.dart';

final GetIt getIt = GetIt.instance;

Future<void> setupLocator() async {
  final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerLazySingleton<ExerciseRepository>(() => ExerciseRepositoryImpl(getIt()));
  getIt.registerLazySingleton<WorkoutRoutineRepository>(() => WorkoutRoutineRepositoryImpl(getIt()));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupLocator(); // Initialize GetIt
  initializeDateFormatting();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => TimerBloc(ticker: const Ticker()),
        ),
        BlocProvider(
          create: (_) => ThemeBloc(getIt<SharedPreferences>()),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          title: 'Body Calendar',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeData.brightness == Brightness.dark
              ? ThemeMode.dark
              : ThemeMode.light,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('ko', 'KR'),
            Locale('en', 'US'),
          ],
          locale: const Locale('ko', 'KR'),
          home: const CalendarScreen(),
        );
      },
    );
  }
}
