import 'package:body_calendar/features/workout/presentation/widgets/exercise_statistics_popup.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('statistics popup stays usable on a narrow large-text screen',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(useMaterial3: true),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6),
          ),
          child: child!,
        ),
        home: const Scaffold(
          body: ExerciseStatisticsPopup(
            exerciseName: '벤치 프레스',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('벤치 프레스 볼륨 추이'), findsOneWidget);
    expect(find.text('아직 기록이 없어요.'), findsOneWidget);
    expect(find.byTooltip('닫기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
