import 'package:body_calendar/core/theme/app_colors.dart';
import 'package:body_calendar/core/theme/app_theme.dart';
import 'package:body_calendar/core/widgets/ios_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('semantic colors follow light and dark brightness', () {
    expect(AppColors.primaryFor(Brightness.light), AppColors.primaryLight);
    expect(AppColors.primaryFor(Brightness.dark), AppColors.primaryDark);
    expect(AppColors.actionFor(Brightness.light), AppColors.actionLight);
    expect(AppColors.actionFor(Brightness.dark), AppColors.actionDark);
    expect(
      AppColors.groupedSurfaceFor(Brightness.dark),
      AppColors.groupedSurfaceDark,
    );
    expect(
      AppColors.primaryGradientFor(Brightness.light).colors,
      const [Color(0xFF4F46E5), Color(0xFF7C3AED)],
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
                          child: IosHeroSurface(
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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            FilledButton(
                              onPressed: () {},
                              child: const Text('저장'),
                            ),
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('나중에'),
                            ),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.tune_rounded),
                            ),
                          ],
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
      expect(find.byType(IosHeroSurface), findsOneWidget);
      expect(find.byType(IosSegmentedTabBar), findsOneWidget);

      final hero = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(IosHeroSurface),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = hero.decoration! as BoxDecoration;
      expect(decoration.gradient, isA<LinearGradient>());

      final iconBadge = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(IosIconBadge).first,
              matching: find.byType(Container),
            )
            .first,
      );
      final iconBadgeDecoration = iconBadge.decoration! as BoxDecoration;
      expect(iconBadgeDecoration.gradient, isA<LinearGradient>());
    });
  }

  test('dark palette has visible tonal separation', () {
    expect(AppColors.backgroundDark, isNot(AppColors.groupedSurfaceDark));
    expect(AppColors.groupedSurfaceDark, isNot(AppColors.elevatedSurfaceDark));
    expect(AppColors.primaryDark, const Color(0xFFB6A3FF));
  });

  test('primary actions and text retain accessible contrast', () {
    double contrastRatio(Color foreground, Color background) {
      final lighter =
          foreground.computeLuminance() > background.computeLuminance()
              ? foreground.computeLuminance()
              : background.computeLuminance();
      final darker =
          foreground.computeLuminance() > background.computeLuminance()
              ? background.computeLuminance()
              : foreground.computeLuminance();
      return (lighter + 0.05) / (darker + 0.05);
    }

    expect(
        contrastRatio(Colors.white, AppColors.actionLight), greaterThan(4.5));
    expect(contrastRatio(Colors.white, AppColors.actionDark), greaterThan(4.5));
    for (final brightness in Brightness.values) {
      for (final color in AppColors.primaryGradientFor(brightness).colors) {
        expect(
          contrastRatio(Colors.white, color),
          greaterThan(4.5),
          reason: '$brightness action gradient endpoint $color',
        );
      }
    }
    expect(
      contrastRatio(AppColors.textPrimaryLight, AppColors.backgroundLight),
      greaterThan(7),
    );
    expect(
      contrastRatio(AppColors.textPrimaryDark, AppColors.backgroundDark),
      greaterThan(7),
    );
  });

  test('button themes retain intrinsic row sizing', () {
    final lightMinimum = AppTheme
        .lightTheme.elevatedButtonTheme.style?.minimumSize
        ?.resolve(<WidgetState>{});
    final darkMinimum = AppTheme.darkTheme.filledButtonTheme.style?.minimumSize
        ?.resolve(<WidgetState>{});

    expect(lightMinimum, const Size(64, 50));
    expect(darkMinimum, const Size(64, 50));
  });

  test('filled button elevation follows interaction state', () {
    for (final theme in [AppTheme.lightTheme, AppTheme.darkTheme]) {
      final elevation = theme.filledButtonTheme.style!.elevation!;

      expect(elevation.resolve(<WidgetState>{}), 1);
      expect(elevation.resolve(<WidgetState>{WidgetState.hovered}), 1);
      expect(elevation.resolve(<WidgetState>{WidgetState.pressed}), 0);
      expect(elevation.resolve(<WidgetState>{WidgetState.disabled}), 0);
      expect(
        elevation.resolve(
          <WidgetState>{WidgetState.disabled, WidgetState.pressed},
        ),
        0,
      );
    }
  });

  test('filled buttons keep distinct normal, pressed, and disabled states', () {
    final light = AppTheme.lightTheme.filledButtonTheme.style!;
    final dark = AppTheme.darkTheme.filledButtonTheme.style!;

    expect(light.backgroundColor!.resolve({}), AppColors.actionLight);
    expect(
      light.backgroundColor!.resolve({WidgetState.pressed}),
      AppColors.secondary,
    );
    expect(dark.backgroundColor!.resolve({}), AppColors.actionDark);
    expect(
      dark.backgroundColor!.resolve({WidgetState.pressed}),
      const Color(0xFF5E46CF),
    );
    expect(
      light.backgroundColor!.resolve({WidgetState.disabled}),
      isNot(AppColors.actionLight),
    );
    expect(
      dark.backgroundColor!.resolve({WidgetState.disabled}),
      isNot(AppColors.actionDark),
    );
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'rendered destructive button overrides the $brightness shared theme',
      (tester) async {
        final theme = brightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
        final expectedAction = AppColors.actionFor(brightness);

        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: Column(
                children: [
                  FilledButton(
                    key: const Key('normal-button'),
                    onPressed: () {},
                    child: const Text('저장'),
                  ),
                  FilledButton(
                    key: const Key('destructive-button'),
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('삭제'),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        Material buttonMaterial(String key) => tester.widget<Material>(
              find
                  .descendant(
                    of: find.byKey(Key(key)),
                    matching: find.byType(Material),
                  )
                  .first,
            );

        expect(buttonMaterial('normal-button').color, expectedAction);
        expect(buttonMaterial('destructive-button').color, AppColors.error);

        final gesture = await tester.startGesture(
          tester.getCenter(find.byKey(const Key('destructive-button'))),
        );
        await tester.pump();
        expect(buttonMaterial('destructive-button').color, AppColors.error);
        await gesture.up();
      },
    );
  }
}
