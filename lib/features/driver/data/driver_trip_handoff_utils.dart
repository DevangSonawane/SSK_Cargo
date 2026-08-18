bool responseMatchesAnyReference(
  Map<String, dynamic> payload,
  Iterable<String> references,
) {
  final normalizedPayload = _unwrapRequestPayload(payload);
  final targetValues = references
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .map((value) => value.toLowerCase())
      .toSet();

  if (targetValues.isEmpty) {
    return true;
  }

  final values = <String>{
    readString(
      normalizedPayload,
      const ['id', 'request_id', 'driver_request_id'],
    ),
    readString(normalizedPayload, const ['bookingId', 'booking_id']),
    readString(normalizedPayload, const ['bookingNumber', 'booking_number']),
    readString(normalizedPayload, const ['tripId', 'trip_id']),
  }..removeWhere((value) => value.isEmpty);

  final trip = _asMap(normalizedPayload['trip']);
  values.addAll(
    {
      readString(trip, const ['id', 'tripId', 'trip_id']),
      readString(trip, const ['bookingId', 'booking_id']),
      readString(trip, const ['bookingNumber', 'booking_number']),
    }..removeWhere((value) => value.isEmpty),
  );

  return values.map((value) => value.toLowerCase()).any(targetValues.contains);
}

Map<String, dynamic>? extractTripFromResponse(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    final trip = data['trip'];
    if (trip is Map<String, dynamic>) {
      return trip;
    }
    return data;
  }

  final trip = response['trip'];
  if (trip is Map<String, dynamic>) {
    return trip;
  }

  return response;
}

String extractTripId(Map<String, dynamic> payload, {String fallback = ''}) {
  final normalizedPayload = _unwrapRequestPayload(payload);
  final trip = _asMap(normalizedPayload['trip']);
  final nested = readString(trip, const ['id', 'tripId', 'trip_id']);
  if (nested.isNotEmpty) {
    return nested;
  }

  for (final key in const ['tripId', 'trip_id', 'tripID']) {
    final value = normalizedPayload[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }

  return fallback.trim();
}

bool tripMatchesContext(
  Map<String, dynamic> trip, {
  String bookingId = '',
  String bookingNumber = '',
  String tripId = '',
}) {
  final references = <String>{
    bookingId.trim(),
    bookingNumber.trim(),
    tripId.trim(),
  }..removeWhere((value) => value.isEmpty);

  if (references.isEmpty) {
    return true;
  }

  final values = <String>{
    readString(trip, const ['id', 'tripId', 'trip_id']),
    readString(trip, const ['bookingId', 'booking_id']),
    readString(trip, const ['bookingNumber', 'booking_number']),
  }..removeWhere((value) => value.isEmpty);

  return values.any(references.contains);
}

String readString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return '';
  for (final key in keys) {
    final raw = json[key]?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw.toLowerCase() != 'null') {
      return raw;
    }
  }
  return '';
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

Map<String, dynamic> _unwrapRequestPayload(Map<String, dynamic> payload) {
  final data = _asMap(payload['data']);
  final request = data['request'];
  if (request is Map<String, dynamic>) {
    return request;
  }
  if (request is Map) {
    return request.cast<String, dynamic>();
  }
  return payload;
}
