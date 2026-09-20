import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  static const Color seedGreen = Color(0xFF2FA56E);
  static const Color seedBlue = Color(0xFF1F88C9);
  static const Color background = Colors.white;
  static const String fontFamily = 'Inter';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedGreen,
      primary: AppColors.brand,
      secondary: AppColors.brand,
      surface: AppColors.surface,
      error: AppColors.dangerText,
    );

    return _build(
      colorScheme: colorScheme,
      appColors: AppColorScheme.light,
      brightness: Brightness.light,
    );
  }

  /// Uber-subtle dark theme for the client flow: charcoal canvas, slightly
  /// lifted charcoal surfaces, off-white text, same green brand (brightened).
  static ThemeData get dark {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.dark,
      primary: AppDarkColors.brand,
      secondary: AppDarkColors.brand,
      surface: AppDarkColors.surface,
      error: const Color(0xFFFF8A80),
    );

    return _build(
      colorScheme: colorScheme,
      appColors: AppColorScheme.dark,
      brightness: Brightness.dark,
    );
  }

  static ThemeData _build({
    required ColorScheme colorScheme,
    required AppColorScheme appColors,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final textPrimary = appColors.textPrimary;
    final fillColor = appColors.fillSubtle;
    final lineColor = appColors.line;
    final brandColor = isDark ? AppDarkColors.brand : AppColors.brand;

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: appColors.canvas,
      extensions: <ThemeExtension<dynamic>>[appColors],
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w800,
          fontFamily: fontFamily,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: brandColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandColor,
          side: BorderSide(color: appColors.brandBorder),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fillColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: appColors.textTertiary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: lineColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: lineColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.fieldRadius,
          borderSide: BorderSide(color: brandColor, width: 1.4),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppDarkColors.surfaceElevated : null,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppDarkColors.surfaceElevated
            : AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppDarkColors.surface : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      dividerColor: appColors.divider,
      textTheme: TextTheme(
        headlineLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
          color: textPrimary,
        ),
        headlineSmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.35, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, height: 1.35, color: textPrimary),
        bodySmall: TextStyle(
          fontSize: 12,
          height: 1.35,
          color: appColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        labelSmall: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: appColors.textSecondary,
        ),
      ),
    );
  }
}
