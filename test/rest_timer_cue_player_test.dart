import 'package:body_calendar/core/utils/ticker.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/features/timer/presentation/rest_timer_cue_player.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final selectedDate = DateTime(2026, 10, 1);

  group('restTimerCueForState', () {
    test('uses the existing warning seconds and completion cue', () {
      for (final duration in const [10, 3, 2, 1]) {
        expect(
          restTimerCueForState(TimerRunInProgress(duration, 60)),
          RestTimerCue.warning,
        );
      }

      expect(
        restTimerCueForState(const TimerRunInProgress(9, 60)),
        isNull,
      );
      expect(
        restTimerCueForState(const TimerRunComplete()),
        RestTimerCue.complete,
      );
    });

    test('manual reset does not produce a completion cue', () {
      expect(restTimerCueForState(const TimerInitial(0)), isNull);
    });
  });

  group('rest timer cue ownership', () {
    test('a solo timer belongs only to its matching exercise screen', () async {
      final bloc = TimerBloc(ticker: const Ticker());
      addTearDown(bloc.close);
      final nextState = bloc.stream.first;

      bloc.add(
        TimerStarted(
          duration: 30,
          exerciseName: '벤치프레스',
          selectedDate: selectedDate,
        ),
      );
      await nextState;

      expect(
        restTimerBelongsToSoloExercise(
          bloc: bloc,
          exerciseName: '벤치프레스',
          selectedDate: selectedDate,
        ),
        isTrue,
      );
      expect(
        restTimerBelongsToSoloExercise(
          bloc: bloc,
          exerciseName: '스쿼트',
          selectedDate: selectedDate,
        ),
        isFalse,
      );
      expect(
        restTimerBelongsToGroup(
          bloc: bloc,
          groupId: 'group-a',
          sessionIndex: 1,
          recordDay: 2,
          selectedDate: selectedDate,
        ),
        isFalse,
      );
    });

    test('a group timer belongs only to its matching group screen', () async {
      final bloc = TimerBloc(ticker: const Ticker());
      addTearDown(bloc.close);
      final nextState = bloc.stream.first;

      bloc.add(
        TimerStarted(
          duration: 30,
          exerciseName: '스쿼트 · 런지',
          selectedDate: selectedDate,
          ownerId: 'group:group-a:2026-10-01:round:0',
          groupNavigationContext: const GroupTimerNavigationContext(
            groupId: 'group-a',
            sessionIndex: 1,
            recordDay: 2,
          ),
        ),
      );
      await nextState;

      expect(
        restTimerBelongsToGroup(
          bloc: bloc,
          groupId: 'group-a',
          sessionIndex: 1,
          recordDay: 2,
          selectedDate: selectedDate,
        ),
        isTrue,
      );
      expect(
        restTimerBelongsToGroup(
          bloc: bloc,
          groupId: 'group-b',
          sessionIndex: 1,
          recordDay: 2,
          selectedDate: selectedDate,
        ),
        isFalse,
      );
      expect(
        restTimerBelongsToSoloExercise(
          bloc: bloc,
          exerciseName: '스쿼트 · 런지',
          selectedDate: selectedDate,
        ),
        isFalse,
      );
    });
  });
}
