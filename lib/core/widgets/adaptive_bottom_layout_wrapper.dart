import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Adds global bottom breathing room for Android system navigation modes.
///
/// Android gesture navigation usually reports a thin bottom inset, while
/// 3-button navigation reports a much larger inset. This wrapper keeps the
/// app responsive to rotation, split-screen, and runtime navigation-mode
/// changes because it reads MediaQuery on every build.
class AdaptiveBottomLayoutWrapper extends StatelessWidget {
  const AdaptiveBottomLayoutWrapper({
    super.key,
    required this.child,
    this.thickNavigationBarThreshold = 40,
    this.extraThickNavigationPadding = 12,
    this.useViewPadding = true,
    this.enabled = true,
  });

  final Widget child;

  /// Insets at or above this value are treated as Android 3-button navigation.
  ///
  /// Gesture navigation commonly sits around 16-24dp; 3-button navigation is
  /// commonly around 48dp or higher depending on device density and OEM skin.
  final double thickNavigationBarThreshold;

  /// Additional app-side breathing room when a thick navigation bar is present.
  final double extraThickNavigationPadding;

  /// Uses [MediaQueryData.viewPadding] by default so runtime navigation-mode
  /// changes remain detectable.
  final bool useViewPadding;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled || defaultTargetPlatform != TargetPlatform.android) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final keyboardIsOpen = mediaQuery.viewInsets.bottom > 0;
    if (keyboardIsOpen) {
      return child;
    }

    final bottomSystemInset = useViewPadding
        ? mediaQuery.viewPadding.bottom
        : mediaQuery.padding.bottom;
    final hasThickNavigationBar =
        bottomSystemInset >= thickNavigationBarThreshold;
    final adaptiveBottomPadding = hasThickNavigationBar
        ? extraThickNavigationPadding
        : 0.0;

    if (adaptiveBottomPadding <= 0) {
      return child;
    }

    return Padding(
      padding: EdgeInsets.only(bottom: adaptiveBottomPadding),
      child: child,
    );
  }
}
