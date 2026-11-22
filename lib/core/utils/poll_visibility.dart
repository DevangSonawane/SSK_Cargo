import 'package:flutter/widgets.dart';

/// True only when this screen is the visible tab/route and the app is in the
/// foreground — web pages only poll while open, so we skip background ticks.
bool shouldPollNow(BuildContext context) {
  final lifecycle = WidgetsBinding.instance.lifecycleState;
  if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
    return false;
  }
  // Inactive StatefulShellRoute branches run with tickers disabled.
  if (!TickerMode.valuesOf(context).enabled) return false;
  return ModalRoute.of(context)?.isCurrent ?? true;
}
