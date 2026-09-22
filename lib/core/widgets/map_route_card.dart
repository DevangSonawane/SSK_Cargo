import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ssk/core/services/google_places_service.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';

/// A compact Google Maps card that geocodes the pickup and drop-off addresses,
/// draws the driving route between them and optionally overlays a
/// pickup/drop-off summary on the bottom edge.
class MapRouteCard extends StatefulWidget {
  const MapRouteCard({
    super.key,
    required this.pickup,
    required this.drop,
    this.isExpress = false,
    this.height = 220,
    this.showRouteLabels = true,
    this.showMarkers = true,
  });

  final String pickup;
  final String drop;
  final bool isExpress;
  final double height;
  final bool showRouteLabels;
  final bool showMarkers;

  @override
  State<MapRouteCard> createState() => _MapRouteCardState();
}

class _MapRouteCardState extends State<MapRouteCard> {
  final GooglePlacesService _geoService = GooglePlacesService();
  GoogleMapController? _mapController;
  LatLng? _pickupLatLng;
  LatLng? _dropLatLng;
  List<LatLng> _routePoints = const [];
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _geocodeAndInitMap();
  }

  @override
  void didUpdateWidget(MapRouteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickup != widget.pickup || oldWidget.drop != widget.drop) {
      _geocodeAndInitMap();
    }
  }

  Future<void> _geocodeAndInitMap() async {
    setState(() {
      _loading = true;
      _loadError = null;
      _markers = {};
      _polylines = {};
    });

    LatLng? pickup;
    LatLng? drop;
    try {
      final results = await Future.wait([
        _geoService.geocodeAddress(address: widget.pickup),
        _geoService.geocodeAddress(address: widget.drop),
      ]);
      final pickupSelection = results[0];
      final dropSelection = results[1];
      pickup = _latLngFrom(pickupSelection);
      drop = _latLngFrom(dropSelection);
    } catch (_) {
      pickup = null;
      drop = null;
    }

    if (!mounted) return;

    if (pickup == null || drop == null) {
      setState(() {
        _loading = false;
        _loadError = 'Could not locate the pickup or drop-off address.';
      });
      return;
    }

    _pickupLatLng = pickup;
    _dropLatLng = drop;

    var route = const <LatLng>[];
    try {
      route = await _geoService.fetchDrivingRoute(
        originLatitude: pickup.latitude,
        originLongitude: pickup.longitude,
        destinationLatitude: drop.latitude,
        destinationLongitude: drop.longitude,
      );
    } catch (_) {
      route = const [];
    }
    if (!mounted) return;

    _routePoints = route;
    _updateMarkersAndRoute();
  }

  void _updateMarkersAndRoute() {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    if (pickup == null || drop == null) return;

    _markers = widget.showMarkers
        ? {
            Marker(
              markerId: const MarkerId('pickup'),
              position: pickup,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
              infoWindow: InfoWindow(title: 'Pickup', snippet: widget.pickup),
            ),
            Marker(
              markerId: const MarkerId('drop'),
              position: drop,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed,
              ),
              infoWindow: InfoWindow(title: 'Drop-off', snippet: widget.drop),
            ),
          }
        : {};

    final routePoints = _routePoints.length >= 2
        ? _routePoints
        : <LatLng>[pickup, drop];

    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: routePoints,
        color: AppColors.brand,
        width: 4,
        patterns: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };

    if (mounted) {
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    if (controller == null || pickup == null || drop == null) return;

    final cameraPoints = _routePoints.length >= 2
        ? _routePoints
        : [pickup, drop];

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;
    for (final point in cameraPoints) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }
    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat!, minLng!),
            northeast: LatLng(maxLat!, maxLng!),
          ),
          60,
        ),
      );
    } catch (_) {
      // The initial camera update can fail while the map is still laying out;
      // the default camera position still shows the markers.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _pickupLatLng ?? const LatLng(20.5937, 78.9629),
                zoom: _pickupLatLng == null ? 4 : 10,
              ),
              onMapCreated: (controller) {
                _mapController = controller;
                _fitCamera();
              },
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              mapType: MapType.normal,
            ),
            if (_loading)
              Container(
                color: Colors.white,
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.brand),
                  ),
                ),
              )
            else if (_loadError != null)
              Container(
                color: Colors.white,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.location_off_outlined,
                          color: AppColors.textTertiary,
                          size: 34,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _loadError!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.isExpress)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brand,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.flash_on_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Express',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (widget.showRouteLabels)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.brandFill,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.place_rounded,
                          color: AppColors.brand,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Pickup',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.pickup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.dangerIcon.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.near_me_rounded,
                          color: AppColors.dangerIcon,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Drop-off',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.drop,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

LatLng? _latLngFrom(GooglePlaceSelection selection) {
  final lat = selection.latitude;
  final lng = selection.longitude;
  if (lat == null || lng == null) return null;
  return LatLng(lat, lng);
}
