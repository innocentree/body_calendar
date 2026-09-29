import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final selectedDate = DateTime(2026, 9, 29);

  test('restores a running native timer and restarts its ticker', () async {
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    final nextState = bloc.stream.first;

    bloc.add(
      TimerRestored(
        initialDuration: 90,
        remainingDuration: 42,
        isPaused: false,
        exerciseName: '벤치프레스',
        selectedDate: selectedDate,
        ownerId: 'solo-owner',
      ),
    );
    final state = await nextState;

    expect(state, isA<TimerRunInProgress>());
    expect(state.duration, 42);
    expect((state as TimerRunInProgress).initialDuration, 90);
    expect(state.expiresAt, isNotNull);
    expect(bloc.exerciseName, '벤치프레스');
    expect(bloc.selectedDate, selectedDate);
    expect(bloc.ownerId, 'solo-owner');
  });

  test('restores paused group metadata without starting a ticker', () async {
    final bloc = TimerBloc(ticker: const Ticker());
    addTearDown(bloc.close);
    const groupContext = GroupTimerNavigationContext(
      groupId: 'legs',
      sessionIndex: 2,
      recordDay: 7,
    );
    final nextState = bloc.stream.first;

    bloc.add(
      TimerRestored(
        initialDuration: 60,
        remainingDuration: 18,
        isPaused: true,
        exerciseName: '스쿼트 · 런지',
        selectedDate: selectedDate,
        ownerId: 'round-owner',
        groupNavigationContext: groupContext,
      ),
    );
    final state = await nextState;

    expect(state, isA<TimerRunPause>());
    expect(state.duration, 18);
    expect((state as TimerRunPause).initialDuration, 60);
    expect(state.expiresAt, isNull);
    expect(bloc.groupNavigationContext, groupContext);
    expect(bloc.ownerId, 'round-owner');
  });
}
