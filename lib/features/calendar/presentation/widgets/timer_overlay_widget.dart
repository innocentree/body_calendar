import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class TimerOverlayWidget extends StatefulWidget {
  const TimerOverlayWidget({super.key});

  @override
  State<TimerOverlayWidget> createState() => _TimerOverlayWidgetState();
}

class _TimerOverlayWidgetState extends State<TimerOverlayWidget> {
  int _totalDuration = 1;
  int _remainingTime = 0;

  @override
  void initState() {
    super.initState();
    _listenForData();
  }

  void _listenForData() {
    FlutterOverlayWindow.shareData.listen((data) {
      if (data is Map<String, dynamic>) {
        setState(() {
          _totalDuration = data['totalDuration'] ?? 1;
          _remainingTime = data['remainingTime'] ?? 0;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => FlutterOverlayWindow.activateApp(),
        child: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: (_totalDuration > 0) ? _remainingTime / _totalDuration : 0.0,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                ),
                Center(
                  child: Text(
                    '$_remainingTime',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
