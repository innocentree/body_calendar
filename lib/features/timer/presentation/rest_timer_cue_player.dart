import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

enum RestTimerCue { warning, complete }

@visibleForTesting
RestTimerCue? restTimerCueForState(TimerState state) {
  if (state is TimerRunComplete) return RestTimerCue.complete;
  if (state is TimerRunInProgress &&
      const {10, 3, 2, 1}.contains(state.duration)) {
    return RestTimerCue.warning;
  }
  return null;
}

bool restTimerBelongsToSoloExercise({
  required TimerBloc bloc,
  required String exerciseName,
  required DateTime selectedDate,
}) {
  return bloc.ownerId == null &&
      bloc.groupNavigationContext == null &&
      bloc.exerciseName == exerciseName &&
      _isSameDate(bloc.selectedDate, selectedDate);
}

bool restTimerBelongsToGroup({
  required TimerBloc bloc,
  required String groupId,
  required int sessionIndex,
  required int recordDay,
  required DateTime selectedDate,
}) {
  final group = bloc.groupNavigationContext;
  return group != null &&
      group.groupId == groupId &&
      group.sessionIndex == sessionIndex &&
      group.recordDay == recordDay &&
      _isSameDate(bloc.selectedDate, selectedDate);
}

bool _isSameDate(DateTime? first, DateTime second) {
  return first != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

class RestTimerCuePlayer {
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> configure() async {
    try {
      await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      await _audioPlayer.setAudioContext(
        AudioContextConfig(
          route: AudioContextConfigRoute.system,
          duckAudio: true,
        ).build(),
      );
    } catch (error) {
      debugPrint('Failed to configure rest timer cue player: $error');
    }
  }

  void handleState(TimerState state) {
    switch (restTimerCueForState(state)) {
      case RestTimerCue.warning:
        unawaited(Vibration.vibrate(duration: 100));
        unawaited(_audioPlayer.play(AssetSource('sounds/beep.mp3')));
        return;
      case RestTimerCue.complete:
        unawaited(Vibration.vibrate(duration: 500));
        unawaited(_audioPlayer.play(AssetSource('sounds/bell.mp3')));
        unawaited(_audioPlayer.play(AssetSource('sounds/bell.mp3')));
        return;
      case null:
        return;
    }
  }

  Future<void> dispose() => _audioPlayer.dispose();
}
