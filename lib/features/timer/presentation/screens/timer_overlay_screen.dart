import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:body_calendar/core/theme/app_colors.dart';

class TimerOverlayScreen extends StatefulWidget {
  const TimerOverlayScreen({super.key});

  @override
  State<TimerOverlayScreen> createState() => _TimerOverlayScreenState();
}

class _TimerOverlayScreenState extends State<TimerOverlayScreen> {
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        if (event.containsKey('totalDuration') &&
            event.containsKey('remainingTime')) {
          // Update via shareData (if used)
          setState(() {
            _remainingTime = event['remainingTime'] as int;
          });
        }
      }
    });

    // Initial data might be needed if not passed via shareData immediately
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    // Note: The overlay size is determined by the window size set in showOverlay
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.customSurface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.45), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 18,
                offset: const Offset(0, 4),
              )
            ]),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Wrap content
          children: [
            // Since we might not get exercise name easily through simple shareData without modifying the sender,
            // let's rely on what we can pass.
            // Actually, overlay_helper_impl.dart currently passes title/content in showOverlay.
            // But for real-time updates, we need shareData.

            // Let's assume the user just wants the timer countdown.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  _formatDuration(_remainingTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '터치하여 앱으로 돌아가기',
              style: TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 10,
                decoration: TextDecoration.none,
              ),
            )
          ],
        ),
      ),
    );
  }
}
