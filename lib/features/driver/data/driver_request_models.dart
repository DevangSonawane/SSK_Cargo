import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

class DriverRequestItem {
  const DriverRequestItem({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.driverId,
    required this.pendingConfirmationBy,
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
  final String driverId;
  final String pendingConfirmationBy;
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

  bool get isAwaitingConfirmation =>
      status.trim().toLowerCase() == 'awaiting_confirmation';

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
    final pendingConfirmationBy = _readString(json, const [
      'pendingConfirmationBy',
      'pending_confirmation_by',
    ]).toLowerCase();

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
      pendingConfirmationBy: pendingConfirmationBy,
      driverId: _firstNonEmpty([
        _readString(json, const ['driverId', 'driver_id']),
        _readString(driver, const ['id', 'driverId', 'driver_id']),
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
      driverId: '',
      pendingConfirmationBy: '',
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

final driverRequestFeedProvider =
    StateNotifierProvider.autoDispose<
      DriverRequestFeedController,
      AsyncValue<List<DriverRequestItem>>
    >((ref) {
      return DriverRequestFeedController(ref);
    });

class DriverRequestFeedController
    extends StateNotifier<AsyncValue<List<DriverRequestItem>>> {
  DriverRequestFeedController(this._ref)
    : super(const AsyncLoading<List<DriverRequestItem>>()) {
    _authSubscription = _ref.listen<AsyncValue<AuthSession?>>(
      authSessionProvider,
      (_, next) {
        unawaited(_syncSession(next.valueOrNull));
      },
      fireImmediately: true,
    );
  }

  final Ref _ref;
  StreamSubscription<Map<String, dynamic>>? _socketSubscription;
  Timer? _pollTimer;
  String? _accessToken;
  AuthSession? _currentSession;
  ProviderSubscription<AsyncValue<AuthSession?>>? _authSubscription;

  Future<void> _syncSession(AuthSession? session) async {
    if (!mounted) {
      return;
    }

    if (session == null) {
      _currentSession = null;
      _accessToken = null;
      await _disposeLiveHandles();
      state = const AsyncData<List<DriverRequestItem>>([]);
      return;
    }

    final nextToken = session.tokens.accessToken;
    final tokenChanged = _accessToken != nextToken;
    _currentSession = session;

    if (!tokenChanged && _socketSubscription != null && _pollTimer != null) {
      await _refreshFromServer(nextToken);
      return;
    }

    _accessToken = nextToken;
    state = const AsyncLoading<List<DriverRequestItem>>();
    await _disposeLiveHandles();

    final socketService = _ref.read(appSocketServiceProvider);
    developer.log(
      'Starting driver request feed for shared websocket updates.',
      name: 'SSK.DriverRequests',
    );
    await socketService.connect(nextToken);
    if (!mounted || _accessToken != nextToken) {
      return;
    }

    _socketSubscription = socketService.driverRequestStream.listen(
      _handleSocketPayload,
    );
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(_refreshFromServer(nextToken));
    });

    await _refreshFromServer(nextToken);
  }

  Future<void> refresh() async {
    final token = _accessToken;
    if (token == null) {
      return;
    }
    await _refreshFromServer(token);
  }

  Future<void> _refreshFromServer(String accessToken) async {
    final session = _currentSession;
    if (session == null || !mounted || _accessToken != accessToken) {
      return;
    }

    try {
      final response = await _ref
          .read(apiClientProvider)
          .getDriverRequests(accessToken: accessToken, page: 1, limit: 20);
      final requests = DriverRequestPage.fromJson(response).requests;
      if (!mounted || _accessToken != accessToken) {
        return;
      }
      state = AsyncData<List<DriverRequestItem>>(requests);
    } catch (error, stackTrace) {
      if (!mounted || _accessToken != accessToken) {
        return;
      }
      if (state.valueOrNull == null) {
        state = AsyncError<List<DriverRequestItem>>(error, stackTrace);
      }
    }
  }

  void _handleSocketPayload(Map<String, dynamic> payload) {
    final incoming = DriverRequestItem.fromMap(payload);
    if (incoming.id.isEmpty || !mounted) {
      return;
    }

    final current = state.valueOrNull ?? const <DriverRequestItem>[];
    final next = _mergeRequest(current, incoming);
    state = AsyncData<List<DriverRequestItem>>(next);
  }

  List<DriverRequestItem> _mergeRequest(
    List<DriverRequestItem> requests,
    DriverRequestItem incoming,
  ) {
    final next = List<DriverRequestItem>.from(requests);
    final index = next.indexWhere((request) => request.id == incoming.id);
    if (index == -1) {
      next.insert(0, incoming);
    } else {
      next[index] = incoming;
    }
    return next;
  }

  Future<void> _disposeLiveHandles() async {
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    unawaited(_disposeLiveHandles());
    _authSubscription?.close();
    super.dispose();
  }
}

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
