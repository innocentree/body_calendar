import 'package:flutter/material.dart';

class AppColors {
  // 주요 색상 (Neon Accents)
  static const Color primary = Color(0xFFB9FF03); // Neon Lime
  static const Color secondary = Color(0xFF00E5FF); // Neon Cyan
  static const Color accent = Color(0xFFFF4081); // Hot Pink
  
  // Aliases for Theme
  static const Color neonLime = primary;
  static const Color neonCyan = secondary;

  // 배경 색상 (Deep Dark)
  static const Color backgroundLight = Color(0xFFF5F5F7); // Soft White (Warm)
  static const Color backgroundDark = Color(0xFF121212); // True Black

  // 카드/서피스 색상
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E24);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E24);
  
  // Custom Colors from User
  static const Color customBackground = Color.fromARGB(255, 34, 41, 53);
  static const Color customSurface = Color.fromARGB(255, 52, 64, 78); // Blue-Grey for Selected/Cards
  static const Color cardDark = Color(0xFF2C2C35); // Lighter Gunmetal

  // 텍스트 색상
  static const Color textPrimaryLight = Color(0xFF1C1C1E);
  static const Color textSecondaryLight = Color(0xFF8E8E93);
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Lighter Grey for readability

  // 상태 색상
  static const Color success = Color(0xFFB9FF03); // Use Primary logic for success
  static const Color error = Color(0xFFFF453A); // iOS Red
  static const Color warning = Color(0xFFFF9F0A); // iOS Orange
  static const Color info = Color(0xFF0A84FF); // iOS Blue

  // 그래프 색상 (Vibrant)
  static const List<Color> chartColors = [
    Color(0xFFB9FF03), // Neon Lime
    Color(0xFF00E5FF), // Neon Cyan
    Color(0xFFFF4081), // Hot Pink
    Color(0xFFAE52DE), // Purple
    Color(0xFFFF9F0A), // Orange
  ];

  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFB9FF03), Color(0xFF82B100)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}