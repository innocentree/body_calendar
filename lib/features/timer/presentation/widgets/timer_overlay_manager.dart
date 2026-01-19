import 'dart:io';
import 'package:body_calendar/features/calendar/presentation/widgets/overlay_helper_impl.dart';
import 'package:body_calendar/features/timer/bloc/timer_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

class TimerOverlayManager extends StatefulWidget {
  final Widget child;
  const TimerOverlayManager({super.key, required this.child});

  @override
  State<TimerOverlayManager> createState() => _TimerOverlayManagerState();
}

class _TimerOverlayManagerState extends State<TimerOverlayManager> with WidgetsBindingObserver, WindowListener {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (Platform.isWindows) {
      windowManager.addListener(this);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (Platform.isWindows) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  // Android & iOS Lifecycle
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (Platform.isAndroid || Platform.isIOS) {
      _handleStateChange(state == AppLifecycleState.paused || state == AppLifecycleState.inactive);
    }
  }

  // Windows Window Listener
  @override
  void onWindowBlur() {
    // 포커스를 잃었을 때 (다른 앱 선택 등)
    if (Platform.isWindows) {
      _handleStateChange(true);
    }
  }

  @override
  void onWindowFocus() {
    // 포커스를 다시 얻었을 때
    if (Platform.isWindows) {
        // MiniMode에서 돌아오는 것은 별도의 "복귀" 버튼이나 closeOverlayFAB 호출에 의해 
        // 이미 처리되었을 수도 있지만, 만약 사용자가 Alt+Tab으로 돌아왔다면?
        // MiniMode 상태에서는 창이 작아져 있으므로, 포커스를 얻는다고 해서 바로 복원하면
        // 사용자가 "작은 창"을 쓰려고 클릭한 것일 수도 있음.
        // 따라서 "포커스 얻음" 만으로 복원하는 것은 좋지 않을 수 있음.
        // 하지만 사용자가 "앱을 실행" (taskbar icon click) 하면 복원되길 원할 것.
        // 일단은 명시적 복귀를 유도하거나, 로직을 단순화.
        
        // 요구사항: "다른 앱을 실행해도... 유지하고 싶어" -> MiniMode 진입.
        // 앱으로 돌아오면? "화면 최상단에 타이머 버튼을 유지" -> 이게 오버레이임.
        // 앱을 다시 "활성화" 하면 원래대로 돌아오는게 자연스러움.
        // 단, MiniMode 상태에서 "일시정지/스킵"을 누르려고 클릭했을 때 커지면 안됨.
        
        // 해결책: MiniMode UI 내에 "복귀" 버튼을 둠.
        // 여기서는 자동 복원 하지 않음. (또는 isMiniMode 플래그 확인 필요하지만 여기선 접근 어려움)
        // -> _handleStateChange(false)를 호출하면 자동으로 원래 크기로 복원됨.
        // MiniMode에서 버튼 클릭 하려면 포커스가 가야함. -> 포커스 가자마자 커지면 버튼 클릭 불가.
        // 결론: Windows에서는 onWindowFocus로 자동 복원하지 않는다. 
        // 사용자가 명시적으로 복귀하거나, 타이머가 끝났을 때 복귀.
    }
  }
  
  // onWindowMinimize 등 다른 이벤트도 고려 가능

  void _handleStateChange(bool isBackground) {
    if (!mounted) return;
    
    final timerState = context.read<TimerBloc>().state;
    final isRunning = timerState is TimerRunInProgress;

    if (isBackground) {
      if (isRunning) {
        // 백그라운드/포커스 상실 시 + 타이머 동작 중 -> 오버레이 실행
        showOverlayFAB(
          exerciseName: context.read<TimerBloc>().exerciseName ?? '',
          restTime: timerState.duration,
          onComplete: () {},
        );
      }
    } else {
       // 포그라운드 복귀 -> 오버레이 종료 
       // (Android는 자동 복귀가 자연스러움. Windows는 위 주석 참고하여 보류하거나 로직 추가)
       if (Platform.isAndroid || Platform.isIOS) {
          closeOverlayFAB();
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TimerBloc, TimerState>(
      listener: (context, state) {
        if (state is TimerRunInProgress) {
          updateOverlayFAB(
            totalDuration: state.initialDuration,
            remainingTime: state.duration,
          );
        } else if (state is TimerRunPause) {
          // 일시정지 상태도 업데이트 (필요시)
          updateOverlayFAB(
            totalDuration: state.initialDuration,
            remainingTime: state.duration,
          );
        } else {
             // 타이머 종료 등 다른 상태 처리
        }
      },
      child: widget.child,
    );
  }
}
