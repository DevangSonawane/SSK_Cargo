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

  Stream<TruckLocationEvent> get truckLocationStream =>
      _truckLocationController.stream;

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
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': accessToken})
          .disableAutoConnect()
          .build(),
    );

    _accessToken = accessToken;
    socket.onConnect((_) {
      developer.log('Shared websocket connected', name: 'SSK.Socket');
      _resyncTruckTrackingRooms();
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
      final event = _parseTruckLocationPayload(payload);
      if (event != null && !_truckLocationController.isClosed) {
        _truckLocationController.add(event);
      }
    });

    _socket = socket;
    socket.connect();
    return socket;
  }

  void setTruckTrackingIds(Iterable<String> truckIds) {
    final nextIds = truckIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

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
      socket.emit('leave-truck-tracking', {'truckId': id});
    }

    for (final id in added) {
      socket.emit('join-truck-tracking', {'truckId': id});
    }
  }

  void clearTruckTrackingIds() {
    final socket = _socket;
    if (socket != null && socket.connected) {
      for (final id in _truckTrackingIds) {
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
  }

  void _resyncTruckTrackingRooms() {
    final socket = _socket;
    if (socket == null || !socket.connected || _truckTrackingIds.isEmpty) {
      return;
    }

    for (final id in _truckTrackingIds) {
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
    final truckId = _readString(data, const ['truckId', 'truck_id', 'id']);
    final lat = _readDouble(data, const ['lat', 'latitude']);
    final lng = _readDouble(data, const ['lng', 'longitude']);
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
}

final appSocketServiceProvider = Provider<AppSocketService>((ref) {
  final service = AppSocketService(ref);
  ref.onDispose(service.dispose);
  return service;
});
