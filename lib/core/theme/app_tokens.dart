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