import 'package:body_calendar/features/timer/presentation/widgets/rest_timer_overlay_consent_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> openDialog(
    WidgetTester tester,
    void Function(Future<bool?> result) onOpened,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              onOpened(showRestTimerOverlayConsentDialog(context));
            },
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('다른 앱 위에 휴식 타이머 표시'), findsOneWidget);
  }

  testWidgets('notification-only choice declines overlay consent',
      (tester) async {
    late Future<bool?> result;
    await openDialog(tester, (value) => result = value);

    await tester.tap(find.text('알림만 사용'));
    await tester.pumpAndSettle();

    expect(await result, isFalse);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('settings choice accepts overlay consent', (tester) async {
    late Future<bool?> result;
    await openDialog(tester, (value) => result = value);

    await tester.tap(find.text('설정 열기'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
