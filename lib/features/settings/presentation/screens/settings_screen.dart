import 'dart:convert';
import 'dart:io';

import 'package:body_calendar/features/settings/bloc/theme_bloc.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_repository.dart';
import 'package:body_calendar/features/workout/domain/repositories/workout_routine_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _useLbs = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useLbs = prefs.getBool('use_lbs') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _toggleWeightUnit(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('use_lbs', value);
    setState(() {
      _useLbs = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '앱 설정',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  '테마, 단위, 데이터 관리 옵션을 한곳에서 정리해보세요.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.68),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionHeader(context, '일반'),
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              final isDarkMode =
                  state.themeData.brightness == Brightness.dark;
              return SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                title: const Text('다크 모드'),
                subtitle: const Text('차분한 다크 테마로 전환해요.'),
                value: isDarkMode,
                onChanged: (value) {
                  context
                      .read<ThemeBloc>()
                      .add(ThemeChanged(isDarkMode: value));
                },
              );
            },
          ),
          if (!_isLoading)
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: const Text('무게 단위 (Lbs)'),
              subtitle: Text(_useLbs ? '현재 단위: 파운드 (lbs)' : '현재 단위: 킬로그램 (kg)'),
              value: _useLbs,
              onChanged: _toggleWeightUnit,
            ),
          const Divider(height: 32),
          _buildSectionHeader(context, '데이터 관리'),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Theme.of(context).cardTheme.color,
            leading: const Icon(Icons.download),
            title: const Text('데이터 백업'),
            subtitle: const Text('운동 기록과 루틴을 파일로 저장해요.'),
            onTap: () => _backupData(context),
          ),
          const SizedBox(height: 10),
          ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            tileColor: Theme.of(context).cardTheme.color,
            leading: const Icon(Icons.upload),
            title: const Text('데이터 복원'),
            subtitle: const Text('백업 파일로 데이터를 복원해요. 기존 데이터는 새 데이터로 대체돼요.'),
            onTap: () => _restoreData(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
      ),
    );
  }

  Future<void> _backupData(BuildContext context) async {
    try {
      final workoutRepo = GetIt.I<WorkoutRepository>();
      final routineRepo = GetIt.I<WorkoutRoutineRepository>();

      final workoutsJson = await workoutRepo.getWorkoutsJson();
      final routinesJson = await routineRepo.getRoutinesJson();

      final backupData = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'workouts': jsonDecode(workoutsJson),
        'routines': jsonDecode(routinesJson),
      };

      final jsonString = jsonEncode(backupData);
      final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
      final fileName = 'body_calendar_backup_$dateStr.json';

      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        // Desktop: Save dialog
        final String? outputFile = await FilePicker.platform.saveFile(
          dialogTitle: '백업 파일 저장하기',
          fileName: fileName,
          allowedExtensions: ['json'],
          type: FileType.custom,
        );

        if (outputFile != null) {
          final file = File(outputFile);
          await file.writeAsString(jsonString);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('백업 파일을 저장했어요: $outputFile')),
            );
          }
        }
      } else {
        // Mobile: Share sheet
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(jsonString);

        final result = await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            text: 'PumpingDay 데이터 백업 ($dateStr)',
            subject: 'PumpingDay 백업 파일',
          ),
        );

        if (result.status == ShareResultStatus.success) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('백업 파일을 준비했어요.')),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 중 문제가 생겼어요: $e')),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();
        final Map<String, dynamic> backupData = jsonDecode(jsonString);

        // 간단한 유효성 검사
        if (!backupData.containsKey('workouts') ||
            !backupData.containsKey('routines')) {
          throw Exception('백업 파일 형식이 올바르지 않아요.');
        }

        final workoutRepo = GetIt.I<WorkoutRepository>();
        final routineRepo = GetIt.I<WorkoutRoutineRepository>();

        if (backupData['workouts'] != null) {
          await workoutRepo
              .restoreWorkoutsFromJson(jsonEncode(backupData['workouts']));
        }
        if (backupData['routines'] != null) {
          await routineRepo
              .restoreRoutinesFromJson(jsonEncode(backupData['routines']));
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('데이터를 복원했어요. 앱을 다시 열어 주세요.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복원 중 문제가 생겼어요: $e')),
        );
      }
    }
  }
}
