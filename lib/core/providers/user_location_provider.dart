import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'google_places_provider.dart';

/// In-memory snapshot of the user's current location.
///
/// Prefetched right after login (see [AuthController]) so booking / map
/// screens can render instantly instead of waiting on GPS + reverse-geocode.
class CachedUserLocation {
  const CachedUserLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.fetchedAt,
    this.accuracy,
  });

  final double latitude;
  final double longitude;
  final String address;
  final DateTime fetchedAt;
  final double? accuracy;

  /// Fresh for 10 minutes — enough to skip the GPS spinner on the
  /// loading / pickup screens without risking a stale pin.
  bool get isFresh =>
      DateTime.now().difference(fetchedAt) < const Duration(minutes: 10);
}

/// Holds the last known location for the current session.
///
/// - `AsyncData(null)` → nothing cached yet (or permission denied/off).
/// - `AsyncData(location)` → ready to use instantly, no GPS wait.
/// - `AsyncLoading` → first fetch in flight.
final userLocationProvider =
    StateNotifierProvider<UserLocationController, AsyncValue<CachedUserLocation?>>(
      (ref) => UserLocationController(ref),
    );

class UserLocationController
    extends StateNotifier<AsyncValue<CachedUserLocation?>> {
  UserLocationController(this._ref) : super(const AsyncData(null));

  final Ref _ref;
  Future<void>? _inFlight;

  /// Fire-and-forget prefetch. Safe to call multiple times — concurrent
  /// calls are de-duplicated and fresh cache is reused unless [force].
  Future<void> prefetch({bool force = false}) {
    final cached = state.valueOrNull;
    if (!force && cached != null && cached.isFresh) {
      return Future.value();
    }
    final ongoing = _inFlight;
    if (ongoing != null) {
      return ongoing;
    }
    final future = _fetch();
    _inFlight = future;
    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });
    return future;
  }

  Future<void> _fetch() async {
    final previous = state.valueOrNull;
    // Only show a loader when we have nothing to show yet — otherwise
    // refresh silently in the background and keep the old pin visible.
    if (previous == null && state is! AsyncLoading) {
      state = const AsyncLoading<CachedUserLocation?>();
    }
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (previous == null) {
          state = const AsyncData<CachedUserLocation?>(null);
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (previous == null) {
          state = const AsyncData<CachedUserLocation?>(null);
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(const Duration(seconds: 12));

      String address = previous?.address ?? '';
      // Keep an old address if reverse-geocode fails — lat/lng is still
      // enough to centre the map instantly.
      try {
        final resolved = await _ref
            .read(googlePlacesServiceProvider)
            .reverseGeocode(
              latitude: position.latitude,
              longitude: position.longitude,
            )
            .timeout(const Duration(seconds: 10));
        if (resolved.isNotEmpty) {
          address = resolved;
        }
      } catch (_) {
        // Ignore — fall back to previous/empty address.
      }

      state = AsyncData(
        CachedUserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          address: address,
          fetchedAt: DateTime.now(),
          accuracy: position.accuracy,
        ),
      );
    } catch (_) {
      // Never break login/home on GPS failure — just leave cache empty
      // (or keep the previous fix).
      if (previous == null) {
        state = const AsyncData<CachedUserLocation?>(null);
      }
    }
  }

  /// Store a freshly resolved fix (e.g. from a booking screen that just
  /// did its own GPS lookup) so the next screen reuses it.
  void cache({
    required double latitude,
    required double longitude,
    required String address,
    double? accuracy,
  }) {
    state = AsyncData(
      CachedUserLocation(
        latitude: latitude,
        longitude: longitude,
        address: address,
        fetchedAt: DateTime.now(),
        accuracy: accuracy,
      ),
    );
  }

  /// Refresh silently without ever emitting a loading state.
  void refreshInBackground() {
    unawaited(prefetch());
  }

  void clear() {
    _inFlight = null;
    state = const AsyncData<CachedUserLocation?>(null);
  }
}
