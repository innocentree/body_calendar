import 'package:flutter/services.dart';

class RestTimerOverlayBridge {
  static const channelName = 'body_calendar/rest_timer_overlay';

  final MethodChannel _channel;

  RestTimerOverlayBridge({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(channelName);

  Future<void> initialize({required void Function() onOpenTimer}) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openTimer') {
        onOpenTimer();
        return true;
      }
      return null;
    });
  }

  Future<bool> consumeOpenTimerRequest() async {
    return await _channel.invokeMethod<bool>('consumeOpenTimerRequest') ??
        false;
  }

  Future<RestTimerOverlaySnapshot?> getSnapshot() async {
    final value = await _channel.invokeMethod<Object?>('getSnapshot');
    if (value is! Map) return null;
    return RestTimerOverlaySnapshot.fromMap(Map<Object?, Object?>.from(value));
  }

  Future<bool> isPermissionGranted() async {
    return await _channel.invokeMethod<bool>('isPermissionGranted') ?? false;
  }

  Future<bool> requestPermission() async {
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  Future<void> start({
    required int initialDuration,
    required int remainingTime,
    required DateTime expiresAt,
    required RestTimerOverlayMetadata metadata,
  }) {
    return _channel.invokeMethod<void>('start', {
      'initialDuration': initialDuration,
      'remainingTime': remainingTime,
      'expiresAtEpochMs': expiresAt.millisecondsSinceEpoch,
      ...metadata.toMap(),
    });
  }

  Future<void> update({
    required int initialDuration,
    required int remainingTime,
    required DateTime expiresAt,
    required RestTimerOverlayMetadata metadata,
  }) {
    return _channel.invokeMethod<void>('update', {
      'initialDuration': initialDuration,
      'remainingTime': remainingTime,
      'expiresAtEpochMs': expiresAt.millisecondsSinceEpoch,
      ...metadata.toMap(),
    });
  }

  Future<void> resume({
    required int initialDuration,
    required int remainingTime,
    required DateTime expiresAt,
    required RestTimerOverlayMetadata metadata,
  }) {
    return _channel.invokeMethod<void>('resume', {
      'initialDuration': initialDuration,
      'remainingTime': remainingTime,
      'expiresAtEpochMs': expiresAt.millisecondsSinceEpoch,
      ...metadata.toMap(),
    });
  }

  Future<void> pause({
    required int initialDuration,
    required int remainingTime,
  }) {
    return _channel.invokeMethod<void>('pause', {
      'initialDuration': initialDuration,
      'remainingTime': remainingTime,
    });
  }

  Future<void> stop() => _channel.invokeMethod<void>('stop');

  Future<void> setAppVisible(bool visible) {
    return _channel.invokeMethod<void>('setAppVisible', {'visible': visible});
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
  }
}

class RestTimerOverlayMetadata {
  final String exerciseName;
  final int selectedDateEpochMs;
  final String? ownerId;
  final String? groupId;
  final int? sessionIndex;
  final int? recordDay;

  const RestTimerOverlayMetadata({
    required this.exerciseName,
    required this.selectedDateEpochMs,
    this.ownerId,
    this.groupId,
    this.sessionIndex,
    this.recordDay,
  });

  Map<String, Object?> toMap() => {
        'exerciseName': exerciseName,
        'selectedDateEpochMs': selectedDateEpochMs,
        'ownerId': ownerId,
        'groupId': groupId,
        'sessionIndex': sessionIndex,
        'recordDay': recordDay,
      };
}

class RestTimerOverlaySnapshot {
  final bool isPaused;
  final int initialDuration;
  final int remainingTime;
  final RestTimerOverlayMetadata metadata;

  const RestTimerOverlaySnapshot({
    required this.isPaused,
    required this.initialDuration,
    required this.remainingTime,
    required this.metadata,
  });

  factory RestTimerOverlaySnapshot.fromMap(Map<Object?, Object?> map) {
    int? optionalInt(String key) => (map[key] as num?)?.toInt();

    return RestTimerOverlaySnapshot(
      isPaused: map['paused'] == true,
      initialDuration: (map['initialDuration'] as num?)?.toInt() ?? 0,
      remainingTime: (map['remainingTime'] as num?)?.toInt() ?? 0,
      metadata: RestTimerOverlayMetadata(
        exerciseName: map['exerciseName'] as String? ?? '',
        selectedDateEpochMs: (map['selectedDateEpochMs'] as num?)?.toInt() ?? 0,
        ownerId: map['ownerId'] as String?,
        groupId: map['groupId'] as String?,
        sessionIndex: optionalInt('sessionIndex'),
        recordDay: optionalInt('recordDay'),
      ),
    );
  }
}
