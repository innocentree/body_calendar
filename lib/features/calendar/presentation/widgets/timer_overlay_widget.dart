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
  StreamSubscription<dynamic>? _dataSubscription;

  @override
  void initState() {
    super.initState();
    _listenForData();
  }

  void _listenForData() {
    _dataSubscription = FlutterOverlayWindow.overlayListener.listen((data) {
      final Map<String, dynamic>? parsed = switch (data) {
        Map<String, dynamic> value => value,
        String value => _tryParseMap(value),
        _ => null,
      };

      if (parsed != null && mounted) {
        setState(() {
          _totalDuration = parsed['totalDuration'] ?? 1;
          _remainingTime = parsed['remainingTime'] ?? 0;
        });
      }
    });
  }

  Map<String, dynamic>? _tryParseMap(String data) {
    try {
      final value = data.startsWith('{')
          ? Map<String, dynamic>.from(
              Map<String, dynamic>.fromEntries(
                (data
                        .replaceAll('{', '')
                        .replaceAll('}', '')
                        .split(','))
                    .where((e) => e.contains(':'))
                    .map((e) {
                  final parts = e.split(':');
                  return MapEntry(parts.first.trim(), int.tryParse(parts.last.trim()) ?? parts.last.trim());
                }),
              ),
            )
          : null;
      return value;
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {},
        child: Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    end: (_totalDuration > 0) ? _remainingTime / _totalDuration : 0.0,
                  ),
                  duration: const Duration(milliseconds: 1000), // Smooth transition over 1 second
                  curve: Curves.linear, // Or Curves.easeInOut for damping effect
                  builder: (context, value, _) {
                    return CircularProgressIndicator(
                      value: value,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                    );
                  },
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
