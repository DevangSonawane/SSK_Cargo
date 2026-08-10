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
    required this.assignedTruck,
  });

  final TrackingDemoShipment? activeTrip;
  final TrackingDemoShipment? upcomingTrip;
  final List<BrokerSettlement> history;
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
      api.getDriverTruck(accessToken: session.tokens.accessToken),
    ]);

    final activeTrip = _shipmentFromTripResponse(results[0]);
    final upcomingTrip = _shipmentFromTripResponse(results[1]);
    final analytics = _analyticsFromResponse(results[2]);
    final truck = _truckFromResponse(results[3]);

    return DriverDashboardData(
      activeTrip: activeTrip,
      upcomingTrip: upcomingTrip,
      history: analytics,
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
    return _shipmentFromTrip(trip);
  }
  return null;
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
    bookingId: id,
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
