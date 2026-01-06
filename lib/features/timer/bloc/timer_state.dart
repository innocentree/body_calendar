part of 'timer_bloc.dart';

abstract class TimerState extends Equatable {
  final int duration;
  final DateTime? expiresAt;
  
  const TimerState(this.duration, {this.expiresAt});

  @override
  List<Object?> get props => [duration, expiresAt];
}

class TimerInitial extends TimerState {
  const TimerInitial(super.duration);

  @override
  String toString() => 'TimerInitial { duration: $duration }';
}

class TimerRunInProgress extends TimerState {
  final int initialDuration;

  const TimerRunInProgress(super.duration, this.initialDuration, {super.expiresAt});

  @override
  String toString() => 'TimerRunInProgress { duration: $duration, initialDuration: $initialDuration, expiresAt: $expiresAt }';
}

class TimerRunPause extends TimerState {
  final int initialDuration;

  const TimerRunPause(super.duration, this.initialDuration, {super.expiresAt});

  @override
  String toString() => 'TimerRunPause { duration: $duration, initialDuration: $initialDuration }';
}

class TimerRunComplete extends TimerState {
  const TimerRunComplete() : super(0);

  @override
  String toString() => 'TimerRunComplete';
}
