import 'package:body_calendar/features/timer/data/rest_timer_overlay_bridge.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(RestTimerOverlayBridge.channelName);
  late List<MethodCall> calls;
  late RestTimerOverlayBridge bridge;

  setUp(() {
    calls = [];
    bridge = RestTimerOverlayBridge(channel: channel);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'isPermissionGranted') return false;
      if (call.method == 'requestPermission') return false;
      if (call.method == 'consumeOpenTimerRequest') return false;
      return null;
    });
  });

  tearDown(() {
    bridge.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('sends a stable deadline payload when starting a timer', () async {
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(1800000000000);
    const metadata = RestTimerOverlayMetadata(
      exerciseName: '벤치프레스',
      selectedDateEpochMs: 1700000000000,
      ownerId: 'owner-1',
      groupId: 'group-1',
      sessionIndex: 2,
      recordDay: 4,
    );

    await bridge.start(
      initialDuration: 90,
      remainingTime: 87,
      expiresAt: expiresAt,
      metadata: metadata,
    );

    expect(calls, hasLength(1));
    expect(calls.single.method, 'start');
    expect(calls.single.arguments, {
      'initialDuration': 90,
      'remainingTime': 87,
      'expiresAtEpochMs': 1800000000000,
      'exerciseName': '벤치프레스',
      'selectedDateEpochMs': 1700000000000,
      'ownerId': 'owner-1',
      'groupId': 'group-1',
      'sessionIndex': 2,
      'recordDay': 4,
    });
  });

  test('sends pause, visibility, and stop commands without timer restarts',
      () async {
    await bridge.pause(initialDuration: 60, remainingTime: 42);
    await bridge.setAppVisible(false);
    await bridge.stop();

    expect(calls.map((call) => call.method), [
      'pause',
      'setAppVisible',
      'stop',
    ]);
    expect(calls[0].arguments, {
      'initialDuration': 60,
      'remainingTime': 42,
    });
    expect(calls[1].arguments, {'visible': false});
  });

  test('cold-open request is consumed after bridge initialization', () async {
    var openCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'consumeOpenTimerRequest') return true;
      return null;
    });

    await bridge.initialize(onOpenTimer: () => openCount++);
    if (await bridge.consumeOpenTimerRequest()) openCount++;

    expect(openCount, 1);
    expect(calls.single.method, 'consumeOpenTimerRequest');
  });

  test('parses a persisted native timer snapshot with group metadata',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method == 'getSnapshot') {
        return {
          'active': true,
          'paused': true,
          'initialDuration': 120,
          'remainingTime': 46,
          'exerciseName': '스쿼트 · 런지',
          'selectedDateEpochMs': 1710000000000,
          'ownerId': 'round-owner',
          'groupId': 'legs',
          'sessionIndex': 3,
          'recordDay': 8,
        };
      }
      return null;
    });

    final snapshot = await bridge.getSnapshot();

    expect(snapshot, isNotNull);
    expect(snapshot!.isPaused, isTrue);
    expect(snapshot.remainingTime, 46);
    expect(snapshot.metadata.exerciseName, '스쿼트 · 런지');
    expect(snapshot.metadata.groupId, 'legs');
    expect(snapshot.metadata.sessionIndex, 3);
    expect(snapshot.metadata.recordDay, 8);
  });
}
