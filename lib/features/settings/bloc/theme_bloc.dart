import 'dart:async';

import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final SharedPreferences _prefs;

  ThemeBloc(this._prefs) : super(_initialState(_prefs)) {
    on<ThemeChanged>(_onThemeChanged);
  }

  static ThemeState _initialState(SharedPreferences prefs) {
    final isDarkMode = prefs.getBool('isDarkMode') ?? false;
    return ThemeState(
      themeData: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
    );
  }

  void _onThemeChanged(ThemeChanged event, Emitter<ThemeState> emit) {
    final isDarkMode = event.isDarkMode;
    _prefs.setBool('isDarkMode', isDarkMode);
    unawaited(GetIt.I<CloudSyncService>().notifyLocalChange());
    emit(ThemeState(
      themeData: isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
    ));
  }
}
