import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:body_calendar/core/theme/app_theme.dart';
import 'package:body_calendar/core/widgets/ios_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semantic colors follow light and dark brightness', () {
    expect(AppColors.primaryFor(Brightness.light), AppColors.primaryLight);
    expect(AppColors.primaryFor(Brightness.dark), AppColors.primaryDark);
    expect(
      AppColors.groupedSurfaceFor(Brightness.dark),
      AppColors.groupedSurfaceDark,
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets('iOS components fit a compact $brightness screen',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final theme = brightness == Brightness.dark
          ? AppTheme.darkTheme
          : AppTheme.lightTheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.6)),
            child: DefaultTabController(
              length: 2,
              child: Builder(
                builder: (context) => Scaffold(
                  body: SingleChildScrollView(
                    child: Column(
                      children: [
                        const IosLargeHeader(
                          title: '운동 기록',
                          subtitle: '오늘의 운동을 기록하세요',
                          trailing: IosIconBadge(icon: Icons.add),
                        ),
                        const IosSectionHeader(title: '최근 운동'),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: IosGroupedSurface(
                            child: Text('벤치 프레스'),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: IosSegmentedTabBar(
                            controller: DefaultTabController.of(context),
                            tabs: const [Text('기록'), Text('통계')],
                          ),
                        ),
                        const IosEmptyState(
                          title: '기록이 없어요',
                          message: '첫 운동을 추가해 보세요.',
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: const IosBottomSafeAction(
                    child: SizedBox(height: 50, child: Text('운동 추가')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(IosGroupedSurface), findsOneWidget);
      expect(find.byType(IosSegmentedTabBar), findsOneWidget);
    });
  }

  test('button themes retain intrinsic row sizing', () {
    final lightMinimum = AppTheme
        .lightTheme.elevatedButtonTheme.style?.minimumSize
        ?.resolve(<WidgetState>{});
    final darkMinimum = AppTheme.darkTheme.filledButtonTheme.style?.minimumSize
        ?.resolve(<WidgetState>{});

    expect(lightMinimum, const Size(64, 50));
    expect(darkMinimum, const Size(64, 50));
  });
}
