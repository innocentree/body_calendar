import 'dart:io';
import 'package:flutter/foundation.dart';
import 'overlay_helper_impl.android.dart' as android;
import 'overlay_helper_impl.windows.dart' as windows;

Future<void> ensureOverlayPermission() async {
  if (!kIsWeb && Platform.isAndroid) {
    await android.ensureOverlayPermission();
  }
}

Future<void> showOverlayFAB({
  required String exerciseName,
  required int restTime,
  required Function() onComplete,
}) async {
  if (kIsWeb) return;
  if (Platform.isWindows) {
    await windows.showOverlayFAB(
      exerciseName: exerciseName,
      restTime: restTime,
      onComplete: onComplete,
    );
  } else if (Platform.isAndroid) {
    await android.showOverlayFAB(
      exerciseName: exerciseName,
      restTime: restTime,
      onComplete: onComplete,
    );
  }
}

Future<void> updateOverlayFAB({required int totalDuration, required int remainingTime}) async {
  if (kIsWeb) return;
  if (Platform.isWindows) {
    await windows.updateOverlayFAB(totalDuration: totalDuration, remainingTime: remainingTime);
  } else if (Platform.isAndroid) {
    await android.updateOverlayFAB(totalDuration: totalDuration, remainingTime: remainingTime);
  }
}

Future<void> closeOverlayFAB() async {
  if (kIsWeb) return;
  if (Platform.isWindows) {
    await windows.closeOverlayFAB();
  } else if (Platform.isAndroid) {
    await android.closeOverlayFAB();
  }
}
