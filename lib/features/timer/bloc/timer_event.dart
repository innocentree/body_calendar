part of 'timer_bloc.dart';

class GroupTimerNavigationContext extends Equatable {
  final String groupId;
  final int sessionIndex;
  final int recordDay;

  const GroupTimerNavigationContext({
    required this.groupId,
    required this.sessionIndex,
    required this.recordDay,
  });

  @override
  List<Object?> get props => [groupId, sessionIndex, recordDay];
}

abstract class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => [];
}

class TimerStarted extends TimerEvent {
  final int duration;
  final String exerciseName;
  final DateTime selectedDate;
  final String? ownerId;
  final GroupTimerNavigationContext? groupNavigationContext;

  const TimerStarted({
    required this.duration,
    required this.exerciseName,
    required this.selectedDate,
    this.ownerId,
    this.groupNavigationContext,
  });

  @override
  List<Object?> get props => [
        duration,
        exerciseName,
        selectedDate,
        ownerId,
        groupNavigationContext,
      ];
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

class TimerDurationUpdated extends TimerEvent {
  final int duration;

  const TimerDurationUpdated({required this.duration});

  @override
  List<Object?> get props => [duration];
}

class _TimerTicked extends TimerEvent {
  final int duration;
  final DateTime? expiresAt;

  const _TimerTicked({required this.duration, this.expiresAt});

  @override
  List<Object?> get props => [duration, expiresAt];
}
