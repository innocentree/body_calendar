import 'package:flutter/material.dart';

class AppColors {
  // Premium indigo/violet system palette.
  // [primaryDark] is intentionally lighter because it is primarily used for
  // icons, focus rings, and selected labels on dark surfaces. Filled actions
  // use the higher-contrast action colors below.
  static const Color primaryLight = Color(0xFF4F46E5);
  static const Color primaryDark = Color(0xFFB6A3FF);
  static const Color actionLight = Color(0xFF4F46E5);
  static const Color actionDark = Color(0xFF7157E8);

  // Legacy alias kept for callers that do not have a BuildContext.
  static const Color primary = primaryLight;
  static const Color secondary = Color(0xFF7C3AED);
  static const Color accent = Color(0xFFA78BFA);

  // Legacy aliases kept for compatibility while tone shifts quieter
  static const Color neonLime = primary;
  static const Color neonCyan = secondary;

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF5F3FF);
  static const Color backgroundDark = Color(0xFF100E18);

  // Semantic grouped surfaces.
  static const Color groupedBackgroundLight = backgroundLight;
  static const Color groupedBackgroundDark = backgroundDark;
  static const Color groupedSurfaceLight = Color(0xFFFFFFFF);
  static const Color groupedSurfaceDark = Color(0xFF1A1726);
  static const Color elevatedSurfaceLight = Color(0xFFFFFFFF);
  static const Color elevatedSurfaceDark = Color(0xFF252036);

  // Tinted surfaces make selection and pressed states visible without relying
  // on heavy shadows.
  static const Color primaryContainerLight = Color(0xFFE9E5FF);
  static const Color primaryContainerDark = Color(0xFF342B50);
  static const Color onPrimaryContainerLight = Color(0xFF302A78);
  static const Color onPrimaryContainerDark = Color(0xFFE8E1FF);

  // Surfaces
  static const Color background = backgroundDark;
  static const Color surface = groupedSurfaceDark;
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = surface;

  static const Color customBackground = backgroundDark;
  static const Color customSurface = elevatedSurfaceDark;
  static const Color cardDark = groupedSurfaceDark;

  // Text
  static const Color textPrimaryLight = Color(0xFF211D32);
  static const Color textSecondaryLight = Color(0xFF6E6882);
  static const Color textPrimaryDark = Color(0xFFF7F3FF);
  static const Color textSecondaryDark = Color(0xFFB8B0CA);

  static const Color separatorLight = Color(0xFFDED8EF);
  static const Color separatorDark = Color(0xFF3B344D);

  // States
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF64D2FF);

  static const List<Color> chartColors = [
    Color(0xFF4F46E5),
    Color(0xFF7C3AED),
    Color(0xFFA78BFA),
    Color(0xFF34C759),
    Color(0xFFFF9F0A),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradientDark = LinearGradient(
    colors: [Color(0xFF5B4BE0), Color(0xFF7C3AED)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  static Color actionFor(Brightness brightness) =>
      brightness == Brightness.dark ? actionDark : actionLight;

  static LinearGradient primaryGradientFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryGradientDark : primaryGradient;

  static Color primaryContainerFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? primaryContainerDark
          : primaryContainerLight;

  static Color onPrimaryContainerFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? onPrimaryContainerDark
          : onPrimaryContainerLight;

  static Color groupedBackgroundFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? groupedBackgroundDark
          : groupedBackgroundLight;

  static Color groupedSurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark ? groupedSurfaceDark : groupedSurfaceLight;

  static Color elevatedSurfaceFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? elevatedSurfaceDark
          : elevatedSurfaceLight;

  static Color separatorFor(Brightness brightness) =>
      brightness == Brightness.dark ? separatorDark : separatorLight;

  static Color primaryTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? textPrimaryDark : textPrimaryLight;

  static Color secondaryTextFor(Brightness brightness) =>
      brightness == Brightness.dark ? textSecondaryDark : textSecondaryLight;
}

extension AppColorContext on BuildContext {
  Brightness get appBrightness => Theme.of(this).brightness;
  Color get appPrimary => AppColors.primaryFor(appBrightness);
  Color get appAction => AppColors.actionFor(appBrightness);
  LinearGradient get appPrimaryGradient =>
      AppColors.primaryGradientFor(appBrightness);
  Color get appPrimaryContainer => AppColors.primaryContainerFor(appBrightness);
  Color get appOnPrimaryContainer =>
      AppColors.onPrimaryContainerFor(appBrightness);
  Color get appGroupedBackground =>
      AppColors.groupedBackgroundFor(appBrightness);
  Color get appGroupedSurface => AppColors.groupedSurfaceFor(appBrightness);
  Color get appElevatedSurface => AppColors.elevatedSurfaceFor(appBrightness);
  Color get appSeparator => AppColors.separatorFor(appBrightness);
  Color get appPrimaryText => AppColors.primaryTextFor(appBrightness);
  Color get appSecondaryText => AppColors.secondaryTextFor(appBrightness);
}
