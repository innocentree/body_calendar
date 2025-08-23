export 'overlay_helper_impl.android.dart' if (dart.library.io) 'overlay_helper_impl.windows.dart';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:intl/intl.dart';

Future<void> ensureOverlayPermission() async {
  if (!await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.requestPermission();
  }
}

Future<void> showOverlayFAB({
  required String exerciseName,
  required int restTime,
  required VoidCallback onComplete,
}) async {
  await ensureOverlayPermission();
  final granted = await FlutterOverlayWindow.isPermissionGranted();
  print('[오버레이 권한] granted: $granted');
  if (granted) {
    print('[오버레이] showOverlayFAB 호출됨');
    await FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "휴식 타이머",
      overlayContent: "운동: $exerciseName\n남은 시간: ${_formatDuration(restTime)}",
      flag: OverlayFlag.defaultFlag,
      alignment: OverlayAlignment.centerRight,
      visibility: NotificationVisibility.visibilityPublic,
      positionGravity: PositionGravity.auto,
      width: 160,
      height: 160,
    );
  } else {
    print('[오버레이] 권한이 없어 오버레이를 띄울 수 없습니다.');
  }
}

Future<void> updateOverlayFAB({required int totalDuration, required int remainingTime}) async {
  if (await FlutterOverlayWindow.isActive()) {
    await FlutterOverlayWindow.shareData({
      'totalDuration': totalDuration,
      'remainingTime': remainingTime,
    });
  }
}

Future<void> closeOverlayFAB() async {
  if (await FlutterOverlayWindow.isPermissionGranted()) {
    await FlutterOverlayWindow.closeOverlay();
  }
}

String _formatDuration(int seconds) {
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}
