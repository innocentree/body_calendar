import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;
import '../../../workout/presentation/screens/workout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../../workout/presentation/screens/statistics_screen.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
import 'dart:async';
import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';

// RouteObserver를 사용할 수 있도록 글로벌 변수 선언
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with RouteAware {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _lastTapTime;
  Map<String, List<String>> _events = {};
  Offset _fabOffset = const Offset(16, 16); // FAB 기본 위치 (우측 하단)
  bool _showRestFab = false;
  int _restRemain = 0;
  String? _exerciseName;
  DateTime? _selectedDate;
  Timer? _fabTimer;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllEventsAndSet();
    _checkRestTimer();
    _fabTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkRestTimer());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    _loadAllEventsAndSet();
    _checkRestTimer();
  }

  @override
  void dispose() {
    _fabTimer?.cancel();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 화면에서 다시 돌아왔을 때 이벤트 새로고침
    _loadAllEventsAndSet();
    _checkRestTimer();
  }

  Future<void> _loadAllEventsAndSet() async {
    try {
      final events = await _loadAllEvents();
      setState(() {
        _events = events;
      });
    } catch (e, stack) {
      debugPrint('캘린더 이벤트 로딩 중 에러: $e\n$stack');
    }
  }

  Future<Map<String, List<String>>> _loadAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('workouts_'));
    final Map<String, List<String>> events = {};
    for (final key in keys) {
      final dateStr = key.replaceFirst('workouts_', '');
      try {
        if (dateStr.length != 10) continue; // yyyy-MM-dd
        final workoutsJson = prefs.getStringList(key) ?? [];
        final names = <String>[];
        for (final jsonStr in workoutsJson) {
          try {
            final workout = jsonDecode(jsonStr);
            final name = workout['name'];
            final id = workout['id']?.toString() ?? '';
            if (name != null) names.add('$name#$id');
          } catch (e) {
            debugPrint('운동 json 파싱 에러: $e ($jsonStr)');
          }
        }
        if (names.isNotEmpty) {
          events[dateStr] = names;
        }
      } catch (e) {
        debugPrint('날짜 파싱 에러: $e ($dateStr)');
      }
    }
    return events;
  }

  List<String> _getEventsForDay(DateTime day) {
    final key = "${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}";
    return _events[key] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    final now = DateTime.now();
    
    if (_lastTapTime != null &&
        isSameDay(selectedDay, _selectedDay)) {
      // 더블 클릭: WorkoutScreen으로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WorkoutScreen(
            selectedDate: selectedDay,
          ),
        ),
      );
      _lastTapTime = null;
    } else {
      // 첫 번째 클릭: 날짜 선택
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _lastTapTime = now;
      });
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  Future<void> _checkRestTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString('rest_timer_start');
    final duration = prefs.getInt('rest_timer_duration') ?? 0;
    final exerciseName = prefs.getString('rest_exercise_name');
    final dateStr = prefs.getString('rest_selected_date');
    //print('[캘린더] 타이머 체크: start=$startStr, duration=$duration, name=$exerciseName, date=$dateStr');
    if (startStr != null && duration > 0 && exerciseName != null && dateStr != null) {
      final start = DateTime.tryParse(startStr);
      if (start != null) {
        final elapsed = DateTime.now().difference(start).inSeconds;
        final remain = duration - elapsed;
        //print('[캘린더] remain=$remain');
        if (remain > 0) {
          //print('[캘린더] setState로 FAB 표시');
          setState(() {
            _showRestFab = true;
            _restRemain = remain;
            _exerciseName = exerciseName;
            _selectedDate = DateTime.tryParse(dateStr);
          });
          return;
        }
      }
    }
    //print('[캘린더] setState로 FAB 숨김');
    setState(() {
      _showRestFab = false;
    });
  }

  void _goToRestingExercise() {
    if (_exerciseName != null && _selectedDate != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExerciseDetailScreen(
            exerciseName: _exerciseName!,
            selectedDate: _selectedDate!,
            initialWeight: 0,
            initialSets: 1,
          ),
        ),
      ).then((_) => _checkRestTimer());
    }
  }

  @override
  Widget build(BuildContext context) {
    //print('[캘린더] build 호출, _showRestFab=$_showRestFab, _restRemain=$_restRemain, _fabOffset=$_fabOffset');
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('캘린더'),
            actions: [
              IconButton(
                icon: const Icon(Icons.analytics),
                tooltip: '통계',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const StatisticsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // 오늘 날짜로 WorkoutScreen 열기
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutScreen(
                        selectedDate: DateTime.now(),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onFormatChanged: _onFormatChanged,
                onPageChanged: _onPageChanged,
                eventLoader: _getEventsForDay,
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red),
                  holidayTextStyle: TextStyle(color: Colors.red),
                  selectedDecoration: BoxDecoration(
                    color: Colors.purple,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.purpleAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(
                child: _selectedDay == null
                    ? const Center(child: Text('날짜를 선택해주세요'))
                    : ListView(
                        children: _getEventsForDay(_selectedDay!).isEmpty
                            ? [
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: Text('선택한 날짜에 운동 기록이 없습니다'),
                                  ),
                                )
                              ]
                            : _getEventsForDay(_selectedDay!).map((event) {
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 4.0,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  child: ListTile(
                                    title: Text(event.split('#').first),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WorkoutScreen(
                                            selectedDate: _selectedDay!,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                      ),
              ),
            ],
          ),
        ),
        RestFabOverlay(),
      ],
    );
  }
} 