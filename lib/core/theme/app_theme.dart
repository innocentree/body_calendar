import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // 텍스트 테마 생성 헬퍼
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.notoSansKrTextTheme(base).copyWith(
      displayLarge: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w500),
      titleSmall: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.notoSansKr(color: textColor),
      bodyMedium: GoogleFonts.notoSansKr(color: textColor),
      bodySmall: GoogleFonts.notoSansKr(color: textColor.withOpacity(0.7)),
      labelLarge: GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w500),
    );
  }

  // 라이트 테마
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      background: AppColors.backgroundLight,
      surface: AppColors.surfaceLight,
      onPrimary: Colors.black, // Neon color needs dark text for contrast
      onSecondary: Colors.black,
      onBackground: AppColors.textPrimaryLight,
      onSurface: AppColors.textPrimaryLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surfaceLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
    ),
    textTheme: _buildTextTheme(ThemeData.light().textTheme, AppColors.textPrimaryLight),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 4,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primary, // This might be hard to see on light, check contrast
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Colors.black, // Primary is neon, too bright for text on light
      unselectedLabelColor: AppColors.textSecondaryLight,
      indicatorColor: AppColors.primary,
      labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
      indicatorSize: TabBarIndicatorSize.label,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE5E5EA),
      thickness: 1,
    ),
  );

  // 다크 테마 (Main Focus)
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.neonLime,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.neonLime,
      secondary: AppColors.neonCyan,
      tertiary: AppColors.accent,
      background: AppColors.backgroundDark,
      surface: AppColors.customBackground,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: AppColors.textPrimaryDark,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.customBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.customBackground, // Seamless app bar
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
       titleTextStyle: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.bold, 
        color: Colors.white,
      ),
    ),
    textTheme: _buildTextTheme(ThemeData.dark().textTheme, AppColors.textPrimaryDark),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0, // Flat design for dark mode
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // More rounded
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        elevation: 0,
        minimumSize: const Size(double.infinity, 52), // Taller buttons
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
       style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      ),
    ),
     textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      elevation: 8,
      shape: CircleBorder(), // Classic circle or RoundedRectangle
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.neonLime,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.customBackground,
      indicatorColor: AppColors.customSurface, // Matches Workout Card Background
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: Colors.white); // Matches "White" Text
        }
        return const IconThemeData(color: AppColors.textSecondaryDark);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white);
        }
        return GoogleFonts.notoSansKr(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondaryDark);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondaryDark,
      indicatorColor: AppColors.primary,
      labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.bold),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent, // Remove tab divider
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF38383A),
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.cardDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder( // Neon focus border
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      hintStyle: TextStyle(color: AppColors.textSecondaryDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}