import 'package:flutter/material.dart';

class AppColors {
  // 주요 색상
  static const Color primary = Color(0xFF1E88E5); // 파란색 계열
  static const Color secondary = Color(0xFF43A047); // 녹색 계열
  static const Color accent = Color(0xFFFF5722); // 주황색 계열

  // 배경 색상
  static const Color backgroundLight = Color(0xFFFFFFFF); // 흰색
  static const Color backgroundDark = Color(0xFF121212); // 검정색

  // 텍스트 색상
  static const Color textPrimaryLight = Color(0xFF212121); // 진한 회색
  static const Color textSecondaryLight = Color(0xFF757575); // 중간 회색
  static const Color textPrimaryDark = Color(0xFFE0E0E0); // 밝은 회색
  static const Color textSecondaryDark = Color(0xFFAAAAAA); // 중간 밝은 회색

  // 상태 색상
  static const Color success = Color(0xFF4CAF50); // 녹색
  static const Color error = Color(0xFFF44336); // 빨간색
  static const Color warning = Color(0xFFFF9800); // 주황색
  static const Color info = Color(0xFF2196F3); // 파란색

  // 그래프 색상
  static const List<Color> chartColors = [
    Color(0xFF1E88E5), // 파란색
    Color(0xFF43A047), // 녹색
    Color(0xFFFF5722), // 주황색
    Color(0xFF9C27B0), // 보라색
    Color(0xFFFFEB3B), // 노란색
  ];

  // 그라데이션
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1976D2), Color(0xFF64B5F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
} 