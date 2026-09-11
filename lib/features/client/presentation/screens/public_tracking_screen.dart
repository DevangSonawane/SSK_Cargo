import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../widgets/client_flow_widgets.dart';
import '../widgets/tracking_route_map_view.dart';

class PublicTrackingScreen extends ConsumerStatefulWidget {
  const PublicTrackingScreen({super.key, required this.token});

  final String token;

  @override
  ConsumerState<PublicTrackingScreen> createState() =>
      _PublicTrackingScreenState();
}

class _PublicTrackingScreenState extends ConsumerState<PublicTrackingScreen> {
  static const Duration _refreshInterval = Duration(seconds: 7);

  Timer? _timer;
  TrackingDemoShipment? _shipment;
  Map<String, dynamic>? _incident;
  String? _errorMessage;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadTracking());
    _timer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) unawaited(_loadTracking(silent: true));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadTracking({bool silent = false}) async {
    if (widget.token.trim().isEmpty) {
      setState(() {
        _loading = false;
        _errorMessage = 'Tracking link is invalid.';
      });
      return;
    }

    if (!silent) {
      setState(() {
        _loading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getPublicTracking(token: widget.token);
      final data = _payloadMap(response['data']).isNotEmpty
          ? _payloadMap(response['data'])
          : response;
      if (!mounted) return;
      setState(() {
        _shipment = _shipmentFromPublicTracking(data);
        _incident = _payloadMap(data['incident']).isEmpty
            ? null
            : _payloadMap(data['incident']);
        _loading = false;
        _errorMessage = null;
      });
    } on ApiException catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _shipment;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: _loading && shipment == null
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null && shipment == null
            ? _PublicTrackingMessage(
                icon: Icons.link_off_rounded,
                title: 'Tracking unavailable',
                message: _errorMessage!,
              )
            : RefreshIndicator(
                onRefresh: _loadTracking,
                color: const Color(0xFF2FA56E),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _PublicHeader(shipment: shipment!),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 300,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: TrackingRouteMapView(
                          shipment: shipment,
                          liveMode: true,
                        ),
                      ),
                    ),
                    if (_incident != null) ...[
                      const SizedBox(height: 14),
                      _IncidentBanner(incident: _incident!),
                    ],
                    const SizedBox(height: 14),
                    _RouteCard(shipment: shipment),
                    const SizedBox(height: 14),
                    _DriverCard(shipment: shipment),
                  ],
                ),
              ),
      ),
    );
  }
}

class _PublicHeader extends StatelessWidget {
  const _PublicHeader({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shipment.trackingId,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            shipment.status,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF2FA56E),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(label: 'Pickup', value: shipment.fromLocation),
          const SizedBox(height: 12),
          _InfoLine(label: 'Drop-off', value: shipment.toLocation),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    final driver = shipment.assignedDriverName?.trim();
    final truck = shipment.assignedTruckName?.trim();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoLine(
            label: 'Driver',
            value: driver?.isNotEmpty == true ? driver! : 'Assigned driver',
          ),
          if (truck?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _InfoLine(label: 'Truck', value: truck!),
          ],
        ],
      ),
    );
  }
}

class _IncidentBanner extends StatelessWidget {
  const _IncidentBanner({required this.incident});

  final Map<String, dynamic> incident;

  @override
  Widget build(BuildContext context) {
    final status = _readPublicString(incident, const ['status']);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4DB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF3DC8C)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB54708)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              status.isEmpty
                  ? 'There is an active delivery update.'
                  : 'Delivery update: ${_titleCase(status)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF8A5200),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: const Color(0xFF98A2B3),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.isEmpty ? '-' : value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _PublicTrackingMessage extends StatelessWidget {
  const _PublicTrackingMessage({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: const Color(0xFF98A2B3)),
            const SizedBox(height: 14),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }
}

TrackingDemoShipment _shipmentFromPublicTracking(Map<String, dynamic> data) {
  final status = _readPublicString(data, const ['status', 'booking_status']);
  final pickup = _readPublicString(data, const [
    'pickup',
    'pickupLocation',
    'pickup_location',
    'pickup_address',
  ]);
  final drop = _readPublicString(data, const [
    'drop',
    'dropoffLocation',
    'dropoff_location',
    'drop_location',
    'drop_address',
  ]);
  final bookingNumber = _readPublicString(data, const [
    'bookingNumber',
    'booking_number',
    'bookingRef',
    'booking_ref',
  ]);
  return TrackingDemoShipment(
    packageName: 'Shipment',
    trackingId: bookingNumber.isEmpty ? 'Live tracking' : bookingNumber,
    fromLocation: pickup,
    toLocation: drop,
    status: _titleCase(status.isEmpty ? 'pending' : status),
    customerName: '',
    weight: '',
    pickupLat: _readPublicDouble(data, const ['pickupLat', 'pickup_lat']),
    pickupLng: _readPublicDouble(data, const ['pickupLng', 'pickup_lng']),
    dropLat: _readPublicDouble(data, const ['dropLat', 'drop_lat']),
    dropLng: _readPublicDouble(data, const ['dropLng', 'drop_lng']),
    liveLat: _readPublicDouble(data, const ['driverLat', 'driver_lat']),
    liveLng: _readPublicDouble(data, const ['driverLng', 'driver_lng']),
    bookingStatus: status,
    assignedDriverName: _readPublicString(data, const [
      'driverName',
      'driver_name',
    ]),
    assignedTruckName: _readPublicString(data, const [
      'truckRegistration',
      'truck_registration',
      'truckReg',
      'truck_reg',
    ]),
    timeline: _publicTimeline(status, pickup, drop),
  );
}

List<TrackingTimelineStep> _publicTimeline(
  String status,
  String pickup,
  String drop,
) {
  final normalized = status.trim().toLowerCase();
  final inTransit = const {
    'assigned',
    'en_route_pickup',
    'picked_up',
    'in_transit',
    'delivered',
    'completed',
  }.contains(normalized);
  final delivered = normalized == 'delivered' || normalized == 'completed';
  return [
    TrackingTimelineStep(
      title: 'Booking created',
      subtitle: pickup.isEmpty ? 'Pickup location' : pickup,
      completed: true,
    ),
    TrackingTimelineStep(
      title: 'Assigned',
      subtitle: 'Vehicle assigned',
      completed: inTransit,
    ),
    TrackingTimelineStep(
      title: 'In transit',
      subtitle: drop.isEmpty ? 'Drop-off location' : drop,
      completed: inTransit,
    ),
    TrackingTimelineStep(
      title: 'Delivered',
      subtitle: delivered ? 'Completed successfully' : 'Pending',
      completed: delivered,
    ),
  ];
}

Map<String, dynamic> _payloadMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String _readPublicString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

double? _readPublicDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}
