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
      displayLarge: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
      ),
      displayMedium: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
      ),
      displaySmall: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineLarge: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
      headlineMedium: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.35,
      ),
      headlineSmall: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
      ),
      titleLarge: GoogleFonts.notoSansKr(
        color: textColor,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w700),
      titleSmall:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.notoSansKr(color: textColor, height: 1.45),
      bodyMedium: GoogleFonts.notoSansKr(color: textColor, height: 1.45),
      bodySmall: GoogleFonts.notoSansKr(
        color: textColor.withValues(alpha: 0.74),
        height: 1.4,
      ),
      labelLarge:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w700),
      labelMedium:
          GoogleFonts.notoSansKr(color: textColor, fontWeight: FontWeight.w600),
    );
  }

  static WidgetStateProperty<Color?> _stateColor({
    required Color normal,
    required Color pressed,
    required Color disabled,
    Color? hovered,
  }) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return disabled;
      if (states.contains(WidgetState.pressed)) return pressed;
      if (states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return hovered ?? pressed;
      }
      return normal;
    });
  }

  static ButtonStyle _primaryButtonStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final action = AppColors.actionFor(brightness);
    final pressed = isDark ? const Color(0xFF5E46CF) : AppColors.secondary;
    final disabled = isDark
        ? AppColors.separatorDark.withValues(alpha: 0.72)
        : AppColors.separatorLight.withValues(alpha: 0.72);
    final disabledForeground = isDark
        ? AppColors.textSecondaryDark.withValues(alpha: 0.68)
        : AppColors.textSecondaryLight.withValues(alpha: 0.68);

    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 50)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      ),
      backgroundColor: _stateColor(
        normal: action,
        hovered: Color.alphaBlend(Colors.white.withValues(alpha: 0.08), action),
        pressed: pressed,
        disabled: disabled,
      ),
      foregroundColor: _stateColor(
        normal: Colors.white,
        pressed: Colors.white,
        disabled: disabledForeground,
      ),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) {
          return Colors.white.withValues(alpha: 0.12);
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return Colors.white.withValues(alpha: 0.07);
        }
        return Colors.transparent;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled) ||
            states.contains(WidgetState.pressed)) {
          return 0;
        }
        return 1;
      }),
      shadowColor: WidgetStatePropertyAll(
        action.withValues(alpha: isDark ? 0.18 : 0.16),
      ),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return BorderSide.none;
        return BorderSide(color: Colors.white.withValues(alpha: 0.14));
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 16),
      ),
    );
  }

  static ButtonStyle _outlinedButtonStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = AppColors.primaryFor(brightness);
    final container = AppColors.primaryContainerFor(brightness);
    final separator = AppColors.separatorFor(brightness);
    final secondaryText = AppColors.secondaryTextFor(brightness);

    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(64, 44)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 18, vertical: 11),
      ),
      foregroundColor: _stateColor(
        normal: primary,
        pressed: AppColors.onPrimaryContainerFor(brightness),
        disabled: secondaryText.withValues(alpha: 0.55),
      ),
      backgroundColor: _stateColor(
        normal: container.withValues(alpha: isDark ? 0.34 : 0.48),
        hovered: container.withValues(alpha: isDark ? 0.72 : 0.82),
        pressed: container,
        disabled: separator.withValues(alpha: 0.22),
      ),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return BorderSide(color: separator.withValues(alpha: 0.45));
        }
        return BorderSide(color: primary.withValues(alpha: 0.34));
      }),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.notoSansKr(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    );
  }

  static ButtonStyle _textButtonStyle(Brightness brightness) {
    final primary = AppColors.primaryFor(brightness);
    final container = AppColors.primaryContainerFor(brightness);
    final secondaryText = AppColors.secondaryTextFor(brightness);
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(44, 44)),
      foregroundColor: _stateColor(
        normal: primary,
        pressed: AppColors.onPrimaryContainerFor(brightness),
        disabled: secondaryText.withValues(alpha: 0.55),
      ),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return container.withValues(alpha: 0.78);
        }
        return Colors.transparent;
      }),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      ),
      textStyle: WidgetStatePropertyAll(
        GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
      ),
    );
  }

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = AppColors.primaryFor(brightness);
    final action = AppColors.actionFor(brightness);
    final background = AppColors.groupedBackgroundFor(brightness);
    final surface = AppColors.groupedSurfaceFor(brightness);
    final elevatedSurface = AppColors.elevatedSurfaceFor(brightness);
    final primaryContainer = AppColors.primaryContainerFor(brightness);
    final onPrimaryContainer = AppColors.onPrimaryContainerFor(brightness);
    final textPrimary = AppColors.primaryTextFor(brightness);
    final textSecondary = AppColors.secondaryTextFor(brightness);
    final separator = AppColors.separatorFor(brightness);

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: primary,
      onPrimary: isDark ? const Color(0xFF21173C) : Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      secondaryContainer:
          isDark ? const Color(0xFF3C245C) : const Color(0xFFF0E7FF),
      onSecondaryContainer:
          isDark ? const Color(0xFFF1E7FF) : const Color(0xFF43216D),
      tertiary: AppColors.accent,
      onTertiary: isDark ? const Color(0xFF21173C) : const Color(0xFF2D1748),
      error: AppColors.error,
      onError: Colors.white,
      surface: surface,
      onSurface: textPrimary,
      surfaceContainerLowest: surface,
      surfaceContainerLow: surface,
      surfaceContainer: surface,
      surfaceContainerHigh: elevatedSurface,
      surfaceContainerHighest: elevatedSurface,
      onSurfaceVariant: textSecondary,
      outline: separator,
      outlineVariant: separator.withValues(alpha: 0.72),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      onInverseSurface: isDark ? AppColors.backgroundDark : Colors.white,
      inversePrimary: isDark ? AppColors.primaryLight : AppColors.primaryDark,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      pageTransitionsTheme: _cupertinoTransitions,
      splashFactory: NoSplash.splashFactory,
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      disabledColor: textSecondary.withValues(alpha: 0.5),
      textTheme: _buildTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
        textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
      primaryIconTheme: IconThemeData(color: primary),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        iconTheme: IconThemeData(color: textPrimary),
        actionsIconTheme: IconThemeData(color: primary),
        titleTextStyle: GoogleFonts.notoSansKr(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.25,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: separator.withValues(alpha: isDark ? 0.8 : 0.72),
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _primaryButtonStyle(brightness),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _primaryButtonStyle(brightness),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(brightness),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(brightness),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: _stateColor(
            normal: primary,
            pressed: onPrimaryContainer,
            disabled: textSecondary.withValues(alpha: 0.5),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return primaryContainer;
            }
            return Colors.transparent;
          }),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: action,
        foregroundColor: Colors.white,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 2,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        indicatorColor: primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? primary
                  : textSecondary,
              size: states.contains(WidgetState.selected) ? 25 : 23,
            )),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => GoogleFonts.notoSansKr(
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color:
                states.contains(WidgetState.selected) ? primary : textSecondary,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: onPrimaryContainer,
        unselectedLabelColor: textSecondary,
        indicator: BoxDecoration(
          color: primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
        unselectedLabelStyle:
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: separator.withValues(alpha: 0.72),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? elevatedSurface : Colors.white,
        prefixIconColor: textSecondary,
        suffixIconColor: primary,
        labelStyle:
            TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
        floatingLabelStyle:
            TextStyle(color: primary, fontWeight: FontWeight.w700),
        hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.86)),
        errorStyle: const TextStyle(color: AppColors.error),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: separator),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: separator),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.error, width: 1.6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: elevatedSurface,
        selectedColor: primaryContainer,
        disabledColor: separator.withValues(alpha: 0.28),
        checkmarkColor: primary,
        labelStyle: GoogleFonts.notoSansKr(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: GoogleFonts.notoSansKr(
          color: onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
        side: BorderSide(color: separator),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? onPrimaryContainer
                  : textSecondary),
          backgroundColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? primaryContainer
                  : Colors.transparent),
          side: WidgetStatePropertyAll(BorderSide(color: separator)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          textStyle: WidgetStatePropertyAll(
            GoogleFonts.notoSansKr(fontWeight: FontWeight.w700),
          ),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return textSecondary.withValues(alpha: 0.45);
          }
          return states.contains(WidgetState.selected) ? Colors.white : surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return separator.withValues(alpha: 0.45);
          }
          return states.contains(WidgetState.selected) ? action : separator;
        }),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return separator.withValues(alpha: 0.55);
          }
          return states.contains(WidgetState.selected)
              ? action
              : Colors.transparent;
        }),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        side: BorderSide(color: separator, width: 1.4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return textSecondary.withValues(alpha: 0.45);
          }
          return states.contains(WidgetState.selected)
              ? primary
              : textSecondary;
        }),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: action,
        inactiveTrackColor: primaryContainer,
        thumbColor: primary,
        overlayColor: primary.withValues(alpha: 0.12),
        valueIndicatorColor: action,
        valueIndicatorTextStyle: const TextStyle(color: Colors.white),
        trackHeight: 5,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primaryContainer,
        circularTrackColor: primaryContainer,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: textPrimary,
        selectedColor: primary,
        selectedTileColor: primaryContainer.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? elevatedSurface : AppColors.textPrimaryLight,
        contentTextStyle: GoogleFonts.notoSansKr(color: Colors.white),
        actionTextColor: isDark ? AppColors.primaryDark : AppColors.accent,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.24 : 0.10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: separator.withValues(alpha: 0.72)),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: elevatedSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: separator),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? elevatedSurface : AppColors.textPrimaryLight,
          borderRadius: BorderRadius.circular(10),
        ),
        textStyle: GoogleFonts.notoSansKr(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static final ThemeData lightTheme = _buildTheme(Brightness.light);
  static final ThemeData darkTheme = _buildTheme(Brightness.dark);
}
