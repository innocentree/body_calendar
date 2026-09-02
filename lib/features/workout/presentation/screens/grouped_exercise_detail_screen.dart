import 'dart:async';
import 'dart:convert';

import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:body_calendar/features/cloud_sync/data/services/cloud_sync_service.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/exercise.dart';
import 'package:body_calendar/features/workout/domain/models/exercise_set.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/domain/repositories/exercise_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _detailSurface = AppColors.surfaceDark;
const _detailSoftSurface = AppColors.customSurface;
const _detailMutedText = AppColors.textSecondaryDark;

class GroupedExerciseDetailScreen extends StatefulWidget {
  final List<WorkoutRecord> workouts;
  final DateTime selectedDate;
  final int recordDay;

  const GroupedExerciseDetailScreen({
    super.key,
    required this.workouts,
    required this.selectedDate,
    required this.recordDay,
  });

  @override
  State<GroupedExerciseDetailScreen> createState() =>
      _GroupedExerciseDetailScreenState();
}

class _GroupedExerciseDetailScreenState
    extends State<GroupedExerciseDetailScreen> {
  late final ExerciseRepository _exerciseRepository;
  late SharedPreferences _prefs;
  late final List<WorkoutRecord> _workouts;
  final Map<String, Exercise?> _exerciseByName = {};
  final Map<String, List<ExerciseSet>> _setsByExerciseName = {};
  bool _isLoading = true;
  final double _weightStep = 5.0;
  final int _repStep = 1;

  @override
  void initState() {
    super.initState();
    _exerciseRepository = GetIt.I<ExerciseRepository>();
    _workouts = [...widget.workouts]
      ..sort((a, b) => (a.groupOrder ?? 0).compareTo(b.groupOrder ?? 0));
    _initialize();
  }

  Future<void> _initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAndSetFirstRecordDate();
    for (final workout in _workouts) {
      _exerciseByName[workout.name] =
          await _exerciseRepository.getExerciseByName(workout.name);
      _setsByExerciseName[workout.name] = _loadSets(workout.name);
    }

    final maxCount = _resolvedRoundCount();
    _ensureRoundCount(maxCount == 0 ? 1 : maxCount, persist: false);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<ExerciseSet> _loadSets(String exerciseName) {
    final setsJson = _prefs.getStringList(_storageKey(exerciseName)) ?? [];
    return setsJson
        .map((json) => ExerciseSet.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> _checkAndSetFirstRecordDate() async {
    const key = 'first_record_date';
    if (_prefs.containsKey(key)) return;
    final todayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    await _prefs.setString(key, todayStr);
  }

  String _storageKey(String exerciseName) {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    return 'exercise_sets_${exerciseName}_$dateStr';
  }

  int _resolvedRoundCount() {
    var count = 0;
    for (final workout in _workouts) {
      count = count < (_setsByExerciseName[workout.name]?.length ?? 0)
          ? (_setsByExerciseName[workout.name]?.length ?? 0)
          : count;
    }
    return count;
  }

  ExerciseSet _buildDefaultSet(WorkoutRecord workout) {
    final exercise = _exerciseByName[workout.name];
    final existing = _setsByExerciseName[workout.name];
    final last = existing != null && existing.isNotEmpty ? existing.last : null;

    return ExerciseSet(
      weight: last?.weight ?? workout.weight,
      reps: last?.reps ?? 12,
      restTime: last?.restTime ?? const Duration(minutes: 1),
      bodyWeight:
          last?.bodyWeight ?? (exercise?.isAssisted == true ? 70.0 : null),
      assistedWeight:
          last?.assistedWeight ?? (exercise?.isAssisted == true ? 0.0 : null),
      isLbs: last?.isLbs ?? false,
    );
  }

  void _ensureRoundCount(int count, {bool persist = true}) {
    var changed = false;
    for (final workout in _workouts) {
      final sets = _setsByExerciseName.putIfAbsent(workout.name, () => []);
      while (sets.length < count) {
        sets.add(_buildDefaultSet(workout));
        changed = true;
      }
    }
    if (changed && persist) {
      unawaited(_persistAllSets());
    }
  }

  Future<void> _persistAllSets({bool triggerSync = false}) async {
    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name] ?? [];
      await _prefs.setStringList(
        _storageKey(workout.name),
        sets.map((set) => jsonEncode(set.toJson())).toList(),
      );
      await _updateRecordedDates(workout.name, sets);
    }
    if (triggerSync) {
      await GetIt.I<CloudSyncService>().notifyLocalChange();
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateRecordedDates(
      String exerciseName, List<ExerciseSet> sets) async {
    final key = 'recorded_dates_$exerciseName';
    final todayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final recordedDates = _prefs.getStringList(key) ?? [];
    recordedDates.removeWhere((value) => value.isEmpty);
    if (sets.isNotEmpty) {
      if (!recordedDates.contains(todayStr)) {
        recordedDates.add(todayStr);
      }
    } else {
      recordedDates.remove(todayStr);
    }
    await _prefs.setStringList(key, recordedDates.toSet().toList()..sort());
  }

  int get _currentRoundIndex {
    final rounds = _resolvedRoundCount();
    for (var i = 0; i < rounds; i++) {
      if (!_isRoundFullyCompleted(i)) {
        return i;
      }
    }
    return rounds == 0 ? 0 : rounds - 1;
  }

  bool _isRoundFullyCompleted(int roundIndex) {
    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name] ?? [];
      if (roundIndex >= sets.length || !sets[roundIndex].isCompleted) {
        return false;
      }
    }
    return true;
  }

  int get _completedRoundCount {
    final rounds = _resolvedRoundCount();
    var count = 0;
    for (var i = 0; i < rounds; i++) {
      if (_isRoundFullyCompleted(i)) count++;
    }
    return count;
  }

  int get _completedSetCount {
    var count = 0;
    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name] ?? const <ExerciseSet>[];
      count += sets.where((set) => set.isCompleted).length;
    }
    return count;
  }

  double get _totalCompletedVolume {
    var total = 0.0;
    for (final workout in _workouts) {
      final exercise = _exerciseByName[workout.name];
      if (exercise?.needsWeight == false) continue;
      final sets = _setsByExerciseName[workout.name] ?? const <ExerciseSet>[];
      for (final set in sets) {
        if (set.isCompleted) {
          total += set.weight * set.reps;
        }
      }
    }
    return total;
  }

  int get _completedWorkSeconds {
    var total = 0;
    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name] ?? const <ExerciseSet>[];
      for (final set in sets) {
        if (!set.isCompleted) continue;
        if (set.startTime != null && set.endTime != null) {
          total += set.endTime!.difference(set.startTime!).inSeconds;
        } else {
          total += set.restTime.inSeconds;
        }
      }
    }
    return total;
  }

  Duration _roundRestTime(int roundIndex) {
    var seconds = 60;
    for (final workout in _workouts) {
      final set = (_setsByExerciseName[workout.name] ??
          const <ExerciseSet>[])[roundIndex];
      if (set.restTime.inSeconds > seconds) {
        seconds = set.restTime.inSeconds;
      }
    }
    return Duration(seconds: seconds);
  }

  Future<void> _setRoundRestTime(int roundIndex, Duration duration) async {
    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name]!;
      sets[roundIndex] = sets[roundIndex].copyWith(restTime: duration);
    }
    await _persistAllSets();
  }

  Future<void> _addRound() async {
    _ensureRoundCount(_resolvedRoundCount() + 1, persist: false);
    await _persistAllSets();
  }

  Future<void> _removeRound(int roundIndex) async {
    if (_resolvedRoundCount() <= 1) return;
    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name]!;
      if (roundIndex < sets.length) {
        sets.removeAt(roundIndex);
      }
    }
    await _persistAllSets(triggerSync: true);
  }

  Future<void> _updateSet(
    WorkoutRecord workout,
    int roundIndex,
    ExerciseSet Function(ExerciseSet current) transform,
  ) async {
    final sets = _setsByExerciseName[workout.name]!;
    sets[roundIndex] = transform(sets[roundIndex]);
    await _persistAllSets();
  }

  Future<void> _toggleComplete(WorkoutRecord workout, int roundIndex) async {
    final sets = _setsByExerciseName[workout.name]!;
    final current = sets[roundIndex];
    final willComplete = !current.isCompleted;
    final wasRoundComplete = _isRoundFullyCompleted(roundIndex);

    sets[roundIndex] = current.copyWith(
      isCompleted: willComplete,
      endTime: willComplete ? DateTime.now() : null,
    );
    await _persistAllSets(triggerSync: true);

    if (willComplete &&
        !wasRoundComplete &&
        _isRoundFullyCompleted(roundIndex)) {
      final duration = _roundRestTime(roundIndex).inSeconds;
      context.read<TimerBloc>().add(TimerStarted(
            duration: duration,
            exerciseName: _workouts.map((w) => w.name).join(' · '),
            selectedDate: widget.selectedDate,
          ));
    }
  }

  Future<void> _toggleRoundCompletion(int roundIndex) async {
    final shouldComplete = !_isRoundFullyCompleted(roundIndex);
    final wasRoundComplete = _isRoundFullyCompleted(roundIndex);

    for (final workout in _workouts) {
      final sets = _setsByExerciseName[workout.name]!;
      final current = sets[roundIndex];
      sets[roundIndex] = current.copyWith(
        isCompleted: shouldComplete,
        endTime: shouldComplete ? DateTime.now() : null,
      );
    }

    await _persistAllSets(triggerSync: true);

    if (shouldComplete && !wasRoundComplete) {
      final duration = _roundRestTime(roundIndex).inSeconds;
      context.read<TimerBloc>().add(TimerStarted(
            duration: duration,
            exerciseName: _workouts.map((w) => w.name).join(' · '),
            selectedDate: widget.selectedDate,
          ));
    }
  }

  Future<double?> _showNumberInputDialog(
    String title,
    double initialValue, {
    bool isInt = false,
  }) async {
    final controller = TextEditingController(
      text: isInt
          ? initialValue.toInt().toString()
          : initialValue.toStringAsFixed(1),
    );

    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor,
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: const InputDecoration(
            hintText: '값 입력',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              final raw = controller.text.trim();
              final parsed =
                  isInt ? int.tryParse(raw)?.toDouble() : double.tryParse(raw);
              Navigator.pop(context, parsed);
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _groupTypeLabel(String? groupType) {
    switch (groupType) {
      case 'superset':
        return '슈퍼세트';
      case 'compound':
        return '컴파운드 세트';
      default:
        return '그룹';
    }
  }

  Color _groupAccentColor(String? groupType) {
    switch (groupType) {
      case 'superset':
        return const Color(0xFF8B5CF6);
      case 'compound':
        return const Color(0xFFF97316);
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _weightText(ExerciseSet set) {
    return set.isLbs
        ? '${(set.weight * 2.20462).toStringAsFixed(1)}lb'
        : '${set.weight.toStringAsFixed(1)}kg';
  }

  String _formatVolume(double kg) {
    if (kg >= 1000) {
      return '${(kg / 1000).toStringAsFixed(1)}톤';
    }
    return '${kg.toStringAsFixed(0)}kg';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _groupAccentColor(_workouts.first.groupType);
    final groupLabel = _groupTypeLabel(_workouts.first.groupType);
    final badge = _workouts.first.groupLabel == null
        ? ''
        : ' ${_workouts.first.groupLabel}';
    final roundCount = _resolvedRoundCount();
    final screenWidth = MediaQuery.sizeOf(context).width;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final useCompactLayout = screenWidth < 420 || textScale > 1.05;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '$groupLabel$badge',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      floatingActionButton: useCompactLayout
          ? FloatingActionButton(
              onPressed: _isLoading ? null : _addRound,
              backgroundColor: accent,
              foregroundColor: Colors.white,
              tooltip: '라운드 추가',
              child: const Icon(Icons.add),
            )
          : FloatingActionButton.extended(
              onPressed: _isLoading ? null : _addRound,
              backgroundColor: accent,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('라운드 추가'),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: accent.withValues(alpha: 0.45)),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compactHeader =
                          constraints.maxWidth < 430 || textScale > 1.05;
                      final currentRoundCard = Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentRoundIndex + 1}',
                              style: TextStyle(
                                color: accent,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '현재 라운드',
                              style: TextStyle(
                                color: accent.withValues(alpha: 0.9),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      );

                      final summaryText = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _workouts.map((w) => w.name).join(' · '),
                            maxLines: compactHeader ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.titleLarge?.color,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '두 운동을 모두 완료해야 휴식 타이머가 시작돼요.',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoPill(
                                label:
                                    '운동 ${widget.recordDay > 0 ? '${widget.recordDay}번째 기록' : '기록'}',
                                color: accent,
                              ),
                              _InfoPill(
                                label:
                                    '완료 라운드 $_completedRoundCount/$roundCount',
                                color: Colors.greenAccent,
                              ),
                            ],
                          ),
                        ],
                      );

                      if (compactHeader) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            summaryText,
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: currentRoundCard,
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: summaryText),
                          const SizedBox(width: 12),
                          currentRoundCard,
                        ],
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: '완료 세트',
                          value: '$_completedSetCount개',
                          subtitle: '${_workouts.length}개 운동',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          title: '볼륨',
                          value: _formatVolume(_totalCompletedVolume),
                          subtitle: '완료 세트 기준',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryCard(
                          title: '진행 시간',
                          value: _formatDuration(
                              Duration(seconds: _completedWorkSeconds)),
                          subtitle: '대략치',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: BlocBuilder<TimerBloc, TimerState>(
                    builder: (context, timerState) {
                      if (timerState is! TimerRunInProgress &&
                          timerState is! TimerRunPause) {
                        return const SizedBox.shrink();
                      }

                      final timerBloc = context.read<TimerBloc>();
                      final isPaused = timerState is TimerRunPause;
                      final totalSeconds = timerState is TimerRunInProgress
                          ? timerState.initialDuration
                          : (timerState as TimerRunPause).initialDuration;
                      final progress = totalSeconds <= 0
                          ? 0.0
                          : (timerState.duration / totalSeconds)
                              .clamp(0.0, 1.0)
                              .toDouble();

                      return _RoundRestTimerCard(
                        accent: accent,
                        title: timerBloc.exerciseName ?? '$groupLabel$badge',
                        remainingText: _formatDuration(
                          Duration(seconds: timerState.duration),
                        ),
                        progress: progress,
                        isPaused: isPaused,
                        onPauseResume: () {
                          context.read<TimerBloc>().add(
                                isPaused
                                    ? const TimerResumed()
                                    : const TimerPaused(),
                              );
                        },
                        onReset: () {
                          context.read<TimerBloc>().add(const TimerReset());
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: roundCount,
                    itemBuilder: (context, roundIndex) {
                      final isCurrent = roundIndex == _currentRoundIndex;
                      final isDone = _isRoundFullyCompleted(roundIndex);
                      final rest = _roundRestTime(roundIndex);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isCurrent
                                ? accent.withValues(alpha: 0.75)
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compactActions = constraints.maxWidth < 460 ||
                                    textScale > 1.05;
                                final roundBadge = Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: (isDone ? Colors.green : accent)
                                        .withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '${roundIndex + 1}라운드',
                                    style: TextStyle(
                                      color:
                                          isDone ? Colors.greenAccent : accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                );

                                final restButton = TextButton.icon(
                                  onPressed: () async {
                                    final value = await _showNumberInputDialog(
                                      '휴식 시간(초)',
                                      rest.inSeconds.toDouble(),
                                      isInt: true,
                                    );
                                    if (value != null) {
                                      await _setRoundRestTime(
                                        roundIndex,
                                        Duration(
                                            seconds:
                                                value.toInt().clamp(0, 3600)),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.timer_outlined,
                                      size: 18),
                                  label: Text(_formatDuration(rest)),
                                );

                                final completeButton = FilledButton.tonalIcon(
                                  onPressed: () =>
                                      _toggleRoundCompletion(roundIndex),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: isDone
                                        ? Theme.of(context)
                                            .dividerColor
                                            .withValues(alpha: 0.35)
                                        : accent.withValues(alpha: 0.16),
                                    foregroundColor: isDone
                                        ? Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withValues(alpha: 0.72)
                                        : accent,
                                  ),
                                  icon: Icon(isDone
                                      ? Icons.undo_rounded
                                      : Icons.done_all_rounded),
                                  label: Text(
                                    isDone ? '라운드 되돌리기' : '라운드 완료',
                                  ),
                                );

                                final deleteButton = roundCount > 1
                                    ? FilledButton.tonalIcon(
                                        onPressed: () => _removeRound(roundIndex),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: Colors.red
                                              .withValues(alpha: 0.12),
                                          foregroundColor: Colors.redAccent,
                                        ),
                                        icon: const Icon(Icons.delete_outline),
                                        label: const Text('라운드 삭제'),
                                      )
                                    : null;

                                if (compactActions) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          roundBadge,
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          restButton,
                                          completeButton,
                                          if (deleteButton != null) deleteButton,
                                        ],
                                      ),
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    roundBadge,
                                    const Spacer(),
                                    restButton,
                                    const SizedBox(width: 8),
                                    completeButton,
                                    if (deleteButton != null) ...[
                                      const SizedBox(width: 8),
                                      deleteButton,
                                    ],
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: (_workouts
                                      .where((workout) => _setsByExerciseName[
                                              workout.name]![roundIndex]
                                          .isCompleted)
                                      .length) /
                                  _workouts.length,
                              minHeight: 8,
                              borderRadius: BorderRadius.circular(999),
                              backgroundColor: Theme.of(context)
                                  .dividerColor
                                  .withValues(alpha: 0.35),
                              valueColor: AlwaysStoppedAnimation<Color>(accent),
                            ),
                            const SizedBox(height: 12),
                            ..._workouts.map((workout) {
                              final exercise = _exerciseByName[workout.name];
                              final set = _setsByExerciseName[workout.name]![
                                  roundIndex];
                              return _ExerciseRoundCard(
                                accent: accent,
                                workout: workout,
                                exercise: exercise,
                                set: set,
                                weightText: _weightText(set),
                                onDecreaseWeight: (exercise?.needsWeight ??
                                        true)
                                    ? () => _updateSet(
                                          workout,
                                          roundIndex,
                                          (current) => current.copyWith(
                                            weight:
                                                (current.weight - _weightStep)
                                                    .clamp(0, 9999),
                                          ),
                                        )
                                    : null,
                                onIncreaseWeight: (exercise?.needsWeight ??
                                        true)
                                    ? () => _updateSet(
                                          workout,
                                          roundIndex,
                                          (current) => current.copyWith(
                                              weight:
                                                  current.weight + _weightStep),
                                        )
                                    : null,
                                onTapWeight: (exercise?.needsWeight ?? true)
                                    ? () async {
                                        final value =
                                            await _showNumberInputDialog(
                                          '${workout.name} 무게',
                                          set.weight,
                                        );
                                        if (value != null) {
                                          await _updateSet(
                                            workout,
                                            roundIndex,
                                            (current) =>
                                                current.copyWith(weight: value),
                                          );
                                        }
                                      }
                                    : null,
                                onDecreaseReps: () => _updateSet(
                                  workout,
                                  roundIndex,
                                  (current) => current.copyWith(
                                    reps:
                                        (current.reps - _repStep).clamp(1, 999),
                                  ),
                                ),
                                onIncreaseReps: () => _updateSet(
                                  workout,
                                  roundIndex,
                                  (current) => current.copyWith(
                                      reps: current.reps + _repStep),
                                ),
                                onTapReps: () async {
                                  final value = await _showNumberInputDialog(
                                    '${workout.name} 횟수',
                                    set.reps.toDouble(),
                                    isInt: true,
                                  );
                                  if (value != null) {
                                    await _updateSet(
                                      workout,
                                      roundIndex,
                                      (current) => current.copyWith(
                                          reps: value.toInt().clamp(1, 999)),
                                    );
                                  }
                                },
                                onToggleComplete: () =>
                                    _toggleComplete(workout, roundIndex),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _ExerciseRoundCard extends StatelessWidget {
  final Color accent;
  final WorkoutRecord workout;
  final Exercise? exercise;
  final ExerciseSet set;
  final String weightText;
  final VoidCallback? onDecreaseWeight;
  final VoidCallback? onIncreaseWeight;
  final VoidCallback? onTapWeight;
  final VoidCallback onDecreaseReps;
  final VoidCallback onIncreaseReps;
  final VoidCallback onTapReps;
  final VoidCallback onToggleComplete;

  const _ExerciseRoundCard({
    required this.accent,
    required this.workout,
    required this.exercise,
    required this.set,
    required this.weightText,
    required this.onDecreaseWeight,
    required this.onIncreaseWeight,
    required this.onTapWeight,
    required this.onDecreaseReps,
    required this.onIncreaseReps,
    required this.onTapReps,
    required this.onToggleComplete,
  });

  @override
  Widget build(BuildContext context) {
    final needsWeight = exercise?.needsWeight ?? true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final compactHeader = constraints.maxWidth < 340 || textScale > 1.05;
              final titleSection = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name,
                    maxLines: compactHeader ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    workout.equipment.isNotEmpty
                        ? workout.equipment
                        : (workout.bodyPart ?? '세트 기록'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: _detailMutedText),
                  ),
                ],
              );

              final completeButton = FilledButton.tonal(
                onPressed: onToggleComplete,
                style: FilledButton.styleFrom(
                  backgroundColor: set.isCompleted
                      ? Colors.green.withValues(alpha: 0.18)
                      : accent.withValues(alpha: 0.16),
                  foregroundColor:
                      set.isCompleted ? Colors.greenAccent : accent,
                ),
                child: Text(set.isCompleted ? '완료됨' : '완료'),
              );

              if (compactHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleSection,
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: completeButton,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleSection),
                  const SizedBox(width: 12),
                  completeButton,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              if (needsWeight)
                _AdjustChip(
                  label: '무게',
                  value: weightText,
                  onTapValue: onTapWeight,
                  onMinus: onDecreaseWeight,
                  onPlus: onIncreaseWeight,
                ),
              _AdjustChip(
                label: '횟수',
                value: '${set.reps}회',
                onTapValue: onTapReps,
                onMinus: onDecreaseReps,
                onPlus: onIncreaseReps,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdjustChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onTapValue;
  final VoidCallback? onMinus;
  final VoidCallback? onPlus;

  const _AdjustChip({
    required this.label,
    required this.value,
    this.onTapValue,
    this.onMinus,
    this.onPlus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: _detailMutedText)),
          const SizedBox(width: 10),
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: onMinus,
            icon: Icon(Icons.remove_circle_outline,
                color: Theme.of(context).iconTheme.color),
          ),
          GestureDetector(
            onTap: onTapValue,
            child: SizedBox(
              width: 78,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconButton(
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: onPlus,
            icon: Icon(Icons.add_circle_outline,
                color: Theme.of(context).iconTheme.color),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final Color color;

  const _InfoPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _detailMutedText,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).textTheme.titleLarge?.color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _detailMutedText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundRestTimerCard extends StatelessWidget {
  final Color accent;
  final String title;
  final String remainingText;
  final double progress;
  final bool isPaused;
  final VoidCallback onPauseResume;
  final VoidCallback onReset;

  const _RoundRestTimerCard({
    required this.accent,
    required this.title,
    required this.remainingText,
    required this.progress,
    required this.isPaused,
    required this.onPauseResume,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Icon(Icons.timer_outlined, color: accent),
              Text(
                '라운드 간 휴식',
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleMedium?.color,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (isPaused)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '일시정지',
                    style: TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            remainingText,
            style: TextStyle(
              color: accent,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(999),
            backgroundColor:
                Theme.of(context).dividerColor.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: onPauseResume,
                icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                label: Text(isPaused ? '재개' : '일시정지'),
              ),
              TextButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.close_rounded),
                label: const Text('닫기'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
