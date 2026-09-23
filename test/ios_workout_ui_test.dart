import 'package:body_calendar/features/workout/presentation/screens/add_workout_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAddWorkout(
    WidgetTester tester, {
    required Brightness brightness,
  }) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: brightness,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF007AFF),
            brightness: brightness,
          ),
        ),
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 800),
            textScaler: TextScaler.linear(1.6),
          ),
          child: const AddWorkoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('workout picker remains usable on a narrow light screen',
      (tester) async {
    await pumpAddWorkout(tester, brightness: Brightness.light);

    expect(find.text('운동 검색'), findsOneWidget);
    expect(find.text('완료'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('workout picker follows dark theme colors', (tester) async {
    await pumpAddWorkout(tester, brightness: Brightness.dark);

    final closeIcon = tester.widget<Icon>(find.byIcon(Icons.close).first);
    expect(closeIcon.color, isNot(Colors.white));
    expect(tester.takeException(), isNull);
  });
}
