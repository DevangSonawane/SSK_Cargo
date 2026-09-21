import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls Light / Dark / System appearance for the client flow.
///
/// Defaults to [ThemeMode.light] so the app opens in light mode even when the
/// device is using a dark system appearance. Persisted storage can be layered
/// on later without changing consumers.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);
