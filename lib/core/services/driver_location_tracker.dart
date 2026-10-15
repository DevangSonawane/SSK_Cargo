import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class DriverLocationTracker {
  DriverLocationTracker(this._ref);

  final Ref _ref;

  /// Localizations for the user-facing messages this tracker returns. The
  /// tracker has no BuildContext, so it looks them up for the current app
  /// locale directly.
  AppLocalizations get _l10n =>
      lookupAppLocalizations(_ref.read(localeProvider));

  StreamSubscription<Position>? _subscription;
  String? _activeTripId;
  Future<String?>? _pendingStart;
  int _generation = 0;
  Position? _lastPublishedPosition;
  DateTime? _lastPublishedAt;

  bool get isRunning => _subscription != null;
  String? get activeTripId => _activeTripId;

  Future<String?> startTracking({String? tripId}) {
    _activeTripId = tripId;
    if (_subscription != null) return Future.value(null);
    final pending = _pendingStart;
    if (pending != null) return pending;

    final generation = _generation;
    late final Future<String?> start;
    start = _startTracking(generation).whenComplete(() {
      if (identical(_pendingStart, start)) _pendingStart = null;
    });
    _pendingStart = start;
    return start;
  }

  bool _canPublish(int generation) {
    if (generation != _generation) return false;
    final session = _ref.read(authSessionProvider).valueOrNull;
    return session != null &&
        session.user.role.trim().toLowerCase() == 'driver';
  }

  Future<String?> _startTracking(int generation) async {
    try {
      if (!_canPublish(generation)) {
        return _l10n.driverTrackingSignInAgainBeforeEnablingLocation;
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return _l10n.driverTrackingEnableLocationServices;
      }
      if (!_canPublish(generation)) return null;

      var permission = await Geolocator.checkPermission();
      if (!_canPublish(generation)) return null;
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!_canPublish(generation)) return null;
      if (permission == LocationPermission.deniedForever) {
        return _l10n.driverTrackingLocationPermissionDeniedForever;
      }
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        return _l10n.driverTrackingLocationPermissionRequired;
      }

      // Permission dialogs and GPS checks can outlive the visible activity.
      final lifecycle = WidgetsBinding.instance.lifecycleState;
      if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
        return null;
      }

      final settings = _trackingSettings();
      // Start the native background stream before waiting for a GPS fix.
      // A slow fix must not delay Android's foreground service startup.
      _subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
            (position) {
              if (_canPublish(generation)) {
                unawaited(_sendPosition(position, generation: generation));
              }
            },
            onError: (Object error, StackTrace stackTrace) {
              developer.log(
                'Driver location stream error',
                name: 'SSK.Location',
                error: error,
                stackTrace: stackTrace,
              );
              if (generation == _generation) {
                unawaited(stopTracking());
              }
            },
            onDone: () {
              if (generation == _generation) _subscription = null;
            },
            cancelOnError: true,
          );
      unawaited(_publishCurrentLocation(settings, generation: generation));
      return null;
    } catch (error, stackTrace) {
      developer.log(
        'Unable to start driver location stream',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
      if (generation != _generation) return null;
      return _l10n.driverTrackingUnableToStartLiveTracking;
    }
  }

  Future<void> _publishCurrentLocation(
    LocationSettings settings, {
    required int generation,
  }) async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: settings.accuracy,
          timeLimit: const Duration(seconds: 20),
        ),
      );
      if (_canPublish(generation)) {
        await _sendPosition(
          currentPosition,
          generation: generation,
          force: true,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Initial driver location lookup failed',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> stopTracking() async {
    _generation++;
    _pendingStart = null;
    final subscription = _subscription;
    _subscription = null;
    _activeTripId = null;
    _lastPublishedPosition = null;
    _lastPublishedAt = null;
    await subscription?.cancel();
  }

  Future<String?> restartTracking() async {
    final tripId = _activeTripId;
    await stopTracking();
    return startTracking(tripId: tripId);
  }

  Future<String?> refreshCurrentLocation() async {
    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return _l10n.driverTrackingSignInAgainBeforeRefreshingLocation;
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return _l10n.driverTrackingEnableLocationServices;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return _l10n.driverTrackingLocationPermissionRequired;
      }
    } else if (permission == LocationPermission.deniedForever) {
      return _l10n.driverTrackingLocationPermissionDeniedForever;
    }

    final settings = _trackingSettings();
    await _publishCurrentLocation(settings, generation: _generation);
    return null;
  }

  void setActiveTripId(String? tripId) {
    _activeTripId = tripId;
  }

  LocationSettings _trackingSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
          intervalDuration: const Duration(seconds: 3),
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'SSK driver tracking active',
            notificationText: 'Sharing live location with broker and client',
            notificationChannelName: 'Driver location tracking',
            setOngoing: true,
            enableWakeLock: true,
          ),
        );
      case TargetPlatform.iOS:
        return AppleSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
          allowBackgroundLocationUpdates: true,
          pauseLocationUpdatesAutomatically: false,
          showBackgroundLocationIndicator: true,
          activityType: ActivityType.automotiveNavigation,
        );
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
      case TargetPlatform.fuchsia:
        return const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        );
    }
  }

  Future<void> _sendPosition(
    Position position, {
    required int generation,
    bool force = false,
  }) async {
    if (!_canPublish(generation)) return;
    if (!force && !_shouldPublishPosition(position)) {
      return;
    }

    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    try {
      developer.log(
        'Publishing driver location lat=${position.latitude} lng=${position.longitude} tripId=$_activeTripId force=$force',
        name: 'SSK.Location',
      );
      await _ref
          .read(apiClientProvider)
          .updateDriverLocation(
            accessToken: session.tokens.accessToken,
            lat: position.latitude,
            lng: position.longitude,
          );
      if (!_canPublish(generation)) return;
      _lastPublishedPosition = position;
      _lastPublishedAt = DateTime.now();
    } catch (error, stackTrace) {
      developer.log(
        'Failed to publish driver location',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (!_canPublish(generation)) return;
    final tripId = _activeTripId;
    if (tripId == null || tripId.isEmpty) {
      developer.log(
        'Skipping trip location publish because no active trip id is set.',
        name: 'SSK.Location',
      );
      return;
    }

    try {
      developer.log(
        'Publishing trip location lat=${position.latitude} lng=${position.longitude} tripId=$tripId force=$force',
        name: 'SSK.Location',
      );
      await _ref
          .read(apiClientProvider)
          .updateTripLocation(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            lat: position.latitude,
            lng: position.longitude,
          );
    } catch (error, stackTrace) {
      developer.log(
        'Failed to publish trip location',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  bool _shouldPublishPosition(Position position) {
    final lastPosition = _lastPublishedPosition;
    final lastPublishedAt = _lastPublishedAt;
    final now = DateTime.now();

    if (lastPosition == null || lastPublishedAt == null) {
      return true;
    }

    final timeElapsed = now.difference(lastPublishedAt);
    final movedMeters = _haversineMeters(
      lastPosition.latitude,
      lastPosition.longitude,
      position.latitude,
      position.longitude,
    );

    if (timeElapsed >= const Duration(seconds: 8) || movedMeters >= 50) {
      return true;
    }

    return false;
  }

  double _haversineMeters(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  double _toRadians(double value) => value * (math.pi / 180);
}
