import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static const _cupertinoTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
    },
  );

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    return GoogleFonts.notoSansKrTextTheme(base).copyWith(
      displayLarge:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w700),
      displayMedium:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w700),
      displaySmall:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w700),
      headlineLarge:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w700),
      headlineMedium:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      headlineSmall:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      titleLarge:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      titleMedium:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      titleSmall:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w500),
      bodyLarge: GoogleFonts.notoSansKr(color: textColor, height: 1.45),
      bodyMedium: GoogleFonts.notoSansKr(color: textColor, height: 1.45),
      bodySmall: GoogleFonts.notoSansKr(
          color: textColor.withValues(alpha: 0.72), height: 1.4),
      labelLarge:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
    );
  }

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    pageTransitionsTheme: _cupertinoTransitions,
    splashFactory: NoSplash.splashFactory,
    primaryColor: AppColors.primary,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryLight,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.surfaceLight,
      surfaceContainer: AppColors.groupedSurfaceLight,
      surfaceContainerHigh: AppColors.elevatedSurfaceLight,
      surfaceContainerHighest: AppColors.elevatedSurfaceLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      foregroundColor: AppColors.textPrimaryLight,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 44,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimaryLight,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
    textTheme: _buildTextTheme(
        ThemeData.light().textTheme, AppColors.textPrimaryLight),
    cardTheme: CardThemeData(
      color: AppColors.surfaceLight,
      elevation: 1,
      shadowColor: const Color(0xFF173B67).withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        minimumSize: const Size(64, 44),
        side: const BorderSide(color: AppColors.separatorLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        minimumSize: const Size(44, 44),
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceLight,
      selectedItemColor: AppColors.primaryLight,
      unselectedItemColor: AppColors.textSecondaryLight,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.textPrimaryLight,
      unselectedLabelColor: AppColors.textSecondaryLight,
      indicatorColor: AppColors.primaryLight,
      labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.separatorLight,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.2),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.primaryLight.withValues(alpha: 0.14),
      iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.primaryLight
                : AppColors.textSecondaryLight,
          )),
      labelTextStyle: WidgetStateProperty.resolveWith((states) =>
          GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w700
                  : FontWeight.w500,
              color: states.contains(WidgetState.selected)
                  ? AppColors.primaryLight
                  : AppColors.textSecondaryLight)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surface,
      contentTextStyle: GoogleFonts.notoSansKr(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primaryLight
              : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primaryLight.withValues(alpha: 0.35)
              : AppColors.separatorLight),
    ),
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    pageTransitionsTheme: _cupertinoTransitions,
    splashFactory: NoSplash.splashFactory,
    primaryColor: AppColors.primaryDark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryDark,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      surface: AppColors.groupedSurfaceDark,
      surfaceContainer: AppColors.groupedSurfaceDark,
      surfaceContainerHigh: AppColors.elevatedSurfaceDark,
      surfaceContainerHighest: AppColors.elevatedSurfaceDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      error: AppColors.error,
    ),
    scaffoldBackgroundColor: AppColors.customBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.customBackground,
      foregroundColor: AppColors.textPrimaryDark,
      elevation: 0,
      centerTitle: true,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 44,
      titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimaryDark),
    ),
    textTheme:
        _buildTextTheme(ThemeData.dark().textTheme, AppColors.textPrimaryDark),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        minimumSize: const Size(64, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle:
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimaryDark,
        minimumSize: const Size(64, 44),
        side: const BorderSide(color: AppColors.separatorDark, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        minimumSize: const Size(44, 44),
        textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryDark,
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.textPrimaryDark,
      unselectedItemColor: AppColors.textSecondaryDark,
      type: BottomNavigationBarType.fixed,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      elevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.groupedSurfaceDark,
      indicatorColor: AppColors.primaryDark.withValues(alpha: 0.18),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.primaryDark);
        }
        return const IconThemeData(color: AppColors.textSecondaryDark);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.notoSansKr(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark);
        }
        return GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondaryDark);
      }),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.textPrimaryDark,
      unselectedLabelColor: AppColors.textSecondaryDark,
      indicatorColor: AppColors.primaryDark,
      labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w600),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.separatorDark,
      thickness: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.customSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
            color: AppColors.primaryDark.withValues(alpha: 0.7), width: 1.1),
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.customSurface,
      contentTextStyle:
          GoogleFonts.notoSansKr(color: AppColors.textPrimaryDark),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceDark,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primaryDark
              : AppColors.textPrimaryDark),
      trackColor: WidgetStateProperty.resolveWith((states) =>
          states.contains(WidgetState.selected)
              ? AppColors.primaryDark.withValues(alpha: 0.35)
              : AppColors.separatorDark),
    ),
  );
}
