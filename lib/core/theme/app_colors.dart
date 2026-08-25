import 'package:flutter/material.dart';

class AppColors {
  // iOS / SwiftUI-inspired system palette
  static const Color primary = Color(0xFF0A84FF);
  static const Color secondary = Color(0xFF5AC8FA);
  static const Color accent = Color(0xFF34C759);

  // Legacy aliases kept for compatibility while tone shifts quieter
  static const Color neonLime = primary;
  static const Color neonCyan = secondary;

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF2F2F7);
  static const Color backgroundDark = Color(0xFF000000);

  // Surfaces
  static const Color background = backgroundDark;
  static const Color surface = Color(0xFF1C1C1E);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = surface;

  static const Color customBackground = Color(0xFF000000);
  static const Color customSurface = Color(0xFF2C2C2E);
  static const Color cardDark = Color(0xFF1C1C1E);

  // Text
  static const Color textPrimaryLight = Color(0xFF111111);
  static const Color textSecondaryLight = Color(0xFF6E6E73);
  static const Color textPrimaryDark = Color(0xFFF5F5F7);
  static const Color textSecondaryDark = Color(0xFF98989D);

  static const Color separatorLight = Color(0xFFD1D1D6);
  static const Color separatorDark = Color(0xFF3A3A3C);

  // States
  static const Color success = Color(0xFF34C759);
  static const Color error = Color(0xFFFF453A);
  static const Color warning = Color(0xFFFF9F0A);
  static const Color info = Color(0xFF64D2FF);

  static const List<Color> chartColors = [
    Color(0xFF0A84FF),
    Color(0xFF5E5CE6),
    Color(0xFF64D2FF),
    Color(0xFF34C759),
    Color(0xFFFF9F0A),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF5AC8FA), Color(0xFF0A84FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
