import 'package:flutter/material.dart';

Future<void> ensureOverlayPermission() async {}

Future<void> showOverlayFAB({
  required String exerciseName,
  required int restTime,
  required VoidCallback onComplete,
}) async {}

Future<void> updateOverlayFAB({
  required int totalDuration,
  required int remainingTime,
}) async {}

Future<void> closeOverlayFAB() async {}
