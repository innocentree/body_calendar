import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

Future<void> ensureOverlayPermission() async {
  if (Platform.isAndroid) {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
  }
}

Future<void> showOverlayFAB({
  required String exerciseName,
  required int restTime,
  required VoidCallback onComplete,
}) async {
  if (Platform.isAndroid) {
    await ensureOverlayPermission();
    final granted = await FlutterOverlayWindow.isPermissionGranted();
    if (granted) {
      await FlutterOverlayWindow.showOverlay(
        enableDrag: true,
        flag: OverlayFlag.defaultFlag,
        alignment: OverlayAlignment.centerRight,
        visibility: NotificationVisibility.visibilitySecret,
        positionGravity: PositionGravity.auto,
        height: 120, // width is deprecated or not used in some versions, relying on content
        width: 120,
      );
      // Pass initial data
      await updateOverlayFAB(totalDuration: restTime, remainingTime: restTime);
    } 
  }
}

Future<void> updateOverlayFAB({required int totalDuration, required int remainingTime}) async {
  if (Platform.isAndroid && await FlutterOverlayWindow.isActive()) {
    await FlutterOverlayWindow.shareData({
      'totalDuration': totalDuration,
      'remainingTime': remainingTime,
    });
  }
}

Future<void> closeOverlayFAB() async {
  if (Platform.isAndroid && await FlutterOverlayWindow.isActive()) {
    await FlutterOverlayWindow.closeOverlay();
  }
} 