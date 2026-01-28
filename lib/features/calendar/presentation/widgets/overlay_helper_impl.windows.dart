import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:body_calendar/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

Rect? _savedBounds;
bool _isMiniMode = false;

Future<void> showOverlayFAB({
  required String exerciseName,
  required int restTime,
  required VoidCallback onComplete,
}) async {
  // MiniMode 여부와 상관없이 윈도우 속성 강제 적용 (최소화 복구 시 크기 유지 등을 위해)
  try {
    if (!_isMiniMode) {
      _isMiniMode = true;
      _savedBounds = await windowManager.getBounds();
      
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => const WindowsTimerOverlay(),
        ),
      );
    }

    // 작은 크기로 변경 (300x150) 및 항상 위 설정
    await windowManager.setMinimumSize(const Size(300, 150));
    await windowManager.setSize(const Size(300, 150));
    await windowManager.setAlignment(Alignment.bottomRight);
    await windowManager.setAlwaysOnTop(true);
  } catch (e) {
    debugPrint('Error entering mini mode: $e');
  }

}

Future<void> closeOverlayFAB() async {
  if (!_isMiniMode) return;
  _isMiniMode = false;

  try {
    if (navigatorKey.currentState?.canPop() == true) {
      navigatorKey.currentState?.pop();
    }

    await windowManager.setAlwaysOnTop(false);
    if (_savedBounds != null) {
      await windowManager.setBounds(_savedBounds!);
    } else {
      await windowManager.setSize(const Size(1280, 720));
      await windowManager.center();
    }
  } catch (e) {
    debugPrint('Error exiting mini mode: $e');
  }
}

Future<void> updateOverlayFAB({required int totalDuration, required int remainingTime}) async {
  // Windows에서는 Bloc이 UI를 업데이트하므로 별도 통신 불필요
}

class WindowsTimerOverlay extends StatelessWidget {
  const WindowsTimerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 눈에 띄게
      body: BlocBuilder<TimerBloc, TimerState>(
        builder: (context, state) {
          int duration = 0;
          String exerciseName = '';
          
          if (state is TimerRunInProgress) {
            duration = state.duration;
            exerciseName = context.read<TimerBloc>().exerciseName ?? '휴식';
          } else if (state is TimerRunPause) {
             duration = state.duration;
             exerciseName = '일시정지';
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  exerciseName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$duration',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (state is TimerRunComplete)
                  ElevatedButton(
                     onPressed: () {
                         // 복귀 로직
                         closeOverlayFAB();
                     },
                     child: const Text('복귀'),
                  )
                else
                 IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: () {
                    context.read<TimerBloc>().add(const TimerReset());
                    closeOverlayFAB();
                  },
                 )
              ],
            ),
          );
        },
      ),
    );
  }
}