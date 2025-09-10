part of 'timer_bloc.dart';

abstract class TimerState extends Equatable {
  final int duration;

  const TimerState(this.duration);

  @override
  List<Object> get props => [duration];
}

class TimerInitial extends TimerState {
  const TimerInitial(super.duration);

  @override
  String toString() => 'TimerInitial { duration: $duration }';
}

class TimerRunInProgress extends TimerState {
  final int initialDuration;
  const TimerRunInProgress(super.duration, this.initialDuration);

  @override
  List<Object> get props => [duration, initialDuration];

  @override
  String toString() => 'TimerRunInProgress { duration: $duration, initialDuration: $initialDuration }';
}

class TimerRunPause extends TimerState {
  final int initialDuration;
  const TimerRunPause(super.duration, this.initialDuration);

  @override
  List<Object> get props => [duration, initialDuration];

  @override
  String toString() => 'TimerRunPause { duration: $duration, initialDuration: $initialDuration }';
}

class TimerRunComplete extends TimerState {
  const TimerRunComplete() : super(0);
}
