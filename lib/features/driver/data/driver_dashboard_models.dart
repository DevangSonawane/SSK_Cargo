import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/presentation/controllers/auth_controller.dart';
import '../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../../core/network/api_client.dart';

class DriverDashboardData {
  const DriverDashboardData({
    required this.activeTrip,
    required this.upcomingTrip,
    required this.history,
    required this.tripFeed,
    required this.assignedTruck,
  });

  final TrackingDemoShipment? activeTrip;
  final TrackingDemoShipment? upcomingTrip;
  final List<BrokerSettlement> history;
  final List<DriverTripSummary> tripFeed;
  final Map<String, dynamic>? assignedTruck;
}

final driverDashboardProvider = FutureProvider.autoDispose<DriverDashboardData>(
  (ref) async {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      throw StateError('No active session');
    }

    final api = ref.read(apiClientProvider);
    final results = await Future.wait([
      api.getActiveTrip(accessToken: session.tokens.accessToken),
      api.getUpcomingTrip(accessToken: session.tokens.accessToken),
      api.getBrokerAnalytics(accessToken: session.tokens.accessToken),
      api.getTrips(
        accessToken: session.tokens.accessToken,
        status: 'delivered,completed,in_transit,cancelled',
        limit: 100,
      ),
      api.getDriverTruck(accessToken: session.tokens.accessToken),
    ]);

    final activeTrip = _shipmentFromTripResponse(results[0]);
    final upcomingTrip = _shipmentFromTripResponse(results[1]);
    final analytics = _analyticsFromResponse(results[2]);
    final tripFeed = _tripFeedFromResponse(results[3]);
    final truck = _truckFromResponse(results[4]);

    return DriverDashboardData(
      activeTrip: activeTrip,
      upcomingTrip: upcomingTrip,
      history: analytics,
      tripFeed: tripFeed,
      assignedTruck: truck,
    );
  },
);

TrackingDemoShipment? _shipmentFromTripResponse(Map<String, dynamic> response) {
  final data = response['data'];
  final trip = data is Map<String, dynamic>
      ? (data['trip'] is Map<String, dynamic>
            ? data['trip'] as Map<String, dynamic>
            : data)
      : response['trip'];
  if (trip is Map<String, dynamic>) {
    if (_looksLikePlaceholderTrip(trip)) {
      return null;
    }
    return _shipmentFromTrip(trip);
  }
  return null;
}

// Kept as a compatibility helper for hot-reloaded isolates that may still
// reference the old dashboard filtering path.
// ignore: unused_element
bool _isLiveTrip(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return false;

  const liveStatuses = {
    'accepted',
    'confirmed',
    'live',
    'ongoing',
    'ontrip',
    'on_trip',
    'en_route_pickup',
    'in_transit',
    'in transit',
    'picked_up',
    'picked up',
    'en_route',
    'en route',
    'started',
    'delivered',
  };

  const inactiveStatuses = {
    'requested',
    'pending',
    'completed',
    'delivered',
    'cancelled',
    'canceled',
    'rejected',
    'declined',
  };

  if (inactiveStatuses.contains(normalized)) {
    return false;
  }

  return liveStatuses.contains(normalized);
}

List<BrokerSettlement> _analyticsFromResponse(Map<String, dynamic> response) {
  final data = response['data'] is Map<String, dynamic>
      ? response['data'] as Map<String, dynamic>
      : response;
  final history =
      data['tripHistory'] ?? data['trip_history'] ?? const <dynamic>[];
  if (history is! List) {
    return const <BrokerSettlement>[];
  }
  return history
      .whereType<Map<String, dynamic>>()
      .map(BrokerSettlement.fromJson)
      .toList();
}

Map<String, dynamic>? _truckFromResponse(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    final truck = data['truck'];
    if (truck is Map<String, dynamic>) {
      return truck;
    }
  }
  return null;
}

List<DriverTripSummary> _tripFeedFromResponse(Map<String, dynamic> response) {
  final data = response['data'] is Map<String, dynamic>
      ? response['data'] as Map<String, dynamic>
      : response;
  final trips = data['trips'] ?? const <dynamic>[];
  if (trips is! List) {
    return const <DriverTripSummary>[];
  }

  return trips
      .whereType<Map<String, dynamic>>()
      .map(DriverTripSummary.fromJson)
      .toList();
}

TrackingDemoShipment _shipmentFromTrip(Map<String, dynamic> trip) {
  final pickup = _mapFrom(trip['pickup'] ?? trip['pickupLocation']);
  final drop = _mapFrom(trip['drop'] ?? trip['dropoffLocation']);
  final currentLocation = _mapFrom(
    trip['currentLocation'] ?? trip['liveLocation'] ?? trip['truckLocation'],
  );
  final status = _stringFrom(trip, const ['status', 'rawStatus']);
  final bookingNumber = _stringFrom(trip, const [
    'bookingNumber',
    'booking_number',
  ]);
  final id = _stringFrom(trip, const ['id', 'tripId', 'trip_id']);
  final pickupLabel = _locationLabel(pickup, 'Pickup location not provided');
  final dropLabel = _locationLabel(drop, 'Drop-off location not provided');
  final timeline = _timelineForStatus(status, pickupLabel, dropLabel);
  final weight = _stringFrom(trip, const [
    'weight',
    'cargoWeight',
    'cargo_weight',
  ]);
  final amount = _doubleFrom(trip, const ['earnings', 'amount', 'price']);
  final packageName = _stringFrom(trip, const ['packageName', 'cargoName']);

  return TrackingDemoShipment(
    packageName: packageName.isNotEmpty
        ? packageName
        : (bookingNumber.isNotEmpty ? bookingNumber : 'Trip'),
    trackingId: bookingNumber.isNotEmpty ? bookingNumber : id,
    fromLocation: pickupLabel,
    toLocation: dropLabel,
    status: status.isEmpty ? 'Assigned' : status,
    customerName: _stringFrom(trip, const ['customerName', 'clientName']),
    weight: weight.isEmpty ? 'N/A' : weight,
    timeline: timeline,
    amount: amount,
    pickupLat: _doubleFrom(pickup, const ['lat', 'latitude']),
    pickupLng: _doubleFrom(pickup, const ['lng', 'longitude']),
    dropLat: _doubleFrom(drop, const ['lat', 'latitude']),
    dropLng: _doubleFrom(drop, const ['lng', 'longitude']),
    liveLat: _doubleFrom(currentLocation, const ['lat', 'latitude']),
    liveLng: _doubleFrom(currentLocation, const ['lng', 'longitude']),
    tripId: id,
    bookingId: _stringFrom(trip, const ['bookingId', 'booking_id']),
    bookingStatus: status,
    assignedDriverName: _stringFrom(trip, const ['driverName', 'driver_name']),
    assignedTruckName: _stringFrom(trip, const ['truckName', 'truck_name']),
  );
}

List<TrackingTimelineStep> _timelineForStatus(
  String status,
  String pickup,
  String drop,
) {
  final normalized = status.toLowerCase();
  if (normalized == 'completed' || normalized == 'delivered') {
    return [
      TrackingTimelineStep(
        title: 'Assigned',
        subtitle: pickup,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In transit',
        subtitle: drop,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Completed successfully',
        completed: true,
      ),
    ];
  }

  if (normalized == 'in_transit' || normalized == 'picked_up') {
    return [
      TrackingTimelineStep(
        title: 'Assigned',
        subtitle: pickup,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Picked up',
        subtitle: pickup,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In transit',
        subtitle: drop,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Pending',
        completed: false,
      ),
    ];
  }

  return [
    TrackingTimelineStep(title: 'Assigned', subtitle: pickup, completed: true),
    TrackingTimelineStep(title: 'En route', subtitle: drop, completed: false),
    TrackingTimelineStep(
      title: 'Delivered',
      subtitle: 'Pending',
      completed: false,
    ),
  ];
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String _locationLabel(Map<String, dynamic> value, String fallback) {
  final label = _stringFrom(value, const ['location', 'address', 'name']);
  return label.isEmpty ? fallback : label;
}

String _stringFrom(Map<String, dynamic> value, List<String> keys) {
  for (final key in keys) {
    final raw = value[key]?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw.toLowerCase() != 'null') {
      return raw;
    }
  }
  return '';
}

double _doubleFrom(Map<String, dynamic> value, List<String> keys) {
  for (final key in keys) {
    final raw = value[key];
    if (raw is num) return raw.toDouble();
    final parsed = double.tryParse(raw?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

bool _looksLikePlaceholderTrip(Map<String, dynamic> trip) {
  final status = _stringFrom(trip, const [
    'status',
    'rawStatus',
  ]).trim().toLowerCase();
  if (status.isEmpty) {
    return false;
  }

  const placeholderStatuses = {'assigned', 'pending', 'requested'};
  if (!placeholderStatuses.contains(status)) {
    return false;
  }

  final pickup = _mapFrom(trip['pickup'] ?? trip['pickupLocation']);
  final drop = _mapFrom(trip['drop'] ?? trip['dropoffLocation']);
  final currentLocation = _mapFrom(
    trip['currentLocation'] ?? trip['liveLocation'] ?? trip['truckLocation'],
  );
  final bookingNumber = _stringFrom(trip, const [
    'bookingNumber',
    'booking_number',
  ]);
  final id = _stringFrom(trip, const ['id', 'tripId', 'trip_id']);

  final hasLocationData =
      pickup.isNotEmpty ||
      drop.isNotEmpty ||
      currentLocation.isNotEmpty ||
      _doubleFrom(pickup, const ['lat', 'latitude']) != 0 ||
      _doubleFrom(pickup, const ['lng', 'longitude']) != 0 ||
      _doubleFrom(drop, const ['lat', 'latitude']) != 0 ||
      _doubleFrom(drop, const ['lng', 'longitude']) != 0 ||
      _doubleFrom(currentLocation, const ['lat', 'latitude']) != 0 ||
      _doubleFrom(currentLocation, const ['lng', 'longitude']) != 0;

  return !hasLocationData && bookingNumber.isEmpty && id.isEmpty;
}

class DriverTripSummary {
  const DriverTripSummary({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.distanceKm,
    required this.status,
    required this.bookingTime,
    required this.amount,
    required this.driverName,
    required this.truckReg,
  });

  factory DriverTripSummary.fromJson(Map<String, dynamic> json) {
    final pickup = _mapFrom(json['pickup']);
    final drop = _mapFrom(json['drop']);
    final createdAt = _stringFrom(json, const ['createdAt', 'created_at']);
    final deliveredAt = _stringFrom(json, const [
      'deliveredAt',
      'delivered_at',
    ]);
    return DriverTripSummary(
      id: _stringFrom(json, const ['id', 'tripId', 'trip_id']),
      bookingId: _stringFrom(json, const ['bookingId', 'booking_id']),
      bookingNumber: _stringFrom(json, const [
        'bookingNumber',
        'booking_number',
      ]),
      fromLocation: _stringFrom(pickup, const ['location', 'address']),
      toLocation: _stringFrom(drop, const ['location', 'address']),
      distanceKm: _readTripDistance(json),
      status: _stringFrom(json, const ['status', 'rawStatus']).isNotEmpty
          ? _stringFrom(json, const ['status', 'rawStatus'])
          : 'pending',
      bookingTime: deliveredAt.isNotEmpty ? deliveredAt : createdAt,
      amount: _doubleFrom(json, const [
        'earnings',
        'amountToCollect',
        'amount',
      ]),
      driverName: _stringFrom(json, const ['driverName', 'driver_name']),
      truckReg: _stringFrom(json, const ['truckReg', 'truck_reg']),
    );
  }

  final String id;
  final String bookingId;
  final String bookingNumber;
  final String fromLocation;
  final String toLocation;
  final double distanceKm;
  final String status;
  final String bookingTime;
  final double amount;
  final String driverName;
  final String truckReg;

  String get distanceLabel => distanceKm > 0
      ? '${distanceKm.toStringAsFixed(distanceKm % 1 == 0 ? 0 : 1)} km'
      : '—';

  BrokerSettlement toSettlement() {
    return BrokerSettlement(
      id: id,
      bookingId: bookingId,
      bookingNumber: bookingNumber.isNotEmpty ? bookingNumber : 'Booking',
      route: '$fromLocation -> $toLocation',
      truck: truckReg,
      driver: driverName,
      amount: amount,
      platformFee: 0,
      netEarnings: amount,
      status: status,
      settledAt: bookingTime.isNotEmpty ? bookingTime : null,
    );
  }
}

double _readTripDistance(Map<String, dynamic> json) {
  final raw = json['distance'];
  if (raw is num) return raw.toDouble();
  final parsed = double.tryParse(raw?.toString() ?? '');
  if (parsed != null) return parsed;
  return _doubleFrom(json, const [
    'distance_km',
    'distanceKm',
    'route_distance',
  ]);
}
