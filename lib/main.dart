import 'dart:io';

import 'package:window_manager/window_manager.dart';

import 'package:body_calendar/core/config/cloud_sync_config.dart';
import 'package:body_calendar/core/navigation/app_navigator.dart';
import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/settings/bloc/theme_bloc.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/timer/presentation/widgets/timer_overlay_manager.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_wakelock.dart';
import 'features/calendar/presentation/screens/calendar_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:body_calendar/features/workout/data/repositories/exercise_repository_impl.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_routine_repository.dart';
import 'package:body_calendar/features/workout/data/repositories/workout_routine_repository_impl.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:body_calendar/features/workout/data/repositories/workout_repository_impl.dart';

final GetIt getIt = GetIt.instance;
Future<void> setupLocator() async {
  final SharedPreferences sharedPreferences =
      await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  getIt.registerLazySingleton<ExerciseRepository>(
      () => ExerciseRepositoryImpl(getIt()));
  getIt.registerLazySingleton<WorkoutRoutineRepository>(
      () => WorkoutRoutineRepositoryImpl(getIt()));
  getIt.registerLazySingleton<WorkoutRepository>(
      () => WorkoutRepositoryImpl(getIt()));
  getIt
      .registerLazySingleton<CloudSyncService>(() => CloudSyncService(getIt()));
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CloudSyncConfig.load();
  if (CloudSyncConfig.isConfigured) {
    await Supabase.initialize(
      url: CloudSyncConfig.supabaseUrl,
      anonKey: CloudSyncConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    // 기본적인 창 옵션 설정 (필요시)
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
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
      child: const AppWakelock(
        child: TimerOverlayManager(child: MyApp()),
      ),
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
          navigatorKey: navigatorKey,
          navigatorObservers: [appNavigatorObserver],
          title: '펌핑데이',
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
          scrollBehavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.mouse,
              PointerDeviceKind.touch,
              PointerDeviceKind.stylus,
              PointerDeviceKind.unknown,
            },
          ),
          home: const CalendarScreen(),
        );
      },
    );
  }
}
