import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';

typedef BrokerTrucksQuery = ({String? status, int page, int limit});
typedef BrokerDriversQuery = ({String? status, int page, int limit});
typedef BrokerJobRequestsQuery = ({int page, int limit});
typedef BrokerDriverRequestsQuery = ({int page, int limit});

final brokerPendingRequestsProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    throw StateError('No active session');
  }

  final response = await ref
      .watch(apiClientProvider)
      .getJobRequests(
        accessToken: session.tokens.accessToken,
        page: 1,
        limit: 100,
      );

  return _BrokerJobRequestPage.fromJson(
    response,
  ).requests.where(isPendingBookingRequest).length;
});

final brokerHistoryProvider =
    FutureProvider.autoDispose<List<TrackingDemoShipment>>((ref) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getJobRequests(
            accessToken: session.tokens.accessToken,
            page: 1,
            limit: 100,
          );

      return _BrokerJobRequestPage.fromJson(response).requests
          .where((request) => !isPendingBookingRequest(request))
          .map(brokerRequestToShipment)
          .toList();
    });

final brokerJobRequestsProvider = FutureProvider.autoDispose
    .family<List<BookingRequest>, BrokerJobRequestsQuery>((ref, query) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getJobRequests(
            accessToken: session.tokens.accessToken,
            page: query.page,
            limit: query.limit,
          );

      return _BrokerJobRequestPage.fromJson(response).requests;
    });

final brokerDriverRequestsProvider = FutureProvider.autoDispose
    .family<List<BrokerDriverRequest>, BrokerDriverRequestsQuery>((
      ref,
      query,
    ) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getDriverRequests(
            accessToken: session.tokens.accessToken,
            page: query.page,
            limit: query.limit,
          );

      return _BrokerDriverRequestPage.fromJson(response).requests;
    });

final brokerTrucksProvider = FutureProvider.autoDispose
    .family<List<BrokerVehicle>, BrokerTrucksQuery>((ref, query) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getTrucks(
            accessToken: session.tokens.accessToken,
            status: query.status,
            page: query.page,
            limit: query.limit,
          );

      return _BrokerTruckPage.fromJson(response).vehicles;
    });

final brokerDriversApiProvider = FutureProvider.autoDispose
    .family<List<BrokerDriver>, BrokerDriversQuery>((ref, query) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getDrivers(
            accessToken: session.tokens.accessToken,
            status: query.status,
            page: query.page,
            limit: query.limit,
          );

      return _BrokerDriverPage.fromJson(response).drivers;
    });

final brokerVehiclesProvider = FutureProvider.autoDispose<List<BrokerVehicle>>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    throw StateError('No active session');
  }

  final response = await ref
      .watch(apiClientProvider)
      .getTrucks(accessToken: session.tokens.accessToken, page: 1, limit: 50);

  return _BrokerTruckPage.fromJson(response).vehicles;
});

final brokerDriversProvider = FutureProvider.autoDispose<List<BrokerDriver>>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    throw StateError('No active session');
  }

  final response = await ref
      .watch(apiClientProvider)
      .getDrivers(accessToken: session.tokens.accessToken, page: 1, limit: 50);

  return _BrokerDriverPage.fromJson(response).drivers;
});

enum BrokerVehicleStatus { idle, onTrip, maintenance }

enum BrokerDriverStatus { onTrip, idle, offline }

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.status,
    required this.clientName,
    required this.clientInitials,
    required this.productName,
    required this.from,
    required this.to,
    required this.weight,
    required this.vehicleType,
    required this.value,
    required this.distance,
    required this.etaText,
    required this.requestedAt,
    this.expiresInMinutes = 0,
  });

  final String id;
  final String status;
  final String clientName;
  final String clientInitials;
  final String productName;
  final String from;
  final String to;
  final String weight;
  final String vehicleType;
  final String value;
  final String distance;
  final String etaText;
  final String requestedAt;
  final int expiresInMinutes;
}

class BrokerDriverRequest {
  const BrokerDriverRequest({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.clientName,
    required this.clientPhone,
    required this.driverName,
    required this.driverPhone,
    required this.brokerName,
    required this.brokerPhone,
    required this.truckReg,
    required this.truckType,
    required this.truckCategory,
    required this.pickup,
    required this.drop,
    required this.weight,
    required this.amount,
    required this.status,
    required this.driverTimedOut,
    required this.offerCount,
    required this.requestedAt,
    required this.updatedAt,
    required this.raw,
  });

  final String id;
  final String bookingId;
  final String bookingNumber;
  final String clientName;
  final String clientPhone;
  final String driverName;
  final String driverPhone;
  final String brokerName;
  final String brokerPhone;
  final String truckReg;
  final String truckType;
  final String truckCategory;
  final String pickup;
  final String drop;
  final String weight;
  final double amount;
  final String status;
  final bool driverTimedOut;
  final int offerCount;
  final DateTime? requestedAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> raw;
}

class _BrokerJobRequestPage {
  const _BrokerJobRequestPage({required this.requests});

  factory _BrokerJobRequestPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final items = _extractItems(data, json);
    return _BrokerJobRequestPage(
      requests: items
          .whereType<Map<String, dynamic>>()
          .map(_bookingRequestFromJson)
          .where((request) => request.id.isNotEmpty)
          .toList(),
    );
  }

  final List<BookingRequest> requests;
}

class _BrokerDriverRequestPage {
  const _BrokerDriverRequestPage({required this.requests});

  factory _BrokerDriverRequestPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final items = _extractItems(data, json);
    return _BrokerDriverRequestPage(
      requests: items
          .whereType<Map<String, dynamic>>()
          .map(_brokerDriverRequestFromJson)
          .where((request) => request.id.isNotEmpty)
          .toList(),
    );
  }

  final List<BrokerDriverRequest> requests;
}

BookingRequest _bookingRequestFromJson(Map<String, dynamic> json) {
  final customer = _asMap(json['customer']);
  final client = _asMap(json['client']);
  final load = _asMap(json['load']);
  final route = _asMap(json['route']);
  final cargo = _asMap(json['cargo']);
  final status = _readString(json, const [
    'status',
    'job_status',
    'request_status',
    'booking_status',
  ]).toLowerCase();
  final createdAt = _readString(json, const [
    'created_at',
    'createdAt',
    'requested_at',
    'requestedAt',
  ]);
  final expiresIn =
      int.tryParse(_readString(json, const ['expires_in', 'expiresIn'])) ?? 0;
  final productName = _firstNonEmpty([
    _readString(json, const [
      'product_name',
      'cargo_name',
      'title',
      'shipment_name',
      'package_name',
    ]),
    _readString(cargo, const ['name', 'title', 'description']),
    'Booking request',
  ]);
  final fromLocation = _firstNonEmpty([
    _readString(json, const ['from', 'pickup_location', 'origin', 'source']),
    _readString(route, const ['from', 'pickup', 'origin', 'source']),
    'Pickup location not provided',
  ]);
  final toLocation = _firstNonEmpty([
    _readString(json, const [
      'to',
      'dropoff_location',
      'destination',
      'target',
    ]),
    _readString(route, const ['to', 'dropoff', 'destination', 'target']),
    'Drop-off location not provided',
  ]);
  final weight = _firstNonEmpty([
    _readString(json, const ['weight', 'cargo_weight', 'load_weight']),
    _readString(load, const ['weight', 'cargo_weight', 'load_weight']),
    'N/A',
  ]);
  final vehicleType = _firstNonEmpty([
    _readString(json, const [
      'vehicle_type',
      'truck_type',
      'required_vehicle_type',
    ]),
    _readString(load, const [
      'vehicle_type',
      'truck_type',
      'required_vehicle_type',
    ]),
    'Truck',
  ]);
  final value = _firstNonEmpty([
    _readString(json, const [
      'value',
      'price',
      'amount',
      'quoted_price',
      'fare',
    ]),
    _readString(load, const [
      'value',
      'price',
      'amount',
      'quoted_price',
      'fare',
    ]),
    '₹0',
  ]);
  final clientName = _firstNonEmpty([
    _readString(json, const ['client_name', 'customer_name', 'name']),
    _readString(client, const ['name', 'full_name', 'display_name']),
    _readString(customer, const ['name', 'full_name', 'display_name']),
    'Customer',
  ]);

  return BookingRequest(
    id: _readString(json, const ['id', 'request_id', 'job_request_id', 'uuid']),
    status: status.isEmpty ? 'pending' : status,
    clientName: clientName,
    clientInitials: _initials(clientName),
    productName: productName,
    from: fromLocation,
    to: toLocation,
    weight: weight,
    vehicleType: vehicleType,
    value: value,
    distance: _readString(json, const [
      'distance',
      'trip_distance',
      'route_distance',
    ]),
    etaText: _firstNonEmpty([
      _readString(json, const ['eta_text', 'eta', 'eta_minutes']),
      _formatRelativeTime(createdAt),
    ]),
    requestedAt: _formatRelativeTime(createdAt),
    expiresInMinutes: expiresIn,
  );
}

BrokerDriverRequest _brokerDriverRequestFromJson(Map<String, dynamic> json) {
  final offerHistory = _asList(json['offerHistory'] ?? json['offer_history']);
  final driverTimedOut =
      json['driverTimedOut'] == true || json['driver_timed_out'] == true;
  return BrokerDriverRequest(
    id: _readString(json, const [
      'id',
      'request_id',
      'driver_request_id',
      'uuid',
    ]),
    bookingId: _readString(json, const ['bookingId', 'booking_id']),
    bookingNumber: _readString(json, const ['bookingNumber', 'booking_number']),
    clientName: _readString(json, const ['clientName', 'client_name']),
    clientPhone: _readString(json, const ['clientPhone', 'client_phone']),
    driverName: _readString(json, const ['driverName', 'driver_name']),
    driverPhone: _readString(json, const ['driverPhone', 'driver_phone']),
    brokerName: _readString(json, const ['brokerName', 'broker_name']),
    brokerPhone: _readString(json, const ['brokerPhone', 'broker_phone']),
    truckReg: _readString(json, const ['truckReg', 'truck_reg']),
    truckType: _readString(json, const ['truckType', 'truck_type']),
    truckCategory: _readString(json, const ['truckCategory', 'truck_category']),
    pickup: _readString(json, const ['pickup']),
    drop: _readString(json, const ['drop']),
    weight: _readString(json, const ['weight']),
    amount: _readDouble(json, const ['amount', 'price', 'value']),
    status: _readString(json, const ['status']).isEmpty
        ? 'pending'
        : _readString(json, const ['status']),
    driverTimedOut: driverTimedOut,
    offerCount: offerHistory.length,
    requestedAt: _parseDateTimeObject(
      json['createdAt'] ?? json['created_at'] ?? json['requested_at'],
    ),
    updatedAt: _parseDateTimeObject(json['updatedAt'] ?? json['updated_at']),
    raw: json,
  );
}

class BrokerVehicle {
  const BrokerVehicle({
    required this.id,
    required this.label,
    required this.plateNumber,
    required this.capacity,
    required this.status,
    required this.assignedDriverName,
    required this.assetPath,
    this.driverId = '',
    this.truckType = '',
    this.category = '',
    this.make = '',
    this.year = '',
    this.insuranceExpiry = '',
  });

  final String id;
  final String label;
  final String plateNumber;
  final String capacity;
  final BrokerVehicleStatus status;
  final String assignedDriverName;
  final String assetPath;
  final String driverId;
  final String truckType;
  final String category;
  final String make;
  final String year;
  final String insuranceExpiry;
}

class _BrokerTruckPage {
  const _BrokerTruckPage({required this.vehicles});

  factory _BrokerTruckPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final items = _extractItems(data, json);
    return _BrokerTruckPage(
      vehicles: items
          .whereType<Map<String, dynamic>>()
          .map(_brokerVehicleFromJson)
          .toList(),
    );
  }

  final List<BrokerVehicle> vehicles;
}

BrokerVehicle _brokerVehicleFromJson(Map<String, dynamic> json) {
  final type = _readString(json, const ['type', 'truck_type', 'vehicle_type']);
  final category = _readString(json, const ['category', 'truck_category']);
  final label = type.isNotEmpty ? type : _labelFromCategory(category);
  final assetPath = _assetPathForLabel(label);
  final registration = _readString(json, const [
    'registration',
    'plate_number',
    'plate',
    'registration_number',
  ]);
  final capacity = _readString(json, const ['capacity', 'load_capacity']);
  final assignedDriver = _readNestedName(json, const [
    'driver',
    'assigned_driver',
  ]);
  final driverId = _readString(json, const ['driver_id', 'driverId']);
  final make = _readString(json, const ['make']);
  final year = _readString(json, const ['year']);
  final insuranceExpiry = _readString(json, const [
    'insurance_expiry',
    'insuranceExpiry',
  ]);
  final status = _vehicleStatusFromApi(_readString(json, const ['status']));

  return BrokerVehicle(
    id: _readString(json, const ['id', 'truck_id', 'uuid']),
    label: label.isEmpty ? 'Truck' : label,
    plateNumber: registration,
    capacity: capacity,
    status: status,
    assignedDriverName: assignedDriver.isEmpty ? 'Unassigned' : assignedDriver,
    assetPath: assetPath,
    driverId: driverId,
    truckType: type,
    category: category,
    make: make,
    year: year,
    insuranceExpiry: insuranceExpiry,
  );
}

String _labelFromCategory(String category) {
  switch (category.toLowerCase()) {
    case 'small':
      return 'Small truck';
    case 'medium':
      return 'Medium truck';
    case 'large':
    case 'big':
      return 'Big truck';
    case 'part':
      return 'Part load';
    default:
      return 'Truck';
  }
}

String _assetPathForLabel(String label) {
  final text = label.toLowerCase();
  if (text.contains('small')) return 'assets/trucks/small truck.png';
  if (text.contains('medium')) return 'assets/trucks/medium truck.png';
  if (text.contains('big') || text.contains('large')) {
    return 'assets/trucks/big truck.png';
  }
  return 'assets/trucks/truck pooling.png';
}

BrokerVehicleStatus _vehicleStatusFromApi(String status) {
  switch (status.toLowerCase()) {
    case 'on_trip':
    case 'in_transit':
    case 'assigned':
      return BrokerVehicleStatus.onTrip;
    case 'maintenance':
      return BrokerVehicleStatus.maintenance;
    case 'available':
    default:
      return BrokerVehicleStatus.idle;
  }
}

BrokerDriverStatus _driverStatusFromApi(String status) {
  switch (status.toLowerCase()) {
    case 'on_trip':
    case 'in_transit':
    case 'assigned':
      return BrokerDriverStatus.onTrip;
    case 'available':
    case 'idle':
      return BrokerDriverStatus.idle;
    case 'offline':
    default:
      return BrokerDriverStatus.offline;
  }
}

List<dynamic> _extractItems(
  Map<String, dynamic> data,
  Map<String, dynamic> root,
) {
  for (final candidate in [
    data['trucks'],
    data['items'],
    data['results'],
    data['rows'],
    data['data'],
    root['trucks'],
    root['items'],
    root['results'],
    root['rows'],
  ]) {
    if (candidate is List) {
      return candidate;
    }
  }

  if (data.isNotEmpty &&
      data.values.every(
        (value) => value is Map<String, dynamic> || value is List,
      )) {
    return const <dynamic>[];
  }

  final nested = root['data'];
  if (nested is List) {
    return nested;
  }

  return const <dynamic>[];
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

List<dynamic> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <dynamic>[];
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

double? _readCoordinate(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }

    if (value is num) {
      return value.toDouble();
    }

    final parsed = double.tryParse(value.toString().trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return null;
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) {
      continue;
    }
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value.toString().trim());
    if (parsed != null) {
      return parsed;
    }
  }
  return 0;
}

DateTime? _parseDateTimeObject(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return DateTime.tryParse(text);
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    final text = value.trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _formatRelativeTime(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) {
    return '';
  }

  final diff = DateTime.now().difference(parsed);
  if (diff.inMinutes < 1) {
    return 'Just now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes} min ago';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h ago';
  }
  return '${diff.inDays}d ago';
}

String _readNestedName(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      final nested = _readString(value, const [
        'name',
        'full_name',
        'display_name',
        'title',
      ]);
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

class BrokerDriver {
  const BrokerDriver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.licenseNo,
    required this.licenseExpiry,
    required this.aadhaar,
    required this.avatar,
    required this.vehicleType,
    required this.status,
    required this.currentLocation,
    this.currentLatitude,
    this.currentLongitude,
    required this.assignedVehicle,
    required this.onTripSince,
    required this.currentBookingRef,
    required this.activeTripId,
    required this.tripStatus,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String licenseNo;
  final String licenseExpiry;
  final String aadhaar;
  final String avatar;
  final String vehicleType;
  final BrokerDriverStatus status;
  final String currentLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  final String assignedVehicle;
  final String onTripSince;
  final String currentBookingRef;
  final String activeTripId;
  final String tripStatus;

  bool get hasLiveCoordinates =>
      currentLatitude != null && currentLongitude != null;

  bool get hasActiveTrip => activeTripId.isNotEmpty;

  bool get hasCompletedTrip {
    final normalized = tripStatus.trim().toLowerCase();
    return const {
      'completed',
      'delivered',
      'closed',
      'settled',
    }.contains(normalized);
  }
}

class _BrokerDriverPage {
  const _BrokerDriverPage({required this.drivers});

  factory _BrokerDriverPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final items = _extractItems(data, json);
    return _BrokerDriverPage(
      drivers: items
          .whereType<Map<String, dynamic>>()
          .map(_brokerDriverFromJson)
          .where((driver) => driver.id.isNotEmpty)
          .toList(),
    );
  }

  final List<BrokerDriver> drivers;
}

BrokerDriver _brokerDriverFromJson(Map<String, dynamic> json) {
  final user = _asMap(json['user']);
  final truck = _asMap(json['truck']);
  final name = _readString(json, const ['name', 'full_name', 'display_name']);
  final userName = _readString(user, const [
    'name',
    'full_name',
    'display_name',
  ]);
  final email = _readString(json, const ['email', 'email_address']);
  final userEmail = _readString(user, const ['email', 'email_address']);
  final phone = _readString(json, const ['phone', 'mobile', 'contact_number']);
  final userPhone = _readString(user, const [
    'phone',
    'mobile',
    'contact_number',
  ]);
  final licenseNo = _readString(json, const [
    'license_no',
    'license_number',
    'driver_license_no',
  ]);
  final licenseExpiry = _readString(json, const [
    'license_expiry',
    'licenseExpiry',
  ]);
  final aadhaar = _readString(json, const ['aadhaar', 'aadhar']);
  final avatar = _readString(json, const ['avatar', 'profile_image']);
  final vehicleType = _readString(json, const [
    'vehicle_type',
    'truck_type',
    'assigned_vehicle_type',
  ]);
  final assignedVehicle = _readString(json, const [
    'assigned_vehicle',
    'truck_number',
    'truck_registration',
  ]);
  final truckPlate = _readString(truck, const [
    'registration',
    'plate_number',
    'plate',
    'registration_number',
  ]);
  final currentLocation = _readString(json, const [
    'current_location',
    'location',
    'last_location',
  ]);
  final currentLatitude = _readCoordinate(json, const [
    'current_lat',
    'latitude',
    'lat',
    'location_lat',
  ]);
  final currentLongitude = _readCoordinate(json, const [
    'current_lng',
    'current_lon',
    'longitude',
    'lng',
    'lon',
    'location_lng',
    'location_lon',
  ]);
  final onTripSince = _readString(json, const ['on_trip_since', 'trip_since']);
  final currentBookingRef = _readString(json, const [
    'current_booking_ref',
    'booking_ref',
  ]);
  final activeTripId = _readString(json, const [
    'active_trip_id',
    'current_trip_id',
    'trip_id',
    'activeTripId',
    'tripId',
  ]);
  final tripStatus = _readString(json, const [
    'trip_status',
    'current_trip_status',
    'delivery_status',
    'shipment_status',
    'booking_status',
  ]);
  final status = _driverStatusFromApi(_readString(json, const ['status']));

  return BrokerDriver(
    id: _readString(json, const ['id', 'driver_id', 'user_id', 'uuid']),
    name: name.isNotEmpty ? name : userName,
    email: email.isNotEmpty ? email : userEmail,
    phone: phone.isNotEmpty ? phone : userPhone,
    licenseNo: licenseNo,
    licenseExpiry: licenseExpiry,
    aadhaar: aadhaar,
    avatar: avatar,
    vehicleType: vehicleType,
    status: status,
    currentLocation: currentLocation,
    currentLatitude: currentLatitude,
    currentLongitude: currentLongitude,
    assignedVehicle: assignedVehicle.isNotEmpty ? assignedVehicle : truckPlate,
    onTripSince: onTripSince,
    currentBookingRef: currentBookingRef,
    activeTripId: activeTripId,
    tripStatus: tripStatus,
  );
}

TrackingDemoShipment bookingRequestToShipment(
  BookingRequest request, {
  String status = 'Accepted',
  String? assignedDriverName,
  String? assignedTruckName,
}) {
  return TrackingDemoShipment(
    packageName: request.productName,
    trackingId: 'TRK-${request.id.toUpperCase()}',
    fromLocation: request.from,
    toLocation: request.to,
    status: status,
    customerName: request.clientName,
    weight: request.weight,
    assignedDriverName: assignedDriverName,
    assignedTruckName: assignedTruckName,
    timeline: [
      const TrackingTimelineStep(
        title: 'Request received',
        subtitle: 'Broker inbox',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Broker $status',
        subtitle: 'Assignment pending',
        completed: true,
      ),
      const TrackingTimelineStep(
        title: 'In transit',
        subtitle: 'Vehicle assignment pending',
        completed: false,
      ),
      const TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Awaiting pickup',
        completed: false,
      ),
    ],
  );
}

TrackingDemoShipment brokerRequestToShipment(BookingRequest request) {
  final status = _normalizeRequestStatus(request.status);
  final shipmentStatus = switch (status) {
    'completed' => 'Completed',
    'assigned' => 'Assigned',
    'confirmed' => 'Accepted',
    'accepted' => 'Accepted',
    _
        when status == 'cancelled' ||
            status == 'declined' ||
            status == 'rejected' ||
            status == 'expired' =>
      'Cancelled',
    _ => request.status.isEmpty ? 'Pending' : request.status,
  };

  return bookingRequestToShipment(request, status: shipmentStatus);
}

TrackingDemoShipment brokerDriverRequestToShipment(
  BrokerDriverRequest request,
) {
  final status = request.status.trim().toLowerCase();
  final shipmentStatus = switch (status) {
    'accepted' => 'Accepted',
    'countered' => 'Countered',
    'declined' || 'rejected' => 'Rejected',
    _ when request.driverTimedOut => 'Driver timed out',
    _ => request.status.isEmpty ? 'Pending' : request.status,
  };

  return TrackingDemoShipment(
    packageName: request.bookingNumber.isNotEmpty
        ? request.bookingNumber
        : 'Timed-out negotiation',
    trackingId: request.bookingNumber.isNotEmpty
        ? request.bookingNumber
        : request.bookingId,
    fromLocation: request.pickup.isNotEmpty
        ? request.pickup
        : 'Pickup location not provided',
    toLocation: request.drop.isNotEmpty
        ? request.drop
        : 'Drop-off location not provided',
    status: shipmentStatus,
    customerName: request.clientName.isNotEmpty ? request.clientName : 'Client',
    weight: request.weight.isNotEmpty ? request.weight : 'N/A',
    amount: request.amount,
    paymentStatus: request.driverTimedOut ? 'pending' : 'confirmed',
    bookingId: request.bookingId,
    bookingStatus: status,
    assignedDriverName: request.driverName.isNotEmpty
        ? request.driverName
        : request.brokerName,
    assignedTruckName: request.truckReg.isNotEmpty
        ? '${request.truckType} • ${request.truckReg}'
        : request.truckType,
    timeline: [
      TrackingTimelineStep(
        title: 'Driver request sent',
        subtitle: request.pickup.isNotEmpty
            ? request.pickup
            : 'Pickup location not provided',
        completed: true,
      ),
      TrackingTimelineStep(
        title: request.driverTimedOut ? 'Driver timed out' : 'Driver response',
        subtitle: request.driverTimedOut
            ? 'Broker handoff is active'
            : (request.status.isNotEmpty ? request.status : 'Waiting'),
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Broker negotiation',
        subtitle: request.drop.isNotEmpty
            ? request.drop
            : 'Drop-off location not provided',
        completed: status == 'accepted',
      ),
      TrackingTimelineStep(
        title: 'Assigned',
        subtitle: status == 'accepted'
            ? 'Truck assignment confirmed'
            : 'Awaiting broker action',
        completed: status == 'accepted',
      ),
    ],
  );
}

bool isPendingBookingRequest(BookingRequest request) {
  return _normalizeRequestStatus(request.status) == 'pending';
}

bool isCompletedBookingRequest(BookingRequest request) {
  return _normalizeRequestStatus(request.status) == 'completed';
}

bool isCancelledBookingRequest(BookingRequest request) {
  final status = _normalizeRequestStatus(request.status);
  return status == 'cancelled' ||
      status == 'declined' ||
      status == 'rejected' ||
      status == 'expired';
}

bool isAcceptedBookingRequest(BookingRequest request) {
  final status = _normalizeRequestStatus(request.status);
  return status == 'accepted' || status == 'confirmed' || status == 'assigned';
}

String _normalizeRequestStatus(String status) {
  return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

class BrokerHeader extends StatelessWidget {
  const BrokerHeader({
    super.key,
    required this.highlighted,
    required this.title,
    this.subtitle,
    required this.pendingRequestsCount,
    required this.onAvatarTap,
    this.onNotificationsTap,
  });

  final bool highlighted;
  final String title;
  final String? subtitle;
  final int pendingRequestsCount;
  final VoidCallback onAvatarTap;
  final VoidCallback? onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted
        ? const Color(0xFF1F88C9)
        : Colors.white;
    final titleColor = highlighted ? Colors.white : const Color(0xFF101828);
    final iconAccent = highlighted ? Colors.white : const Color(0xFF1F88C9);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlighted ? 0.10 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: highlighted
                          ? Colors.white.withValues(alpha: 0.84)
                          : const Color(0xFF667085),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            hasBadge: pendingRequestsCount > 0,
            iconColor: iconAccent,
            size: 30,
            badgeOffset: const Offset(5, 2),
            onTap: onNotificationsTap ?? () {},
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: highlighted
                    ? Colors.white.withValues(alpha: 0.16)
                    : const Color(0xFFF1F4F8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFE5EAF0),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/user.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.hasBadge,
    required this.iconColor,
    required this.size,
    required this.badgeOffset,
    required this.onTap,
  });

  final IconData icon;
  final bool hasBadge;
  final Color iconColor;
  final double size;
  final Offset badgeOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          if (hasBadge)
            Positioned(
              right: badgeOffset.dx,
              top: badgeOffset.dy,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE23A4B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE23A4B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
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

class BrokerBottomBar extends StatelessWidget {
  const BrokerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.pendingRequestsCount,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingRequestsCount;

  @override
  Widget build(BuildContext context) {
    final items = <_BrokerNavItem>[
      _BrokerNavItem(
        icon: Icons.inbox_rounded,
        label: 'New Booking',
        showDot: pendingRequestsCount > 0,
      ),
      const _BrokerNavItem(
        icon: Icons.local_shipping_rounded,
        label: 'Vehicles',
      ),
      const _BrokerNavItem(icon: Icons.gps_fixed_rounded, label: 'Tracking'),
      const _BrokerNavItem(icon: Icons.history_rounded, label: 'History'),
    ];

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: _BrokerBottomBarItem(
                  item: items[index],
                  selected: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              ),
              if (index != items.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrokerNavItem {
  const _BrokerNavItem({
    required this.icon,
    required this.label,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool showDot;
}

class _BrokerBottomBarItem extends StatelessWidget {
  const _BrokerBottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BrokerNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF1F88C9);
    final iconColor = selected ? selectedColor : const Color(0xFF98A2B3);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(child: Icon(item.icon, color: iconColor, size: 20)),
                  if (item.showDot)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE23A4B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE23A4B,
                              ).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? selectedColor : const Color(0xFF667085),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class BrokerRequestCard extends StatelessWidget {
  const BrokerRequestCard({
    super.key,
    required this.request,
    required this.onTap,
  });

  final BookingRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A365D).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Load ID: #${request.id.toUpperCase()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                          fontSize: 11,
                          letterSpacing: 0.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        request.productName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF1A365D),
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E3FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.value,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF002045),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 28, child: _RouteLine()),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LoadPoint(
                        label: 'Pickup',
                        icon: Icons.location_on_rounded,
                        iconColor: const Color(0xFF1F88C9),
                        place: request.from,
                        timeText: request.requestedAt,
                      ),
                      const SizedBox(height: 14),
                      _LoadPoint(
                        label: 'Drop-off',
                        icon: Icons.near_me_rounded,
                        iconColor: const Color(0xFF1F88C9),
                        place: request.to,
                        timeText: '',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    size: 18,
                    color: Color(0xFF667085),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${request.weight} • ${request.vehicleType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0B1C30),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1F88C9),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Open request',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1F88C9).withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF1F88C9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 2,
          height: 54,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF74777F).withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1F88C9).withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF1F88C9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadPoint extends StatelessWidget {
  const _LoadPoint({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.place,
    required this.timeText,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String place;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                place,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF0B1C30),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (timeText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, required this.onTap});

  final BrokerVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _vehicleCardMeta(vehicle.status);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E5EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: meta.iconBackground,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Image.asset(
                            vehicle.assetPath,
                            width: 34,
                            height: 34,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vehicle.plateNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 18,
                                    color: const Color(0xFF1A365D),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${vehicle.label} • ${vehicle.assignedDriverName}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 13,
                                    color: const Color(0xFF667085),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _VehicleStatusBadge(
                  label: vehicleStatusLabel(vehicle.status),
                  backgroundColor: meta.badgeBackground,
                  textColor: meta.badgeText,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(height: 1, color: const Color(0xFFE8EDF2)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _VehicleStatBlock(
                    label: 'Capacity',
                    value: vehicle.capacity,
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _VehicleStatBlock(
                    label: meta.secondaryLabel,
                    value: meta.secondaryValue,
                    valueColor: meta.secondaryValueColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleStatusBadge extends StatelessWidget {
  const _VehicleStatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _VehicleStatBlock extends StatelessWidget {
  const _VehicleStatBlock({
    required this.label,
    required this.value,
    this.valueColor = const Color(0xFF0B1C30),
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF667085),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: valueColor,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _VehicleCardMeta {
  const _VehicleCardMeta({
    required this.iconBackground,
    required this.badgeBackground,
    required this.badgeText,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.secondaryValueColor,
  });

  final Color iconBackground;
  final Color badgeBackground;
  final Color badgeText;
  final String secondaryLabel;
  final String secondaryValue;
  final Color secondaryValueColor;
}

_VehicleCardMeta _vehicleCardMeta(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return const _VehicleCardMeta(
        iconBackground: Color(0xFFEFF6FF),
        badgeBackground: Color(0xFFE8F4EC),
        badgeText: Color(0xFF2FA56E),
        secondaryLabel: 'Location',
        secondaryValue: 'Main Hub A',
        secondaryValueColor: Color(0xFF0B1C30),
      );
    case BrokerVehicleStatus.onTrip:
      return const _VehicleCardMeta(
        iconBackground: Color(0xFFEFF6FF),
        badgeBackground: Color(0xFFFFF0DB),
        badgeText: Color(0xFFB45309),
        secondaryLabel: 'Heading To',
        secondaryValue: 'In transit',
        secondaryValueColor: Color(0xFF0B1C30),
      );
    case BrokerVehicleStatus.maintenance:
      return const _VehicleCardMeta(
        iconBackground: Color(0xFFFFF1F1),
        badgeBackground: Color(0xFFFDECEC),
        badgeText: Color(0xFFD92D20),
        secondaryLabel: 'Last Known',
        secondaryValue: 'Service Bay',
        secondaryValueColor: Color(0xFFD92D20),
      );
  }
}

class DriverListTile extends StatelessWidget {
  const DriverListTile({
    super.key,
    required this.driver,
    required this.onTap,
    required this.onEdit,
    required this.onRemove,
  });

  final BrokerDriver driver;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final meta = _driverCardMeta(driver);
    final visuals = _driverCardVisuals(driver);

    return InkWell(
      onTap: onTap,
      onLongPress: onRemove,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: visuals.backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: visuals.borderColor),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A365D).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Opacity(
          opacity: visuals.opacity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 560;

              final rightColumn = Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DriverActionIconButton(
                        icon: Icons.visibility_rounded,
                        backgroundColor: const Color(0xFFE9EFF8),
                        iconColor: const Color(0xFF1A365D),
                        onPressed: onEdit,
                        tooltip: 'View driver details',
                      ),
                      const SizedBox(width: 8),
                      _DriverActionIconButton(
                        icon: Icons.delete_rounded,
                        backgroundColor: const Color(0xFFFDEDED),
                        iconColor: const Color(0xFFD92D20),
                        onPressed: onRemove,
                        tooltip: 'Delete driver',
                      ),
                      if (meta.ctaLabel.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: visuals.ctaBackgroundColor,
                            foregroundColor: visuals.ctaForegroundColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 10,
                            ),
                            minimumSize: const Size(0, 38),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            meta.ctaLabel,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              );

              final leftColumn = Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DriverAvatar(
                    initials: _initials(driver.name),
                    backgroundColor: visuals.avatarBackgroundColor,
                    textColor: visuals.avatarTextColor,
                    statusColor: visuals.statusDotColor,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              driver.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: 15,
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            _DriverCardMetaChip(
                              label: 'ID: ${driver.id.toUpperCase()}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              meta.statusIcon,
                              size: 18,
                              color: visuals.statusTextColor,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                meta.statusLine,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: 12,
                                      color: visuals.statusTextColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 16,
                              color: Color(0xFF667085),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                driver.currentLocation,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      fontSize: 11,
                                      color: const Color(0xFF667085),
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: leftColumn),
                    const SizedBox(width: 16),
                    rightColumn,
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  leftColumn,
                  const SizedBox(height: 14),
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFE8EDF2),
                  ),
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerLeft, child: rightColumn),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.initials,
    required this.backgroundColor,
    required this.textColor,
    required this.statusColor,
  });

  final String initials;
  final Color backgroundColor;
  final Color textColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverActionIconButton extends StatelessWidget {
  const _DriverActionIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _DriverCardMetaChip extends StatelessWidget {
  const _DriverCardMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 10,
          color: const Color(0xFF344054),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DriverCardVisuals {
  const _DriverCardVisuals({
    required this.backgroundColor,
    required this.borderColor,
    required this.avatarBackgroundColor,
    required this.avatarTextColor,
    required this.statusDotColor,
    required this.statusTextColor,
    required this.ctaBackgroundColor,
    required this.ctaForegroundColor,
    required this.opacity,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color avatarBackgroundColor;
  final Color avatarTextColor;
  final Color statusDotColor;
  final Color statusTextColor;
  final Color ctaBackgroundColor;
  final Color ctaForegroundColor;
  final double opacity;
}

_DriverCardVisuals _driverCardVisuals(BrokerDriver driver) {
  if (driver.hasCompletedTrip) {
    return const _DriverCardVisuals(
      backgroundColor: Color(0xFFF0FBF4),
      borderColor: Color(0xFFB7E4C7),
      avatarBackgroundColor: Color(0xFFD9F6E3),
      avatarTextColor: Color(0xFF136F3E),
      statusDotColor: Color(0xFF22C55E),
      statusTextColor: Color(0xFF136F3E),
      ctaBackgroundColor: Color(0xFF15803D),
      ctaForegroundColor: Colors.white,
      opacity: 1,
    );
  }

  switch (driver.status) {
    case BrokerDriverStatus.onTrip:
      return const _DriverCardVisuals(
        backgroundColor: Color(0xFFF8F9FF),
        borderColor: Color(0xFFC4C6CF),
        avatarBackgroundColor: Color(0xFFD6E3FF),
        avatarTextColor: Color(0xFF002045),
        statusDotColor: Color(0xFF22C55E),
        statusTextColor: Color(0xFF1A365D),
        ctaBackgroundColor: Color(0xFF1A365D),
        ctaForegroundColor: Colors.white,
        opacity: 1,
      );
    case BrokerDriverStatus.idle:
      return const _DriverCardVisuals(
        backgroundColor: Color(0xFFF8F9FF),
        borderColor: Color(0xFFC4C6CF),
        avatarBackgroundColor: Color(0xFFFEECC8),
        avatarTextColor: Color(0xFF875200),
        statusDotColor: Color(0xFFF59E0B),
        statusTextColor: Color(0xFF875200),
        ctaBackgroundColor: Color(0xFF875200),
        ctaForegroundColor: Colors.white,
        opacity: 1,
      );
    case BrokerDriverStatus.offline:
      return const _DriverCardVisuals(
        backgroundColor: Color(0xFFEFF4FF),
        borderColor: Color(0xFFC4C6CF),
        avatarBackgroundColor: Color(0xFFE5E7EB),
        avatarTextColor: Color(0xFF667085),
        statusDotColor: Color(0xFF9CA3AF),
        statusTextColor: Color(0xFF667085),
        ctaBackgroundColor: Color(0xFF667085),
        ctaForegroundColor: Colors.white,
        opacity: 0.8,
      );
  }
}

class _DriverCardMeta {
  const _DriverCardMeta({
    required this.statusLine,
    required this.lastSeen,
    required this.ctaLabel,
    required this.ctaIcon,
    required this.statusIcon,
  });

  final String statusLine;
  final String lastSeen;
  final String ctaLabel;
  final IconData ctaIcon;
  final IconData statusIcon;
}

_DriverCardMeta _driverCardMeta(BrokerDriver driver) {
  if (driver.hasCompletedTrip) {
    return _DriverCardMeta(
      statusLine: driver.tripStatus.isNotEmpty
          ? 'Trip ${_prettyTripStatus(driver.tripStatus)}'
          : 'Trip completed',
      lastSeen: driver.onTripSince.isEmpty
          ? 'Recently completed'
          : '${driver.onTripSince} ago',
      ctaLabel: 'Settlements',
      ctaIcon: Icons.payments_rounded,
      statusIcon: Icons.verified_rounded,
    );
  }

  switch (driver.status) {
    case BrokerDriverStatus.onTrip:
      return _DriverCardMeta(
        statusLine: driver.tripStatus.isNotEmpty
            ? 'Trip ${_prettyTripStatus(driver.tripStatus)}'
            : driver.currentBookingRef.isEmpty
            ? 'Active on trip'
            : 'Active on Booking ${driver.currentBookingRef}',
        lastSeen: driver.onTripSince.isEmpty
            ? 'Just now'
            : '${driver.onTripSince} ago',
        ctaLabel: 'View Map',
        ctaIcon: Icons.map_outlined,
        statusIcon: Icons.check_circle,
      );
    case BrokerDriverStatus.idle:
      return _DriverCardMeta(
        statusLine: 'Idle - Awaiting Assignment',
        lastSeen: '14 mins ago',
        ctaLabel: '',
        ctaIcon: Icons.add_task_rounded,
        statusIcon: Icons.schedule,
      );
    case BrokerDriverStatus.offline:
      return _DriverCardMeta(
        statusLine: 'Offline',
        lastSeen: 'Not available',
        ctaLabel: 'View Details',
        ctaIcon: Icons.info_outline_rounded,
        statusIcon: Icons.do_not_disturb_on_outlined,
      );
  }
}

String _prettyTripStatus(String value) {
  final normalized = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (normalized.isEmpty) return 'active';
  return normalized
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

class BrokerProfileActionCard extends StatelessWidget {
  const BrokerProfileActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrokerMenuTile extends StatelessWidget {
  const BrokerMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.titleColor = const Color(0xFF101828),
    this.iconColor = const Color(0xFF1C2430),
    this.completed = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: completed ? const Color(0xFF2FA56E) : iconColor,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: completed ? const Color(0xFF1F7A52) : titleColor,
                ),
              ),
            ),
            if (completed) ...[
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2FA56E),
                size: 18,
              ),
              const SizedBox(width: 8),
            ],
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}

class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF1F88C9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? selectedColor.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? selectedColor.withValues(alpha: 0.28)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected
                    ? selectedColor.withValues(alpha: 0.12)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? selectedColor : const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VehicleSelectionTile extends StatelessWidget {
  const VehicleSelectionTile({
    super.key,
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? vehicle.accentColor : const Color(0xFF98A2B3);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? vehicle.accentColor.withValues(alpha: 0.08)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? vehicle.accentColor.withValues(alpha: 0.24)
                : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.local_shipping_rounded,
                    color: accent,
                    size: 20,
                  ),
                ),
                const Spacer(),
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: selected
                      ? vehicle.accentColor
                      : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              vehicle.capacity,
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

Color vehicleStatusBackground(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return const Color(0xFFF5F7FB);
    case BrokerVehicleStatus.onTrip:
      return const Color(0xFFE0F4E8);
    case BrokerVehicleStatus.maintenance:
      return const Color(0xFFFFF3D9);
  }
}

Color vehicleStatusColor(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return const Color(0xFF667085);
    case BrokerVehicleStatus.onTrip:
      return const Color(0xFF2FA56E);
    case BrokerVehicleStatus.maintenance:
      return const Color(0xFFF59E0B);
  }
}

String vehicleStatusLabel(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return 'Idle';
    case BrokerVehicleStatus.onTrip:
      return 'On Trip';
    case BrokerVehicleStatus.maintenance:
      return 'Maintenance';
  }
}

Color driverStatusBackground(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFFE0F4E8);
    case BrokerDriverStatus.idle:
      return const Color(0xFFF5F7FB);
    case BrokerDriverStatus.offline:
      return const Color(0xFFF3F4F6);
  }
}

Color driverStatusColor(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFF2FA56E);
    case BrokerDriverStatus.idle:
      return const Color(0xFF667085);
    case BrokerDriverStatus.offline:
      return const Color(0xFF98A2B3);
  }
}

String driverStatusLabel(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return 'On Trip';
    case BrokerDriverStatus.idle:
      return 'Idle';
    case BrokerDriverStatus.offline:
      return 'Offline';
  }
}

Color driverAvatarColor(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFFE0F4E8);
    case BrokerDriverStatus.idle:
      return const Color(0xFFEFF6FF);
    case BrokerDriverStatus.offline:
      return const Color(0xFFF3F4F6);
  }
}

Color driverAvatarTextColor(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFF2FA56E);
    case BrokerDriverStatus.idle:
      return const Color(0xFF1F88C9);
    case BrokerDriverStatus.offline:
      return const Color(0xFF98A2B3);
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}

String maskPersonName(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  return parts.map(_maskWord).join(' ');
}

String _maskWord(String word) {
  final normalized = word.toLowerCase();
  if (normalized.length <= 2) {
    return '${normalized.substring(0, 1)}*';
  }
  if (normalized.length == 3) {
    return '${normalized[0]}*${normalized[2]}';
  }

  final middleLength = normalized.length - 2;
  final maskedMiddle = middleLength <= 3
      ? '*' * middleLength
      : '${'*' * (middleLength - 2)}${normalized[normalized.length - 2]}*';

  return '${normalized[0]}$maskedMiddle${normalized[normalized.length - 1]}';
}
