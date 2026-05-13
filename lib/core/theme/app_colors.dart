import 'package:flutter/material.dart';

class AppColors {
  // Claude-inspired neutral product palette
  static const Color primary = Color(0xFFD97706); // warm amber accent
  static const Color secondary = Color(0xFFB45309);
  static const Color accent = Color(0xFF92400E);

  // Legacy aliases kept for compatibility while tone shifts quieter
  static const Color neonLime = primary;
  static const Color neonCyan = secondary;

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF7F5F2);
  static const Color backgroundDark = Color(0xFF171411);

  // Surfaces
  static const Color background = backgroundDark;
  static const Color surface = Color(0xFF211D19);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = surface;

  static const Color customBackground = Color(0xFF171411);
  static const Color customSurface = Color(0xFF23201C);
  static const Color cardDark = Color(0xFF2A2622);

  // Text
  static const Color textPrimaryLight = Color(0xFF1F1B16);
  static const Color textSecondaryLight = Color(0xFF7A746D);
  static const Color textPrimaryDark = Color(0xFFF4EFE8);
  static const Color textSecondaryDark = Color(0xFFA8A099);

  // States
  static const Color success = Color(0xFF3F7A5F);
  static const Color error = Color(0xFFD35D47);
  static const Color warning = Color(0xFFC98A2E);
  static const Color info = Color(0xFF7C8FA8);

  static const List<Color> chartColors = [
    Color(0xFFD97706),
    Color(0xFFB45309),
    Color(0xFF7C8FA8),
    Color(0xFF3F7A5F),
    Color(0xFFC98A2E),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
