// ignore_for_file: use_null_aware_elements

import 'dart:ui' as ui;
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/widgets/truck_marker_icon.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/client_map_theme.dart';
import '../../../broker/presentation/widgets/broker_flow_widgets.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../shared/data/trip_route_stop.dart';
import 'client_flow_widgets.dart';

class TrackingRouteMapView extends StatefulWidget {
  const TrackingRouteMapView({
    super.key,
    required this.shipment,
    this.liveMode = false,
  });

  final TrackingDemoShipment shipment;
  final bool liveMode;

  @override
  State<TrackingRouteMapView> createState() => _TrackingRouteMapViewState();
}

class _TrackingRouteMapViewState extends State<TrackingRouteMapView> {
  GoogleMapController? _controller;
  final GooglePlacesService _routesService = GooglePlacesService();
  List<LatLng> _routePoints = const [];
  int _routeRequestToken = 0;
  BitmapDescriptor? _truckMarkerIcon;
  final Map<String, BitmapDescriptor> _stopMarkerIcons = {};
  LatLng? _lastRoutedOrigin;
  String? _lastRoutedPhase;

  LatLng? get _pickupPoint =>
      _latLng(widget.shipment.pickupLat, widget.shipment.pickupLng);

  LatLng? get _dropPoint =>
      _latLng(widget.shipment.dropLat, widget.shipment.dropLng);

  LatLng? get _livePoint {
    return _latLng(widget.shipment.liveLat, widget.shipment.liveLng);
  }

  List<TripRouteStop> get _routeStops => widget.shipment.stops
      .where((stop) => stop.isExtraStop && stop.hasCoordinates)
      .toList(growable: false);

  List<LatLng> get _stopPoints => [
    for (final stop in _routeStops) LatLng(stop.lat!, stop.lng!),
  ];

  bool get _prePickup {
    final status = (widget.shipment.bookingStatus ?? widget.shipment.status)
        .trim()
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return const {'assigned', 'confirmed', 'en_route_pickup'}.contains(status);
  }

  List<LatLng> get _points {
    final pickup = _pickupPoint;
    final live = _livePoint;
    final drop = _dropPoint;
    return [
      if (pickup != null) pickup,
      if (live != null &&
          (pickup == null ||
              live.latitude != pickup.latitude ||
              live.longitude != pickup.longitude) &&
          (drop == null ||
              live.latitude != drop.latitude ||
              live.longitude != drop.longitude))
        live,
      if (!_prePickup) ..._stopPoints,
      if (drop != null) drop,
    ];
  }

  List<LatLng> get _cameraPoints =>
      _routePoints.isNotEmpty ? _routePoints : _points;

  Set<Marker> get _markers {
    final markers = <Marker>{};
    final pickup = _pickupPoint;
    final live = _livePoint;
    final drop = _dropPoint;
    final stops = _routeStops;

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: InfoWindow(title: widget.shipment.fromLocation),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (live != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live'),
          position: live,
          infoWindow: const InfoWindow(title: 'Truck live position'),
          icon:
              _truckMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
        ),
      );
    }

    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop'),
          position: drop,
          infoWindow: InfoWindow(title: widget.shipment.toLocation),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (!_prePickup) {
      var loadingCount = 0;
      var unloadingCount = 0;
      for (var index = 0; index < stops.length; index++) {
        final stop = stops[index];
        final label = stop.isLoading
            ? 'L${++loadingCount}'
            : 'U${++unloadingCount}';
        markers.add(
          Marker(
            markerId: MarkerId('stop-${stop.index}'),
            position: LatLng(stop.lat!, stop.lng!),
            infoWindow: InfoWindow(
              title: '$label ${stop.isLoading ? 'Loading' : 'Unloading'}',
              snippet: stop.location,
            ),
            icon:
                _stopMarkerIcons[label] ??
                BitmapDescriptor.defaultMarkerWithHue(
                  stop.isLoading
                      ? BitmapDescriptor.hueYellow
                      : BitmapDescriptor.hueOrange,
                ),
            zIndexInt: 2,
          ),
        );
      }
    }

    return markers;
  }

  Set<Polyline> get _polylines {
    if (_routePoints.length < 2) {
      return const {};
    }
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        width: 6,
        color: const Color(0xFF2FA56E),
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      ),
    };
  }

  LatLngBounds? get _bounds {
    final points = _cameraPoints;
    if (points.isEmpty) return null;
    if (points.length == 1) {
      final point = points.first;
      return LatLngBounds(southwest: point, northeast: point);
    }
    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;
    for (final point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  LatLng _defaultCenter() {
    final points = _cameraPoints;
    if (points.isNotEmpty) {
      return points.first;
    }
    return const LatLng(19.0760, 72.8777);
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    final bounds = _bounds;
    if (controller == null || bounds == null) {
      return;
    }

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } catch (_) {
      // Bounds fitting can fail briefly on initial layout; the fallback camera
      // position still renders the route correctly.
    }
  }

  @override
  void didUpdateWidget(covariant TrackingRouteMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shipment != widget.shipment ||
        oldWidget.liveMode != widget.liveMode) {
      _loadRoute();
      _loadStopMarkerIcons();
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  @override
  void initState() {
    super.initState();
    _loadRoute();
    _loadTruckMarkerIcon();
    _loadStopMarkerIcons();
  }

  Future<void> _loadTruckMarkerIcon() async {
    try {
      final icon = await loadTruckMarkerIcon();
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = icon;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      });
    }
  }

  Future<void> _loadStopMarkerIcons() async {
    final labels = <String, Color>{};
    var loadingCount = 0;
    var unloadingCount = 0;
    for (final stop in _routeStops) {
      if (stop.isLoading) {
        labels['L${++loadingCount}'] = const Color(0xFFB45309);
      } else if (stop.isUnloading) {
        labels['U${++unloadingCount}'] = const Color(0xFF2FA56E);
      }
    }
    final missingLabels = labels.entries
        .where((entry) => !_stopMarkerIcons.containsKey(entry.key))
        .toList(growable: false);
    if (missingLabels.isEmpty) {
      return;
    }

    final icons = <String, BitmapDescriptor>{};
    for (final entry in missingLabels) {
      icons[entry.key] = await _buildStopMarkerIcon(entry.key, entry.value);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _stopMarkerIcons.addAll(icons);
    });
  }

  Future<void> _loadRoute() async {
    final pickup = _pickupPoint;
    final drop = _dropPoint;
    final live = _livePoint;
    final status = (widget.shipment.bookingStatus ?? widget.shipment.status)
        .trim()
        .toLowerCase();
    final prePickup = _prePickup;
    final origin = live ?? pickup;
    final destination = prePickup ? pickup : drop;
    final waypoints = prePickup ? const <LatLng>[] : _stopPoints;
    final token = ++_routeRequestToken;
    if (origin == null || destination == null) {
      if (mounted) {
        setState(() {
          _routePoints = const [];
        });
      }
      return;
    }

    final previousOrigin = _lastRoutedOrigin;
    final routePhase =
        '$status|${waypoints.map((point) => '${point.latitude},${point.longitude}').join('|')}';
    if (_lastRoutedPhase == routePhase &&
        previousOrigin != null &&
        Geolocator.distanceBetween(
              previousOrigin.latitude,
              previousOrigin.longitude,
              origin.latitude,
              origin.longitude,
            ) <
            150 &&
        _routePoints.length >= 2) {
      return;
    }

    _lastRoutedOrigin = origin;
    _lastRoutedPhase = routePhase;

    try {
      final route = await _routesService.fetchDrivingRoute(
        originLatitude: origin.latitude,
        originLongitude: origin.longitude,
        destinationLatitude: destination.latitude,
        destinationLongitude: destination.longitude,
        waypoints: waypoints,
      );
      if (!mounted || token != _routeRequestToken) {
        return;
      }
      setState(() {
        _routePoints = route;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    } catch (error) {
      if (!mounted || token != _routeRequestToken) {
        return;
      }
      debugPrint('[TrackingMap] route fetch failed: $error');
      setState(() {
        _routePoints = const [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final points = _cameraPoints;
    debugPrint(
      '[TrackingMap] build live=${widget.liveMode} '
      'pickup=${widget.shipment.pickupLat},${widget.shipment.pickupLng} '
      'drop=${widget.shipment.dropLat},${widget.shipment.dropLng} '
      'live=${widget.shipment.liveLat},${widget.shipment.liveLng} '
      'points=${points.length} routePoints=${_routePoints.length}',
    );
    if (points.isEmpty) {
      debugPrint('[TrackingMap] empty state: no coordinates available');
      return const _EmptyMapState();
    }

    return GoogleMap(
      style: widget.liveMode ? null : ClientMapTheme.styleFor(context),
      initialCameraPosition: CameraPosition(
        target: _defaultCenter(),
        zoom: points.length == 1 ? 11 : 7,
      ),
      mapType: MapType.normal,
      markers: _markers,
      polylines: _polylines,
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: true,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onCameraMoveStarted: () {
        debugPrint('[TrackingMap] camera move started');
      },
      onCameraIdle: () {
        debugPrint('[TrackingMap] camera idle');
      },
      onMapCreated: (controller) {
        _controller = controller;
        debugPrint('[TrackingMap] map created, fitting camera');
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
      },
    );
  }
}

LatLng? _latLng(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) {
    return null;
  }
  return LatLng(latitude, longitude);
}

Future<BitmapDescriptor> _buildStopMarkerIcon(String label, Color color) async {
  const size = 96.0;
  const center = Offset(size / 2, size / 2);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  final shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.22)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
  canvas.drawCircle(center.translate(0, 5), 30, shadowPaint);

  final fillPaint = Paint()..color = color;
  canvas.drawCircle(center, 30, fillPaint);

  final borderPaint = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;
  canvas.drawCircle(center, 30, borderPaint);

  final tailPath = Path()
    ..moveTo(center.dx - 10, center.dy + 24)
    ..lineTo(center.dx, center.dy + 43)
    ..lineTo(center.dx + 10, center.dy + 24)
    ..close();
  canvas.drawPath(tailPath, fillPaint);
  canvas.drawPath(tailPath, borderPaint);

  final textPainter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 25,
        fontWeight: FontWeight.w900,
        letterSpacing: 0,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  textPainter.paint(
    canvas,
    Offset(
      center.dx - textPainter.width / 2,
      center.dy - textPainter.height / 2,
    ),
  );

  final image = await recorder.endRecording().toImage(
    size.toInt(),
    size.toInt(),
  );
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final bytes = byteData?.buffer.asUint8List() ?? Uint8List(0);
  return BitmapDescriptor.bytes(bytes, width: 48, height: 48);
}

class _EmptyMapState extends StatelessWidget {
  const _EmptyMapState();

  @override
  Widget build(BuildContext context) {
    debugPrint('[TrackingMap] empty placeholder shown');
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F6FB), Color(0xFFE8EEF6)],
        ),
      ),
      child: Center(
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: context.colors.brandFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.map_outlined,
                  color: Color(0xFF2FA56E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Map loading',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Location coordinates will appear once the booking has pickup and drop details.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TrackingRouteOverviewCard extends StatelessWidget {
  const TrackingRouteOverviewCard({
    super.key,
    required this.shipment,
    required this.title,
    required this.subtitle,
    this.liveMode = false,
  });

  final TrackingDemoShipment shipment;
  final String title;
  final String subtitle;
  final bool liveMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: TrackingRouteMapView(shipment: shipment, liveMode: liveMode),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.infoEmphasis,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(
                    AppIcons.chevron_right_rounded,
                    color: context.colors.textTertiary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveLocationMapView extends StatefulWidget {
  const LiveLocationMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.label = 'Live location',
    this.markerHue = BitmapDescriptor.hueAzure,
    this.emptyTitle = 'Location pending',
    this.emptySubtitle =
        'Live GPS coordinates will appear once the driver sends an update.',
  });

  final double? latitude;
  final double? longitude;
  final String label;
  final double markerHue;
  final String emptyTitle;
  final String emptySubtitle;

  @override
  State<LiveLocationMapView> createState() => _LiveLocationMapViewState();
}

class _LiveLocationMapViewState extends State<LiveLocationMapView> {
  GoogleMapController? _controller;
  BitmapDescriptor? _truckMarkerIcon;

  LatLng? get _location => _latLng(widget.latitude, widget.longitude);

  @override
  void initState() {
    super.initState();
    _loadTruckMarkerIcon();
  }

  Future<void> _loadTruckMarkerIcon() async {
    try {
      final icon = await loadTruckMarkerIcon();
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = icon;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      });
    }
  }

  Set<Marker> get _markers {
    final location = _location;
    if (location == null) {
      return const {};
    }

    return {
      Marker(
        markerId: const MarkerId('live'),
        position: location,
        infoWindow: InfoWindow(title: widget.label),
        icon:
            _truckMarkerIcon ??
            BitmapDescriptor.defaultMarkerWithHue(widget.markerHue),
        anchor: const Offset(0.5, 0.5),
        zIndexInt: 3,
      ),
    };
  }

  LatLng _defaultCenter() {
    return _location ?? const LatLng(19.0760, 72.8777);
  }

  Future<void> _fitCamera() async {
    final controller = _controller;
    final location = _location;
    if (controller == null || location == null) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(location, 13.5),
      );
    } catch (_) {
      // The initial camera update can fail while the map view is still
      // laying out. The default camera position already points to the driver.
    }
  }

  @override
  void didUpdateWidget(covariant LiveLocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude ||
        oldWidget.label != widget.label) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = _location;
    if (location == null) {
      return _EmptyLiveLocationState(
        title: widget.emptyTitle,
        subtitle: widget.emptySubtitle,
      );
    }

    return GoogleMap(
      style: ClientMapTheme.styleFor(context),
      initialCameraPosition: CameraPosition(
        target: _defaultCenter(),
        zoom: 13.5,
      ),
      mapType: MapType.normal,
      markers: _markers,
      myLocationButtonEnabled: false,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      trafficEnabled: true,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      onMapCreated: (controller) {
        _controller = controller;
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
      },
    );
  }
}

class DriverLocationOverviewCard extends StatelessWidget {
  const DriverLocationOverviewCard({
    super.key,
    required this.driver,
    required this.title,
    required this.subtitle,
    this.height = 240,
  });

  final BrokerDriver driver;
  final String title;
  final String subtitle;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final map = ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        children: [
          Positioned.fill(
            child: LiveLocationMapView(
              latitude: driver.currentLatitude,
              longitude: driver.currentLongitude,
              label: driver.name,
              emptyTitle: 'Live location pending',
              emptySubtitle:
                  'Driver coordinates will appear once the backend reports GPS updates.',
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                title,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.infoEmphasis,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: context.colors.textSecondary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        driverStatusLabel(driver.status),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: driverStatusColor(driver.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    driver.hasLiveCoordinates
                        ? '${driver.currentLatitude!.toStringAsFixed(5)}, ${driver.currentLongitude!.toStringAsFixed(5)}'
                        : 'Live GPS pending from backend',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (height == null) {
      return Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: context.colors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: map,
      );
    }

    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: map,
    );
  }
}

class _EmptyLiveLocationState extends StatelessWidget {
  const _EmptyLiveLocationState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF3F6FB), Color(0xFFE8EEF6)],
        ),
      ),
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.colors.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAF2FB),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.gps_fixed_rounded,
                  color: Color(0xFF1F88C9),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
