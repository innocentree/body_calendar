import 'package:body_calendar/features/settings/bloc/theme_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<ThemeBloc, ThemeState>(
          builder: (context, state) {
            final isDarkMode =
                state.themeData.brightness == Brightness.dark;
            return SwitchListTile(
              title: const Text('다크 모드'),
              value: isDarkMode,
              onChanged: (value) {
                context.read<ThemeBloc>().add(ThemeChanged(isDarkMode: value));
              },
            );
          },
        ),
      ),
    );
  }
}
