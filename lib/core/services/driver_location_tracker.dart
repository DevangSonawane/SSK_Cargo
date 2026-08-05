import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_client.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';

class DriverLocationTracker {
  DriverLocationTracker(this._ref);

  final Ref _ref;

  StreamSubscription<Position>? _subscription;
  io.Socket? _socket;
  String? _activeTripId;
  Position? _lastPublishedPosition;
  DateTime? _lastPublishedAt;

  bool get isRunning => _subscription != null;
  String? get activeTripId => _activeTripId;

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

    _ensureSocket(session.tokens.accessToken);
    final settings = _trackingSettings();

    try {
      final currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      await _sendPosition(currentPosition, force: true);
    } catch (error, stackTrace) {
      developer.log(
        'Initial driver location lookup failed',
        name: 'SSK.Location',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      _subscription = Geolocator.getPositionStream(locationSettings: settings)
          .listen(
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
    _lastPublishedPosition = null;
    _lastPublishedAt = null;
    await _subscription?.cancel();
    _subscription = null;
    _disconnectSocket();
  }

  Future<String?> restartTracking() async {
    final tripId = _activeTripId;
    await stopTracking();
    return startTracking(tripId: tripId);
  }

  void setActiveTripId(String? tripId) {
    _activeTripId = tripId;
  }

  void _ensureSocket(String accessToken) {
    if (_socket != null) {
      return;
    }

    final baseUrl = _ref.read(dioProvider).options.baseUrl;
    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      developer.log('Driver websocket connected', name: 'SSK.Location');
    });
    socket.onConnectError((error) {
      developer.log(
        'Driver websocket connect error',
        name: 'SSK.Location',
        error: error,
      );
    });
    socket.onError((error) {
      developer.log(
        'Driver websocket error',
        name: 'SSK.Location',
        error: error,
      );
    });

    _socket = socket;
    socket.connect();
  }

  void _disconnectSocket() {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    _socket = null;
    socket.disconnect();
    socket.dispose();
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

  Future<void> _sendPosition(Position position, {bool force = false}) async {
    if (!force && !_shouldPublishPosition(position)) {
      return;
    }

    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    try {
      _emitLocation(position);
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
  }

  void _emitLocation(Position position) {
    final socket = _socket;
    if (socket == null) {
      return;
    }

    final payload = <String, dynamic>{
      'lat': position.latitude,
      'lng': position.longitude,
      'lastLocationAt': DateTime.now().toIso8601String(),
      if ((_activeTripId?.isNotEmpty ?? false)) 'tripId': _activeTripId,
    };

    socket.emit('driver-location', payload);
    socket.emit('truck-location', payload);
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
