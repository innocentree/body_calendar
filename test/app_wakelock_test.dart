import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:body_calendar/core/widgets/app_wakelock.dart';

class _RecordingWakelock {
  final List<bool> changes = <bool>[];

  Future<void> call(bool enable) async {
    changes.add(enable);
  }
}

void main() {
  testWidgets('enables on startup and follows app lifecycle', (tester) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final recordingPlatform = _RecordingWakelock();
    await tester.pumpWidget(
      AppWakelock(
        child: const SizedBox(),
        wakelockHandler: recordingPlatform.call,
      ),
    );
    await tester.pump();
    expect(recordingPlatform.changes, <bool>[true]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(recordingPlatform.changes, <bool>[true, false]);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(recordingPlatform.changes, <bool>[true, false, true]);

    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(recordingPlatform.changes, <bool>[true, false, true, false]);
  });
}
