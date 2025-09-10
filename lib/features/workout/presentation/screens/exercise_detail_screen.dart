import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/exercise.dart';
import 'dart:async';
import 'package:screen_brightness/screen_brightness.dart';
import 'dart:io';
import 'package:body_calendar/features/calendar/presentation/widgets/overlay_helper_impl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';

class ExerciseSet {
  final double weight;
  final int reps;
  final Duration restTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;

  ExerciseSet({
    required this.weight,
    required this.reps,
    this.restTime = const Duration(minutes: 1),
    this.startTime,
    this.endTime,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
        'restTime': restTime.inSeconds,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isCompleted': isCompleted,
      };

  factory ExerciseSet.fromJson(Map<String, dynamic> json) => ExerciseSet(
        weight: (json['weight'] is int)
            ? (json['weight'] as int).toDouble()
            : (json['weight'] is double)
                ? json['weight']
                : double.tryParse(json['weight'].toString()) ?? 0.0,
        reps: json['reps'],
        restTime: Duration(seconds: json['restTime']),
        startTime:
            json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
        endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        isCompleted: json['isCompleted'],
      );

  ExerciseSet copyWith({
    double? weight,
    int? reps,
    Duration? restTime,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
  }) {
    return ExerciseSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class ExerciseDetailScreen extends StatefulWidget {
  final String exerciseName;
  final DateTime selectedDate;
  final int initialWeight;
  final int initialSets;
  final int recordDay;

  const ExerciseDetailScreen({
    super.key,
    required this.exerciseName,
    required this.selectedDate,
    required this.initialWeight,
    required this.initialSets,
    this.recordDay = 0,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with WidgetsBindingObserver {
  List<ExerciseSet> _sets = [];
  double _currentWeight = 0;
  int _currentReps = 12;
  Duration _currentRestTime = const Duration(minutes: 1);
  int _currentSetIndex = 0;
  late SharedPreferences _prefs;

  // 증가/감소 단위 변수 수정
  double _weightStep = 5.0;
  int _repsStep = 1;
  int _restTimeStep = 30;
  final AudioPlayer _audioPlayer = AudioPlayer();

  DateTime? _firstRecordDate;
  List<String> _recordedDates = [];

  // 드롭다운 상태 관리
  List<ExpansionTileController> _tileControllers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentWeight = widget.initialWeight.toDouble();
    _initializePrefs();
    // 화면이 꺼지지 않게 설정
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _audioPlayer.dispose(); // Dispose audio player
    super.dispose();
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    await _checkAndSetFirstRecordDate();
    await _loadPreviousExerciseSets();
    _loadSets();
    if (_sets.isEmpty) {
      setState(() {
        _sets.add(ExerciseSet(
          weight: _currentWeight,
          reps: _currentReps,
          restTime: _currentRestTime,
        ));
        _saveSets();
      });
    }
    // 드롭다운 상태 초기화
    _tileControllers =
        List.generate(_sets.length, (index) => ExpansionTileController());
  }

  Future<void> _checkAndSetFirstRecordDate() async {
    final key = 'first_record_date';
    final todayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    if (!_prefs.containsKey(key)) {
      await _prefs.setString(key, todayStr);
      _firstRecordDate = widget.selectedDate;
    } else {
      final saved = _prefs.getString(key);
      try {
        if (saved != null && saved.length >= 10) {
          _firstRecordDate = DateTime.parse(saved);
        } else {
          _firstRecordDate = widget.selectedDate;
        }
      } catch (e) {
        _firstRecordDate = widget.selectedDate;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _updateRecordedDates() async {
    final key = 'recorded_dates_${widget.exerciseName}';
    final todayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    try {
      _recordedDates = _prefs.getStringList(key) ?? [];
      _recordedDates.removeWhere((e) => e == null || e.isEmpty);
      if (_sets.isNotEmpty) {
        if (!_recordedDates.contains(todayStr)) {
          _recordedDates.add(todayStr);
        }
      } else {
        _recordedDates.remove(todayStr);
      }
      _recordedDates = _recordedDates.toSet().toList()..sort();
      await _prefs.setStringList(key, _recordedDates);
      if (mounted) setState(() {});
    } catch (e, st) {
      debugPrint('Error in _updateRecordedDates: $e\n$st');
      // 예외 발생 시 기록일 리스트를 강제로 초기화
      await _prefs.setStringList(key, []);
      _recordedDates = [];
      if (mounted) setState(() {});
    }
  }

  void _loadSets() {
    try {
      final key = _getStorageKey();
      final setsJson = _prefs.getStringList(key) ?? [];
      setState(() {
        _sets = setsJson
            .map((json) => ExerciseSet.fromJson(jsonDecode(json)))
            .toList();
        // 완료되지 않은 첫 세트로 인덱스 이동, 모두 완료면 마지막 세트
        final firstIncomplete = _sets.indexWhere((set) => !set.isCompleted);
        if (firstIncomplete == -1) {
          _currentSetIndex = _sets.isEmpty ? 0 : _sets.length - 1;
        } else {
          _currentSetIndex = firstIncomplete;
        }
      });
      _updateRecordedDates();
    } catch (e) {
      debugPrint('Error loading sets: $e');
    }
  }

  Future<void> _saveSets() async {
    try {
      final key = _getStorageKey();
      final setsJson = _sets.map((set) => jsonEncode(set.toJson())).toList();
      await _prefs.setStringList(key, setsJson);
    } catch (e) {
      debugPrint('Error saving sets: $e');
    }
  }

  String _getStorageKey() {
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    return 'exercise_sets_${widget.exerciseName}_$dateStr';
  }

  void _addSet() {
    setState(() {
      final allPreviousSetsCompleted = _sets.every((set) => set.isCompleted);

      // 이전 세트가 있으면 그 정보를 사용, 없으면 현재 설정된 값 사용
      final lastSet = _sets.isNotEmpty ? _sets.last : null;
      _sets.add(ExerciseSet(
        weight: lastSet?.weight ?? _currentWeight,
        reps: lastSet?.reps ?? _currentReps,
        restTime: lastSet?.restTime ?? _currentRestTime,
      ));
      _tileControllers.add(ExpansionTileController());

      _saveSets();
    });
    _updateRecordedDates();
  }

  void _removeSet(int index) {
    setState(() {
      _sets.removeAt(index);
      _tileControllers.removeAt(index);
      if (_currentSetIndex >= _sets.length) {
        _currentSetIndex = _sets.isEmpty ? 0 : _sets.length - 1;
      }
      _saveSets();
    });
    _updateRecordedDates();
  }

  void _completeSet() {
    if (_sets.isEmpty || _currentSetIndex >= _sets.length) return;

    final timerDuration = _sets[_currentSetIndex].restTime.inSeconds;
    context.read<TimerBloc>().add(TimerStarted(
        duration: timerDuration,
        exerciseName: widget.exerciseName,
        selectedDate: widget.selectedDate));

    setState(() {
      _sets[_currentSetIndex] = _sets[_currentSetIndex].copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
      _saveSets();

      final nextIndex = _currentSetIndex + 1;
      if (nextIndex < _sets.length) {
        _currentSetIndex = nextIndex;
      }
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _showNumberInputDialog(
    BuildContext context,
    String title,
    double initialValue,
    Function(double) onChanged, {
    bool isDouble = false,
  }) {
    final controller = TextEditingController(text: initialValue.toString());
    // 텍스트 전체 선택을 위한 포커스 노드 추가
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (context) {
        // 다이얼로그가 표시된 후 텍스트 전체 선택
        WidgetsBinding.instance.addPostFrameCallback((_) {
          controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: controller.text.length,
          );
          focusNode.requestFocus();
        });

        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: isDouble
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
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
                final value = isDouble
                    ? double.tryParse(controller.text) ?? initialValue
                    : double.tryParse(controller.text)?.toInt().toDouble() ??
                        initialValue;
                onChanged(value);
                Navigator.pop(context);
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showEditSetDialog(int index) {
    final set = _sets[index];
    double tempWeight = set.weight;
    int tempReps = set.reps;
    int tempRest = set.restTime.inSeconds;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('세트 편집'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 90,
                    child: Text('무게(kg)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempWeight = (tempWeight - _weightStep).clamp(0, 1000);
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(
                        width: 40,
                        child: GestureDetector(
                          onTap: () {
                            _showNumberInputDialog(
                              context,
                              '무게 입력',
                              tempWeight,
                              (value) {
                                setStateDialog(() {
                                  tempWeight = value;
                                });
                              },
                              isDouble: true,
                            );
                          },
                          child:
                              Center(child: Text(tempWeight.toStringAsFixed(1))),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempWeight = (tempWeight + _weightStep).clamp(0, 1000);
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 32,
                        child: GestureDetector(
                          onTap: () {
                            _showNumberInputDialog(
                              context,
                              '무게 단위 입력',
                              _weightStep,
                              (value) {
                                setStateDialog(() {
                                  _weightStep = value.clamp(0.5, 10.0);
                                });
                              },
                              isDouble: true,
                            );
                          },
                          child:
                              Center(child: Text(_weightStep.toStringAsFixed(1))),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 90,
                    child:
                        Text('횟수', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempReps = (tempReps - _repsStep).clamp(1, 100);
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(
                        width: 40,
                        child: GestureDetector(
                          onTap: () {
                            _showNumberInputDialog(
                              context,
                              '횟수 입력',
                              tempReps.toDouble(),
                              (value) {
                                setStateDialog(() {
                                  tempReps = value.toInt();
                                });
                              },
                            );
                          },
                          child: Center(child: Text(tempReps.toString())),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempReps = (tempReps + _repsStep).clamp(1, 100);
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 32,
                        child: GestureDetector(
                          onTap: () {
                            _showNumberInputDialog(
                              context,
                              '횟수 단위 입력',
                              _repsStep.toDouble(),
                              (value) {
                                setStateDialog(() {
                                  _repsStep = value.toInt().clamp(1, 10);
                                });
                              },
                            );
                          },
                          child: Center(child: Text('$_repsStep')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(
                    width: 90,
                    child: Text('휴식(초)',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempRest = (tempRest - _restTimeStep).clamp(10, 300);
                          });
                        },
                        icon: const Icon(Icons.remove_circle_outline),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      SizedBox(
                        width: 40,
                        child: GestureDetector(
                          onTap: () {
                            _showNumberInputDialog(
                              context,
                              '휴식시간 입력(초)',
                              tempRest.toDouble(),
                              (value) {
                                setStateDialog(() {
                                  tempRest = value.toInt();
                                });
                              },
                            );
                          },
                          child: Center(child: Text(tempRest.toString())),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setStateDialog(() {
                            tempRest = (tempRest + _restTimeStep).clamp(10, 300);
                          });
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        constraints: BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 32,
                        child: GestureDetector(
                          onTap: () {
                            _showNumberInputDialog(
                              context,
                              '휴식시간 단위 입력(초)',
                              _restTimeStep.toDouble(),
                              (value) {
                                setStateDialog(() {
                                  _restTimeStep = value.toInt().clamp(5, 60);
                                });
                              },
                            );
                          },
                          child: Center(child: Text('$_restTimeStep')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _sets[index] = set.copyWith(
                    weight: tempWeight,
                    reps: tempReps,
                    restTime: Duration(seconds: tempRest),
                  );
                  _saveSets();
                });
                Navigator.pop(context);
              },
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadPreviousExerciseSets() async {
    try {
      // 오늘 날짜의 키
      final todayKey = _getStorageKey();

      // 오늘 날짜의 세트가 이미 있으면 불러오지 않음
      if (_prefs.containsKey(todayKey)) {
        return;
      }

      // 기록된 모든 날짜 가져오기
      final recordedDates =
          _prefs.getStringList('recorded_dates_${widget.exerciseName}') ?? [];
      if (recordedDates.isEmpty) return;

      // 최근 날짜부터 확인
      recordedDates.sort();

      for (final dateStr in recordedDates.reversed) {
        final key = 'exercise_sets_${widget.exerciseName}_$dateStr';
        final setsJson = _prefs.getStringList(key);

        if (setsJson != null && setsJson.isNotEmpty) {
          // 이전 세트 정보 불러오기
          final previousSets = setsJson
              .map((json) => ExerciseSet.fromJson(jsonDecode(json)))
              .toList();

          if (previousSets.isNotEmpty) {
            // 마지막 세트의 정보로 현재 값 설정
            final lastSet = previousSets.last;
            setState(() {
              _currentWeight = lastSet.weight;
              _currentReps = lastSet.reps;
              _currentRestTime = lastSet.restTime;
            });

            // 이전 세트들을 현재 날짜에 복사
            setState(() {
              _sets = previousSets
                  .map((set) => ExerciseSet(
                        weight: set.weight,
                        reps: set.reps,
                        restTime: set.restTime,
                        isCompleted: false, // 완료 상태는 초기화
                      ))
                  .toList();
              _currentSetIndex = 0;
            });
            _saveSets();
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading previous exercise sets: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final allCompleted =
          _sets.isNotEmpty && _sets.every((set) => set.isCompleted);

      // === 통계 계산 ===
      // 오늘 기록
      double todayMaxWeight = 0;
      double todayMax1RM = 0;
      double todayTotalVolume = 0;
      for (final set in _sets) {
        todayMaxWeight = set.weight * set.reps > todayMaxWeight
            ? set.weight * set.reps
            : todayMaxWeight;
        final oneRM = set.weight * (1 + set.reps / 30.0);
        todayMax1RM = oneRM > todayMax1RM ? oneRM : todayMax1RM;
        todayTotalVolume += set.weight * set.reps;
      }
      // 오늘 최대 무게(세트별 무게*횟수), 최대 1RM, 총 볼륨

      // 이전 기록(오늘 이전 날짜 중 가장 최근)
      double prevMaxWeight = 0;
      double prevMax1RM = 0;
      double prevTotalVolume = 0;
      if (_recordedDates.isNotEmpty) {
        final todayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
        final otherDates = _recordedDates.where((d) => d != todayStr).toList();
        final prevDate = otherDates.isNotEmpty ? otherDates.last : '';

        if (prevDate.isNotEmpty) {
          final prevKey = 'exercise_sets_${widget.exerciseName}_$prevDate';
          final prevSetsJson = _prefs.getStringList(prevKey) ?? [];
          final prevSets = prevSetsJson
              .map((json) => ExerciseSet.fromJson(jsonDecode(json)))
              .toList();
          for (final set in prevSets) {
            prevMaxWeight = set.weight * set.reps > prevMaxWeight
                ? set.weight * set.reps
                : prevMaxWeight;
            final oneRM = set.weight * (1 + set.reps / 30.0);
            prevMax1RM = oneRM > prevMax1RM ? oneRM : prevMax1RM;
            prevTotalVolume += set.weight * set.reps;
          }
        }
      }
      // 역대 최고 기록
      double bestMaxWeight = 0;
      double bestMax1RM = 0;
      double bestTotalVolume = 0;
      for (final date in _recordedDates) {
        final key = 'exercise_sets_${widget.exerciseName}_$date';
        final setsJson = _prefs.getStringList(key) ?? [];
        final sets = setsJson
            .map((json) => ExerciseSet.fromJson(jsonDecode(json)))
            .toList();
        double localMaxWeight = 0;
        double localMax1RM = 0;
        double localTotalVolume = 0;
        for (final set in sets) {
          localMaxWeight = set.weight * set.reps > localMaxWeight
              ? set.weight * set.reps
              : localMaxWeight;
          final oneRM = set.weight * (1 + set.reps / 30.0);
          localMax1RM = oneRM > localMax1RM ? oneRM : localMax1RM;
          localTotalVolume += set.weight * set.reps;
        }
        bestMaxWeight =
            localMaxWeight > bestMaxWeight ? localMaxWeight : bestMaxWeight;
        bestMax1RM = localMax1RM > bestMax1RM ? localMax1RM : bestMax1RM;
        bestTotalVolume = localTotalVolume > bestTotalVolume
            ? localTotalVolume
            : bestTotalVolume;
      }

      // === UI ===
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('yyyy-MM-dd').format(widget.selectedDate),
                style: const TextStyle(fontSize: 14),
              ),
              Text(
                (widget.recordDay > 0 ? '${widget.recordDay}번째 기록  ' : ''),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                widget.exerciseName,
                style: const TextStyle(fontSize: 15),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // === 오늘/이전/역대 기록 요약 ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatBox(
                        title: '최대 무게',
                        value: todayMaxWeight,
                        prev: prevMaxWeight,
                        best: bestMaxWeight,
                        unit: 'kg',
                        formatter: (v) => v.toStringAsFixed(1),
                      ),
                      _StatBox(
                        title: '최대 1RM',
                        value: todayMax1RM,
                        prev: prevMax1RM,
                        best: bestMax1RM,
                        unit: 'kg',
                        formatter: (v) => v.toStringAsFixed(1),
                      ),
                      _StatBox(
                        title: '볼륨',
                        value: todayTotalVolume,
                        prev: prevTotalVolume,
                        best: bestTotalVolume,
                        unit: 'kg',
                        formatter: (v) => v.toStringAsFixed(0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // === 세트 목록 ===
            Expanded(
              child: ListView.builder(
                itemCount: _sets.length,
                itemBuilder: (context, index) {
                  final set = _sets[index];
                  return Card(
                    color: index == _currentSetIndex
                        ? Colors.blue.withOpacity(0.1)
                        : null,
                    child: ExpansionTile(
                      controller: _tileControllers[index],
                      onExpansionChanged: (expanded) {
                        // 타일이 확장될 때, 다른 모든 타일들을 축소시킵니다.
                        // 이를 통해 한 번에 하나의 타일만 확장된 상태를 유지합니다.
                        if (expanded) {
                          for (int i = 0; i < _tileControllers.length; i++) {
                            if (i != index) {
                              _tileControllers[i].collapse();
                            }
                          }
                        }
                      },
                      leading: CircleAvatar(
                        child: Text('${index + 1}'),
                        backgroundColor: set.isCompleted
                            ? Colors.green
                            : index == _currentSetIndex
                                ? Colors.blue
                                : Colors.grey,
                        foregroundColor: Colors.white,
                      ),
                      title: Text(
                        '${set.weight}kg × ${set.reps}회',
                        style: set.isCompleted
                            ? const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      subtitle: Text('휴식: ${set.restTime.inSeconds}초'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeSet(index),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              // 무게
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('무게',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _sets[index] = _sets[index].copyWith(
                                                weight: (_sets[index].weight -
                                                        _weightStep)
                                                    .clamp(0, 1000));
                                            _saveSets();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showNumberInputDialog(
                                              context,
                                              '무게 입력',
                                              _sets[index].weight,
                                              (value) {
                                                setState(() {
                                                  _sets[index] = _sets[index]
                                                      .copyWith(
                                                          weight: value.clamp(
                                                              0, 1000));
                                                  _saveSets();
                                                });
                                              },
                                              isDouble: true,
                                            );
                                          },
                                          child: Center(
                                              child: Text(_sets[index]
                                                  .weight
                                                  .toStringAsFixed(1))),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _sets[index] = _sets[index].copyWith(
                                                weight: (_sets[index].weight +
                                                        _weightStep)
                                                    .clamp(0, 1000));
                                            _saveSets();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // 횟수
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('횟수',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _sets[index] = _sets[index].copyWith(
                                                reps: (_sets[index].reps -
                                                        _repsStep)
                                                    .clamp(1, 100));
                                            _saveSets();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showNumberInputDialog(
                                              context,
                                              '횟수 입력',
                                              _sets[index].reps.toDouble(),
                                              (value) {
                                                setState(() {
                                                  _sets[index] = _sets[index]
                                                      .copyWith(
                                                          reps: value
                                                              .toInt()
                                                              .clamp(1, 100));
                                                  _saveSets();
                                                });
                                              },
                                            );
                                          },
                                          child: Center(
                                              child: Text(
                                                  _sets[index].reps.toString())),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _sets[index] = _sets[index].copyWith(
                                                reps: (_sets[index].reps +
                                                        _repsStep)
                                                    .clamp(1, 100));
                                            _saveSets();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // 휴식
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('휴식(초)',
                                      style:
                                          TextStyle(fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _sets[index] = _sets[index].copyWith(
                                                restTime: Duration(
                                                    seconds: (_sets[index]
                                                                .restTime
                                                                .inSeconds -
                                                            _restTimeStep)
                                                        .clamp(10, 300)));
                                            _saveSets();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: GestureDetector(
                                          onTap: () {
                                            _showNumberInputDialog(
                                              context,
                                              '휴식시간 입력(초)',
                                              _sets[index]
                                                  .restTime
                                                  .inSeconds
                                                  .toDouble(),
                                              (value) {
                                                setState(() {
                                                  _sets[index] = _sets[index]
                                                      .copyWith(
                                                          restTime: Duration(
                                                              seconds: value
                                                                  .toInt()
                                                                  .clamp(
                                                                      10, 300)));
                                                  _saveSets();
                                                });
                                              },
                                            );
                                          },
                                          child: Center(
                                              child: Text(_sets[index]
                                                  .restTime
                                                  .inSeconds
                                                  .toString())),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _sets[index] = _sets[index].copyWith(
                                                restTime: Duration(
                                                    seconds: (_sets[index]
                                                                .restTime
                                                                .inSeconds +
                                                            _restTimeStep)
                                                        .clamp(10, 300)));
                                            _saveSets();
                                          });
                                        },
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // 하단 버튼
            SafeArea(
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    ElevatedButton(
                      onPressed: _addSet,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(40),
                      ),
                      child: const Text('세트 추가'),
                    ),
                    const SizedBox(height: 8),
                    if (_sets.isNotEmpty)
                      BlocBuilder<TimerBloc, TimerState>(
                        builder: (context, state) {
                          final isRunning = state is TimerRunInProgress;
                          final duration = state.duration;
                          final initialDuration = isRunning ? state.initialDuration : 0;


                          return ElevatedButton(
                            onPressed: () {
                              if (isRunning) {
                                context.read<TimerBloc>().add(const TimerReset());
                              } else if (!allCompleted) {
                                _completeSet();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(56),
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // 1. 전체 배경: 연한 주황색
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    color: Colors.orange.withOpacity(0.2),
                                  ),
                                ),
                                // 2. 차오르는 게이지: 진한 주황색
                                if (isRunning)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: (initialDuration > 0)
                                            ? ((initialDuration - duration) / initialDuration)
                                                .clamp(0.0, 1.0)
                                            : 0.0,
                                        child: Container(
                                          height: 56,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ),
                                  ),
                                // 3. 텍스트
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      if (isRunning)
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white),
                                        ),
                                      if (isRunning) const SizedBox(width: 12),
                                      if (isRunning)
                                        const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.skip_next,
                                                color: Colors.white),
                                            SizedBox(width: 4),
                                            Text(
                                              '휴식 완료',
                                              style:
                                                  TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                      if (!isRunning)
                                        Text(
                                          allCompleted
                                              ? '모든 세트 완료'
                                              : '${_currentSetIndex + 1}번 세트 완료',
                                          style: const TextStyle(
                                              fontSize: 18, color: Colors.orange),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e, st) {
      debugPrint('Error in build: $e\n$st');
      return const SizedBox.shrink();
    }
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final double value;
  final double prev;
  final double best;
  final String unit;
  final String Function(double) formatter;

  const _StatBox({
    required this.title,
    required this.value,
    required this.prev,
    required this.best,
    required this.unit,
    required this.formatter,
    Key? key,
  }) : super(key: key);

  Widget _buildComparisonArrow(double current, double reference) {
    if (reference == 0 || current == 0) {
      return const SizedBox.shrink();
    }
    if (current > reference) {
      return const Icon(Icons.arrow_upward, color: Colors.green, size: 12);
    } else if (current < reference) {
      return const Icon(Icons.arrow_downward, color: Colors.red, size: 12);
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(
            '${formatter(value)} $unit',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Text('이전 ${formatter(prev)}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const SizedBox(width: 4),
              _buildComparisonArrow(value, prev),
            ],
          ),
          Row(
            children: [
              Text('최고 ${formatter(best)}',
                  style: const TextStyle(fontSize: 11, color: Colors.orange)),
              const SizedBox(width: 4),
              _buildComparisonArrow(value, best),
            ],
          ),
        ],
      ),
    );
  }
}
