// Part-Load (Shared-Truck) models — NEW files, duplicated from full-truck
// concepts but standalone. No imports from client_flow / driver request
// models so the full-truck flow stays untouched.
// Backend contract: docs/reference/PART_LOAD_FLUTTER_GUIDE.md

String _readString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return '';
  for (final key in keys) {
    final v = json[key]?.toString().trim();
    if (v != null && v.isNotEmpty && v.toLowerCase() != 'null') return v;
  }
  return '';
}

double? _readDouble(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final v = json[key];
    if (v is num) return v.toDouble();
    final p = double.tryParse(v?.toString() ?? '');
    if (p != null) return p;
  }
  return null;
}

/// One on-trip truck candidate from
/// GET /api/vehicles/trucks/nearby-on-trip
class PartLoadTruck {
  const PartLoadTruck({
    required this.truckId,
    required this.registration,
    required this.driverId,
    required this.driverName,
    required this.capacityTons,
    required this.spareTons,
    required this.distanceKm,
    required this.etaMinutes,
    required this.currentLat,
    required this.currentLng,
    required this.currentTripId,
    required this.estimatedTotal,
    required this.raw,
  });

  final String truckId;
  final String registration;
  final String driverId;
  final String driverName;
  final double capacityTons;
  final double spareTons;
  final double? distanceKm;
  final int? etaMinutes;
  final double? currentLat;
  final double? currentLng;
  final String currentTripId;
  final double estimatedTotal;
  final Map<String, dynamic> raw;

  factory PartLoadTruck.fromJson(Map<String, dynamic> json) {
    final price = json['estimatedPrice'];
    final total = price is Map
        ? _readDouble(price.cast<String, dynamic>(), const ['total'])
        : null;
    return PartLoadTruck(
      truckId: _readString(json, const ['truckId', 'truck_id', 'id']),
      registration:
          _readString(json, const ['registration', 'truckReg', 'truck_reg']),
      driverId: _readString(json, const ['driverId', 'driver_id']),
      driverName: _readString(json, const ['driverName', 'driver_name']),
      capacityTons:
          _readDouble(json, const ['capacityTons', 'capacity_tons']) ?? 0,
      spareTons: _readDouble(json, const ['spareTons', 'spare_tons']) ?? 0,
      distanceKm: _readDouble(json, const ['distanceKm', 'distance_km']),
      etaMinutes:
          _readDouble(json, const ['etaMinutes', 'eta_minutes'])?.round(),
      currentLat: _readDouble(json, const ['currentLat', 'current_lat']),
      currentLng: _readDouble(json, const ['currentLng', 'current_lng']),
      currentTripId:
          _readString(json, const ['currentTripId', 'current_trip_id']),
      estimatedTotal: total ?? 0,
      raw: json,
    );
  }
}

/// A trip-join request row: POST /api/trip-join-requests response,
/// GET /api/trip-join-requests/booking/:bookingId, inbox list item.
class PartLoadJoinRequest {
  const PartLoadJoinRequest({
    required this.id,
    required this.status,
    required this.bookingId,
    required this.bookingNumber,
    required this.truckId,
    required this.truckReg,
    required this.driverId,
    required this.driverName,
    required this.driverPhone,
    required this.clientName,
    required this.clientPhone,
    required this.pickup,
    required this.drop,
    required this.weight,
    required this.amount,
    required this.createdAt,
    required this.driverTimedOut,
    required this.raw,
  });

  final String id;
  final String status; // pending/requested | accepted | declined (lowercased)
  final String bookingId;
  final String bookingNumber;
  final String truckId;
  final String truckReg;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final String clientName;
  final String clientPhone;
  final String pickup;
  final String drop;
  final String weight;
  final String amount;
  final String createdAt;
  final bool driverTimedOut;
  final Map<String, dynamic> raw;

  /// Backend `pending` displays as "Requested" on web (see utils
  /// BOOKING_STATUS) — accept both spellings here.
  bool get isPending => status == 'pending' || status == 'requested';
  bool get isAccepted => status == 'accepted';
  bool get isDeclined => status == 'declined';

  factory PartLoadJoinRequest.fromJson(Map<String, dynamic> json) {
    final timedOut = json['driverTimedOut'] ?? json['driver_timed_out'];
    final client = json['client'];
    final clientMap =
        client is Map ? client.cast<String, dynamic>() : null;
    return PartLoadJoinRequest(
      id: _readString(json, const ['id', 'requestId', 'request_id']),
      status: _readString(json, const ['status']).toLowerCase(),
      bookingId: _readString(json, const ['bookingId', 'booking_id']),
      bookingNumber:
          _readString(json, const ['bookingNumber', 'booking_number']),
      truckId: _readString(json, const ['truckId', 'truck_id']),
      truckReg: _readString(json, const ['truckReg', 'truck_reg']),
      driverId: _readString(json, const ['driverId', 'driver_id']),
      driverName: _readString(json, const ['driverName', 'driver_name']),
      driverPhone: _readString(json, const ['driverPhone', 'driver_phone']),
      clientName: _readString(clientMap ?? json,
          const ['clientName', 'client_name', 'name']),
      clientPhone: _readString(clientMap ?? json,
          const ['clientPhone', 'client_phone', 'phone']),
      pickup: _readString(json, const ['pickup']),
      drop: _readString(json, const ['drop']),
      weight: _readString(json, const ['weight']),
      amount: _readString(json, const ['amount']),
      createdAt: _readString(
          json, const ['createdAt', 'created_at', 'date', 'createdOn']),
      driverTimedOut:
          timedOut is bool ? timedOut : timedOut.toString() == 'true',
      raw: json,
    );
  }

  /// Unwrap { success, data: { request: {...} } } shapes.
  static PartLoadJoinRequest? fromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map) {
      final m = data.cast<String, dynamic>();
      final req = m['request'];
      if (req is Map) {
        return PartLoadJoinRequest.fromJson(req.cast<String, dynamic>());
      }
    }
    return null;
  }
}
