import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps turn-by-turn navigation for the driver trip and manages
/// the floating "tap to return" bubble shown over Google Maps (Android only).
///
/// Background GPS itself keeps running through the existing
/// [DriverLocationTracker] foreground service — the bubble is only a shortcut
/// that brings the driver app back to the foreground without using the app
/// switcher, like Rapido/Uber/Ola do.
class DriverExternalNavigationService {
  DriverExternalNavigationService._();

  static const MethodChannel _mapsChannel = MethodChannel(
    'ssk/google_maps_launcher',
  );
  static const MethodChannel _bubbleChannel = MethodChannel(
    'ssk/driver_bubble',
  );

  static String _coords(double? lat, double? lng) {
    return '$lat,$lng';
  }

  static bool _hasCoords(double? lat, double? lng) {
    return lat != null && lng != null && lat != 0 && lng != 0;
  }

  /// Builds a universal Google Maps directions URL.
  ///
  /// When [navigate] is true, Maps starts turn-by-turn navigation
  /// (`dir_action=navigate`). Origin is omitted when unknown so Maps falls
  /// back to the device location.
  static Uri buildDirectionsUri({
    String? origin,
    required String destination,
    String? waypoints,
    bool navigate = true,
  }) {
    final params = <String, String>{
      'api': '1',
      'destination': destination,
      'travelmode': 'driving',
    };
    if (origin != null && origin.trim().isNotEmpty) {
      params['origin'] = origin.trim();
    }
    if (waypoints != null && waypoints.trim().isNotEmpty) {
      params['waypoints'] = waypoints.trim();
    }
    if (navigate) {
      params['dir_action'] = 'navigate';
    }
    return Uri.https('www.google.com', '/maps/dir/', params);
  }

  /// Opens navigation to the current driver target (pickup or drop).
  ///
  /// Returns `null` on success, otherwise a user-facing error message.
  static Future<String?> openDriverNavigation({
    double? pickupLat,
    double? pickupLng,
    String pickupAddress = '',
    double? dropLat,
    double? dropLng,
    String dropAddress = '',
    double? liveLat,
    double? liveLng,
    required bool headingToPickup,
  }) async {
    final hasPickupCoords = _hasCoords(pickupLat, pickupLng);
    final hasDropCoords = _hasCoords(dropLat, dropLng);

    final String destination;
    if (headingToPickup) {
      destination = hasPickupCoords
          ? _coords(pickupLat, pickupLng)
          : pickupAddress.trim();
    } else {
      destination = hasDropCoords
          ? _coords(dropLat, dropLng)
          : dropAddress.trim();
    }
    if (destination.isEmpty) {
      return 'Destination is not available for this trip yet.';
    }

    // Prefer the live GPS fix as origin so Maps routes from where the truck
    // actually is; otherwise let Maps use the device location.
    final String? origin = _hasCoords(liveLat, liveLng)
        ? _coords(liveLat, liveLng)
        : null;

    final uri = buildDirectionsUri(origin: origin, destination: destination);

    // Try the native launcher first (handles NEW_TASK + Maps package
    // preference), then fall back to url_launcher.
    try {
      final opened = await _mapsChannel.invokeMethod<bool>(
        'openNavigationUrl',
        {'url': uri.toString()},
      );
      if (opened == true) {
        return null;
      }
    } catch (error) {
      debugPrint('[DriverNav] native launch failed, falling back: $error');
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return 'Could not open Google Maps on this device.';
      }
      return null;
    } catch (error) {
      debugPrint('[DriverNav] url_launcher failed: $error');
      return 'Could not open Google Maps on this device.';
    }
  }

  /// Opens a pickup → drop route preview (no turn-by-turn).
  static Future<String?> openRoutePreview({
    double? pickupLat,
    double? pickupLng,
    String pickupAddress = '',
    double? dropLat,
    double? dropLng,
    String dropAddress = '',
  }) async {
    final origin = _hasCoords(pickupLat, pickupLng)
        ? _coords(pickupLat, pickupLng)
        : pickupAddress.trim();
    final destination = _hasCoords(dropLat, dropLng)
        ? _coords(dropLat, dropLng)
        : dropAddress.trim();
    if (origin.isEmpty || destination.isEmpty) {
      return 'Pickup or drop details are not available yet.';
    }
    final uri = buildDirectionsUri(
      origin: origin,
      destination: destination,
      navigate: false,
    );
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        return 'Could not open Google Maps on this device.';
      }
      return null;
    } catch (_) {
      return 'Could not open Google Maps on this device.';
    }
  }

  // ---------------------------------------------------------------------------
  // Floating bubble (Android "display over other apps" overlay).
  // ---------------------------------------------------------------------------

  static bool get supportsBubble => Platform.isAndroid;

  static Future<bool> hasBubblePermission() async {
    if (!supportsBubble) return false;
    try {
      final granted = await _bubbleChannel.invokeMethod<bool>(
        'hasOverlayPermission',
      );
      return granted == true;
    } catch (_) {
      return false;
    }
  }

  /// Opens Android's "Display over other apps" settings page.
  /// Returns true if the settings screen could be opened.
  static Future<bool> requestBubblePermission() async {
    if (!supportsBubble) return false;
    try {
      final opened = await _bubbleChannel.invokeMethod<bool>(
        'requestOverlayPermission',
      );
      return opened == true;
    } catch (error) {
      debugPrint('[DriverNav] overlay permission request failed: $error');
      return false;
    }
  }

  /// Shows the draggable circular bubble over Google Maps.
  /// Returns true if the overlay is visible.
  static Future<bool> showBubble({String label = 'SSK'}) async {
    if (!supportsBubble) return false;
    try {
      final shown = await _bubbleChannel.invokeMethod<bool>(
        'showBubble',
        {'label': label},
      );
      return shown == true;
    } catch (error) {
      debugPrint('[DriverNav] showBubble failed: $error');
      return false;
    }
  }

  static Future<void> hideBubble() async {
    if (!supportsBubble) return;
    try {
      await _bubbleChannel.invokeMethod<bool>('hideBubble');
    } catch (_) {
      // Best effort only.
    }
  }
}
