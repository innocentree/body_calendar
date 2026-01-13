import 'package:body_calendar/features/settings/presentation/screens/settings_screen.dart';
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
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// RouteObserver를 사용할 수 있도록 글로벌 변수 선언
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with RouteAware {
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _lastTapTime;
  Map<String, List<String>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadAllEventsAndSet();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
    _loadAllEventsAndSet();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // 다른 화면에서 다시 돌아왔을 때 이벤트 새로고침
    _loadAllEventsAndSet();
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

  

  Widget _buildViewToggleButton(String text, CalendarFormat format) {
    final isSelected = _calendarFormat == format;
    return GestureDetector(
      onTap: () {
        setState(() {
          _calendarFormat = format;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                  )
                ]
              : null,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCapsule(BuildContext context, DateTime day, {required bool isSelected, required bool isToday}) {
    final events = _getEventsForDay(day);
    final hasEvent = events.isNotEmpty;
    
    // Color Logic
    final backgroundColor = isSelected 
        ? AppColors.customSurface 
        : (isToday ? const Color.fromARGB(255, 34, 41, 53) : Colors.transparent);
        
    final borderColor = (!isSelected && !isToday) 
        ? Colors.grey[700] 
        : null;
        
    final textColor = isSelected 
        ? Colors.white 
        : (isToday ? Colors.white : Colors.grey);

    return Container(
      width: double.infinity, // Maximize width
      margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 4), // Further reduced width (margin 5 -> 7)
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(50),
        border: borderColor != null ? Border.all(color: borderColor, width: 1.5) : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.E('en_US').format(day)[0], 
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          // Dot
          Container(
             width: 6,
             height: 6,
             decoration: BoxDecoration(
               color: hasEvent 
                   ? Theme.of(context).primaryColor // Neon dot always
                   : Colors.transparent,
               shape: BoxShape.circle,
               boxShadow: hasEvent
                   ? [
                       BoxShadow(
                         color: Theme.of(context).primaryColor.withOpacity(0.8),
                         blurRadius: 6,
                         spreadRadius: 1,
                       )
                     ] 
                   : null,
             ),
          ),
        ],
      ),
    );
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
                icon: const Icon(Icons.settings),
                tooltip: '설정',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
              ),
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
            ],
          ),
          body: Column(
            children: [
              // View Toggle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildViewToggleButton('월간', CalendarFormat.month),
                    _buildViewToggleButton('주간', CalendarFormat.week),
                  ],
                ),
              ),
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                rowHeight: _calendarFormat == CalendarFormat.week ? 85 : 52,
                daysOfWeekVisible: _calendarFormat == CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: _onDaySelected,
                onFormatChanged: _onFormatChanged,
                onPageChanged: _onPageChanged,
                eventLoader: _getEventsForDay,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[300]),
                  holidayTextStyle: TextStyle(color: Colors.red[300]),
                  
                  // Selected Day
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  selectedTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  
                  // Today
                  todayDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).primaryColor, width: 1.5),
                  ),
                  todayTextStyle: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                  
                  // Default
                  defaultTextStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.notoSansKr(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Theme.of(context).iconTheme.color),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Theme.of(context).iconTheme.color),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_calendarFormat == CalendarFormat.week) {
                      return _buildWeekCapsule(context, day, isSelected: false, isToday: isSameDay(day, DateTime.now()));
                    }
                    return Container(
                      margin: const EdgeInsets.all(4),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.day}',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    if (_calendarFormat == CalendarFormat.week) {
                      return _buildWeekCapsule(context, day, isSelected: true, isToday: isSameDay(day, DateTime.now()));
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    if (_calendarFormat == CalendarFormat.week) {
                      return _buildWeekCapsule(context, day, isSelected: false, isToday: true);
                    }
                    return null;
                  },
                  markerBuilder: (context, day, events) {
                    if (_calendarFormat == CalendarFormat.week) return const SizedBox.shrink(); // Force hide markers
                    
                    if (events.isEmpty) return null;
                    return Positioned(
                      bottom: 8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: events.take(3).map((_) {
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.secondary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16.0),
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
                                final parts = event.split('#');
                                final name = parts.first;
                                // Use hash of name to pick a color for variety, or cycle through chartColors
                                final randomColor = AppColors.chartColors[name.hashCode % AppColors.chartColors.length];
                                
                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.customSurface,
                                    borderRadius: BorderRadius.circular(20.0),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(20.0),
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
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    name,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                Icon(Icons.chevron_right, color: Colors.grey[600]),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            const Text(
                                              "운동 완료", 
                                              style: TextStyle(color: Colors.grey, fontSize: 13),
                                            ),
                                            const SizedBox(height: 16),
                                            
                                            // Progress Bar Decoration
                                            Container(
                                              height: 6,
                                              width: 100, // Fixed width or flexible
                                              decoration: BoxDecoration(
                                                color: randomColor,
                                                borderRadius: BorderRadius.circular(3),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: randomColor.withOpacity(0.5),
                                                    blurRadius: 6,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                      ),
              ),
            ],
          ),
          floatingActionButton: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(32),
                onTap: () {
                   if (_selectedDay != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WorkoutScreen(
                            selectedDate: _selectedDay!,
                          ),
                        ),
                      );
                   }
                },
                child: const Icon(
                  Icons.add,
                  color: Colors.black,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
        // Return to Today Button
        if (!isSameDay(_focusedDay, DateTime.now()))
          Positioned(
            left: 20,
            bottom: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  final now = DateTime.now();
                  setState(() {
                    _focusedDay = now;
                    _selectedDay = now;
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.customSurface.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.today, color: Theme.of(context).primaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '오늘로 이동',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        const RestFabOverlay(),
      ],
    );
  }
} 