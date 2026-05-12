import 'package:body_calendar/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../workout/presentation/screens/workout_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../workout/presentation/screens/statistics_screen.dart';
import 'dart:async';
import 'package:body_calendar/features/calendar/presentation/widgets/rest_fab_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

const _calendarBorderColor = Color(0xFF3A342E);
const _calendarMutedSurface = Color(0xFF211D19);
const _calendarSoftSurface = Color(0xFF2A2520);

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  Map<DateTime, List<String>> _events = {};
  bool _showRestFab = false;
  Duration _restRemain = Duration.zero;
  final Offset _fabOffset = const Offset(0, 0);
  Timer? _restFabTimer;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadEvents();
    _restoreRestFabState();
  }

  @override
  void dispose() {
    _restFabTimer?.cancel();
    super.dispose();
  }

  Future<void> _restoreRestFabState() async {
    final prefs = await SharedPreferences.getInstance();
    final isVisible = prefs.getBool('rest_fab_visible') ?? false;
    final endMillis = prefs.getInt('rest_fab_end_time');

    if (!isVisible || endMillis == null) return;

    final endTime = DateTime.fromMillisecondsSinceEpoch(endMillis);
    final remain = endTime.difference(DateTime.now());
    if (remain.inSeconds <= 0) {
      await prefs.remove('rest_fab_visible');
      await prefs.remove('rest_fab_end_time');
      return;
    }

    setState(() {
      _showRestFab = true;
      _restRemain = remain;
    });

    _restFabTimer?.cancel();
    _restFabTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final newRemain = endTime.difference(DateTime.now());
      if (newRemain.inSeconds <= 0) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _showRestFab = false;
            _restRemain = Duration.zero;
          });
        }
        await prefs.remove('rest_fab_visible');
        await prefs.remove('rest_fab_end_time');
      } else {
        if (mounted) {
          setState(() {
            _restRemain = newRemain;
          });
        }
      }
    });
  }

  Future<void> _loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final Map<DateTime, List<String>> loadedEvents = {};

    for (final key in keys) {
      if (key.startsWith('workout_records_')) {
        final dateString = key.replaceFirst('workout_records_', '');
        try {
          final date = DateTime.parse(dateString);
          final List<String> stored = prefs.getStringList(key) ?? [];
          final names = stored.map((json) {
            final map = jsonDecode(json);
            return map['name']?.toString() ?? '운동';
          }).toList();
          if (names.isNotEmpty) {
            loadedEvents[DateTime(date.year, date.month, date.day)] = names;
          }
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() {
        _events = loadedEvents;
      });
    }
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
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
      onTap: () => _onFormatChanged(format),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _calendarSoftSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)
                : Colors.transparent,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).textTheme.bodyLarge?.color
                : Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withValues(alpha: 0.62),
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekCapsule(
    BuildContext context,
    DateTime day, {
    required bool isSelected,
    required bool isToday,
  }) {
    final hasEvent = _getEventsForDay(day).isNotEmpty;
    final backgroundColor = isSelected
        ? _calendarSoftSurface
        : (isToday ? _calendarMutedSurface : Colors.transparent);
    final borderColor = isSelected
        ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.28)
        : (isToday
            ? _calendarBorderColor
            : _calendarBorderColor.withValues(alpha: 0.72));
    final textColor = isSelected || isToday
        ? Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white
        : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.72) ??
            Colors.grey;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.E('en_US').format(day)[0],
            style: TextStyle(
              color: textColor.withValues(alpha: 0.66),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${day.day}',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: hasEvent ? 14 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: hasEvent
                  ? Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: isSelected ? 0.95 : 0.7)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    MaterialPageRoute(
                      builder: (context) => const SettingsScreen(),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.analytics),
                tooltip: '통계',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StatisticsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _calendarMutedSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _calendarBorderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '세션 캘린더',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _selectedDay == null
                              ? '기록이 남은 날짜를 선택해 세션 로그를 확인해보세요.'
                              : '${DateFormat('M월 d일 EEEE', 'ko_KR').format(_selectedDay!)} 기록을 보고 있어요.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color
                                        ?.withValues(alpha: 0.68),
                                  ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.customBackground.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  _calendarBorderColor.withValues(alpha: 0.85),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildViewToggleButton('월간', CalendarFormat.month),
                              _buildViewToggleButton('주간', CalendarFormat.week),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    decoration: BoxDecoration(
                      color: _calendarMutedSurface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _calendarBorderColor),
                    ),
                    child: TableCalendar(
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
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.6),
                            width: 1,
                          ),
                        ),
                        todayTextStyle: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        defaultTextStyle: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: FontWeight.w600,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.72),
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        headerPadding: const EdgeInsets.symmetric(vertical: 8),
                        titleTextStyle: GoogleFonts.notoSansKr(
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).textTheme.titleLarge?.color,
                        ),
                        leftChevronIcon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.customBackground
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chevron_left,
                            color: Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                        rightChevronIcon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.customBackground
                                .withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.chevron_right,
                            color: Theme.of(context).iconTheme.color,
                            size: 20,
                          ),
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                          if (_calendarFormat == CalendarFormat.week) {
                            return _buildWeekCapsule(
                              context,
                              day,
                              isSelected: false,
                              isToday: isSameDay(day, DateTime.now()),
                            );
                          }
                          return Container(
                            margin: const EdgeInsets.all(4),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          if (_calendarFormat == CalendarFormat.week) {
                            return _buildWeekCapsule(
                              context,
                              day,
                              isSelected: true,
                              isToday: isSameDay(day, DateTime.now()),
                            );
                          }
                          return null;
                        },
                        todayBuilder: (context, day, focusedDay) {
                          if (_calendarFormat == CalendarFormat.week) {
                            return _buildWeekCapsule(
                              context,
                              day,
                              isSelected: false,
                              isToday: true,
                            );
                          }
                          return null;
                        },
                        markerBuilder: (context, day, events) {
                          if (_calendarFormat == CalendarFormat.week) {
                            return const SizedBox.shrink();
                          }
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
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.75),
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _selectedDay == null
                      ? const Center(child: Text('날짜를 선택해보세요'))
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                          children: _getEventsForDay(_selectedDay!).isEmpty
                              ? [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 28,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _calendarMutedSurface,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: _calendarBorderColor,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.event_note_rounded,
                                          size: 28,
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.color
                                              ?.withValues(alpha: 0.5),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          '아직 기록된 운동이 없어요',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '오른쪽 아래 버튼으로 오늘의 운동을 추가해보세요.',
                                          textAlign: TextAlign.center,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium
                                                    ?.color
                                                    ?.withValues(alpha: 0.66),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ]
                              : _getEventsForDay(_selectedDay!).map((event) {
                                  final name = event.split('#').first;
                                  final accent = AppColors.chartColors[
                                      name.hashCode % AppColors.chartColors.length];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: _calendarMutedSurface,
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: _calendarBorderColor,
                                      ),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(22),
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
                                          padding: const EdgeInsets.all(18),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 44,
                                                height: 44,
                                                decoration: BoxDecoration(
                                                  color:
                                                      accent.withValues(alpha: 0.16),
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                                child: Icon(
                                                  Icons.fitness_center_rounded,
                                                  color: accent,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '운동 완료',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: Theme.of(context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.color
                                                                ?.withValues(
                                                                  alpha: 0.86,
                                                                ),
                                                          ),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Container(
                                                      height: 4,
                                                      width: 88,
                                                      decoration: BoxDecoration(
                                                        color: accent.withValues(
                                                          alpha: 0.8,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          999,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.chevron_right_rounded,
                                                color: Theme.of(context)
                                                    .iconTheme
                                                    .color
                                                    ?.withValues(alpha: 0.7),
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
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
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
            child: const Icon(Icons.add_rounded),
          ),
        ),
        if (!isSameDay(_focusedDay, DateTime.now()))
          Positioned(
            left: 20,
            bottom: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _focusedDay = DateTime.now();
                    _selectedDay = DateTime.now();
                  });
                },
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _calendarMutedSurface.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Theme.of(context)
                          .primaryColor
                          .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.today,
                        color: Theme.of(context).primaryColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '오늘 로그로 이동',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
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
