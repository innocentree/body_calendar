import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Keeps the display awake while the app is in the foreground.
class AppWakelock extends StatefulWidget {
  final Widget child;

  @visibleForTesting
  final Future<void> Function(bool enabled)? wakelockHandler;

  const AppWakelock({
    super.key,
    required this.child,
    this.wakelockHandler,
  });

  @override
  State<AppWakelock> createState() => _AppWakelockState();
}

class _AppWakelockState extends State<AppWakelock> with WidgetsBindingObserver {
  Future<void> _wakelockOperation = Future<void>.value();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Apply the current lifecycle immediately so startup does not enable the
    // wakelock while the app is already backgrounded.
    _setWakelockEnabled(
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setWakelockEnabled(false);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _setWakelockEnabled(state == AppLifecycleState.resumed);
  }

  void _setWakelockEnabled(bool enabled) {
    _wakelockOperation = _wakelockOperation
        .then<void>((_) => enabled
            ? (widget.wakelockHandler?.call(true) ?? WakelockPlus.enable())
            : (widget.wakelockHandler?.call(false) ?? WakelockPlus.disable()))
        .catchError((Object error, StackTrace stackTrace) {
      debugPrint('Unable to update wakelock: $error');
    });
    unawaited(_wakelockOperation);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
