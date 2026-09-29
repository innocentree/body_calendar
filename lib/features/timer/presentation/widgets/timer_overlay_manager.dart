import 'dart:async';
import 'dart:io';

import 'package:body_calendar/core/navigation/app_navigator.dart';
import 'package:body_calendar/features/calendar/presentation/widgets/overlay_helper_impl.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/timer/data/rest_timer_overlay_bridge.dart';
import 'package:body_calendar/features/timer/presentation/timer_navigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

class TimerOverlayManager extends StatefulWidget {
  final Widget child;

  const TimerOverlayManager({super.key, required this.child});

  @override
  State<TimerOverlayManager> createState() => _TimerOverlayManagerState();
}

class _TimerOverlayManagerState extends State<TimerOverlayManager>
    with WidgetsBindingObserver, WindowListener {
  final RestTimerOverlayBridge _androidBridge = RestTimerOverlayBridge();
  Future<void> _androidSync = Future.value();
  _AndroidTimerSnapshot _lastAndroidSnapshot =
      const _AndroidTimerSnapshot.stopped();
  bool _appVisible = true;
  bool _permissionRequested = false;
  bool _openingTimer = false;
  bool _pendingOpenTimer = false;
  bool _nativeRestoreInProgress = false;
  bool _androidInitializationComplete = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows) {
      windowManager.addListener(this);
    } else if (Platform.isAndroid) {
      unawaited(_initializeAndroidBridge());
    }
  }

  Future<void> _initializeAndroidBridge() async {
    try {
      await _androidBridge.initialize(onOpenTimer: _handleOpenTimerRequest);
      if (!mounted) return;
      final snapshot = await _androidBridge.getSnapshot();
      if (snapshot != null &&
          snapshot.remainingTime > 0 &&
          snapshot.metadata.exerciseName.isNotEmpty &&
          snapshot.metadata.selectedDateEpochMs > 0) {
        final groupId = snapshot.metadata.groupId;
        final sessionIndex = snapshot.metadata.sessionIndex;
        final recordDay = snapshot.metadata.recordDay;
        final groupContext =
            groupId != null && sessionIndex != null && recordDay != null
                ? GroupTimerNavigationContext(
                    groupId: groupId,
                    sessionIndex: sessionIndex,
                    recordDay: recordDay,
                  )
                : null;
        final bloc = context.read<TimerBloc>();
        final restoredState = bloc.stream.first;
        _nativeRestoreInProgress = true;
        bloc.add(
          TimerRestored(
            initialDuration: snapshot.initialDuration,
            remainingDuration: snapshot.remainingTime,
            isPaused: snapshot.isPaused,
            exerciseName: snapshot.metadata.exerciseName,
            selectedDate: DateTime.fromMillisecondsSinceEpoch(
              snapshot.metadata.selectedDateEpochMs,
            ),
            ownerId: snapshot.metadata.ownerId,
            groupNavigationContext: groupContext,
          ),
        );
        await restoredState;
        final state = bloc.state;
        if (state is TimerRunInProgress) {
          _lastAndroidSnapshot = _AndroidTimerSnapshot.running(
            initialDuration: state.initialDuration,
            remainingTime: state.duration,
            expiresAtEpochMs: state.expiresAt?.millisecondsSinceEpoch,
          );
        } else if (state is TimerRunPause) {
          _lastAndroidSnapshot = _AndroidTimerSnapshot.paused(
            initialDuration: state.initialDuration,
            remainingTime: state.duration,
          );
        }
        _nativeRestoreInProgress = false;
      }
      await _androidBridge.setAppVisible(_appVisible);
      _androidInitializationComplete = true;
      if (await _androidBridge.consumeOpenTimerRequest()) {
        _handleOpenTimerRequest();
      } else if (_pendingOpenTimer) {
        _handleOpenTimerRequest();
      }
    } catch (error, stackTrace) {
      _nativeRestoreInProgress = false;
      _androidInitializationComplete = true;
      if (_pendingOpenTimer) _handleOpenTimerRequest();
      _logAndroidOverlayError(error, stackTrace);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    } else if (Platform.isAndroid) {
      _androidBridge.dispose();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (Platform.isAndroid) {
      final bool visible;
      switch (state) {
        case AppLifecycleState.resumed:
          visible = true;
        case AppLifecycleState.inactive:
          return;
        case AppLifecycleState.hidden:
        case AppLifecycleState.paused:
        case AppLifecycleState.detached:
          visible = false;
      }
      if (_appVisible != visible) {
        _appVisible = visible;
        _queueAndroid(() => _androidBridge.setAppVisible(visible));
      }
    }
  }

  @override
  void onWindowBlur() {
    if (Platform.isWindows) {
      _handleWindowsStateChange(true);
    }
  }

  @override
  void onWindowFocus() {
    // Windows mini mode stays active until the user explicitly returns.
  }

  @override
  void onWindowMinimize() {
    if (!Platform.isWindows) return;
    final timerState = context.read<TimerBloc>().state;
    if (timerState is TimerRunInProgress) {
      unawaited(windowManager.restore());
      _handleWindowsStateChange(true);
    }
  }

  void _handleWindowsStateChange(bool isBackground) {
    if (!mounted) return;
    final bloc = context.read<TimerBloc>();
    final timerState = bloc.state;
    if (isBackground && timerState is TimerRunInProgress) {
      unawaited(
        showOverlayFAB(
          exerciseName: bloc.exerciseName ?? '',
          restTime: timerState.duration,
          onComplete: () {},
        ),
      );
    }
  }

  void _syncAndroidTimer(TimerState state) {
    if (!Platform.isAndroid) return;

    if (state is TimerRunInProgress) {
      final expiresAt = state.expiresAt ??
          DateTime.now().add(Duration(seconds: state.duration));
      final next = _AndroidTimerSnapshot.running(
        initialDuration: state.initialDuration,
        remainingTime: state.duration,
        expiresAtEpochMs: expiresAt.millisecondsSinceEpoch,
      );
      final previous = _lastAndroidSnapshot;
      _lastAndroidSnapshot = next;

      if (_nativeRestoreInProgress) return;

      if (previous.phase == _AndroidTimerPhase.stopped) {
        _queueAndroid(() async {
          await _androidBridge.start(
            initialDuration: next.initialDuration,
            remainingTime: next.remainingTime,
            expiresAt: expiresAt,
            metadata: _androidMetadata(),
          );
          await _requestOverlayPermissionOnce();
        });
      } else if (previous.phase == _AndroidTimerPhase.paused) {
        _queueAndroid(
          () => _androidBridge.resume(
            initialDuration: next.initialDuration,
            remainingTime: next.remainingTime,
            expiresAt: expiresAt,
            metadata: _androidMetadata(),
          ),
        );
      } else if (previous.initialDuration != next.initialDuration ||
          previous.expiresAtEpochMs != next.expiresAtEpochMs) {
        _queueAndroid(
          () => _androidBridge.update(
            initialDuration: next.initialDuration,
            remainingTime: next.remainingTime,
            expiresAt: expiresAt,
            metadata: _androidMetadata(),
          ),
        );
      }
      return;
    }

    if (state is TimerRunPause) {
      final next = _AndroidTimerSnapshot.paused(
        initialDuration: state.initialDuration,
        remainingTime: state.duration,
      );
      if (_lastAndroidSnapshot != next) {
        _lastAndroidSnapshot = next;
        if (_nativeRestoreInProgress) return;
        _queueAndroid(
          () => _androidBridge.pause(
            initialDuration: next.initialDuration,
            remainingTime: next.remainingTime,
          ),
        );
      }
      return;
    }

    if (_lastAndroidSnapshot.phase != _AndroidTimerPhase.stopped) {
      _lastAndroidSnapshot = const _AndroidTimerSnapshot.stopped();
      _queueAndroid(_androidBridge.stop);
    }
  }

  RestTimerOverlayMetadata _androidMetadata() {
    final bloc = context.read<TimerBloc>();
    final group = bloc.groupNavigationContext;
    return RestTimerOverlayMetadata(
      exerciseName: bloc.exerciseName ?? '',
      selectedDateEpochMs: bloc.selectedDate?.millisecondsSinceEpoch ?? 0,
      ownerId: bloc.ownerId,
      groupId: group?.groupId,
      sessionIndex: group?.sessionIndex,
      recordDay: group?.recordDay,
    );
  }

  Future<void> _requestOverlayPermissionOnce() async {
    if (_permissionRequested) return;
    _permissionRequested = true;
    if (!await _androidBridge.isPermissionGranted()) {
      await _androidBridge.requestPermission();
    }
  }

  void _queueAndroid(Future<void> Function() operation) {
    _androidSync = _androidSync
        .then((_) => operation())
        .catchError(_logAndroidOverlayError);
  }

  void _logAndroidOverlayError(Object error, [StackTrace? stackTrace]) {
    if (error is MissingPluginException) return;
    debugPrint('Android rest timer overlay error: $error');
  }

  void _handleOpenTimerRequest() {
    if (!mounted || _openingTimer) return;
    _pendingOpenTimer = true;
    if (!_androidInitializationComplete) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openPendingTimer();
    });
  }

  void _openPendingTimer() {
    if (!mounted || !_pendingOpenTimer || _openingTimer) return;
    final bloc = context.read<TimerBloc>();
    if (bloc.state is TimerInitial || bloc.exerciseName == null) {
      _pendingOpenTimer = false;
      return;
    }
    if (const {'/exercise_detail', '/grouped_exercise_detail'}
        .contains(appNavigatorObserver.currentRouteName)) {
      final navigator = navigatorKey.currentState;
      if (navigator?.canPop() == true) {
        navigator!.pop();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _openPendingTimer();
        });
        return;
      }
    }
    final navigationContext = navigatorKey.currentContext;
    if (navigationContext == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openPendingTimer();
      });
      return;
    }

    _pendingOpenTimer = false;
    _openingTimer = true;
    unawaited(
      navigateToRunningTimer(navigationContext, bloc).whenComplete(() {
        _openingTimer = false;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, state) {
        if (Platform.isAndroid) {
          _syncAndroidTimer(state);
          return;
        }
        if (!Platform.isWindows) return;

        if (state is TimerRunInProgress) {
          unawaited(
            updateOverlayFAB(
              totalDuration: state.initialDuration,
              remainingTime: state.duration,
            ),
          );
        } else if (state is TimerRunPause) {
          unawaited(
            updateOverlayFAB(
              totalDuration: state.initialDuration,
              remainingTime: state.duration,
            ),
          );
        } else {
          unawaited(
            updateOverlayFAB(totalDuration: 1, remainingTime: 0),
          );
        }
      },
      child: widget.child,
    );
  }
}

enum _AndroidTimerPhase { stopped, running, paused }

class _AndroidTimerSnapshot {
  final _AndroidTimerPhase phase;
  final int initialDuration;
  final int remainingTime;
  final int? expiresAtEpochMs;

  const _AndroidTimerSnapshot.stopped()
      : phase = _AndroidTimerPhase.stopped,
        initialDuration = 0,
        remainingTime = 0,
        expiresAtEpochMs = null;

  const _AndroidTimerSnapshot.running({
    required this.initialDuration,
    required this.remainingTime,
    required this.expiresAtEpochMs,
  }) : phase = _AndroidTimerPhase.running;

  const _AndroidTimerSnapshot.paused({
    required this.initialDuration,
    required this.remainingTime,
  })  : phase = _AndroidTimerPhase.paused,
        expiresAtEpochMs = null;

  @override
  bool operator ==(Object other) {
    return other is _AndroidTimerSnapshot &&
        other.phase == phase &&
        other.initialDuration == initialDuration &&
        other.remainingTime == remainingTime &&
        other.expiresAtEpochMs == expiresAtEpochMs;
  }

  @override
  int get hashCode => Object.hash(
        phase,
        initialDuration,
        remainingTime,
        expiresAtEpochMs,
      );
}
