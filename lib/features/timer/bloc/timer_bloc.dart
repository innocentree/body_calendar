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
    _tickerSubscription?.cancel();
    _tickerSubscription = _ticker
        .tick(ticks: event.duration) // Ticker still ticks 1 second at a time
        .listen((_) {
          // Instead of relying on the ticker's count, we calculate remaining time
          final now = DateTime.now();
          if (_expiresAt != null) {
            final remaining = _expiresAt!.difference(now).inSeconds;
             add(_TimerTicked(duration: remaining < 0 ? 0 : remaining, expiresAt: _expiresAt));
          }
        });
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
      _tickerSubscription?.resume();
      // On resume, strictly speaking, we might want to recalculate expiresAt if we wanted to "extend" the timer by the paused duration.
      // However, usually "active" timer in background implies it keeps running. 
      // If the user hit PAUSE, they expect it to stop. 
      // If the USER hit HOME (background), we want it to keep running (handled by _onTicked checking DateTime).
      
      // If we are coming back from a PAUSE state (user action), we should probably reset _expiresAt based on current remaining duration?
      // For now, let's assume "Resumed" means continuing from where we left off.
      // Re-calculating expiresAt:
      final remaining = state.duration;
      _expiresAt = DateTime.now().add(Duration(seconds: remaining));
      
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

  void _onTicked(_TimerTicked event, Emitter<TimerState> emit) {
    // Determine actual remaining time based on expiresAt if available
    int duration = event.duration;
    
    // Safety check if we drift heavily or calculate manually
    if (_expiresAt != null) {
       final remaining = _expiresAt!.difference(DateTime.now()).inSeconds;
       // We use the larger of the two to avoid premature 0 if the tick is slightly fast? 
       // Actually correct approach is purely time difference.
       // However, Ticker emits periodically.
       // The event.duration comes from our Listen calculation above.
       duration = remaining;
    }

    emit(
      duration > 0
          ? TimerRunInProgress(duration, (state as TimerRunInProgress).initialDuration, expiresAt: _expiresAt)
          : const TimerRunComplete(),
    );
  }
}