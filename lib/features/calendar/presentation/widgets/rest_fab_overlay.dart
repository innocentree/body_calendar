import 'dart:convert';

import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/workout/domain/models/workout_record.dart';
import 'package:body_calendar/features/workout/presentation/screens/grouped_exercise_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';

class RestFabOverlay extends StatefulWidget {
  const RestFabOverlay({Key? key}) : super(key: key);

  @override
  State<RestFabOverlay> createState() => _RestFabOverlayState();
}

class _RestFabOverlayState extends State<RestFabOverlay> {
  Offset _fabOffset = const Offset(16, 16);
  Offset? _dragStartOffset;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _loadFabOffset();
  }

  Future<void> _loadFabOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('rest_fab_offset_dx') ?? 16.0;
    final dy = prefs.getDouble('rest_fab_offset_dy') ?? 16.0;
    if (mounted) {
      setState(() {
        _fabOffset = Offset(dx, dy);
      });
    }
  }

  Future<void> _saveFabOffset(Offset offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rest_fab_offset_dx', offset.dx);
    await prefs.setDouble('rest_fab_offset_dy', offset.dy);
  }

  Future<void> _goToRestingExercise(TimerBloc bloc) async {
    final exerciseName = bloc.exerciseName;
    final selectedDate = bloc.selectedDate;
    if (exerciseName == null || selectedDate == null) return;

    final groupContext = bloc.groupNavigationContext;
    if (groupContext != null) {
      final prefs = await SharedPreferences.getInstance();
      final date = DateFormat('yyyy-MM-dd').format(selectedDate);
      final stored = prefs.getStringList('workouts_$date') ?? const [];
      final workouts = <WorkoutRecord>[];
      try {
        workouts.addAll(stored
            .map((raw) => WorkoutRecord.fromJson(jsonDecode(raw)))
            .where((workout) =>
                workout.groupId == groupContext.groupId &&
                workout.sessionIndex == groupContext.sessionIndex));
      } catch (_) {
        workouts.clear();
      }
      workouts.sort(
        (a, b) => (a.groupOrder ?? 0).compareTo(b.groupOrder ?? 0),
      );
      if (!mounted) return;
      if (workouts.isEmpty) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(content: Text('이 그룹 운동을 찾을 수 없어요.')),
        );
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => GroupedExerciseDetailScreen(
            workouts: workouts,
            selectedDate: selectedDate,
            recordDay: groupContext.recordDay,
          ),
          settings: const RouteSettings(name: '/grouped_exercise_detail'),
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseDetailScreen(
          exerciseName: exerciseName,
          selectedDate: selectedDate,
          initialWeight: 0,
          initialSets: 1,
        ),
        settings: const RouteSettings(name: '/exercise_detail'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimerBloc, TimerState>(
      builder: (context, state) {
        final isExerciseDetail = const {
          '/exercise_detail',
          '/grouped_exercise_detail'
        }.contains(ModalRoute.of(context)?.settings.name);
        if (state is! TimerRunInProgress || isExerciseDetail) {
          return const SizedBox.shrink();
        }

        final mq = MediaQuery.of(context);
        return Positioned(
          right: _fabOffset.dx,
          bottom: _fabOffset.dy + mq.padding.bottom,
          child: GestureDetector(
            onPanStart: (details) {
              _dragStartOffset = _fabOffset;
              _dragStartPosition = details.globalPosition;
            },
            onPanUpdate: (details) {
              if (_dragStartOffset != null && _dragStartPosition != null) {
                final dx = details.globalPosition.dx - _dragStartPosition!.dx;
                final dy = details.globalPosition.dy - _dragStartPosition!.dy;
                double newRight = (_dragStartOffset!.dx - dx);
                double newBottom = (_dragStartOffset!.dy - dy);
                final maxRight = mq.size.width - 72;
                final maxBottom = mq.size.height - 72;
                newRight =
                    newRight.clamp(0.0, maxRight.isFinite ? maxRight : 0.0);
                newBottom =
                    newBottom.clamp(0.0, maxBottom.isFinite ? maxBottom : 0.0);
                if (newRight.isNaN ||
                    newBottom.isNaN ||
                    newRight < 0 ||
                    newBottom < 0) return;
                setState(() {
                  _fabOffset = Offset(newRight, newBottom);
                });
              }
            },
            onPanEnd: (_) {
              if (_fabOffset != null) {
                _saveFabOffset(_fabOffset);
              }
              _dragStartOffset = null;
              _dragStartPosition = null;
            },
            child: _buildFab(context, state.duration),
          ),
        );
      },
    );
  }

  Widget _buildFab(BuildContext context, int duration) {
    final bloc = context.read<TimerBloc>();
    return GestureDetector(
      onTap: () => _goToRestingExercise(bloc),
      child: Container(
        key: const ValueKey('rest-fab-overlay'),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.deepPurple,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              '$duration',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.none,
                fontSize: 40,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
