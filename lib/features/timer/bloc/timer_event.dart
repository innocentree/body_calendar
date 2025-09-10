part of 'timer_bloc.dart';

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object> get props => [];
}

class TimerStarted extends TimerEvent {
  final int duration;
  final String exerciseName;
  final DateTime selectedDate;

  const TimerStarted({required this.duration, required this.exerciseName, required this.selectedDate});

  @override
  List<Object> get props => [duration, exerciseName, selectedDate];
}

class TimerPaused extends TimerEvent {
  const TimerPaused();
}

class TimerResumed extends TimerEvent {
  const TimerResumed();
}

class TimerReset extends TimerEvent {
  const TimerReset();
}

class _TimerTicked extends TimerEvent {
  final int duration;

  const _TimerTicked({required this.duration});

  @override
  List<Object> get props => [duration];
}
