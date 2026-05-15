import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:body_calendar/core/utils/ticker.dart';

part 'timer_event.dart';
part 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  final Ticker _ticker;
  StreamSubscription<int>? _tickerSubscription;

  String? exerciseName;
  DateTime? selectedDate;
  DateTime? _expiresAt; // Internal tracking of expiration time

  TimerBloc({required Ticker ticker})
      : _ticker = ticker,
        super(const TimerInitial(0)) {
    on<TimerStarted>(_onStarted);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerReset>(_onReset);
    on<TimerDurationUpdated>(_onDurationUpdated);
    on<_TimerTicked>(_onTicked);
  }

  @override
  Future<void> close() {
    _tickerSubscription?.cancel();
    return super.close();
  }

  void _onStarted(TimerStarted event, Emitter<TimerState> emit) {
    _expiresAt = DateTime.now().add(Duration(seconds: event.duration));
    emit(TimerRunInProgress(event.duration, event.duration, expiresAt: _expiresAt));
    _restartTicker(event.duration);
    exerciseName = event.exerciseName;
    selectedDate = event.selectedDate;
  }

  void _onPaused(TimerPaused event, Emitter<TimerState> emit) {
    if (state is TimerRunInProgress) {
      _tickerSubscription?.pause();
      // When paused, we lose the "flow". If needed to resume correctly, we might need to adjust logic.
      // But user requirement is mainly about background resilience.
      // For simple pause:
      emit(TimerRunPause(state.duration, (state as TimerRunInProgress).initialDuration));
    }
  }

  void _onResumed(TimerResumed event, Emitter<TimerState> emit) {
    if (state is TimerRunPause) {
      final remaining = state.duration;
      _expiresAt = DateTime.now().add(Duration(seconds: remaining));
      _restartTicker(remaining);

      emit(TimerRunInProgress(state.duration, (state as TimerRunPause).initialDuration, expiresAt: _expiresAt));
    }
  }

  void _onReset(TimerReset event, Emitter<TimerState> emit) {
    _tickerSubscription?.cancel();
    _expiresAt = null;
    emit(const TimerInitial(0));
    exerciseName = null;
    selectedDate = null;
  }

  void _onDurationUpdated(TimerDurationUpdated event, Emitter<TimerState> emit) {
    if (state is TimerRunInProgress) {
      final oldState = state as TimerRunInProgress;
      final delta = event.duration - oldState.initialDuration;
      final adjustedRemaining = (oldState.duration + delta).clamp(0, event.duration);

      _expiresAt = DateTime.now().add(Duration(seconds: adjustedRemaining));
      _restartTicker(adjustedRemaining);
      emit(
        TimerRunInProgress(
          adjustedRemaining,
          event.duration,
          expiresAt: _expiresAt,
        ),
      );
    } else if (state is TimerRunPause) {
      final oldState = state as TimerRunPause;
      final delta = event.duration - oldState.initialDuration;
      final adjustedRemaining = (oldState.duration + delta).clamp(0, event.duration);
      emit(TimerRunPause(adjustedRemaining, event.duration));
    }
  }

  void _restartTicker(int ticks) {
    _tickerSubscription?.cancel();
    if (ticks <= 0) return;
    _tickerSubscription = _ticker.tick(ticks: ticks).listen((_) {
      final now = DateTime.now();
      if (_expiresAt != null) {
        final remaining = _expiresAt!.difference(now).inSeconds;
        add(_TimerTicked(duration: remaining < 0 ? 0 : remaining, expiresAt: _expiresAt));
      }
    });
  }

  void _onTicked(_TimerTicked event, Emitter<TimerState> emit) {
    int duration = event.duration;

    if (_expiresAt != null) {
      final remaining = _expiresAt!.difference(DateTime.now()).inSeconds;
      duration = remaining < 0 ? 0 : remaining;
    }

    if (state is! TimerRunInProgress) {
      emit(duration > 0
          ? TimerRunInProgress(duration, duration, expiresAt: _expiresAt)
          : const TimerRunComplete());
      return;
    }

    emit(
      duration > 0
          ? TimerRunInProgress(
              duration,
              (state as TimerRunInProgress).initialDuration,
              expiresAt: _expiresAt,
            )
          : const TimerRunComplete(),
    );
  }
}