import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class DriverRequestItem {
  const DriverRequestItem({
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
    required this.tripId,
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
  final String tripId;
  final Map<String, dynamic> raw;

  bool get canNegotiate =>
      !driverTimedOut &&
      (status.toLowerCase().isEmpty ||
          status.toLowerCase() == 'requested' ||
          status.toLowerCase() == 'pending');

  String get displayRef =>
      bookingNumber.isNotEmpty ? bookingNumber : (id.isNotEmpty ? id : '-');

  factory DriverRequestItem.fromMap(Map<String, dynamic> json) {
    final offerHistory = _asList(json['offerHistory'] ?? json['offer_history']);
    final client = _asMap(json['client']);
    final driver = _asMap(json['driver']);
    final broker = _asMap(json['broker']);
    final route = _asMap(json['route']);
    final truck = _asMap(json['truck']);
    final driverTimedOut =
        json['driverTimedOut'] == true || json['driver_timed_out'] == true;
    final status = _readString(json, const ['status']).toLowerCase();

    return DriverRequestItem(
      id: _readString(json, const [
        'id',
        'request_id',
        'driver_request_id',
        'uuid',
      ]),
      bookingId: _readString(json, const ['bookingId', 'booking_id']),
      bookingNumber: _readString(json, const [
        'bookingNumber',
        'booking_number',
      ]),
      clientName: _firstNonEmpty([
        _readString(json, const ['clientName', 'client_name']),
        _readString(client, const ['name', 'full_name', 'display_name']),
      ]),
      clientPhone: _firstNonEmpty([
        _readString(json, const ['clientPhone', 'client_phone']),
        _readString(client, const ['phone', 'mobile']),
      ]),
      driverName: _firstNonEmpty([
        _readString(json, const ['driverName', 'driver_name']),
        _readString(driver, const ['name', 'full_name', 'display_name']),
      ]),
      driverPhone: _firstNonEmpty([
        _readString(json, const ['driverPhone', 'driver_phone']),
        _readString(driver, const ['phone', 'mobile']),
      ]),
      brokerName: _firstNonEmpty([
        _readString(json, const ['brokerName', 'broker_name']),
        _readString(broker, const ['name', 'full_name', 'display_name']),
      ]),
      brokerPhone: _firstNonEmpty([
        _readString(json, const ['brokerPhone', 'broker_phone']),
        _readString(broker, const ['phone', 'mobile']),
      ]),
      truckReg: _firstNonEmpty([
        _readString(json, const ['truckReg', 'truck_reg']),
        _readString(truck, const ['registrationNumber', 'reg_number', 'plate']),
      ]),
      truckType: _firstNonEmpty([
        _readString(json, const ['truckType', 'truck_type']),
        _readString(truck, const ['type', 'truckType', 'truck_type']),
      ]),
      truckCategory: _firstNonEmpty([
        _readString(json, const ['truckCategory', 'truck_category']),
        _readString(truck, const [
          'category',
          'truckCategory',
          'truck_category',
        ]),
      ]),
      pickup: _firstNonEmpty([
        _readString(json, const ['pickup']),
        _readString(route, const ['from', 'pickup', 'origin', 'source']),
      ]),
      drop: _firstNonEmpty([
        _readString(json, const ['drop']),
        _readString(route, const ['to', 'dropoff', 'destination', 'target']),
      ]),
      weight: _readString(json, const ['weight']),
      amount: _readDouble(json, const ['amount', 'price', 'value']),
      status: status.isEmpty ? 'requested' : status,
      driverTimedOut: driverTimedOut,
      offerCount: offerHistory.length,
      requestedAt: _parseDateTimeObject(
        json['createdAt'] ?? json['created_at'] ?? json['requested_at'],
      ),
      updatedAt: _parseDateTimeObject(json['updatedAt'] ?? json['updated_at']),
      tripId: _firstNonEmpty([
        _readString(json, const ['tripId', 'trip_id']),
        _readString(_asMap(json['trip']), const ['id', 'tripId', 'trip_id']),
      ]),
      raw: json,
    );
  }

  factory DriverRequestItem.fromExtra(Object? extra) {
    if (extra is DriverRequestItem) {
      return extra;
    }
    if (extra is Map<String, dynamic>) {
      return DriverRequestItem.fromMap(extra);
    }
    if (extra is Map) {
      return DriverRequestItem.fromMap(extra.cast<String, dynamic>());
    }
    return const DriverRequestItem(
      id: '',
      bookingId: '',
      bookingNumber: '',
      clientName: '',
      clientPhone: '',
      driverName: '',
      driverPhone: '',
      brokerName: '',
      brokerPhone: '',
      truckReg: '',
      truckType: '',
      truckCategory: '',
      pickup: '',
      drop: '',
      weight: '',
      amount: 0,
      status: 'requested',
      driverTimedOut: false,
      offerCount: 0,
      requestedAt: null,
      updatedAt: null,
      tripId: '',
      raw: <String, dynamic>{},
    );
  }
}

class DriverRequestPage {
  const DriverRequestPage({required this.requests});

  factory DriverRequestPage.fromJson(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    final requests = _extractItems(data, json)
        .whereType<Map<String, dynamic>>()
        .map(DriverRequestItem.fromMap)
        .where((item) => item.id.isNotEmpty)
        .toList();
    return DriverRequestPage(requests: requests);
  }

  final List<DriverRequestItem> requests;
}

final driverRequestsProvider =
    FutureProvider.autoDispose<List<DriverRequestItem>>((ref) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        return const [];
      }

      final response = await ref
          .read(apiClientProvider)
          .getDriverRequests(
            accessToken: session.tokens.accessToken,
            page: 1,
            limit: 20,
          );
      return DriverRequestPage.fromJson(response).requests;
    });

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.cast<String, dynamic>();
  }
  return <String, dynamic>{};
}

List<Object?> _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return const <Object?>[];
}

List<Object?> _extractItems(
  Map<String, dynamic> data,
  Map<String, dynamic> root,
) {
  final candidates = <Object?>[
    data['requests'],
    data['items'],
    data['data'],
    root['requests'],
    root['items'],
  ];

  for (final candidate in candidates) {
    final items = _asList(candidate);
    if (items.isNotEmpty) {
      return items;
    }
  }

  return const <Object?>[];
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) {
      return parsed;
    }
  }
  return 0;
}

DateTime? _parseDateTimeObject(Object? value) {
  if (value is DateTime) {
    return value;
  }
  return DateTime.tryParse(value?.toString() ?? '');
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) {
      return value;
    }
  }
  return '';
}
