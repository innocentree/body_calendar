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
  if (_isMiniMode) return;
  _isMiniMode = true;

  try {
    _savedBounds = await windowManager.getBounds();
    // 작은 크기로 변경 (300x150)
    await windowManager.setMinimumSize(const Size(300, 150));
    await windowManager.setSize(const Size(300, 150));
    await windowManager.setAlignment(Alignment.bottomRight);
    await windowManager.setAlwaysOnTop(true);
    // 타이틀바 숨기기 (선택 사항, 깔끔하게 보이려면 숨기는게 좋음)
    // await windowManager.setTitleBarStyle(TitleBarStyle.hidden); 
    // -> TitleBarStyle 변경은 앱 재시작 필요할 수 있으므로 주의. 
    // 여기서는 단순히 내용만 변경.

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => const WindowsTimerOverlay(),
      ),
    );
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