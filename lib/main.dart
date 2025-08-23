import 'package:flutter/material.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Calendar',
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.light(
          primary: Colors.deepPurple,
          onPrimary: Colors.white,
          background: Colors.white,
          onBackground: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        useMaterial3: true,
        tabBarTheme: const TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
      themeMode: ThemeMode.light,
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
      debugShowCheckedModeBanner: false,
      // navigatorObservers: [routeObserver],
    );
  }
}
