import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:body_calendar/features/workout/presentation/screens/exercise_detail_screen.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'dart:io' show Platform;

class RestFabOverlay extends StatefulWidget {
  const RestFabOverlay({Key? key}) : super(key: key);

  @override
  State<RestFabOverlay> createState() => _RestFabOverlayState();
}

class _RestFabOverlayState extends State<RestFabOverlay> {
  bool _showRestFab = false;
  int _restRemain = 0;
  String? _exerciseName;
  DateTime? _selectedDate;
  Timer? _timer;
  Offset _fabOffset = const Offset(16, 16);
  Offset? _dragStartOffset;
  Offset? _dragStartPosition;

  @override
  void initState() {
    super.initState();
    _loadFabOffset();
    _checkRestTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _checkRestTimer());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadFabOffset() async {
    final prefs = await SharedPreferences.getInstance();
    final dx = prefs.getDouble('rest_fab_offset_dx') ?? 16.0;
    final dy = prefs.getDouble('rest_fab_offset_dy') ?? 16.0;
    setState(() {
      _fabOffset = Offset(dx, dy);
    });
  }

  Future<void> _saveFabOffset(Offset offset) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('rest_fab_offset_dx', offset.dx);
    await prefs.setDouble('rest_fab_offset_dy', offset.dy);
  }

  Future<void> _checkRestTimer() async {
    final prefs = await SharedPreferences.getInstance();
    final startStr = prefs.getString('rest_timer_start');
    final duration = prefs.getInt('rest_timer_duration') ?? 0;
    final exerciseName = prefs.getString('rest_exercise_name');
    final dateStr = prefs.getString('rest_selected_date');
    if (startStr != null && duration > 0 && exerciseName != null && dateStr != null) {
      final start = DateTime.tryParse(startStr);
      if (start != null) {
        final elapsed = DateTime.now().difference(start).inSeconds;
        final remain = duration - elapsed;
        if (remain > 0) {
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
    setState(() {
      _showRestFab = false;
    });
  }

  void _goToRestingExercise() {
    if (_exerciseName != null && _selectedDate != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExerciseDetailScreen(
            exerciseName: _exerciseName!,
            selectedDate: _selectedDate!,
            initialWeight: 0,
            initialSets: 1,
          ),
          settings: const RouteSettings(name: '/exercise_detail'),
        ),
      ).then((_) => _checkRestTimer());
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExerciseDetail = ModalRoute.of(context)?.settings.name == '/exercise_detail';
    if (!_showRestFab || isExerciseDetail) return const SizedBox.shrink();
    final mq = MediaQuery.of(context);
    return Positioned(
      right: _fabOffset.dx,
      bottom: _fabOffset.dy,
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
            newRight = newRight.clamp(0.0, maxRight.isFinite ? maxRight : 0.0);
            newBottom = newBottom.clamp(0.0, maxBottom.isFinite ? maxBottom : 0.0);
            if (newRight.isNaN || newBottom.isNaN || newRight < 0 || newBottom < 0) return;
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
        child: _buildFab(),
      ),
    );
  }

  Widget _buildFab() {
    return GestureDetector(
      onTap: _goToRestingExercise,
      child: Container(
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
              '$_restRemain',
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