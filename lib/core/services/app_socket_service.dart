import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../network/api_client.dart';

class TruckLocationEvent {
  const TruckLocationEvent({
    required this.truckId,
    required this.lat,
    required this.lng,
    required this.lastLocationAt,
  });

  final String truckId;
  final double lat;
  final double lng;
  final DateTime? lastLocationAt;
}

class AppSocketService {
  AppSocketService(this._ref);

  final Ref _ref;

  io.Socket? _socket;
  String? _accessToken;
  final Set<String> _truckTrackingIds = <String>{};
  final StreamController<TruckLocationEvent> _truckLocationController =
      StreamController<TruckLocationEvent>.broadcast();
  final StreamController<Map<String, dynamic>> _driverRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _jobRequestController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _bookingPaymentController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _tripStatusController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _loginAttemptAlertController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<TruckLocationEvent> get truckLocationStream =>
      _truckLocationController.stream;

  Stream<Map<String, dynamic>> get driverRequestStream =>
      _driverRequestController.stream;

  Stream<Map<String, dynamic>> get jobRequestStream =>
      _jobRequestController.stream;

  Stream<Map<String, dynamic>> get bookingPaymentStream =>
      _bookingPaymentController.stream;

  Stream<Map<String, dynamic>> get tripStatusStream =>
      _tripStatusController.stream;

  Stream<Map<String, dynamic>> get loginAttemptAlertStream =>
      _loginAttemptAlertController.stream;

  io.Socket? get socket => _socket;

  Future<io.Socket?> ensureConnected({required String accessToken}) async {
    final currentSocket = _socket;
    if (currentSocket != null) {
      if (_accessToken == accessToken) {
        if (!currentSocket.connected) {
          currentSocket.connect();
        }
        return currentSocket;
      }
      _disposeSocket();
    }

    final baseUrl = _ref.read(dioProvider).options.baseUrl;
    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    _accessToken = accessToken;
    socket.onConnect((_) {
      developer.log('Shared websocket connected', name: 'SSK.Socket');
      _resyncTruckTrackingRooms();
    });
    socket.onDisconnect((_) {
      developer.log('Shared websocket disconnected', name: 'SSK.Socket');
    });
    socket.onConnectError((error) {
      developer.log(
        'Shared websocket connect error',
        name: 'SSK.Socket',
        error: error,
      );
    });
    socket.onError((error) {
      developer.log('Shared websocket error', name: 'SSK.Socket', error: error);
    });
    socket.on('truck-location', (payload) {
      developer.log(
        'Shared websocket truck-location payload: $payload',
        name: 'SSK.Socket',
      );
      final event = _parseTruckLocationPayload(payload);
      if (event != null && !_truckLocationController.isClosed) {
        developer.log(
          'Shared websocket truck-location parsed truckId=${event.truckId} lat=${event.lat} lng=${event.lng}',
          name: 'SSK.Socket',
        );
        _truckLocationController.add(event);
      } else {
        developer.log(
          'Shared websocket truck-location payload ignored: unable to parse',
          name: 'SSK.Socket',
        );
      }
    });
    socket.on('driver-request-updated', (payload) {
      developer.log(
        'Shared websocket driver-request-updated payload: $payload',
        name: 'SSK.Socket',
      );
      final event = _parseDriverRequestPayload(payload);
      if (event != null && !_driverRequestController.isClosed) {
        _driverRequestController.add(event);
      }
    });
    socket.on('job-request-updated', (payload) {
      developer.log(
        'Shared websocket job-request-updated payload: $payload',
        name: 'SSK.Socket',
      );
      final event = _parseDriverRequestPayload(payload);
      if (event != null && !_jobRequestController.isClosed) {
        _jobRequestController.add(event);
      }
    });
    socket.on('booking-payment-updated', (payload) {
      developer.log(
        'Shared websocket booking-payment-updated payload: $payload',
        name: 'SSK.Socket',
      );
      final event = _parseDriverRequestPayload(payload);
      if (event != null && !_bookingPaymentController.isClosed) {
        _bookingPaymentController.add(event);
      }
    });
    socket.on('trip-status-updated', (payload) {
      developer.log(
        'Shared websocket trip-status-updated payload: $payload',
        name: 'SSK.Socket',
      );
      final event = _parseTripStatusPayload(payload);
      if (event != null && !_tripStatusController.isClosed) {
        _tripStatusController.add(event);
      }
    });
    socket.on('login-attempt-alert', (payload) {
      developer.log(
        'Shared websocket login-attempt-alert payload: $payload',
        name: 'SSK.Socket',
      );
      final event = _parseLoginAttemptAlertPayload(payload);
      if (event != null && !_loginAttemptAlertController.isClosed) {
        _loginAttemptAlertController.add(event);
      }
    });

    _socket = socket;
    socket.connect();
    return socket;
  }

  Future<io.Socket?> connect(String accessToken) {
    return ensureConnected(accessToken: accessToken);
  }

  void disconnect() => _disposeSocket();

  void setTruckTrackingIds(Iterable<String> truckIds) {
    final nextIds = truckIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    developer.log(
      'Shared websocket setTruckTrackingIds count=${nextIds.length} ids=${nextIds.join(",")}',
      name: 'SSK.Socket',
    );

    final removed = _truckTrackingIds.difference(nextIds).toList();
    final added = nextIds.difference(_truckTrackingIds).toList();

    _truckTrackingIds
      ..clear()
      ..addAll(nextIds);

    final socket = _socket;
    if (socket == null || !socket.connected) {
      return;
    }

    for (final id in removed) {
      developer.log(
        'Shared websocket leave-truck-tracking truckId=$id',
        name: 'SSK.Socket',
      );
      socket.emit('leave-truck-tracking', {'truckId': id});
    }

    for (final id in added) {
      developer.log(
        'Shared websocket join-truck-tracking truckId=$id',
        name: 'SSK.Socket',
      );
      socket.emit('join-truck-tracking', {'truckId': id});
    }
  }

  void clearTruckTrackingIds() {
    final socket = _socket;
    if (socket != null && socket.connected) {
      for (final id in _truckTrackingIds) {
        developer.log(
          'Shared websocket leave-truck-tracking truckId=$id',
          name: 'SSK.Socket',
        );
        socket.emit('leave-truck-tracking', {'truckId': id});
      }
    }

    _truckTrackingIds.clear();
  }

  void reset() {
    clearTruckTrackingIds();
    _disposeSocket();
  }

  void dispose() {
    reset();
    _truckLocationController.close();
    _driverRequestController.close();
    _jobRequestController.close();
    _bookingPaymentController.close();
    _tripStatusController.close();
    _loginAttemptAlertController.close();
  }

  void _resyncTruckTrackingRooms() {
    final socket = _socket;
    if (socket == null || !socket.connected || _truckTrackingIds.isEmpty) {
      developer.log(
        'Shared websocket resync skipped connected=${socket?.connected ?? false} tracked=${_truckTrackingIds.length}',
        name: 'SSK.Socket',
      );
      return;
    }

    developer.log(
      'Shared websocket resync truck tracking ids=${_truckTrackingIds.join(",")}',
      name: 'SSK.Socket',
    );
    for (final id in _truckTrackingIds) {
      developer.log(
        'Shared websocket join-truck-tracking truckId=$id',
        name: 'SSK.Socket',
      );
      socket.emit('join-truck-tracking', {'truckId': id});
    }
  }

  void _disposeSocket() {
    final socket = _socket;
    if (socket == null) {
      _accessToken = null;
      return;
    }

    _socket = null;
    _accessToken = null;
    socket.disconnect();
    socket.dispose();
  }

  TruckLocationEvent? _parseTruckLocationPayload(Object? payload) {
    if (payload is! Map) {
      return null;
    }

    final data = payload.cast<String, dynamic>();
    final truckId = _readString(data, const [
      'truckId',
      'truck_id',
      'id',
      'truck',
    ]);
    final lat = _readDouble(data, const [
      'lat',
      'latitude',
      'current_lat',
      'currentLat',
      'location_lat',
      'locationLat',
    ]);
    final lng = _readDouble(data, const [
      'lng',
      'longitude',
      'current_lng',
      'currentLng',
      'location_lng',
      'locationLng',
    ]);
    if (truckId.isEmpty || lat == null || lng == null) {
      return null;
    }

    return TruckLocationEvent(
      truckId: truckId,
      lat: lat,
      lng: lng,
      lastLocationAt: _readDateTime(data, const [
        'lastLocationAt',
        'last_location_at',
        'updatedAt',
        'updated_at',
      ]),
    );
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

  double? _readDouble(Map<String, dynamic> json, List<String> keys) {
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
    return null;
  }

  DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  Map<String, dynamic>? _parseDriverRequestPayload(Object? payload) {
    if (payload is! Map) {
      return null;
    }

    return payload.cast<String, dynamic>();
  }

  Map<String, dynamic>? _parseTripStatusPayload(Object? payload) {
    if (payload is! Map) {
      return null;
    }

    return payload.cast<String, dynamic>();
  }

  Map<String, dynamic>? _parseLoginAttemptAlertPayload(Object? payload) {
    if (payload is! Map) {
      return null;
    }

    return payload.cast<String, dynamic>();
  }
}

final appSocketServiceProvider = Provider<AppSocketService>((ref) {
  final service = AppSocketService(ref);
  ref.onDispose(service.dispose);
  return service;
});
