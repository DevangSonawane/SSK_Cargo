import 'package:flutter/material.dart';

class GpsTrackerDevice {
  const GpsTrackerDevice({
    required this.deviceId,
    required this.name,
    required this.deviceImei,
    required this.type,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.course,
    required this.ignition,
    required this.alarm,
    required this.deviceFixTime,
    required this.lastUpdate,
    required this.status,
    required this.source,
    required this.lastSeenAt,
  });

  factory GpsTrackerDevice.fromJson(Map<String, dynamic> json) {
    return GpsTrackerDevice(
      deviceId: json['deviceId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      deviceImei: json['deviceImei']?.toString() ?? json['imei']?.toString() ?? '',
      type: json['type']?.toString(),
      phone: json['phone']?.toString(),
      latitude: _asDouble(json['latitude']),
      longitude: _asDouble(json['longitude']),
      speed: _asDouble(json['speed']),
      course: _asDouble(json['course']),
      ignition: _asBool(json['ignition']),
      alarm: json['alarm']?.toString(),
      deviceFixTime: _parseDateTime(json['deviceFixTime']),
      lastUpdate: _parseDateTime(json['lastUpdate']),
      status: json['status']?.toString(),
      source: json['source']?.toString(),
      lastSeenAt: _parseDateTime(json['lastSeenAt']),
    );
  }

  final String deviceId;
  final String name;
  final String deviceImei;
  final String? type;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final double? course;
  final bool? ignition;
  final String? alarm;
  final DateTime? deviceFixTime;
  final DateTime? lastUpdate;
  final String? status;
  final String? source;
  final DateTime? lastSeenAt;

  bool get hasLocation => latitude != null && longitude != null;

  String get displayName {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return deviceImei.isNotEmpty ? deviceImei : 'Unnamed device';
  }

  String get subtitle {
    final parts = <String>[
      if (type != null && type!.trim().isNotEmpty) type!.trim(),
      if (deviceImei.isNotEmpty) deviceImei,
    ];
    return parts.isEmpty ? 'GPS tracker' : parts.join(' · ');
  }

  String get statusLabel {
    final value = status?.trim();
    if (value == null || value.isEmpty) {
      return 'Unknown';
    }
    return value;
  }

  String get vehicleLabel => displayName;

  String get plate => vehicleLabel;

  String get modelLabel {
    final value = type?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return deviceImei.isNotEmpty ? 'IMEI $deviceImei' : 'GPS tracker';
  }

  String get model => modelLabel;

  String get driverLabel {
    if (phone != null && phone!.trim().isNotEmpty) {
      return phone!.trim();
    }
    return statusLabel;
  }

  String get driver => driverLabel;

  String get speedLabel {
    if (speed == null) {
      return '—';
    }
    final rounded = speed!.roundToDouble();
    final text = speed == rounded ? speed!.toStringAsFixed(0) : speed!.toStringAsFixed(1);
    return '$text km/h';
  }

  String get locationLabel {
    if (hasLocation) {
      return '${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}';
    }
    if (lastSeenAt != null) {
      return 'Last seen ${_formatShortDateTime(lastSeenAt!)}';
    }
    return source == 'cached' ? 'Cached position' : 'No location yet';
  }

  String get timeAgoLabel {
    final dt = lastUpdate ?? lastSeenAt;
    if (dt == null) {
      return '--';
    }
    return _formatShortDateTime(dt);
  }

  Color get color {
    final value = statusLabel.toLowerCase();
    if (value.contains('online') || value.contains('running')) {
      return const Color(0xFF13B36C);
    }
    if (source == 'cached') {
      return const Color(0xFFD19A00);
    }
    if (value.contains('offline') || value.contains('stopped')) {
      return const Color(0xFF4B84F6);
    }
    return const Color(0xFF8F98AA);
  }

  IconData get icon => Icons.local_shipping_rounded;
}

List<GpsTrackerDevice> parseGpsTrackerDevices(Map<String, dynamic> response) {
  final data = _asMap(response['data']);
  final rawDevices = _asList(data['devices']) ?? _asList(response['devices']) ?? _asList(data) ?? const [];
  return rawDevices
      .map((item) => item is Map<String, dynamic> ? item : null)
      .whereType<Map<String, dynamic>>()
      .map(GpsTrackerDevice.fromJson)
      .toList();
}

GpsTrackerDevice? parseGpsTrackerDevice(Map<String, dynamic> response) {
  final data = _asMap(response['data']);
  final rawDevice = data['device'] ?? response['device'] ?? data;
  if (rawDevice is List) {
    for (final item in rawDevice) {
      if (item is Map<String, dynamic>) {
        return GpsTrackerDevice.fromJson(item);
      }
    }
    return null;
  }
  if (rawDevice is Map<String, dynamic>) {
    return GpsTrackerDevice.fromJson(rawDevice);
  }
  return null;
}

double? _asDouble(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value.toString());
}

bool? _asBool(Object? value) {
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  final text = value.toString().toLowerCase();
  if (text == 'true' || text == '1' || text == 'yes') {
    return true;
  }
  if (text == 'false' || text == '0' || text == 'no') {
    return false;
  }
  return null;
}

DateTime? _parseDateTime(Object? value) {
  if (value == null) {
    return null;
  }
  final text = value.toString();
  if (text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

List<Object?>? _asList(Object? value) {
  if (value is List) {
    return value;
  }
  return null;
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

String _formatShortDateTime(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour == 0 ? 12 : local.hour > 12 ? local.hour - 12 : local.hour;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} $hour:$minute $period';
}
