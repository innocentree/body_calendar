import 'package:flutter/material.dart';

class AppColors {
  // Game UI palette: controlled, cinematic, not noisy
  static const Color primary = Color(0xFF74F0B2); // quest/clear accent
  static const Color secondary = Color(0xFF4BC2FF); // system accent
  static const Color accent = Color(0xFFFFB84D); // reward accent

  static const Color neonLime = primary;
  static const Color neonCyan = secondary;

  static const Color backgroundLight = Color(0xFFF6F8FB);
  static const Color backgroundDark = Color(0xFF0D1117);

  static const Color background = backgroundDark;
  static const Color surface = Color(0xFF121824);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = surface;

  static const Color customBackground = Color(0xFF0D1117);
  static const Color customSurface = Color(0xFF151C29);
  static const Color cardDark = Color(0xFF1A2332);

  static const Color textPrimaryLight = Color(0xFF111827);
  static const Color textSecondaryLight = Color(0xFF667085);
  static const Color textPrimaryDark = Color(0xFFF5F7FB);
  static const Color textSecondaryDark = Color(0xFF9AA7BD);

  static const Color success = Color(0xFF74F0B2);
  static const Color error = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB84D);
  static const Color info = Color(0xFF4BC2FF);

  static const List<Color> chartColors = [
    Color(0xFF74F0B2),
    Color(0xFF4BC2FF),
    Color(0xFFFFB84D),
    Color(0xFF8B7BFF),
    Color(0xFFFF7A59),
  ];

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF74F0B2), Color(0xFF4BC2FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
