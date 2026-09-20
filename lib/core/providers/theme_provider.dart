import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls Light / Dark / System appearance for the client flow.
///
/// Defaults to [ThemeMode.system] so the app follows the OS out of the box;
/// the client Settings screen lets users override it. Persisted storage can
/// be layered on later without changing consumers.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);
