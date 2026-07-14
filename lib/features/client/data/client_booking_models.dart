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
