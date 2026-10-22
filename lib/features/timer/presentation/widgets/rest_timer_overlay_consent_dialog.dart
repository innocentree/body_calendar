import 'package:flutter/material.dart';

Future<bool?> showRestTimerOverlayConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const RestTimerOverlayConsentDialog(),
  );
}

class RestTimerOverlayConsentDialog extends StatelessWidget {
  const RestTimerOverlayConsentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('다른 앱 위에 휴식 타이머 표시'),
      content: const Text(
        '운동 중 다른 앱을 보더라도 남은 휴식 시간을 확인할 수 있도록 작은 타이머를 화면 위에 표시할 수 있어요. '
        '이 기능은 선택 사항이며, 사용하지 않아도 알림에서 타이머가 계속 동작합니다.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('알림만 사용'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('설정 열기'),
        ),
      ],
    );
  }
}
