import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:body_calendar/core/theme/app_colors.dart';

class TimerOverlayScreen extends StatefulWidget {
  const TimerOverlayScreen({super.key});

  @override
  State<TimerOverlayScreen> createState() => _TimerOverlayScreenState();
}

class _TimerOverlayScreenState extends State<TimerOverlayScreen> {
  String _exerciseName = '';
  int _remainingTime = 0;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        if (event.containsKey('totalDuration') && event.containsKey('remainingTime')) {
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
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.neonLime, width: 2),
          boxShadow: [
             BoxShadow(
               color: AppColors.neonLime.withOpacity(0.3),
               blurRadius: 8,
               offset: const Offset(0, 4),
             )
          ]
        ),
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
                 const Icon(Icons.timer, color: AppColors.neonLime, size: 20),
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
               '터치하여 복귀',
               style: TextStyle(
                 color: Colors.white.withOpacity(0.7),
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
