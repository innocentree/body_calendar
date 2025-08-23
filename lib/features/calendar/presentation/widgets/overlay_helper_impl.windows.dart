import 'package:flutter/material.dart';

Future<void> showOverlayFAB() async {
  // 윈도우즈에서는 오버레이 미지원
  return;
}

Future<void> closeOverlayFAB() async {
  // 윈도우즈에서는 오버레이 미지원
  return;
}

class OverlayEntryWidget extends StatelessWidget {
  const OverlayEntryWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
} 