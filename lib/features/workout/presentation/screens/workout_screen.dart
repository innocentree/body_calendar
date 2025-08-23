import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../domain/models/exercise.dart';
import 'select_exercise_screen.dart';
import 'exercise_detail_screen.dart';
import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';
import 'package:body_calendar/features/profile/profile_feature.dart';

class WorkoutRecord {
  final int id;
  final String name;
  final String imagePath;
  final int sets;
  final double weight;
  final DateTime timestamp;
  final int sessionIndex;
  final String equipment;

  WorkoutRecord({
    required this.id,
    required this.name,
    this.imagePath = 'assets/images/default_exercise.png',
    required this.sets,
    required this.weight,
    required this.timestamp,
    required this.sessionIndex,
    this.equipment = '',
  });

  // JSON으로 변환
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imagePath': imagePath,
    'sets': sets,
    'weight': weight,
    'timestamp': timestamp.toIso8601String(),
    'sessionIndex': sessionIndex,
    'equipment': equipment,
  };

  // JSON에서 객체 생성
  factory WorkoutRecord.fromJson(Map<String, dynamic> json) => WorkoutRecord(
    id: json['id'],
    name: json['name'],
    imagePath: json['imagePath'],
    sets: json['sets'],
    weight: json['weight'],
    timestamp: DateTime.parse(json['timestamp']),
    sessionIndex: json['sessionIndex'],
    equipment: json['equipment'] ?? '',
  );
}

class WorkoutScreen extends StatefulWidget {
  final DateTime selectedDate;
  final int sessionIndex; // 1회차, 2회차, 3회차 등

  const WorkoutScreen({
    super.key,
    required this.selectedDate,
    this.sessionIndex = 1,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> with SingleTickerProviderStateMixin {
  List<WorkoutRecord> _workouts = [];
  late TabController _tabController;
  int _recordCount = 0; // 총 운동 기록 횟수
  late SharedPreferences _prefs;
  int _recordDay = 0;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    try {
      _tabController = TabController(length: 3, vsync: this, initialIndex: widget.sessionIndex - 1);
      _tabController.addListener(_handleTabSelection);
      
      // 실제 앱에서는 이 부분에서 데이터베이스에서 운동 기록을 불러옵니다
      _recordCount = 181; // 예시 데이터
      _calculateRecordDay();
    } catch (e) {
      debugPrint('Error initializing WorkoutScreen: $e');
      // 에러 발생 시 기본값으로 초기화
      _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
      _recordCount = 0;
    }
  }

  Future<void> _initializePrefs() async {
    _prefs = await SharedPreferences.getInstance();
    _loadWorkouts();
  }

  void _loadWorkouts() {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final workoutsJson = _prefs.getStringList('workouts_$dateKey') ?? [];
      
      setState(() {
        _workouts = workoutsJson
            .map((json) => WorkoutRecord.fromJson(jsonDecode(json)))
            .where((workout) => workout.sessionIndex == _tabController.index + 1)
            .toList();
      });
      _calculateRecordDay();
    } catch (e) {
      debugPrint('Error loading workouts: $e');
    }
  }

  Future<void> _saveWorkouts() async {
    try {
      final dateKey = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
      final allWorkouts = _prefs.getStringList('workouts_$dateKey') ?? [];
      
      // 현재 세션의 운동들을 제외
      final otherSessionWorkouts = allWorkouts
          .map((json) => WorkoutRecord.fromJson(jsonDecode(json)))
          .where((workout) => workout.sessionIndex != _tabController.index + 1)
          .toList();
      
      // 현재 세션의 운동들과 다른 세션의 운동들을 합침
      final updatedWorkouts = [
        ...otherSessionWorkouts,
        ..._workouts,
      ];
      
      // JSON으로 변환하여 저장
      await _prefs.setStringList(
        'workouts_$dateKey',
        updatedWorkouts.map((workout) => jsonEncode(workout.toJson())).toList(),
      );
    } catch (e) {
      debugPrint('Error saving workouts: $e');
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      _loadWorkouts();
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final isToday = widget.selectedDate.year == now.year &&
        widget.selectedDate.month == now.month &&
        widget.selectedDate.day == now.day;
    
    final formatter = DateFormat('yyyy-MM-dd');
    return '${formatter.format(widget.selectedDate)} ${isToday ? '오늘' : ''}';
  }

  Future<void> _calculateRecordDay() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workouts_'));
    final Set<String> recordedDates = {};
    for (final key in keys) {
      final dateStr = key.replaceFirst('workouts_', '');
      final workoutsJson = prefs.getStringList(key) ?? [];
      if (workoutsJson.isNotEmpty) {
        recordedDates.add(dateStr);
      }
    }
    final todayStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final sortedDates = recordedDates.toList()..sort();
    final idx = sortedDates.indexOf(todayStr);
    setState(() {
      _recordDay = idx != -1 ? idx + 1 : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_getFormattedDate(), style: const TextStyle(fontSize: 18)),
                Text(_recordDay > 0 ? '$_recordDay번째 기록' : '', style: const TextStyle(fontSize: 14)),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              tabs: const [
                Tab(text: '1회차'),
                Tab(text: '2회차'),
                Tab(text: '3회차'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: List.generate(3, (index) {
              // 각 회차별 운동 기록만 필터링
              final sessionWorkouts = _workouts
                  .where((workout) => workout.sessionIndex == index + 1)
                  .toList();

              return Column(
                children: [
                  if (sessionWorkouts.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 운동시간 : N분
                          FutureBuilder<List<dynamic>>(
                            future: _getCompletedSetStats(sessionWorkouts),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text('운동시간 : 0분');
                              final totalMinutes = snapshot.data![0] as int;
                              return Text('운동시간 : $totalMinutes분');
                            },
                          ),
                          // 완료 세트/무게
                          FutureBuilder<List<dynamic>>(
                            future: _getCompletedSetStats(sessionWorkouts),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) return const Text('0세트 0kg');
                              final completedSets = snapshot.data![1] as int;
                              final totalWeight = snapshot.data![2] as double;
                              return Text('${completedSets}세트 ${_formatWeight(totalWeight * 1000)}');
                            },
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: sessionWorkouts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.fitness_center, size: 80, color: Colors.grey),
                              const SizedBox(height: 16),
                              Text(
                                '${index + 1}회차 운동 기록이 없습니다.',
                                style: const TextStyle(fontSize: 18),
                              ),
                              const Text('우측 하단 + 버튼을 눌러 추가해보세요'),
                              const SizedBox(height: 32),
                              const Text('하루에 운동을 여러번 하시나요?'),
                              const Text('회차를 선택해서 구분해보세요'),
                              const Text('운동 시간 등이 별도로 기록됩니다'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: sessionWorkouts.length,
                          itemBuilder: (context, i) {
                            final workout = sessionWorkouts[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: InkWell(
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ExerciseDetailScreen(
                                        exerciseName: workout.name,
                                        selectedDate: widget.selectedDate,
                                        initialWeight: workout.weight.toInt(),
                                        initialSets: workout.sets,
                                        recordDay: _recordDay,
                                      ),
                                    ),
                                  );
                                  _loadWorkouts();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  workout.name,
                                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (workout.equipment.isNotEmpty)
                                                  Text(
                                                    '장비: ${workout.equipment}',
                                                    style: const TextStyle(color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const Row(
                                            children: [
                                              Icon(Icons.fitness_center, size: 40),
                                              SizedBox(width: 8),
                                              Icon(Icons.fitness_center, size: 40),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          FutureBuilder<List<dynamic>>(
                                            future: _getSetInfo(workout.name, widget.selectedDate),
                                            builder: (context, snapshot) {
                                              if (!snapshot.hasData) {
                                                return const Text('세트 정보 불러오는 중...');
                                              }
                                              final sets = snapshot.data![0] as int;
                                              final completed = snapshot.data![1] as int;
                                              return Text('$completed/$sets 세트');
                                            },
                                          ),
                                          TextButton(
                                            onPressed: () => _deleteWorkout(workout),
                                            child: const Text('삭제'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              );
            }),
          ),
          bottomNavigationBar: NavigationBar(
            destinations: [
              NavigationDestination(
                icon: _workouts.isNotEmpty && _tabController.index == 0
                    ? const Icon(Icons.fitness_center, color: Colors.red)
                    : const Icon(Icons.fitness_center),
                label: '운동',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person),
                label: '프로필',
              ),
              const NavigationDestination(
                icon: Icon(Icons.calendar_today),
                label: '캘린더',
              ),
            ],
            selectedIndex: 0,
            onDestinationSelected: (index) {
              if (index == 1) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen(selectedDate: widget.selectedDate)),
                );
              } else if (index == 2) {
                Navigator.pop(context);
              }
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _addWorkout,
            child: const Icon(Icons.add),
          ),
        ),
        RestFabOverlay(),
      ],
    );
  }

  Future<void> _addWorkout() async {
    try {
      final Exercise? selectedExercise = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SelectExerciseScreen(),
        ),
      );

      if (selectedExercise != null) {
        setState(() {
          _workouts.add(WorkoutRecord(
            id: DateTime.now().millisecondsSinceEpoch,
            name: selectedExercise.name,
            imagePath: selectedExercise.imagePath,
            sets: selectedExercise.sets,
            weight: selectedExercise.weight,
            timestamp: DateTime.now(),
            sessionIndex: _tabController.index + 1,
            equipment: selectedExercise.equipment,
          ));
          _saveWorkouts();
        });
      }
    } catch (e) {
      debugPrint('Error adding workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('운동을 추가하는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  void _deleteWorkout(WorkoutRecord workout) async {
    try {
      setState(() {
        _workouts.removeWhere((w) => w.id == workout.id);
      });
      await _saveWorkouts();
    } catch (e) {
      debugPrint('Error deleting workout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('운동 삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  // 운동별 세트 정보 불러오기
  Future<List<dynamic>> _getSetInfo(String exerciseName, DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final key = 'exercise_sets_${exerciseName}_$dateStr';
    final setsJson = prefs.getStringList(key) ?? [];
    int total = setsJson.length;
    int completed = 0;
    for (final jsonStr in setsJson) {
      try {
        final set = jsonDecode(jsonStr);
        if (set['isCompleted'] == true) completed++;
      } catch (_) {}
    }
    return [total, completed];
  }

  // 완료 세트의 총 시간(분), 완료 세트 수, 완료 세트 무게(톤) 반환
  Future<List<dynamic>> _getCompletedSetStats(List<WorkoutRecord> workouts) async {
    final prefs = await SharedPreferences.getInstance();
    int totalSeconds = 0;
    int completedSets = 0;
    double totalWeight = 0.0;
    for (final workout in workouts) {
      final dateStr = DateFormat('yyyy-MM-dd').format(workout.timestamp);
      final key = 'exercise_sets_${workout.name}_$dateStr';
      final setsJson = prefs.getStringList(key) ?? [];
      for (final jsonStr in setsJson) {
        try {
          final set = jsonDecode(jsonStr);
          if (set['isCompleted'] == true) {
            completedSets++;
            // 실제 수행 시간(초)
            if (set['startTime'] != null && set['endTime'] != null) {
              final start = DateTime.tryParse(set['startTime']);
              final end = DateTime.tryParse(set['endTime']);
              if (start != null && end != null) {
                totalSeconds += end.difference(start).inSeconds;
              }
            } else if (set['restTime'] != null) {
              totalSeconds += set['restTime'] as int;
            }
            // 무게(kg) * 횟수
            final weight = (set['weight'] is int)
                ? (set['weight'] as int).toDouble()
                : (set['weight'] is double)
                    ? set['weight']
                    : double.tryParse(set['weight'].toString()) ?? 0.0;
            final reps = set['reps'] ?? 0;
            totalWeight += weight * (reps is int ? reps : int.tryParse(reps.toString()) ?? 0);
          }
        } catch (_) {}
      }
    }
    // kg → 톤
    return [(totalSeconds / 60).round(), completedSets, totalWeight / 1000];
  }

  String _formatWeight(double kg) {
    if (kg < 1000) {
      return '${kg.toStringAsFixed(1)}kg';
    } else {
      return '${(kg / 1000).toStringAsFixed(1)}톤';
    }
  }
} 