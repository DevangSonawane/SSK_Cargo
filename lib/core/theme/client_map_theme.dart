import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uber-style dark basemap for the client flow.
///
/// Usage: pass [styleFor] into `GoogleMap(style: ...)` so the basemap follows
/// the current theme. The JSON is cached after the first load; call
/// [ensureLoaded] at startup to avoid a light-map flash in dark mode.
abstract final class ClientMapTheme {
  static const String _assetPath = 'assets/map_dark.json';

  static String? _darkStyleJson;

  static Future<void> ensureLoaded() async {
    if (_darkStyleJson != null) return;
    try {
      _darkStyleJson = await rootBundle.loadString(_assetPath);
    } catch (_) {
      _darkStyleJson = null;
    }
  }

  /// Returns the dark map style in dark mode, `null` (default basemap)
  /// in light mode. Call [ensureLoaded] first (e.g. in `main`) so the
  /// style is ready before the first map builds.
  static String? styleFor(BuildContext context) {
    if (Theme.of(context).brightness != Brightness.dark) return null;
    return _darkStyleJson;
  }
}
