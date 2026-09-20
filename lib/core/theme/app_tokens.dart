import 'package:flutter/material.dart';

/// Design tokens extracted from the client flow's design language.
///
/// The client flow is the reference aesthetic: a minimal, premium look built
/// around a single green brand color, a restrained neutral palette and soft
/// surfaces. The broker (and future) flows should consume these tokens instead
/// of hardcoding raw hex values so the whole app stays visually unified.
abstract final class AppColors {
  // Brand green
  static const Color brand = Color(0xFF2FA56E);
  static const Color brandBright = Color(0xFF38B47A);
  static const Color brandDark = Color(0xFF15803D);
  static const Color brandInk = Color(0xFF136F3E);
  static const Color brandGlow = Color(0xFF22C55E);
  static const Color brandFill = Color(0xFFF0F7F3);
  static const Color brandTint = Color(0xFFEAF8EF);
  static const Color brandBorder = Color(0xFFD7EBDD);

  // Text
  static const Color textPrimary = Color(0xFF101828);
  static const Color textHeading = Color(0xFF0B1F3A);
  static const Color textSecondary = Color(0xFF667085);
  static const Color textTertiary = Color(0xFF98A2B3);
  static const Color textMuted = Color(0xFF9AA4B2);
  static const Color textOnBrand = Colors.white;

  // Surfaces
  static const Color canvas = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color fillSubtle = Color(0xFFF2F4F7);
  static const Color line = Color(0xFFE3E8EF);
  static const Color divider = Color(0xFFE6EAF0);

  // Semantic
  static const Color successText = Color(0xFF136F3E);
  static const Color successFill = Color(0xFFEAF8EF);
  static const Color successBorder = Color(0xFFB7E4C7);
  static const Color dangerText = Color(0xFFB42318);
  static const Color dangerIcon = Color(0xFFF05252);
  static const Color dangerFill = Color(0xFFFDECEC);
  static const Color dangerBorder = Color(0xFFF7B4B4);
  static const Color warningText = Color(0xFFB45309);
  static const Color warningFill = Color(0xFFFFF0DB);
  static const Color warningBorder = Color(0xFFFCD34D);

  // Secondary accent (client uses this blue sparingly for links/map actions)
  static const Color accentBlue = Color(0xFF1F88C9);
  static const Color accentBlueBorder = Color(0xFFD7E7F4);

  // Status dots
  static const Color unreadDot = Color(0xFFE23A4B);
}

/// Uber-subtle dark palette for the client flow.
///
/// Deliberately charcoal, not AMOLED black: surfaces sit slightly above the
/// canvas, text is off-white (~87%) instead of pure white, and the green
/// brand color is brightened one step so it keeps contrast on dark surfaces.
abstract final class AppDarkColors {
  // Surfaces
  static const Color canvas = Color(0xFF101214);
  static const Color surface = Color(0xFF1A1D21);
  static const Color surfaceElevated = Color(0xFF23272E);
  static const Color fillSubtle = Color(0xFF23272E);
  static const Color line = Color(0xFF2B3138);
  static const Color divider = Color(0xFF262C34);

  // Text (off-whites, never pure white)
  static const Color textPrimary = Color(0xFFECEEF1);
  static const Color textSecondary = Color(0xFF9AA4B2);
  static const Color textTertiary = Color(0xFF6E7A89);
  static const Color textOnBrand = Colors.white;

  // Emphasis text: colored text that stays legible on both light fills and
  // dark surfaces (deep tones in light mode, brightened pastels in dark).
  static const Color brandEmphasis = Color(0xFF4ADE80);
  static const Color dangerEmphasis = Color(0xFFF97066);
  static const Color warningEmphasis = Color(0xFFFDB022);
  static const Color infoEmphasis = Color(0xFF53B1FD);

  // Brand on dark
  static const Color brand = Color(0xFF3BB97F);
  static const Color brandFill = Color(0xFF10281D);
  static const Color brandTint = Color(0xFF143325);
  static const Color brandBorder = Color(0xFF1E4A34);

  // Semantic fills tuned for dark surfaces
  static const Color successFill = Color(0xFF10281D);
  static const Color successBorder = Color(0xFF1E4A34);
  static const Color dangerFill = Color(0xFF33151A);
  static const Color dangerBorder = Color(0xFF5C222B);
  static const Color warningFill = Color(0xFF2E2111);
  static const Color warningBorder = Color(0xFF5C441A);
  static const Color infoFill = Color(0xFF14222E);
  static const Color infoBorder = Color(0xFF23405A);
}

/// Semantic surface/text tokens that resolve per brightness.
///
/// Client flow widgets should read these via `context.colors` instead of
/// hardcoding light hex values, so both [AppTheme.light] and [AppTheme.dark]
/// render correctly.
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.canvas,
    required this.surface,
    required this.surfaceElevated,
    required this.fillSubtle,
    required this.line,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.brandFill,
    required this.brandBorder,
    required this.brandEmphasis,
    required this.dangerEmphasis,
    required this.warningEmphasis,
    required this.infoEmphasis,
  });

  final Color canvas;
  final Color surface;
  final Color surfaceElevated;
  final Color fillSubtle;
  final Color line;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color brandFill;
  final Color brandBorder;

  /// Colored text/icons on tinted or theme surfaces. Light values match the
  /// legacy deep tones; dark values are brightened for charcoal backgrounds.
  final Color brandEmphasis;
  final Color dangerEmphasis;
  final Color warningEmphasis;
  final Color infoEmphasis;

  static const AppColorScheme light = AppColorScheme(
    canvas: AppColors.canvas,
    surface: AppColors.surface,
    surfaceElevated: AppColors.surface,
    fillSubtle: AppColors.fillSubtle,
    line: AppColors.line,
    divider: AppColors.divider,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    textTertiary: AppColors.textTertiary,
    brandFill: AppColors.brandFill,
    brandBorder: AppColors.brandBorder,
    brandEmphasis: Color(0xFF167247),
    dangerEmphasis: Color(0xFFB42318),
    warningEmphasis: Color(0xFFB45309),
    infoEmphasis: Color(0xFF1F88C9),
  );

  static const AppColorScheme dark = AppColorScheme(
    canvas: AppDarkColors.canvas,
    surface: AppDarkColors.surface,
    surfaceElevated: AppDarkColors.surfaceElevated,
    fillSubtle: AppDarkColors.fillSubtle,
    line: AppDarkColors.line,
    divider: AppDarkColors.divider,
    textPrimary: AppDarkColors.textPrimary,
    textSecondary: AppDarkColors.textSecondary,
    textTertiary: AppDarkColors.textTertiary,
    brandFill: AppDarkColors.brandFill,
    brandBorder: AppDarkColors.brandBorder,
    brandEmphasis: AppDarkColors.brandEmphasis,
    dangerEmphasis: AppDarkColors.dangerEmphasis,
    warningEmphasis: AppDarkColors.warningEmphasis,
    infoEmphasis: AppDarkColors.infoEmphasis,
  );

  @override
  AppColorScheme copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceElevated,
    Color? fillSubtle,
    Color? line,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? brandFill,
    Color? brandBorder,
    Color? brandEmphasis,
    Color? dangerEmphasis,
    Color? warningEmphasis,
    Color? infoEmphasis,
  }) {
    return AppColorScheme(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      fillSubtle: fillSubtle ?? this.fillSubtle,
      line: line ?? this.line,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      brandFill: brandFill ?? this.brandFill,
      brandBorder: brandBorder ?? this.brandBorder,
      brandEmphasis: brandEmphasis ?? this.brandEmphasis,
      dangerEmphasis: dangerEmphasis ?? this.dangerEmphasis,
      warningEmphasis: warningEmphasis ?? this.warningEmphasis,
      infoEmphasis: infoEmphasis ?? this.infoEmphasis,
    );
  }

  @override
  AppColorScheme lerp(ThemeExtension<AppColorScheme>? other, double t) {
    if (other is! AppColorScheme) return this;
    return AppColorScheme(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      fillSubtle: Color.lerp(fillSubtle, other.fillSubtle, t)!,
      line: Color.lerp(line, other.line, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      brandFill: Color.lerp(brandFill, other.brandFill, t)!,
      brandBorder: Color.lerp(brandBorder, other.brandBorder, t)!,
      brandEmphasis: Color.lerp(brandEmphasis, other.brandEmphasis, t)!,
      dangerEmphasis: Color.lerp(dangerEmphasis, other.dangerEmphasis, t)!,
      warningEmphasis: Color.lerp(warningEmphasis, other.warningEmphasis, t)!,
      infoEmphasis: Color.lerp(infoEmphasis, other.infoEmphasis, t)!,
    );
  }
}

/// Shortcut for `Theme.of(context).extension<AppColorScheme>()`.
extension AppThemeContext on BuildContext {
  AppColorScheme get colors =>
      Theme.of(this).extension<AppColorScheme>() ?? AppColorScheme.light;
}

abstract final class AppRadius {
  static const double card = 24;
  static const double field = 22;
  static const double button = 15;
  static const double small = 10;
  static const double pill = 999;
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(card));
  static const BorderRadius fieldRadius = BorderRadius.all(Radius.circular(field));
  static const BorderRadius buttonRadius = BorderRadius.all(Radius.circular(button));
  static const BorderRadius smallRadius = BorderRadius.all(Radius.circular(small));
}

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double page = 20;
}

abstract final class AppShadows {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 14,
      offset: Offset(0, 6),
    ),
  ];

  static const List<BoxShadow> float = [
    BoxShadow(
      color: Color(0x29000000),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static const List<BoxShadow> brandGlow = [
    BoxShadow(
      color: Color(0x572FA56E),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
}