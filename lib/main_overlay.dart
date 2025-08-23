import 'package:body_calendar/features/calendar/presentation/widgets/timer_overlay_widget.dart';
import 'package:flutter/material.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(const MaterialApp(
    home: TimerOverlayWidget(),
    debugShowCheckedModeBanner: false,
  ));
}
