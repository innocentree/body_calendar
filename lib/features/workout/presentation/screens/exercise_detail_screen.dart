import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:get_it/get_it.dart';
import '../../domain/models/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import 'dart:async';
import 'package:screen_brightness/screen_brightness.dart';
import 'dart:io';
import 'package:body_calendar/features/calendar/presentation/widgets/overlay_helper_impl.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/exercise_statistics_popup.dart';

class ExerciseSet {
  final double weight;
  final int reps;
  final Duration restTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final double? bodyWeight;
  final double? assistedWeight;

  ExerciseSet({
    required this.weight,
    required this.reps,
    this.restTime = const Duration(minutes: 1),
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.bodyWeight,
    this.assistedWeight,
  });

  Map<String, dynamic> toJson() => {
        'weight': weight,
        'reps': reps,
        'restTime': restTime.inSeconds,
        'startTime': startTime?.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'isCompleted': isCompleted,
        'bodyWeight': bodyWeight,
        'assistedWeight': assistedWeight,
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
        bodyWeight: (json['bodyWeight'] is int)
            ? (json['bodyWeight'] as int).toDouble()
            : (json['bodyWeight'] as double?),
        assistedWeight: (json['assistedWeight'] is int)
            ? (json['assistedWeight'] as int).toDouble()
            : (json['assistedWeight'] as double?),
      );

  ExerciseSet copyWith({
    double? weight,
    int? reps,
    Duration? restTime,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    double? bodyWeight,
    double? assistedWeight,
  }) {
    return ExerciseSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      restTime: restTime ?? this.restTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      bodyWeight: bodyWeight ?? this.bodyWeight,
      assistedWeight: assistedWeight ?? this.assistedWeight,
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
  Exercise? _exercise;
  late final ExerciseRepository _exerciseRepository;

  // 증가/감소 단위 변수 수정
  double _weightStep = 5.0;
  int _repsStep = 1;
  int _restTimeStep = 30;
  final AudioPlayer _audioPlayer = AudioPlayer();

  DateTime? _firstRecordDate;
  List<String> _recordedDates = [];

  // 드롭다운 상태 관리
  List<ExpansionTileController> _tileControllers = [];

  // PR Highlight States
  bool _highlightMaxWeight = false;
  bool _highlight1RM = false;
  bool _highlightVolume = false;
  
  // Running Bests for PR detection
  double _runningBestMaxWeight = 0;
  double _runningBest1RM = 0;
  double _runningBestVolume = 0; // Volume is cumulative? user said "Volume value updates". Usually total volume.
  // If total volume updates, it always updates on every set?
  // "Volume value" usually means "Total Volume for the exercise".
  // If so, every set increases volume. So every set updates the record if today is a PR day?
  // Maybe "Session Volume" PR.
  // If today's volume > best volume ever.
  // Every set adds volume, so yes, every set after crossing the threshold will trigger.
  // Maybe user wants that. Or maybe only when crossing the threshold?
  // "최고값을 갱신하면" -> Whenever it updates. So yes.
  
  double _historicalBestVolume = 0; // To track if we are in PR territory for volume

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentWeight = widget.initialWeight.toDouble();
    _exerciseRepository = GetIt.I<ExerciseRepository>();
    _loadExercise().then((_) {
      _initializePrefs();
    });
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

  Future<void> _loadExercise() async {
    final exercise = await _exerciseRepository.getExerciseByName(widget.exerciseName);
    setState(() {
      _exercise = exercise;
    });
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

    _calculateInitialRunningBests();
  }

  Future<void> _calculateInitialRunningBests() async {
    // Calculate bests from all recorded dates (including today if already loaded)
    // Actually, we want to know the state *before* the next set.
    // So just calculate the current "Global Best".
    
    double bestMaxWeight = 0;
    double bestMax1RM = 0;
    double bestTotalVolume = 0;

    // Use _recordedDates (which might include today)
    // If today is included, we need to respect today's current values.
    
    // Logic similar to build's best calculation
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
          if (_exercise?.needsWeight == true) {
            localMaxWeight = set.weight > localMaxWeight ? set.weight : localMaxWeight;
            final oneRM = set.weight * (1 + set.reps / 30.0);
            localMax1RM = oneRM > localMax1RM ? oneRM : localMax1RM;
            localTotalVolume += set.weight * set.reps;
          }
      }
      
      if (_exercise?.needsWeight == true) {
          bestMaxWeight = localMaxWeight > bestMaxWeight ? localMaxWeight : bestMaxWeight;
          bestMax1RM = localMax1RM > bestMax1RM ? localMax1RM : bestMax1RM;
          bestTotalVolume = localTotalVolume > bestTotalVolume ? localTotalVolume : bestTotalVolume;
      }
    }
    
    _runningBestMaxWeight = bestMaxWeight;
    _runningBest1RM = bestMax1RM;
    _runningBestVolume = bestTotalVolume;
    
    // Also calculate historical best volume (excluding today) to see when we cross it?
    // Actually _runningBestVolume already includes today's current total.
    // If we add a set, volume increases.
    // newTotal > _runningBestVolume -> Update & Highlight.
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
      // 이전 세트가 있으면 그 정보를 사용, 없으면 현재 설정된 값 사용
      final lastSet = _sets.isNotEmpty ? _sets.last : null;
      _sets.add(ExerciseSet(
        weight: lastSet?.weight ?? _currentWeight,
        reps: lastSet?.reps ?? _currentReps,
        restTime: lastSet?.restTime ?? _currentRestTime,
        bodyWeight: lastSet?.bodyWeight ?? (_exercise?.isAssisted == true ? 70.0 : null),
        assistedWeight: lastSet?.assistedWeight ?? (_exercise?.isAssisted == true ? 0.0 : null),
      ));
      _tileControllers.add(ExpansionTileController());

      final firstIncomplete = _sets.indexWhere((set) => !set.isCompleted);
      if (firstIncomplete != -1) {
        _currentSetIndex = firstIncomplete;
      }

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
      
      _checkAndHighlightPRs();
    });
  }

  void _checkAndHighlightPRs() {
      // Re-calculate today's stats based on the UPDATED sets
      double todayMaxWeight = 0;
      double todayMax1RM = 0;
      double todayTotalVolume = 0;

      for (final set in _sets) {
        if (_exercise?.needsWeight == true) {
          // Check completed sets? Or all sets as per build logic? 
          // Build logic uses all sets. We stick to that.
          double currentSetVolume = set.weight * set.reps;
          todayMaxWeight = set.weight > todayMaxWeight ? set.weight : todayMaxWeight;
          
          final oneRM = set.weight * (1 + set.reps / 30.0);
          todayMax1RM = oneRM > todayMax1RM ? oneRM : todayMax1RM;
          todayTotalVolume += currentSetVolume;
        }
      }

      if (_exercise?.needsWeight == true) {
          if (todayMaxWeight > _runningBestMaxWeight) {
             _runningBestMaxWeight = todayMaxWeight;
             setState(() => _highlightMaxWeight = true);
             Timer(const Duration(seconds: 3), () => setState(() => _highlightMaxWeight = false));
          }
          
          if (todayMax1RM > _runningBest1RM) {
             _runningBest1RM = todayMax1RM;
             setState(() => _highlight1RM = true);
             Timer(const Duration(seconds: 3), () => setState(() => _highlight1RM = false));
          }
          
          if (todayTotalVolume > _runningBestVolume) {
             _runningBestVolume = todayTotalVolume;
             setState(() => _highlightVolume = true);
             Timer(const Duration(seconds: 3), () => setState(() => _highlightVolume = false));
          }
      }
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
    var set = _sets[index]; // Make locally mutable for dialog state
    double tempWeight = set.weight;
    // 초기값 설정
    if (_exercise?.isAssisted == true && set.bodyWeight == null) {
      set = set.copyWith(bodyWeight: 70.0, assistedWeight: 0.0);
      tempWeight = 70.0; 
    }
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
              if ((_exercise?.needsWeight ?? true) && !(_exercise?.isAssisted ?? false))
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
              if (_exercise?.isAssisted ?? false)
              Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text('체중(kg)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setStateDialog(() {
                                // Default to 70 if not set
                                double currentBodyWeight = set.bodyWeight ?? 70.0; 
                                currentBodyWeight = (currentBodyWeight - 1.0).clamp(0, 300);
                                set = set.copyWith(bodyWeight: currentBodyWeight);
                                tempWeight = (set.bodyWeight ?? 70.0) - (set.assistedWeight ?? 0.0);
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
                                  '체중 입력',
                                  set.bodyWeight ?? 70.0,
                                  (value) {
                                    setStateDialog(() {
                                      set = set.copyWith(bodyWeight: value);
                                      tempWeight = (set.bodyWeight ?? 70.0) - (set.assistedWeight ?? 0.0);
                                    });
                                  },
                                  isDouble: true,
                                );
                              },
                              child:
                                  Center(child: Text((set.bodyWeight ?? 70.0).toStringAsFixed(1))),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setStateDialog(() {
                                double currentBodyWeight = set.bodyWeight ?? 70.0;
                                currentBodyWeight = (currentBodyWeight + 1.0).clamp(0, 300);
                                set = set.copyWith(bodyWeight: currentBodyWeight);
                                tempWeight = (set.bodyWeight ?? 70.0) - (set.assistedWeight ?? 0.0);
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                           const SizedBox(width: 48), // Spacing to align
                        ],
                      ),
                    ],
                  ),
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        width: 90,
                        child: Text('보조(kg)',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              setStateDialog(() {
                                double currentAssisted = set.assistedWeight ?? 0.0;
                                currentAssisted = (currentAssisted - _weightStep).clamp(0, 300);
                                set = set.copyWith(assistedWeight: currentAssisted);
                                tempWeight = (set.bodyWeight ?? 70.0) - (set.assistedWeight ?? 0.0);
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
                                  '보조 무게 입력',
                                  set.assistedWeight ?? 0.0,
                                  (value) {
                                    setStateDialog(() {
                                      set = set.copyWith(assistedWeight: value);
                                      tempWeight = (set.bodyWeight ?? 70.0) - (set.assistedWeight ?? 0.0);
                                    });
                                  },
                                  isDouble: true,
                                );
                              },
                              child:
                                  Center(child: Text((set.assistedWeight ?? 0.0).toStringAsFixed(1))),
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              setStateDialog(() {
                                 double currentAssisted = set.assistedWeight ?? 0.0;
                                currentAssisted = (currentAssisted + _weightStep).clamp(0, 300);
                                set = set.copyWith(assistedWeight: currentAssisted);
                                tempWeight = (set.bodyWeight ?? 70.0) - (set.assistedWeight ?? 0.0);
                              });
                            },
                            icon: const Icon(Icons.add_circle_outline),
                            constraints: BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                           const SizedBox(width: 48), // Spacing to align
                        ],
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
                Navigator.pop(context);
                setState(() {
                  final newRestTime = Duration(seconds: tempRest);
                  _sets[index] = set.copyWith( // Use the potentially modified 'set'
                    weight: tempWeight,
                    reps: tempReps,
                    restTime: newRestTime,
                  );
                  _saveSets();
                  
                  if (index == _currentSetIndex - 1) {
                        context.read<TimerBloc>().add(
                            TimerDurationUpdated(duration: newRestTime.inSeconds));
                  }
                });
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
                        bodyWeight: set.bodyWeight ?? (_exercise?.isAssisted == true ? 70.0 : null),
                        assistedWeight: set.assistedWeight ??
                            (set.bodyWeight != null
                                ? set.bodyWeight! - set.weight
                                : (_exercise?.isAssisted == true
                                    ? 70.0 - set.weight
                                    : null)),
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
      // === 통계 계산 ===
      // 오늘 기록
      double todayMaxWeight = 0;
      double todayMax1RM = 0;
      double todayTotalVolume = 0;
      int todayMaxReps = 0;
      int todayTotalReps = 0;

      for (final set in _sets) {
        if (_exercise?.needsWeight == true) {
          double currentSetVolume = set.weight * set.reps;
          todayMaxWeight = set.weight > todayMaxWeight ? set.weight : todayMaxWeight;
          
          final oneRM = set.weight * (1 + set.reps / 30.0);
          todayMax1RM = oneRM > todayMax1RM ? oneRM : todayMax1RM;
          todayTotalVolume += currentSetVolume;
        } else {
          // Bodyweight / No Weight
          todayMaxReps = set.reps > todayMaxReps ? set.reps : todayMaxReps;
          todayTotalReps += set.reps;
        }
      }

      // 이전 기록(오늘 이전 날짜 중 가장 최근)
      double prevMaxWeight = 0;
      double prevMax1RM = 0;
      double prevTotalVolume = 0;
      int prevMaxReps = 0;
      int prevTotalReps = 0;

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
            if (_exercise?.needsWeight == true) {
               prevMaxWeight = set.weight > prevMaxWeight ? set.weight : prevMaxWeight;
               final oneRM = set.weight * (1 + set.reps / 30.0);
               prevMax1RM = oneRM > prevMax1RM ? oneRM : prevMax1RM;
               prevTotalVolume += set.weight * set.reps;
            } else {
               prevMaxReps = set.reps > prevMaxReps ? set.reps : prevMaxReps;
               prevTotalReps += set.reps;
            }
          }
        }
      }
      
      // 역대 최고 기록
      double bestMaxWeight = 0;
      double bestMax1RM = 0;
      double bestTotalVolume = 0;
      int bestMaxReps = 0;
      int bestTotalReps = 0;

      for (final date in _recordedDates) {
        final key = 'exercise_sets_${widget.exerciseName}_$date';
        final setsJson = _prefs.getStringList(key) ?? [];
        final sets = setsJson
            .map((json) => ExerciseSet.fromJson(jsonDecode(json)))
            .toList();
            
        double localMaxWeight = 0;
        double localMax1RM = 0;
        double localTotalVolume = 0;
        int localMaxReps = 0;
        int localTotalReps = 0;

        for (final set in sets) {
           if (_exercise?.needsWeight == true) {
              localMaxWeight = set.weight > localMaxWeight ? set.weight : localMaxWeight;
              final oneRM = set.weight * (1 + set.reps / 30.0);
              localMax1RM = oneRM > localMax1RM ? oneRM : localMax1RM;
              localTotalVolume += set.weight * set.reps;
           } else {
              localMaxReps = set.reps > localMaxReps ? set.reps : localMaxReps;
              localTotalReps += set.reps;
           }
        }
        
        if (_exercise?.needsWeight == true) {
           bestMaxWeight = localMaxWeight > bestMaxWeight ? localMaxWeight : bestMaxWeight;
           bestMax1RM = localMax1RM > bestMax1RM ? localMax1RM : bestMax1RM;
           bestTotalVolume = localTotalVolume > bestTotalVolume ? localTotalVolume : bestTotalVolume;
        } else {
           bestMaxReps = localMaxReps > bestMaxReps ? localMaxReps : bestMaxReps;
           bestTotalReps = localTotalReps > bestTotalReps ? localTotalReps : bestTotalReps;
        }
      }

      // === UI ===
      return BlocListener<TimerBloc, TimerState>(
        listener: (context, state) {
          if (state is TimerRunInProgress) {
            final duration = state.duration;
            if (duration == 10 || duration == 3 || duration == 2 || duration == 1) {
              Vibration.vibrate(duration: 100); // Short vibration
              _audioPlayer.play(AssetSource('sounds/beep.mp3')); // Single beep
            }
          } else if (state is TimerRunComplete) {
            Vibration.vibrate(duration: 500); // Long vibration
            _audioPlayer.play(AssetSource('sounds/bell.mp3')); // Play twice for two beeps
            _audioPlayer.play(AssetSource('sounds/bell.mp3'));
          }
        },
        child: Scaffold(
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
                      if (_exercise?.needsWeight == true) ...[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => ExerciseStatisticsPopup(
                                exerciseName: widget.exerciseName,
                                type: ExerciseStatisticType.maxWeight,
                              ),
                            );
                          },
                          child: _StatBox(
                            title: '최대 무게',
                            value: todayMaxWeight,
                            prev: prevMaxWeight,
                            best: bestMaxWeight,
                            unit: 'kg',
                            formatter: (v) => v.toStringAsFixed(1),
                            isHighlighted: _highlightMaxWeight,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => ExerciseStatisticsPopup(
                                exerciseName: widget.exerciseName,
                                type: ExerciseStatisticType.oneRM,
                              ),
                            );
                          },
                          child: _StatBox(
                            title: '최대 1RM',
                            value: todayMax1RM,
                            prev: prevMax1RM,
                            best: bestMax1RM,
                            unit: 'kg',
                            formatter: (v) => v.toStringAsFixed(1),
                            isHighlighted: _highlight1RM,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => ExerciseStatisticsPopup(
                                exerciseName: widget.exerciseName,
                                type: ExerciseStatisticType.volume,
                              ),
                            );
                          },
                          child: _StatBox(
                            title: '볼륨',
                            value: todayTotalVolume,
                            prev: prevTotalVolume,
                            best: bestTotalVolume,
                            unit: 'kg',
                            formatter: (v) => v.toStringAsFixed(0),
                            isHighlighted: _highlightVolume,
                          ),
                        ),
                      ] else ...[
                        _StatBox(
                          title: '최대 횟수',
                          value: todayMaxReps.toDouble(),
                          prev: prevMaxReps.toDouble(),
                          best: bestMaxReps.toDouble(),
                          unit: '회',
                          formatter: (v) => v.toInt().toString(),
                        ),
                         _StatBox(
                          title: '총 횟수',
                          value: todayTotalReps.toDouble(),
                          prev: prevTotalReps.toDouble(),
                          best: bestTotalReps.toDouble(),
                          unit: '회',
                          formatter: (v) => v.toInt().toString(),
                        ),
                      ]
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
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.customSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: index == _currentSetIndex
                          ? Border.all(color: AppColors.neonCyan.withOpacity(0.5), width: 1)
                          : null,
                    ),
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                        iconTheme: const IconThemeData(color: Colors.white),
                        textTheme: const TextTheme(titleMedium: TextStyle(color: Colors.white)),
                      ),
                      child: ExpansionTile(
                        controller: _tileControllers[index],
                        backgroundColor: Colors.transparent,
                        collapsedBackgroundColor: Colors.transparent,
                        collapsedIconColor: Colors.white,
                        iconColor: AppColors.neonLime,
                        onExpansionChanged: (expanded) {
                          if (expanded) {
                            for (int i = 0; i < _tileControllers.length; i++) {
                              if (i != index) {
                                _tileControllers[i].collapse();
                              }
                            }
                          }
                        },
                        leading: CircleAvatar(
                          child: Text('${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: set.isCompleted
                              ? AppColors.neonLime.withOpacity(0.8)
                              : index == _currentSetIndex
                                  ? AppColors.neonCyan
                                  : Colors.grey.withOpacity(0.3),
                          foregroundColor: set.isCompleted || index == _currentSetIndex ? Colors.black : Colors.white,
                        ),
                        title: Text(
                          _exercise?.needsWeight ?? true
                              ? '${set.weight}kg × ${set.reps}회'
                              : '${set.reps}회',
                          style: set.isCompleted
                              ? const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                )
                              : const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                        ),
                        subtitle: Text('휴식: ${set.restTime.inSeconds}초', style: const TextStyle(color: Colors.grey)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white54),
                          onPressed: () => _removeSet(index),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                // 보조 운동 무게 조절
                                if (_exercise?.isAssisted ?? false)
                                Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(
                                          width: 90,
                                          child: Text('체중(kg)',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  double currentBody = _sets[index].bodyWeight ?? 70.0;
                                                  currentBody = (currentBody - 1.0).clamp(0, 300);
                                                  double currentAssisted = _sets[index].assistedWeight ?? 0.0;
                                                  _sets[index] = _sets[index].copyWith(
                                                    bodyWeight: currentBody,
                                                    weight: currentBody - currentAssisted,
                                                  );
                                                  _saveSets();
                                                });
                                              },
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showNumberInputDialog(
                                                    context,
                                                    '체중 입력',
                                                    _sets[index].bodyWeight ?? 70.0,
                                                    (value) {
                                                      setState(() {
                                                        double currentAssisted = _sets[index].assistedWeight ?? 0.0;
                                                        _sets[index] = _sets[index].copyWith(
                                                          bodyWeight: value,
                                                          weight: value - currentAssisted,
                                                        );
                                                        _saveSets();
                                                      });
                                                    },
                                                    isDouble: true,
                                                  );
                                                },
                                                child: Center(
                                                    child: Text((_sets[index].bodyWeight ?? 70.0)
                                                        .toStringAsFixed(1), style: const TextStyle(color: Colors.white))),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  double currentBody = _sets[index].bodyWeight ?? 70.0;
                                                  currentBody = (currentBody + 1.0).clamp(0, 300);
                                                  double currentAssisted = _sets[index].assistedWeight ?? 0.0;
                                                  _sets[index] = _sets[index].copyWith(
                                                    bodyWeight: currentBody,
                                                    weight: currentBody - currentAssisted,
                                                  );
                                                  _saveSets();
                                                });
                                              },
                                              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
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
                                          child: Text('보조(kg)',
                                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                        ),
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  double currentAssisted = _sets[index].assistedWeight ?? 0.0;
                                                  currentAssisted = (currentAssisted - _weightStep).clamp(0, 300);
                                                  double currentBody = _sets[index].bodyWeight ?? 70.0;
                                                  _sets[index] = _sets[index].copyWith(
                                                    assistedWeight: currentAssisted,
                                                    weight: currentBody - currentAssisted,
                                                  );
                                                  _saveSets();
                                                });
                                              },
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white),
                                            ),
                                            SizedBox(
                                              width: 40,
                                              child: GestureDetector(
                                                onTap: () {
                                                  _showNumberInputDialog(
                                                    context,
                                                    '보조 무게 입력',
                                                    _sets[index].assistedWeight ?? 0.0,
                                                    (value) {
                                                      setState(() {
                                                        double currentBody = _sets[index].bodyWeight ?? 70.0;
                                                        _sets[index] = _sets[index].copyWith(
                                                          assistedWeight: value,
                                                          weight: currentBody - value,
                                                        );
                                                        _saveSets();
                                                      });
                                                    },
                                                    isDouble: true,
                                                  );
                                                },
                                                child: Center(
                                                    child: Text((_sets[index].assistedWeight ?? 0.0)
                                                        .toStringAsFixed(1), style: const TextStyle(color: Colors.white))),
                                              ),
                                            ),
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  double currentAssisted = _sets[index].assistedWeight ?? 0.0;
                                                  currentAssisted = (currentAssisted + _weightStep).clamp(0, 300);
                                                  double currentBody = _sets[index].bodyWeight ?? 70.0;
                                                  _sets[index] = _sets[index].copyWith(
                                                    assistedWeight: currentAssisted,
                                                    weight: currentBody - currentAssisted,
                                                  );
                                                  _saveSets();
                                                });
                                              },
                                              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                                            ),
 
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                
                                // 일반 무게
                                if ((_exercise?.needsWeight ?? true) && !(_exercise?.isAssisted ?? false))
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 90,
                                      child: Text('무게(kg)',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
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
                                              Icons.remove_circle_outline, color: Colors.white),
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
                                            child:
                                                Center(child: Text(_sets[index]
                                                    .weight
                                                    .toStringAsFixed(1), style: const TextStyle(color: Colors.white))),
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
                                              Icons.add_circle_outline, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // 횟수
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 90,
                                      child: Text('횟수',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
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
                                              Icons.remove_circle_outline, color: Colors.white),
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
                                            child: Center(child: Text(
                                                _sets[index].reps.toString(), style: const TextStyle(color: Colors.white))),
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
                                              Icons.add_circle_outline, color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                // 휴식
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(
                                      width: 90,
                                      child: Text('휴식(초)',
                                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              final newRestTime = Duration(
                                                  seconds: (_sets[index]
                                                              .restTime
                                                              .inSeconds -
                                                          _restTimeStep) 
                                                      .clamp(10, 300));
                                              _sets[index] = _sets[index].copyWith(restTime: newRestTime);
                                              _saveSets();
                                              
                                              // 현재 휴식 중인 세트(직전 완료된 세트)의 휴식 시간이 변경되면 타이머 업데이트
                                              if (index == _currentSetIndex - 1) {
                                                  context.read<TimerBloc>().add(
                                                      TimerDurationUpdated(duration: newRestTime.inSeconds));
                                              }
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.remove_circle_outline, color: Colors.white),
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
                                                    final newRestTime = Duration(seconds: value.toInt()
                                                                                              .clamp(10, 300));
                                                    _sets[index] = _sets[index]
                                                        .copyWith(restTime: newRestTime);
                                                    _saveSets();
                                                    
                                                    if (index == _currentSetIndex - 1) {
                                                        context.read<TimerBloc>().add(
                                                            TimerDurationUpdated(duration: newRestTime.inSeconds));
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                            child: Center(child: Text(_sets[index]
                                                    .restTime
                                                    .inSeconds
                                                    .toString(), style: const TextStyle(color: Colors.white))),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              final newRestTime = Duration(
                                                  seconds: (_sets[index]
                                                              .restTime
                                                              .inSeconds +
                                                          _restTimeStep) 
                                                      .clamp(10, 300));
                                              _sets[index] = _sets[index].copyWith(restTime: newRestTime);
                                              _saveSets();

                                              // 현재 휴식 중인 세트(직전 완료된 세트)의 휴식 시간이 변경되면 타이머 업데이트
                                              if (index == _currentSetIndex - 1) {
                                                  context.read<TimerBloc>().add(
                                                      TimerDurationUpdated(duration: newRestTime.inSeconds));
                                              }
                                            });
                                          },
                                          icon: const Icon(
                                              Icons.add_circle_outline, color: Colors.white),
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
                        minimumSize: const Size.fromHeight(50),
                        backgroundColor: AppColors.neonLime,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text('세트 추가', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                                // 1. 전체 배경: Dark Surface
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(28),
                                  child: Container(
                                    width: double.infinity,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.customSurface,
                                      border: Border.all(color: AppColors.customSurface, width: 2),
                                    ),
                                  ),
                                ),
                                // 2. 차오르는 게이지: Neon Cyan (Smooth Animation)
                                if (isRunning)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(28),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(
                                          begin: 0.0,
                                          end: (initialDuration > 0)
                                              ? ((initialDuration - duration) / initialDuration).clamp(0.0, 1.0)
                                              : 0.0,
                                        ),
                                        duration: const Duration(seconds: 1),
                                        curve: Curves.linear,
                                        builder: (context, value, child) {
                                          return FractionallySizedBox(
                                            widthFactor: value,
                                            child: Container(
                                              height: 56,
                                              color: AppColors.neonCyan.withOpacity(0.8),
                                            ),
                                          );
                                        },
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
                                      if (isRunning) ...[
                                        Text(
                                          _formatDuration(duration),
                                          style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black), // Black on Cyan
                                        ),
                                        const SizedBox(width: 12),
                                        const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.skip_next, color: Colors.black),
                                            SizedBox(width: 4),
                                            Text(
                                              '휴식 완료',
                                              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (!isRunning)
                                        Text(
                                          allCompleted
                                              ? '모든 세트 완료'
                                              : '${_currentSetIndex + 1}번 세트 완료',
                                          style: const TextStyle(
                                              fontSize: 18, 
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.neonCyan), // Cyan text on Dark
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
  final bool isHighlighted;
  final String unit;
  final String Function(double) formatter;

  const _StatBox({
    required this.title,
    required this.value,
    required this.prev,
    required this.best,
    required this.unit,
    required this.formatter,
    this.isHighlighted = false,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 110,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.customSurface,
        borderRadius: BorderRadius.circular(16),
        border: isHighlighted
            ? Border.all(color: AppColors.neonLime, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
        boxShadow: isHighlighted 
            ? [BoxShadow(color: AppColors.neonLime.withOpacity(0.5), blurRadius: 10)]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            '${formatter(value)} $unit',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.neonCyan),
          ),
          const SizedBox(height: 4),
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
                  style: const TextStyle(fontSize: 11, color: AppColors.neonLime)),
              const SizedBox(width: 4),
              _buildComparisonArrow(value, best),
            ],
          ),
        ],
      ),
    );
  }
}