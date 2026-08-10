class ClientBookingPage {
  const ClientBookingPage({
    required this.bookings,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ClientBookingPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final items = _extractItems(data, json);

    return ClientBookingPage(
      bookings: items
          .whereType<Map<String, dynamic>>()
          .map(ClientBooking.fromJson)
          .toList(),
      page: _asInt(data['page']) ?? _asInt(json['page']) ?? 1,
      limit: _asInt(data['limit']) ?? _asInt(json['limit']) ?? items.length,
      total: _asInt(data['total']) ?? _asInt(json['total']) ?? items.length,
      totalPages:
          _asInt(data['total_pages']) ??
          _asInt(data['totalPages']) ??
          _asInt(json['total_pages']) ??
          _asInt(json['totalPages']) ??
          1,
    );
  }

  final List<ClientBooking> bookings;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class ClientPricingConfig {
  const ClientPricingConfig({
    required this.interCity,
    required this.intraCity,
    required this.partTruck,
  });

  factory ClientPricingConfig.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return ClientPricingConfig(
      interCity: ClientInterCityPricing.fromJson(_asMap(data['interCity'])),
      intraCity: ClientIntraCityPricing.fromJson(_asMap(data['intraCity'])),
      partTruck: ClientPartTruckPricing.fromJson(_asMap(data['partTruck'])),
    );
  }

  final ClientInterCityPricing interCity;
  final ClientIntraCityPricing intraCity;
  final ClientPartTruckPricing partTruck;
}

class ClientInterCityPricing {
  const ClientInterCityPricing({
    required this.platformFee,
    required this.tollHandling,
    required this.baseRatePerKm,
    required this.fuelSurcharge,
    required this.tollFixedAmount,
  });

  factory ClientInterCityPricing.fromJson(Map<String, dynamic> json) {
    return ClientInterCityPricing(
      platformFee: _asDouble(json['platformFee']),
      tollHandling: _readString(json, const ['tollHandling']),
      baseRatePerKm: _asDouble(json['baseRatePerKm']),
      fuelSurcharge: _asDouble(json['fuelSurcharge']),
      tollFixedAmount: _asDouble(json['tollFixedAmount']),
    );
  }

  final double platformFee;
  final String tollHandling;
  final double baseRatePerKm;
  final double fuelSurcharge;
  final double tollFixedAmount;
}

class ClientIntraCityPricing {
  const ClientIntraCityPricing({
    required this.large,
    required this.small,
    required this.medium,
  });

  factory ClientIntraCityPricing.fromJson(Map<String, dynamic> json) {
    return ClientIntraCityPricing(
      large: ClientTruckPricingTier.fromJson(_asMap(json['large'])),
      small: ClientTruckPricingTier.fromJson(_asMap(json['small'])),
      medium: ClientTruckPricingTier.fromJson(_asMap(json['medium'])),
    );
  }

  final ClientTruckPricingTier large;
  final ClientTruckPricingTier small;
  final ClientTruckPricingTier medium;
}

class ClientTruckPricingTier {
  const ClientTruckPricingTier({
    required this.baseFare,
    required this.perKmRate,
    required this.platformFee,
    required this.waitingCharge,
    required this.demandMultiplier,
    required this.tollFixedAmount,
  });

  factory ClientTruckPricingTier.fromJson(Map<String, dynamic> json) {
    return ClientTruckPricingTier(
      baseFare: _asDouble(json['baseFare']),
      perKmRate: _asDouble(json['perKmRate']),
      platformFee: _asDouble(json['platformFee']),
      waitingCharge: _asDouble(json['waitingCharge']),
      demandMultiplier: _asDouble(json['demandMultiplier']),
      tollFixedAmount: _asDouble(json['tollFixedAmount']),
    );
  }

  final double baseFare;
  final double perKmRate;
  final double platformFee;
  final double waitingCharge;
  final double demandMultiplier;
  final double tollFixedAmount;
}

class ClientPartTruckPricing {
  const ClientPartTruckPricing({
    required this.baseFare,
    required this.platformFee,
  });

  factory ClientPartTruckPricing.fromJson(Map<String, dynamic> json) {
    return ClientPartTruckPricing(
      baseFare: _asDouble(json['baseFare']),
      platformFee: _asDouble(json['platformFee']),
    );
  }

  final double baseFare;
  final double platformFee;
}

class ClientBooking {
  const ClientBooking({
    required this.id,
    required this.bookingRef,
    required this.bookingNumber,
    required this.status,
    required this.clientName,
    required this.material,
    required this.packageName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.weight,
    required this.vehicleType,
    required this.amountText,
    required this.requestedAt,
    required this.raw,
  });

  factory ClientBooking.fromJson(Map<String, dynamic> json) {
    final status = _readString(json, const ['status', 'booking_status']);

    return ClientBooking(
      id: _readString(json, const ['id', 'booking_id', 'uuid']),
      bookingRef: _readString(json, const [
        'booking_ref',
        'booking_reference',
        'reference',
        'tracking_id',
        'tracking_number',
      ]),
      bookingNumber: _readString(json, const [
        'booking_number',
        'bookingNumber',
        'booking_no',
        'bookingNo',
      ]),
      status: status.isEmpty ? 'pending' : status,
      clientName: _readNestedName(json, const [
        'client_name',
        'customer_name',
        'customer',
        'client',
        'user',
        'name',
      ]),
      material: _readString(json, const [
        'material',
        'cargo_material',
        'goods',
        'item',
      ]),
      packageName: _readString(json, const [
        'package_name',
        'product_name',
        'load_name',
        'cargo_name',
        'title',
      ]),
      pickupLocation: _readString(json, const [
        'pickup_location',
        'pickup_address',
        'from',
        'origin',
        'source_location',
      ]),
      dropoffLocation: _readString(json, const [
        'dropoff_location',
        'drop_off_location',
        'to',
        'destination',
        'target_location',
      ]),
      weight: _readString(json, const [
        'weight',
        'cargo_weight',
        'load_weight',
        'item_weight',
      ]),
      vehicleType: _readString(json, const [
        'vehicle_type',
        'truck_type',
        'required_vehicle',
        'vehicle',
      ]),
      amountText: _formatAmount(
        json['amount'] ?? json['price'] ?? json['fare'] ?? json['value'],
      ),
      requestedAt: _parseDateTime(
        json['requested_at'] ??
            json['created_at'] ??
            json['booked_at'] ??
            json['updated_at'],
      ),
      raw: json,
    );
  }

  final String id;
  final String bookingRef;
  final String bookingNumber;
  final String status;
  final String clientName;
  final String material;
  final String packageName;
  final String pickupLocation;
  final String dropoffLocation;
  final String weight;
  final String vehicleType;
  final String amountText;
  final DateTime? requestedAt;
  final Map<String, dynamic> raw;

  String get displayTitle => material.isNotEmpty
      ? material
      : (packageName.isNotEmpty ? packageName : 'Booking');

  String get displaySubtitle {
    final ref = bookingNumber.isNotEmpty
        ? bookingNumber
        : (bookingRef.isEmpty ? id : bookingRef);
    return ref.isEmpty ? 'No booking reference' : 'Booking #$ref';
  }

  String get displayStatusLabel => _titleCase(status);
}

class ClientBookingOffer {
  const ClientBookingOffer({
    required this.id,
    required this.status,
    required this.amountText,
    required this.brokerName,
    required this.note,
    required this.createdAt,
    required this.raw,
  });

  factory ClientBookingOffer.fromJson(Map<String, dynamic> json) {
    final broker = _asMap(json['broker']);
    final brokerUser = _asMap(json['user']);
    final amountValue =
        json['amount'] ??
        json['price'] ??
        json['counter_amount'] ??
        json['value'];

    return ClientBookingOffer(
      id: _readString(json, const [
        'id',
        'request_id',
        'job_request_id',
        'uuid',
      ]),
      status: _readString(json, const ['status', 'job_status']).isEmpty
          ? 'pending'
          : _readString(json, const ['status', 'job_status']),
      amountText: _formatAmount(amountValue),
      brokerName:
          _readNestedName(json, const [
            'broker_name',
            'broker',
            'created_by',
            'user',
            'driver',
          ]).isNotEmpty
          ? _readNestedName(json, const [
              'broker_name',
              'broker',
              'created_by',
              'user',
              'driver',
            ])
          : _readNestedName(broker, const [
              'name',
              'full_name',
              'display_name',
            ]).isNotEmpty
          ? _readNestedName(broker, const ['name', 'full_name', 'display_name'])
          : _readNestedName(brokerUser, const [
              'name',
              'full_name',
              'display_name',
            ]),
      note: _readString(json, const ['note', 'message', 'remarks']),
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'] ?? json['updated_at'],
      ),
      raw: json,
    );
  }

  final String id;
  final String status;
  final String amountText;
  final String brokerName;
  final String note;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;

  bool get isCountered => _normalizeStatus(status) == 'countered';
  bool get isPending => _normalizeStatus(status) == 'pending';
  String get displayStatusLabel => _titleCase(status);
}

class NearbyTruckPage {
  const NearbyTruckPage({required this.trucks});

  factory NearbyTruckPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final items = <dynamic>[];
    final trucks = data['trucks'];
    if (trucks is List) {
      items.addAll(trucks);
    }

    final rootTrucks = json['trucks'];
    if (rootTrucks is List) {
      items.addAll(rootTrucks);
    }

    items.addAll(_extractItems(data, json));

    return NearbyTruckPage(
      trucks: items
          .whereType<Map<String, dynamic>>()
          .map(NearbyTruck.fromJson)
          .where((truck) => truck.id.isNotEmpty)
          .toList(),
    );
  }

  final List<NearbyTruck> trucks;
}

class NearbyTruck {
  const NearbyTruck({
    required this.id,
    required this.registration,
    required this.type,
    required this.truckNumber,
    required this.truckName,
    required this.capacity,
    required this.category,
    required this.status,
    required this.currentLat,
    required this.currentLng,
    required this.lastLocationAt,
    required this.distanceKm,
    required this.raw,
  });

  factory NearbyTruck.fromJson(Map<String, dynamic> json) {
    final truck = _asMap(json['truck']);
    final vehicle = _asMap(json['vehicle']);
    final location = _asMap(json['location']);
    final id = _firstNonEmpty([
      _readString(json, const ['id', 'truck_id', 'uuid']),
      _readString(truck, const ['id', 'truck_id', 'uuid']),
      _readString(vehicle, const ['id', 'truck_id', 'uuid']),
    ]);
    final latValue =
        json['current_lat'] ??
        json['currentLat'] ??
        json['truck_lat'] ??
        json['truckLat'] ??
        location['current_lat'] ??
        location['currentLat'] ??
        location['lat'] ??
        location['latitude'];
    final lngValue =
        json['current_lng'] ??
        json['currentLng'] ??
        json['truck_lng'] ??
        json['truckLng'] ??
        location['current_lng'] ??
        location['currentLng'] ??
        location['lng'] ??
        location['longitude'];

    return NearbyTruck(
      id: id,
      registration: _firstNonEmpty([
        _readString(json, const [
          'registration',
          'registration_number',
          'registrationNumber',
          'truck_number',
          'truckNumber',
          'plate_number',
          'plateNumber',
        ]),
        _readString(truck, const [
          'registration',
          'registration_number',
          'registrationNumber',
          'truck_number',
          'truckNumber',
          'plate_number',
          'plateNumber',
        ]),
        _readString(vehicle, const [
          'registration',
          'registration_number',
          'registrationNumber',
          'truck_number',
          'truckNumber',
          'plate_number',
          'plateNumber',
        ]),
      ]),
      type: _firstNonEmpty([
        _readString(json, const ['type', 'truck_type']),
        _readString(truck, const ['type', 'truck_type']),
        _readString(vehicle, const ['type', 'truck_type']),
      ]),
      truckNumber: _firstNonEmpty([
        _readString(json, const [
          'truck_number',
          'registration_number',
          'plate_number',
          'vehicle_number',
          'number_plate',
          'reg_no',
          'truck_no',
        ]),
        _readString(truck, const [
          'truck_number',
          'registration_number',
          'plate_number',
          'vehicle_number',
          'number_plate',
          'reg_no',
          'truck_no',
        ]),
        _readString(vehicle, const [
          'truck_number',
          'registration_number',
          'plate_number',
          'vehicle_number',
          'number_plate',
          'reg_no',
          'truck_no',
        ]),
      ]),
      truckName: _firstNonEmpty([
        _readString(json, const [
          'truck_name',
          'name',
          'title',
          'vehicle_name',
        ]),
        _readString(truck, const [
          'truck_name',
          'name',
          'title',
          'vehicle_name',
        ]),
        _readString(vehicle, const [
          'truck_name',
          'name',
          'title',
          'vehicle_name',
        ]),
      ]),
      capacity: _firstNonEmpty([
        _readString(json, const ['capacity', 'load_capacity']),
        _readString(truck, const ['capacity', 'load_capacity']),
        _readString(vehicle, const ['capacity', 'load_capacity']),
      ]),
      category: _firstNonEmpty([
        _readString(json, const ['truck_category', 'category']),
        _readString(truck, const ['truck_category', 'category']),
        _readString(vehicle, const ['truck_category', 'category']),
      ]),
      status: _readString(json, const ['status', 'truck_status']).isEmpty
          ? 'available'
          : _readString(json, const ['status', 'truck_status']),
      currentLat: _asDouble(latValue),
      currentLng: _asDouble(lngValue),
      lastLocationAt: _parseDateTime(
        json['last_location_at'] ??
            json['lastLocationAt'] ??
            json['updated_at'] ??
            json['updatedAt'] ??
            location['last_location_at'] ??
            location['lastLocationAt'],
      ),
      distanceKm: _asDouble(
        json['distance_km'] ??
            json['distanceKm'] ??
            json['distance'] ??
            location['distance_km'] ??
            location['distanceKm'],
      ),
      raw: json,
    );
  }

  final String id;
  final String registration;
  final String type;
  final String truckNumber;
  final String truckName;
  final String capacity;
  final String category;
  final String status;
  final double currentLat;
  final double currentLng;
  final DateTime? lastLocationAt;
  final double distanceKm;
  final Map<String, dynamic> raw;

  bool get hasLocation => currentLat != 0 && currentLng != 0;

  String get displayTitle {
    if (registration.isNotEmpty) {
      return registration;
    }
    if (truckNumber.isNotEmpty) {
      return truckNumber;
    }
    if (truckName.isNotEmpty) {
      return truckName;
    }
    return 'Truck ${id.isNotEmpty ? id.substring(0, id.length > 6 ? 6 : id.length) : ''}'
        .trim();
  }

  String get displaySubtitle {
    final parts = <String>[
      if (type.isNotEmpty) _titleCase(type),
      if (capacity.isNotEmpty) capacity,
      if (category.isNotEmpty) _titleCase(category),
      if (status.isNotEmpty) _titleCase(status),
    ];
    return parts.isEmpty ? 'Available truck' : parts.join(' · ');
  }

  String get selectionLabel =>
      displayTitle.isNotEmpty ? displayTitle : 'Selected truck';
}

class ClientNotification {
  const ClientNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.raw,
  });

  factory ClientNotification.fromJson(Map<String, dynamic> json) {
    return ClientNotification(
      id: _readString(json, const ['id', 'notification_id', 'uuid']),
      title: _readString(json, const ['title', 'subject', 'heading']),
      message: _readString(json, const ['message', 'body', 'content']),
      isRead: _readBool(json, const ['is_read', 'isRead', 'read']),
      createdAt: _parseDateTime(
        json['created_at'] ?? json['createdAt'] ?? json['updated_at'],
      ),
      raw: json,
    );
  }

  final String id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> raw;
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

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) continue;
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

List<dynamic> _extractItems(
  Map<String, dynamic> data,
  Map<String, dynamic> root,
) {
  for (final candidate in [
    data['bookings'],
    data['items'],
    data['results'],
    data['rows'],
    data['data'],
    root['bookings'],
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

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
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
  return 'Client';
}

String _formatAmount(Object? value) {
  if (value == null) {
    return '';
  }

  if (value is num) {
    return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
  }

  final text = value.toString().trim();
  if (text.isEmpty || text.toLowerCase() == 'null') {
    return '';
  }

  if (text.contains('₹') || text.contains(r'$')) {
    return text;
  }

  return '₹$text';
}

DateTime? _parseDateTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return DateTime.tryParse(text);
}

int? _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is double) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '');
}

String _titleCase(String value) {
  final words = value.replaceAll('_', ' ').trim().split(RegExp(r'\s+'));
  if (words.isEmpty || words.first.isEmpty) {
    return 'Pending';
  }
  return words
      .where((word) => word.isNotEmpty)
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}

String _normalizeStatus(String value) {
  return value.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}
