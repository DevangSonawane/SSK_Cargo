import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/driver_location_tracker.dart';

final driverLocationTrackerProvider = Provider<DriverLocationTracker>((ref) {
  final tracker = DriverLocationTracker(ref);
  ref.onDispose(() => unawaited(tracker.stopTracking()));
  return tracker;
});
