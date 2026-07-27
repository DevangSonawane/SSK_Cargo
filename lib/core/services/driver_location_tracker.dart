import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class DriverLocationTracker {
  DriverLocationTracker(this._ref);

  final Ref _ref;

  StreamSubscription<Position>? _subscription;
  String? _activeTripId;

  bool get isRunning => _subscription != null;

  Future<String?> startTracking({String? tripId}) async {
    _activeTripId = tripId;

    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return 'Please sign in again before enabling location sharing.';
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return 'Enable location services on the device to share live tracking.';
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      final requested = await Geolocator.requestPermission();
      if (requested == LocationPermission.denied ||
          requested == LocationPermission.deniedForever) {
        return 'Location permission is required for live driver tracking.';
      }
    } else if (permission == LocationPermission.deniedForever) {
      return 'Location permission is permanently denied. Open app settings to enable it.';
    }

    if (_subscription != null) {
      return null;
    }

    final settings = _trackingSettings();

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      await _sendPosition(currentPosition);
    } catch (error, stackTrace) {
      developer.log(
        'Initial driver location lookup failed',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      _subscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        (position) {
          unawaited(_sendPosition(position));
        },
        onError: (error, stackTrace) {
          developer.log(
            'Driver location stream error',
            name: 'SSK.Location',
            error: error,
            stackTrace: stackTrace is StackTrace ? stackTrace : null,
          );
        },
      );
    } catch (error, stackTrace) {
      developer.log(
        'Unable to start driver location stream',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
      return 'Unable to start live tracking on this device.';
    }

    return null;
  }

  Future<void> stopTracking() async {
    _activeTripId = null;
    await _subscription?.cancel();
    _subscription = null;
  }

  LocationSettings _trackingSettings() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
          intervalDuration: const Duration(seconds: 5),
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
          distanceFilter: 10,
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
          distanceFilter: 10,
        );
    }
  }

  Future<void> _sendPosition(Position position) async {
    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final api = _ref.read(apiClientProvider);

    try {
      await api.updateDriverLocation(
        accessToken: session.tokens.accessToken,
        lat: position.latitude,
        lng: position.longitude,
      );

      final tripId = _activeTripId;
      if (tripId != null && tripId.isNotEmpty) {
        await api.updateTripLocation(
          accessToken: session.tokens.accessToken,
          tripId: tripId,
          lat: position.latitude,
          lng: position.longitude,
        );
      }
    } catch (error, stackTrace) {
      developer.log(
        'Failed to publish driver location',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
