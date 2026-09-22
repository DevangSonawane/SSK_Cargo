import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/widgets/map_route_card.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';
import '../../../driver/data/driver_trip_handoff_utils.dart';

class BrokerRequestDetailScreen extends ConsumerStatefulWidget {
  const BrokerRequestDetailScreen({super.key, this.initialRequest});

  final Object? initialRequest;

  @override
  ConsumerState<BrokerRequestDetailScreen> createState() =>
      _BrokerRequestDetailScreenState();
}

class _BrokerRequestDetailScreenState
    extends ConsumerState<BrokerRequestDetailScreen> {
  bool _submitting = false;
  double _counterAmount = 0;
  bool _jobRequestAwaitingConfirmation = false;
  BookingRequest? _liveBookingRequest;
  BrokerDriverRequest? _liveDriverRequest;
  StreamSubscription<Map<String, dynamic>>? _jobRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;
  Timer? _countdownTimer;

  BookingRequest get _request => widget.initialRequest is BookingRequest
      ? _liveBookingRequest ?? widget.initialRequest as BookingRequest
      : const BookingRequest(
          id: '',
          status: 'pending',
          pendingConfirmationBy: '',
          clientName: 'Customer',
          clientPhone: '',
          clientInitials: 'C',
          productName: 'Booking request',
          from: 'Pickup location not provided',
          to: 'Drop-off location not provided',
          weight: 'N/A',
          vehicleType: 'Truck',
          value: '₹0',
          distance: '',
          etaText: '',
          requestedAt: '',
          driverId: '',
          truckId: '',
          assignedDriverName: '',
          assignedTruckName: '',
        );

  BrokerDriverRequest? get _driverRequest =>
      _liveDriverRequest ??
      (widget.initialRequest is BrokerDriverRequest
          ? widget.initialRequest as BrokerDriverRequest
          : null);

  bool get _isDriverNegotiation => _driverRequest != null;

  bool get _isBrokerAssignedDriverRequest =>
      _driverRequest?.jobRequestId.isNotEmpty == true;

  bool get _isExpressRequest => _driverRequest?.isExpress ?? _request.isExpress;

  String get _counterSeedText {
    final driverRequest = _driverRequest;
    if (driverRequest != null) {
      return driverRequest.amount.toStringAsFixed(0);
    }
    return _readAmount(_request.value).toStringAsFixed(0);
  }

  String get _pickupText => _isDriverNegotiation
      ? (_driverRequest!.pickup.isNotEmpty
            ? _driverRequest!.pickup
            : 'Pickup location not provided')
      : _request.from;

  String get _dropText => _isDriverNegotiation
      ? (_driverRequest!.drop.isNotEmpty
            ? _driverRequest!.drop
            : 'Drop-off location not provided')
      : _request.to;

  String get _vehicleText => _isDriverNegotiation
      ? (_driverRequest!.truckType.isNotEmpty
            ? _driverRequest!.truckType
            : 'Truck')
      : _request.vehicleType;

  String get _weightText => _isDriverNegotiation
      ? (_driverRequest!.weight.isNotEmpty ? _driverRequest!.weight : 'N/A')
      : _request.weight;

  String get _valueText => _isDriverNegotiation
      ? '₹${_driverRequest!.amount.toStringAsFixed(0)}'
      : _request.value;

  String get _normalizedStatus =>
      (_isDriverNegotiation ? _driverRequest!.status : _request.status)
          .trim()
          .toLowerCase()
          .replaceAll('-', '_')
          .replaceAll(' ', '_');

  bool get _isTerminalStatus {
    if (_normalizedStatus == 'accepted') {
      return _isDriverNegotiation;
    }
    return const {
      'declined',
      'rejected',
      'expired',
      'cancelled',
      'canceled',
      'completed',
    }.contains(_normalizedStatus);
  }

  bool get _isAcceptedJobReadyForAssignment =>
      !_isDriverNegotiation && _normalizedStatus == 'accepted';

  bool get _isWaitingOnBroker =>
      _isDriverNegotiation &&
      _normalizedStatus == 'awaiting_confirmation' &&
      _driverRequest!.pendingConfirmationBy == 'broker';

  bool get _isLockedWaitingForClient =>
      _isDriverNegotiation &&
      _normalizedStatus == 'awaiting_confirmation' &&
      _driverRequest!.pendingConfirmationBy == 'client';

  String get _jobRequestPendingParty =>
      _request.pendingConfirmationBy.trim().toLowerCase();

  bool get _isJobRequestAwaitingConfirmation =>
      !_isDriverNegotiation && _normalizedStatus == 'awaiting_confirmation';

  bool get _isJobRequestBrokerTurn =>
      _isJobRequestAwaitingConfirmation && _jobRequestPendingParty == 'client';

  bool get _isPendingJobRequest =>
      !_isDriverNegotiation &&
      !_isTerminalStatus &&
      !_isJobRequestAwaitingConfirmation &&
      !_jobRequestAwaitingConfirmation;

  bool get _isWaitingForClientConfirmation =>
      !_isDriverNegotiation &&
      (_jobRequestAwaitingConfirmation ||
          (_isJobRequestAwaitingConfirmation && !_isJobRequestBrokerTurn));

  bool get _canTakeAction =>
      !_submitting &&
      !_isTerminalStatus &&
      !_isWaitingOnBroker &&
      !_isWaitingForClientConfirmation;

  @override
  void initState() {
    super.initState();
    if (widget.initialRequest is BookingRequest) {
      _liveBookingRequest = widget.initialRequest as BookingRequest;
    } else if (widget.initialRequest is BrokerDriverRequest) {
      _liveDriverRequest = widget.initialRequest as BrokerDriverRequest;
    }
    _counterAmount = _readAmount(_counterSeedText);
    if (_counterAmount <= 0) {
      _counterAmount = 1000;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_startLiveUpdates());
      }
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _jobRequestSubscription?.cancel();
    _driverRequestSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  double _readAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    return parsed == null || parsed.isNaN ? 0 : parsed;
  }

  String _selectedDriverName(List<BrokerDriver> drivers) {
    final explicitName = _request.assignedDriverName.trim();
    if (explicitName.isNotEmpty) {
      return explicitName;
    }

    final explicitId = _request.driverId.trim();
    if (explicitId.isNotEmpty) {
      for (final driver in drivers) {
        if (driver.id == explicitId) {
          return driver.name.isNotEmpty ? driver.name : driver.id;
        }
      }
    }

    for (final driver in drivers) {
      if (driver.vehicleType.toLowerCase() ==
          _request.vehicleType.toLowerCase()) {
        return driver.name.isNotEmpty ? driver.name : driver.id;
      }
    }

    return 'Auto-selected driver';
  }

  String _selectedTruckName(List<BrokerVehicle> trucks) {
    final explicitName = _request.assignedTruckName.trim();
    if (explicitName.isNotEmpty) {
      return explicitName;
    }

    final explicitId = _request.truckId.trim();
    if (explicitId.isNotEmpty) {
      for (final truck in trucks) {
        if (truck.id == explicitId) {
          return truck.plateNumber.isNotEmpty
              ? '${truck.label} • ${truck.plateNumber}'
              : truck.label;
        }
      }
    }

    for (final truck in trucks) {
      if (truck.label.toLowerCase() == _request.vehicleType.toLowerCase()) {
        return truck.plateNumber.isNotEmpty
            ? '${truck.label} • ${truck.plateNumber}'
            : truck.label;
      }
    }

    return 'Auto-selected truck';
  }

  String? _defaultDriverId(List<BrokerDriver> drivers) {
    final explicitId = _request.driverId.trim();
    if (explicitId.isNotEmpty) {
      for (final driver in drivers) {
        if (driver.id == explicitId && _isAssignableDriver(driver)) {
          return driver.id;
        }
      }
    }
    for (final driver in drivers) {
      if (_isAssignableDriver(driver) &&
          driver.vehicleType.toLowerCase() ==
              _request.vehicleType.toLowerCase()) {
        return driver.id;
      }
    }
    for (final driver in drivers) {
      if (_isAssignableDriver(driver)) {
        return driver.id;
      }
    }
    return null;
  }

  String? _defaultTruckId(List<BrokerVehicle> trucks) {
    final explicitId = _request.truckId.trim();
    if (explicitId.isNotEmpty) {
      for (final truck in trucks) {
        if (truck.id == explicitId && _isAssignableTruck(truck)) {
          return truck.id;
        }
      }
    }
    for (final truck in trucks) {
      if (_isAssignableTruck(truck) &&
          truck.label.toLowerCase() == _request.vehicleType.toLowerCase()) {
        return truck.id;
      }
    }
    for (final truck in trucks) {
      if (_isAssignableTruck(truck)) {
        return truck.id;
      }
    }
    return null;
  }

  bool _isAssignableDriver(BrokerDriver driver) {
    return driver.status == BrokerDriverStatus.idle;
  }

  bool _isAssignableTruck(BrokerVehicle truck) {
    return truck.status == BrokerVehicleStatus.idle;
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );

    await _jobRequestSubscription?.cancel();
    _jobRequestSubscription = socketService.jobRequestStream.listen((payload) {
      final payloadMap = _detailAsMap(payload);
      if (payloadMap == null || !mounted || _driverRequest != null) {
        return;
      }
      if (!_matchesBookingRequestPayload(payloadMap)) {
        return;
      }
      setState(() {
        _liveBookingRequest = _updatedBookingRequest(payloadMap);
        _jobRequestAwaitingConfirmation =
            _request.status.trim().toLowerCase() == 'awaiting_confirmation';
      });
    });

    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      final payloadMap = _detailAsMap(payload);
      if (payloadMap == null || !mounted || _driverRequest == null) {
        return;
      }
      if (!_matchesDriverRequestPayload(payloadMap)) {
        return;
      }
      setState(() {
        _liveDriverRequest = _updatedDriverRequest(payloadMap);
      });
    });

    await _tripStatusSubscription?.cancel();
    _tripStatusSubscription = socketService.tripStatusStream.listen((payload) {
      final payloadMap = _detailAsMap(payload);
      if (payloadMap == null || !mounted) {
        return;
      }
      if (!_matchesTripStatusPayload(payloadMap)) {
        return;
      }

      setState(() {
        if (_driverRequest != null) {
          _liveDriverRequest = _updatedDriverRequest(payloadMap);
        } else {
          _liveBookingRequest = _updatedBookingRequest(payloadMap);
        }
      });

      ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
    });
  }

  bool _matchesBookingRequestPayload(Map<String, dynamic> payload) {
    final requestId = _readString(payload, const [
      'id',
      'request_id',
      'job_request_id',
    ]);
    return requestId.isNotEmpty && requestId == _request.id;
  }

  bool _matchesDriverRequestPayload(Map<String, dynamic> payload) {
    final requestId = _readString(payload, const [
      'id',
      'request_id',
      'driver_request_id',
    ]);
    final bookingId = _readString(payload, const ['bookingId', 'booking_id']);
    return requestId.isNotEmpty &&
            _driverRequest != null &&
            requestId == _driverRequest!.id ||
        bookingId.isNotEmpty &&
            _driverRequest != null &&
            bookingId == _driverRequest!.bookingId;
  }

  bool _matchesTripStatusPayload(Map<String, dynamic> payload) {
    final references = <String>[
      _request.id,
      _driverRequest?.id ?? '',
      _driverRequest?.bookingId ?? '',
      _driverRequest?.bookingNumber ?? '',
    ];

    return responseMatchesAnyReference(payload, references);
  }

  String _readString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  bool _readBool(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is bool) {
        return value;
      }
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
    }
    return false;
  }

  DateTime? _readDateTime(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  BookingRequest _updatedBookingRequest(Map<String, dynamic> payload) {
    final current = _request;
    final booking =
        _detailAsMap(payload['booking']) ?? const <String, dynamic>{};
    final route = _detailAsMap(payload['route']) ?? const <String, dynamic>{};
    final bookingRoute =
        _detailAsMap(booking['route']) ?? const <String, dynamic>{};
    final status = _readString(payload, const [
      'status',
      'requestStatus',
    ]).toLowerCase();
    final bookingStatus = _readString(booking, const [
      'status',
      'booking_status',
      'bookingStatus',
    ]).toLowerCase();
    final effectiveStatus = _isCancelledDetailStatus(bookingStatus)
        ? bookingStatus
        : status;
    final pendingConfirmationBy = _readString(payload, const [
      'pendingConfirmationBy',
      'pending_confirmation_by',
    ]).toLowerCase();
    final contact = brokerContactInfoFromPayload(
      payload,
      fallbackName: current.clientName,
      fallbackPhone: current.clientPhone,
    );
    return BookingRequest(
      id: current.id,
      status: effectiveStatus.isEmpty ? current.status : effectiveStatus,
      pendingConfirmationBy: pendingConfirmationBy.isEmpty
          ? current.pendingConfirmationBy
          : pendingConfirmationBy,
      clientName: contact.name,
      clientPhone: contact.phone,
      clientInitials: _detailInitials(contact.name),
      productName: current.productName,
      from: _detailFirstNonEmpty([
        _detailLocationString(payload, _detailPickupKeys),
        _detailLocationString(booking, _detailPickupKeys),
        _detailLocationString(route, _detailRoutePickupKeys),
        _detailLocationString(bookingRoute, _detailRoutePickupKeys),
        current.from,
      ]),
      to: _detailFirstNonEmpty([
        _detailLocationString(payload, _detailDropKeys),
        _detailLocationString(booking, _detailDropKeys),
        _detailLocationString(route, _detailRouteDropKeys),
        _detailLocationString(bookingRoute, _detailRouteDropKeys),
        current.to,
      ]),
      weight: current.weight,
      vehicleType: current.vehicleType,
      value: current.value,
      distance: current.distance,
      etaText: current.etaText,
      requestedAt: current.requestedAt,
      driverId: current.driverId,
      truckId: current.truckId,
      assignedDriverName: current.assignedDriverName,
      assignedTruckName: current.assignedTruckName,
      expiresInMinutes: current.expiresInMinutes,
      isExpress: current.isExpress,
    );
  }

  BrokerDriverRequest _updatedDriverRequest(Map<String, dynamic> payload) {
    final current = _driverRequest!;
    final status = _readString(payload, const [
      'status',
      'requestStatus',
    ]).toLowerCase();
    final pendingConfirmationBy = _readString(payload, const [
      'pendingConfirmationBy',
      'pending_confirmation_by',
    ]).toLowerCase();
    final driverTimedOut = _readBool(payload, const [
      'driverTimedOut',
      'driver_timed_out',
    ]);
    final updatedAt = _readDateTime(payload, const ['updatedAt', 'updated_at']);
    final contact = brokerContactInfoFromPayload(
      payload,
      fallbackName: current.clientName,
      fallbackPhone: current.clientPhone,
    );
    return BrokerDriverRequest(
      id: current.id,
      bookingId: current.bookingId,
      jobRequestId: current.jobRequestId,
      bookingNumber: current.bookingNumber,
      pendingConfirmationBy: pendingConfirmationBy.isEmpty
          ? current.pendingConfirmationBy
          : pendingConfirmationBy,
      clientName: contact.name,
      clientPhone: contact.phone,
      driverName: current.driverName,
      driverPhone: current.driverPhone,
      brokerName: current.brokerName,
      brokerPhone: current.brokerPhone,
      truckReg: current.truckReg,
      truckType: current.truckType,
      truckCategory: current.truckCategory,
      pickup: current.pickup,
      drop: current.drop,
      weight: current.weight,
      amount: current.amount,
      status: status.isEmpty ? current.status : status,
      driverTimedOut: driverTimedOut || current.driverTimedOut,
      offerCount: current.offerCount,
      isExpress: current.isExpress,
      requestedAt: current.requestedAt,
      updatedAt: updatedAt ?? current.updatedAt,
      raw: current.raw,
    );
  }

  Future<void> _reject() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _submitting = true);
    try {
      if (_isDriverNegotiation) {
        await ref
            .read(apiClientProvider)
            .rejectDriverRequest(
              accessToken: session.tokens.accessToken,
              id: _driverRequest!.id,
            );
        ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      } else {
        await ref
            .read(apiClientProvider)
            .declineJobRequest(
              accessToken: session.tokens.accessToken,
              id: _request.id,
            );
        ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected.'),
          backgroundColor: AppColors.brand,
        ),
      );
      if (context.canPop()) context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _counter() async {
    if (!_canTakeAction ||
        _isBrokerAssignedDriverRequest ||
        _normalizedStatus == 'awaiting_confirmation') {
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final amount = _counterAmount;
    if (amount <= 0) {
      return;
    }

    setState(() => _submitting = true);
    try {
      if (_isDriverNegotiation) {
        await ref
            .read(apiClientProvider)
            .counterDriverRequest(
              accessToken: session.tokens.accessToken,
              id: _driverRequest!.id,
              amount: amount,
            );
        ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      } else {
        await ref
            .read(apiClientProvider)
            .counterJobRequest(
              accessToken: session.tokens.accessToken,
              id: _request.id,
              amount: amount,
            );
        ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Counter sent.'),
          backgroundColor: AppColors.brand,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _acceptAndAssign({
    required List<BrokerDriver> drivers,
    required List<BrokerVehicle> trucks,
  }) async {
    if (!_canTakeAction) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final selection = await _showAssignmentSheet(
      drivers: drivers,
      trucks: trucks,
    );
    if (selection == null) {
      return;
    }
    final selectedDriver = selection.driver;
    final selectedTruck = selection.truck;

    setState(() => _submitting = true);
    try {
      if (!_isAcceptedJobReadyForAssignment) {
        final response = await ref
            .read(apiClientProvider)
            .acceptJobRequest(
              accessToken: session.tokens.accessToken,
              id: _request.id,
            );
        final responseData = _detailAsMap(response['data']);
        final booking = _detailAsMap(responseData?['booking']);
        final requestData = _detailAsMap(responseData?['request']);
        final status = _detailString(responseData, const ['status']).isNotEmpty
            ? _detailString(responseData, const ['status']).toLowerCase()
            : _detailString(requestData, const ['status']).toLowerCase();

        if ((booking == null || booking.isEmpty) &&
            status == 'awaiting_confirmation') {
          if (!mounted) return;
          setState(() {
            _jobRequestAwaitingConfirmation = true;
          });
          ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Accepted - waiting for the client to confirm.'),
              backgroundColor: AppColors.brand,
            ),
          );
          if (context.canPop()) context.pop(true);
          return;
        }
      }

      await ref
          .read(apiClientProvider)
          .assignDriverToJob(
            accessToken: session.tokens.accessToken,
            id: _request.id,
            driverId: selectedDriver.id,
            truckId: selectedTruck.id,
          );
      ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer sent to the driver - waiting for response.'),
          backgroundColor: AppColors.brand,
        ),
      );
      if (context.canPop()) context.pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<_BrokerAssignmentSelection?> _showAssignmentSheet({
    required List<BrokerDriver> drivers,
    required List<BrokerVehicle> trucks,
  }) {
    final defaultDriverId = _defaultDriverId(drivers);
    final defaultTruckId = _defaultTruckId(trucks);
    return showDialog<_BrokerAssignmentSelection>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) {
        String? selectedDriverId = defaultDriverId;
        String? selectedTruckId = defaultTruckId;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final selectedDriver = selectedDriverId == null
                ? null
                : _findDriverById(drivers, selectedDriverId!);
            final selectedTruck = selectedTruckId == null
                ? null
                : _findTruckById(trucks, selectedTruckId!);
            final canConfirm =
                selectedDriver != null &&
                selectedTruck != null &&
                _isAssignableDriver(selectedDriver) &&
                _isAssignableTruck(selectedTruck);

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              backgroundColor: Colors.transparent,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 560),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Assign Driver & Truck',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                  icon: const Icon(
                                    AppIcons.close_rounded,
                                    color: AppColors.textSecondary,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Booking #${_request.id} - pick an available driver and truck.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _AssignmentPickerField(
                                label: 'Driver',
                                icon: AppIcons.person_rounded,
                                value: selectedDriver == null
                                    ? 'Select driver'
                                    : selectedDriver.name.isNotEmpty
                                    ? selectedDriver.name
                                    : selectedDriver.id,
                                selected: selectedDriver != null,
                                onTap: () async {
                                  final id = await _showDriverChoiceSheet(
                                    drivers: drivers,
                                    selectedDriverId: selectedDriverId,
                                  );
                                  if (id == null || !context.mounted) return;
                                  final driver = _findDriverById(drivers, id);
                                  setSheetState(() {
                                    selectedDriverId = id;
                                    final linkedTruck = _truckForDriver(
                                      trucks,
                                      driver,
                                    );
                                    if (linkedTruck != null) {
                                      selectedTruckId = linkedTruck.id;
                                    }
                                  });
                                },
                              ),
                              const SizedBox(height: 12),
                              _AssignmentPickerField(
                                label: 'Truck',
                                icon: AppIcons.fire_truck_rounded,
                                value: selectedTruck == null
                                    ? 'Select truck'
                                    : '${selectedTruck.label} - ${selectedTruck.plateNumber.isNotEmpty ? selectedTruck.plateNumber : selectedTruck.id}',
                                selected: selectedTruck != null,
                                onTap: () async {
                                  final id = await _showTruckChoiceSheet(
                                    trucks: trucks,
                                    selectedTruckId: selectedTruckId,
                                  );
                                  if (id == null || !context.mounted) return;
                                  setSheetState(() => selectedTruckId = id);
                                },
                              ),
                              if (!canConfirm) ...[
                                const SizedBox(height: 10),
                                Text(
                                  'Select one idle driver and one idle truck to continue.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.dangerIcon),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () =>
                                    Navigator.of(sheetContext).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.textSecondary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(
                                      color: AppColors.line,
                                    ),
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: canConfirm
                                    ? () => Navigator.of(sheetContext).pop(
                                        _BrokerAssignmentSelection(
                                          driver: selectedDriver,
                                          truck: selectedTruck,
                                        ),
                                      )
                                    : null,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brand,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text('Confirm Assignment'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<String?> _showDriverChoiceSheet({
    required List<BrokerDriver> drivers,
    required String? selectedDriverId,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => _AssignmentChoiceSheet<BrokerDriver>(
        title: 'Select driver',
        emptyText: 'No drivers found',
        items: drivers,
        selectedId: selectedDriverId,
        idOf: (driver) => driver.id,
        enabledOf: _isAssignableDriver,
        titleOf: (driver) => driver.name.isNotEmpty ? driver.name : driver.id,
        subtitleOf: (driver) => [
          if (driver.phone.isNotEmpty) driver.phone,
          driverStatusLabel(driver.status),
        ].join(' - '),
      ),
    );
  }

  Future<String?> _showTruckChoiceSheet({
    required List<BrokerVehicle> trucks,
    required String? selectedTruckId,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (context) => _AssignmentChoiceSheet<BrokerVehicle>(
        title: 'Select truck',
        emptyText: 'No trucks found',
        items: trucks,
        selectedId: selectedTruckId,
        idOf: (truck) => truck.id,
        enabledOf: _isAssignableTruck,
        titleOf: (truck) {
          final plate = truck.plateNumber.isNotEmpty
              ? truck.plateNumber
              : truck.id;
          return '${truck.label} - $plate';
        },
        subtitleOf: (truck) => [
          if (truck.capacity.isNotEmpty) truck.capacity,
          vehicleStatusLabel(truck.status),
        ].join(' - '),
      ),
    );
  }

  BrokerDriver? _findDriverById(List<BrokerDriver> drivers, String id) {
    for (final driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  BrokerVehicle? _findTruckById(List<BrokerVehicle> trucks, String id) {
    for (final truck in trucks) {
      if (truck.id == id) return truck;
    }
    return null;
  }

  BrokerVehicle? _truckForDriver(
    List<BrokerVehicle> trucks,
    BrokerDriver? driver,
  ) {
    if (driver == null) return null;
    final assigned = driver.assignedVehicle.trim().toLowerCase();
    if (assigned.isEmpty) return null;
    for (final truck in trucks) {
      final plate = truck.plateNumber.trim().toLowerCase();
      if (plate.isNotEmpty && plate == assigned) {
        return truck;
      }
    }
    return null;
  }

  Future<void> _acceptTimedOutDriverRequest() async {
    if (!_canTakeAction) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    final request = _driverRequest;
    if (session == null || request == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .acceptDriverRequestAsDriver(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
      ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      if (!mounted) return;
      final shipment = brokerDriverRequestToShipment(request);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Negotiation accepted.'),
          backgroundColor: AppColors.brand,
        ),
      );
      context.go('/broker/tracking/details', extra: shipment);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildFinalStateCard(BuildContext context) {
    final visual = _detailRequestStatusVisual(_normalizedStatus);
    final isAccepted =
        _normalizedStatus == 'accepted' ||
        _normalizedStatus == 'confirmed' ||
        _normalizedStatus == 'assigned';
    final isAwaitingConfirmation = _normalizedStatus == 'awaiting_confirmation';

    return _StatusBannerCard(
      icon: visual.icon,
      title: visual.label,
      subtitle: isAwaitingConfirmation
          ? 'This request is awaiting confirmation from the other side.'
          : isAccepted
          ? 'This request has been accepted. No assignment card is shown here.'
          : 'This request has been declined. No further broker actions are available.',
      backgroundColor: visual.backgroundColor,
      borderColor: visual.textColor.withValues(alpha: 0.30),
      iconColor: visual.textColor,
    );
  }

  Widget _buildJobAwaitingConfirmationCard(BuildContext context) {
    return const _StatusBannerCard(
      icon: AppIcons.schedule_rounded,
      title: 'Waiting for client confirmation',
      subtitle:
          'Your accept has been saved. Countering is locked until the client confirms or declines.',
      backgroundColor: Color(0xFFEAF4FB),
      borderColor: AppColors.accentBlueBorder,
      iconColor: AppColors.accentBlue,
    );
  }

  Widget _buildDriverNegotiationCard(BuildContext context) {
    if (_isTerminalStatus) {
      return _buildFinalStateCard(context);
    }

    if (_isWaitingOnBroker) {
      return const _StatusBannerCard(
        icon: AppIcons.schedule_rounded,
        title: 'Waiting for client confirmation',
        subtitle:
            'Your accept has been saved. No more countering is available until the client responds.',
        backgroundColor: Color(0xFFEAF4FB),
        borderColor: AppColors.accentBlueBorder,
        iconColor: AppColors.accentBlue,
      );
    }

    if (_isLockedWaitingForClient) {
      return const _StatusBannerCard(
        icon: AppIcons.schedule_rounded,
        title: 'Waiting for client confirmation',
        subtitle:
            'Your accept has been saved. The request is locked until the client confirms or declines.',
        backgroundColor: Color(0xFFEAF4FB),
        borderColor: AppColors.accentBlueBorder,
        iconColor: AppColors.accentBlue,
      );
    }

    if (_isBrokerAssignedDriverRequest) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.brandBorder),
                  ),
                  child: Text(
                    'Broker-assigned',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Assigned driver request',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This price was already agreed with the broker. Accept or decline only - no counter-offers.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerIcon,
                      side: const BorderSide(color: Color(0xFFF7B4B4)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _submitting
                        ? null
                        : _acceptTimedOutDriverRequest,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                    ),
                    child: Text(_submitting ? 'Saving...' : 'Accept & assign'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Broker negotiation',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _normalizedStatus == 'countered'
                ? 'Counter sent. Waiting for the client to respond before the broker can assign this booking.'
                : 'Counter or reject the timed-out driver request, then accept to assign this truck.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          _CounterAmountSlider(
            label: 'Counter amount',
            amount: _counterAmount,
            minAmount: (_driverRequest!.amount * 0.75)
                .clamp(1, double.infinity)
                .toDouble(),
            maxAmount: (_driverRequest!.amount * 1.25)
                .clamp(2, double.infinity)
                .toDouble(),
            onChanged: _submitting
                ? null
                : (value) => setState(() => _counterAmount = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _reject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.dangerIcon,
                    side: const BorderSide(color: Color(0xFFF7B4B4)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : _counter,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(
                      color: AppColors.brandBorder,
                      width: 1.4,
                    ),
                  ),
                  child: const Text('Counter'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _acceptTimedOutDriverRequest,
              style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
              child: Text(_submitting ? 'Saving...' : 'Accept & assign'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobAssignmentCard(
    BuildContext context,
    List<BrokerDriver> drivers,
    List<BrokerVehicle> trucks,
  ) {
    final selectedDriverName = _selectedDriverName(drivers);
    final selectedTruckName = _selectedTruckName(trucks);
    final selectedDriverId = _defaultDriverId(drivers);
    final selectedTruckId = _defaultTruckId(trucks);
    final isConfirmationTurn = _isJobRequestBrokerTurn;
    final isAcceptedAssignment = _isAcceptedJobReadyForAssignment;
    final negotiationLocked = isConfirmationTurn || isAcceptedAssignment;
    final colors = context.colors;
    final title = isConfirmationTurn
        ? 'Confirm booking'
        : isAcceptedAssignment
        ? 'Assign Driver & Truck'
        : 'Assignment';
    final subtitle = isConfirmationTurn
        ? 'The client accepted this offer. Confirm to finalize, then assign the driver and truck.'
        : isAcceptedAssignment
        ? 'This request is accepted. Pick the assigned driver and truck to create the trip.'
        : 'Driver and truck are auto-selected from the booking details.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: colors.brandFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.local_shipping_rounded,
                  color: Color(0xFF2FA56E),
                  size: 21,
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
                        color: colors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.fillSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Auto-selected assignment',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                _AssigneeRow(
                  leading: _DriverInitialsBadge(name: selectedDriverName),
                  label: 'Driver',
                  value: selectedDriverName,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, thickness: 1, color: colors.line),
                ),
                _AssigneeRow(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: colors.brandFill,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      AppIcons.local_shipping_outlined,
                      size: 18,
                      color: Color(0xFF2FA56E),
                    ),
                  ),
                  label: 'Truck',
                  value: selectedTruckName,
                ),
              ],
            ),
          ),
          if (!negotiationLocked) ...[
            const SizedBox(height: 12),
            _CounterAmountSlider(
              label: 'Counter amount',
              amount: _counterAmount,
              minAmount: (_readAmount(_request.value) * 0.75)
                  .clamp(1, double.infinity)
                  .toDouble(),
              maxAmount: (_readAmount(_request.value) * 1.25)
                  .clamp(2, double.infinity)
                  .toDouble(),
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _counterAmount = value),
            ),
          ],
          const SizedBox(height: 14),
          if (!isAcceptedAssignment) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerIcon,
                      side: const BorderSide(color: Color(0xFFF7B4B4)),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                if (!isConfirmationTurn) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting ? null : _counter,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(
                          color: AppColors.brandBorder,
                          width: 1.4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Counter'),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _acceptAndAssign(drivers: drivers, trucks: trucks),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: Text(
                _submitting
                    ? 'Saving...'
                    : isConfirmationTurn
                    ? 'Confirm & assign'
                    : isAcceptedAssignment
                    ? 'Assign Driver & Truck'
                    : 'Accept & assign',
              ),
            ),
          ),
          if (selectedDriverId == null || selectedTruckId == null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.brandFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.brandBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      AppIcons.info_outline_rounded,
                      size: 15,
                      color: Color(0xFF2FA56E),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No exact match found — a fallback driver or truck will be used when you accept.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(
      brokerDriversApiProvider((status: null, page: 1, limit: 100)),
    );
    final trucksAsync = ref.watch(brokerVehiclesProvider);
    final topAmount = _isDriverNegotiation ? _valueText : _request.value;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _BookingNavRow(onBack: () => context.pop()),
            const SizedBox(height: 14),
            MapRouteCard(
              pickup: _pickupText,
              drop: _dropText,
              isExpress: _isExpressRequest,
              showRouteLabels: false,
            ),
            const SizedBox(height: 14),
            _BrokerRouteCard(
              pickup: _pickupText,
              drop: _dropText,
              weight: _weightText,
              vehicle: _vehicleText,
              distance: _request.distance,
              eta: _request.etaText,
            ),
            const SizedBox(height: 14),
            _BrokerOverviewCard(
              requestedOn: _request.requestedAt.isEmpty
                  ? 'Unavailable'
                  : _request.requestedAt,
              requestedBy: _isDriverNegotiation
                  ? (_driverRequest!.clientName.isEmpty
                        ? 'Customer'
                        : _driverRequest!.clientName)
                  : (_request.clientName.isEmpty
                        ? 'Customer'
                        : _request.clientName),
              loadType: _isDriverNegotiation
                  ? (_driverRequest!.truckCategory.isEmpty
                        ? 'General'
                        : _driverRequest!.truckCategory)
                  : (_request.productName.isEmpty
                        ? 'General'
                        : _request.productName),
              payment: topAmount,
            ),
            const SizedBox(height: 14),
            if (_isDriverNegotiation)
              _buildDriverNegotiationCard(context)
            else if (_isJobRequestBrokerTurn)
              driversAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: AppColors.dangerIcon),
                  ),
                ),
                data: (drivers) {
                  return trucksAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                        style: const TextStyle(color: AppColors.dangerIcon),
                      ),
                    ),
                    data: (trucks) =>
                        _buildJobAssignmentCard(context, drivers, trucks),
                  );
                },
              )
            else if (_isWaitingForClientConfirmation)
              _buildJobAwaitingConfirmationCard(context)
            else if (_isPendingJobRequest)
              driversAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    style: const TextStyle(color: AppColors.dangerIcon),
                  ),
                ),
                data: (drivers) {
                  return trucksAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Text(
                        error.toString().replaceFirst('Exception: ', ''),
                        style: const TextStyle(color: AppColors.dangerIcon),
                      ),
                    ),
                    data: (trucks) =>
                        _buildJobAssignmentCard(context, drivers, trucks),
                  );
                },
              )
            else
              _buildFinalStateCard(context),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }
}

class _StatusBannerCard extends StatelessWidget {
  const _StatusBannerCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.backgroundColor,
    required this.borderColor,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color backgroundColor;
  final Color borderColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookingNavRow extends StatelessWidget {
  const _BookingNavRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            AppIcons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          iconSize: 24,
          padding: const EdgeInsets.all(8),
          style: IconButton.styleFrom(
            backgroundColor: Colors.transparent,
            minimumSize: const Size(40, 40),
            shape: const RoundedRectangleBorder(),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            'Booking Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _BrokerOverviewCard extends StatelessWidget {
  const _BrokerOverviewCard({
    required this.requestedOn,
    required this.requestedBy,
    required this.loadType,
    required this.payment,
  });

  final String requestedOn;
  final String requestedBy;
  final String loadType;
  final String payment;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          _OverviewDetailRow(
            icon: AppIcons.calendar_today_rounded,
            label: 'Requested on',
            value: requestedOn,
          ),
          Divider(height: 24, thickness: 1, color: colors.line),
          _OverviewDetailRow(
            icon: AppIcons.person_rounded,
            label: 'Requested by',
            value: requestedBy,
          ),
          Divider(height: 24, thickness: 1, color: colors.line),
          _OverviewDetailRow(
            icon: AppIcons.local_offer_rounded,
            label: 'Load type',
            value: loadType,
          ),
          Divider(height: 24, thickness: 1, color: colors.line),
          _OverviewDetailRow(
            icon: AppIcons.currency_rupee_rounded,
            label: 'Payment',
            value: payment,
            highlight: true,
          ),
        ],
      ),
    );
  }
}

class _OverviewDetailRow extends StatelessWidget {
  const _OverviewDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: highlight ? AppColors.warningFill : colors.brandFill,
            borderRadius: BorderRadius.circular(10),
            border: highlight
                ? Border.all(color: AppColors.warningBorder)
                : null,
          ),
          child: Icon(
            icon,
            size: 17,
            color: highlight
                ? AppColors.warningText
                : const Color(0xFF2FA56E),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: highlight ? 16 : 14,
                  fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrokerRouteCard extends StatelessWidget {
  const _BrokerRouteCard({
    required this.pickup,
    required this.drop,
    required this.weight,
    required this.vehicle,
    this.distance = '',
    this.eta = '',
  });

  final String pickup;
  final String drop;
  final String weight;
  final String vehicle;
  final String distance;
  final String eta;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textTheme = Theme.of(context).textTheme;
    final trimmedDistance = distance.trim();
    final trimmedEta = eta.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Route Information',
                  style: textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (trimmedDistance.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.brandFill,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.brandBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.route_rounded,
                        size: 13,
                        color: Color(0xFF2FA56E),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        trimmedDistance,
                        style: textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF2FA56E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.fillSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BrokerRailStop(
                  marker: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA56E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2FA56E,
                          ).withValues(alpha: 0.18),
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                  ),
                  label: 'Pickup',
                  value: pickup.trim().isEmpty
                      ? 'Pickup pending'
                      : pickup.trim(),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                _BrokerRailStop(
                  marker: const Icon(
                    AppIcons.location_on_rounded,
                    color: Color(0xFF2FA56E),
                    size: 18,
                  ),
                  label: 'Drop-off',
                  value: drop.trim().isEmpty ? 'Drop pending' : drop.trim(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BrokerMetaTile(
                  icon: AppIcons.scale_outlined,
                  label: 'Weight',
                  value: weight.trim().isEmpty ? '-' : weight.trim(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BrokerMetaTile(
                  icon: AppIcons.local_shipping_outlined,
                  label: 'Vehicle',
                  value: vehicle.trim().isEmpty ? 'Truck' : vehicle.trim(),
                ),
              ),
            ],
          ),
          if (trimmedEta.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.brandFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.brandBorder),
              ),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.schedule_rounded,
                    size: 15,
                    color: Color(0xFF2FA56E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ETA $trimmedEta',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrokerRailStop extends StatelessWidget {
  const _BrokerRailStop({
    required this.marker,
    required this.label,
    required this.value,
  });

  final Widget marker;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 22,
          child: Align(alignment: Alignment.topCenter, child: marker),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BrokerMetaTile extends StatelessWidget {
  const _BrokerMetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.brandFill,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 15, color: const Color(0xFF2FA56E)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssigneeRow extends StatelessWidget {
  const _AssigneeRow({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverInitialsBadge extends StatelessWidget {
  const _DriverInitialsBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials.isEmpty ? 'D' : initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF2FA56E),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Map<String, dynamic>? _detailAsMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String _detailString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return '';
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

const _detailPickupKeys = [
  'pickup',
  'from',
  'pickup_location',
  'pickup_address',
  'pickupLocation',
  'pickupAddress',
  'pickup_location_name',
  'pickupLocationName',
  'origin',
  'origin_address',
  'originAddress',
  'source',
  'pickup_details',
  'pickupDetails',
];

const _detailRoutePickupKeys = [
  'from',
  'pickup',
  'pickup_location',
  'pickup_address',
  'pickupLocation',
  'pickupAddress',
  'pickup_location_name',
  'pickupLocationName',
  'origin',
  'origin_address',
  'originAddress',
  'source',
];

const _detailDropKeys = [
  'drop',
  'dropoff',
  'drop_off',
  'to',
  'dropoff_location',
  'drop_off_location',
  'drop_location',
  'dropoffLocation',
  'dropOffLocation',
  'dropoffAddress',
  'dropAddress',
  'drop_address',
  'drop_location_name',
  'dropLocationName',
  'destination',
  'destination_address',
  'destinationAddress',
  'target',
  'drop_details',
  'dropDetails',
  'dropoff_details',
  'dropoffDetails',
];

const _detailRouteDropKeys = [
  'to',
  'drop',
  'dropoff',
  'dropoff_location',
  'drop_location',
  'dropoffLocation',
  'dropOffLocation',
  'dropoffAddress',
  'dropAddress',
  'drop_address',
  'drop_location_name',
  'dropLocationName',
  'destination',
  'destination_address',
  'destinationAddress',
  'target',
];

String _detailFirstNonEmpty(List<String> values) {
  for (final value in values) {
    final text = value.trim();
    if (text.isNotEmpty) {
      return text;
    }
  }
  return '';
}

String _detailLocationString(Map<String, dynamic> json, List<String> keys) {
  const nestedKeys = [
    'formattedAddress',
    'formatted_address',
    'fullAddress',
    'full_address',
    'address',
    'addressLine',
    'address_line',
    'name',
    'label',
    'description',
    'place',
    'city',
  ];

  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is Map<String, dynamic>) {
      final nested = _detailFirstNonEmpty([
        _detailString(value, nestedKeys),
        [
          _detailString(value, const ['name', 'label', 'place']),
          _detailString(value, const [
            'address',
            'formattedAddress',
            'formatted_address',
          ]),
        ].where((part) => part.isNotEmpty).join(', '),
      ]);
      if (nested.isNotEmpty) return nested;
      continue;
    }
    if (value is Map) {
      final nested = _detailLocationString(
        value.cast<String, dynamic>(),
        nestedKeys,
      );
      if (nested.isNotEmpty) return nested;
      continue;
    }
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

class _DetailRequestStatusVisual {
  const _DetailRequestStatusVisual({
    required this.label,
    required this.description,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final String description;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
}

_DetailRequestStatusVisual _detailRequestStatusVisual(String status) {
  switch (status) {
    case 'accepted':
    case 'confirmed':
    case 'assigned':
      return const _DetailRequestStatusVisual(
        label: 'Accepted',
        description:
            'This request has been accepted. Assign a driver and truck.',
        backgroundColor: AppColors.brandFill,
        textColor: AppColors.brandInk,
        icon: AppIcons.check_circle_rounded,
      );
    case 'countered':
      return const _DetailRequestStatusVisual(
        label: 'Countered',
        description: 'Counter sent. Waiting for the client to respond.',
        backgroundColor: Color(0xFFFEF3C7),
        textColor: AppColors.warningText,
        icon: AppIcons.payments_rounded,
      );
    case 'declined':
    case 'rejected':
    case 'expired':
    case 'cancelled':
    case 'canceled':
      return const _DetailRequestStatusVisual(
        label: 'Cancelled',
        description:
            'This booking has been cancelled. No further broker actions are available.',
        backgroundColor: Color(0xFFFDECEC),
        textColor: AppColors.dangerText,
        icon: AppIcons.cancel_rounded,
      );
    default:
      return const _DetailRequestStatusVisual(
        label: 'Pending',
        description: 'This request is still waiting for action.',
        backgroundColor: Color(0xFFEAF4FB),
        textColor: AppColors.accentBlue,
        icon: AppIcons.inbox_rounded,
      );
  }
}

class _BrokerCounterSliderSheet extends StatefulWidget {
  const _BrokerCounterSliderSheet({
    required this.title,
    required this.bookingLabel,
    required this.initialAmount,
  });

  final String title;
  final String bookingLabel;
  final double initialAmount;

  @override
  State<_BrokerCounterSliderSheet> createState() =>
      _BrokerCounterSliderSheetState();
}

class _BrokerCounterSliderSheetState extends State<_BrokerCounterSliderSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialAmount;
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.initialAmount > 0 ? widget.initialAmount : 1000.0;
    final min = (base * 0.75).clamp(1.0, double.infinity).toDouble();
    final max = (base * 1.25).clamp(min + 1.0, double.infinity).toDouble();
    final value = _value.clamp(min, max).toDouble();

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.bookingLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            _CounterAmountSlider(
              label: 'Set counter amount',
              amount: value,
              minAmount: min,
              maxAmount: max,
              onChanged: (next) => setState(() => _value = next),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(value),
                    child: const Text('Send counter'),
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

class _CounterAmountSlider extends StatelessWidget {
  const _CounterAmountSlider({
    required this.label,
    required this.amount,
    required this.minAmount,
    required this.maxAmount,
    required this.onChanged,
  });

  final String label;
  final double amount;
  final double minAmount;
  final double maxAmount;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final value = amount.clamp(minAmount, maxAmount).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.fillSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.brandFill,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '₹${value.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF2FA56E),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: minAmount,
            max: maxAmount,
            divisions: 100,
            activeColor: AppColors.brand,
            onChanged: onChanged,
          ),
          Row(
            children: [
              Text(
                '₹${minAmount.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textTertiary),
              ),
              const Spacer(),
              Text(
                '₹${maxAmount.toStringAsFixed(0)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BrokerAssignmentSelection {
  const _BrokerAssignmentSelection({required this.driver, required this.truck});

  final BrokerDriver driver;
  final BrokerVehicle truck;
}

class _AssignmentPickerField extends StatelessWidget {
  const _AssignmentPickerField({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.fillSubtle,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              AppIcons.keyboard_arrow_down_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentChoiceSheet<T> extends StatelessWidget {
  const _AssignmentChoiceSheet({
    required this.title,
    required this.emptyText,
    required this.items,
    required this.selectedId,
    required this.idOf,
    required this.enabledOf,
    required this.titleOf,
    required this.subtitleOf,
  });

  final String title;
  final String emptyText;
  final List<T> items;
  final String? selectedId;
  final String Function(T item) idOf;
  final bool Function(T item) enabledOf;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      backgroundColor: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 430),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      AppIcons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ],
              ),
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                child: Text(
                  emptyText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 2),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final id = idOf(item);
                    final enabled = enabledOf(item);
                    final selected = id == selectedId;
                    return InkWell(
                      onTap: enabled
                          ? () => Navigator.of(context).pop(id)
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? AppColors.brandFill
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _AssignmentOptionLabel(
                                title: titleOf(item),
                                subtitle: subtitleOf(item),
                                enabled: enabled,
                              ),
                            ),
                            if (selected)
                              const Icon(
                                AppIcons.check_rounded,
                                color: AppColors.brand,
                                size: 18,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AssignmentOptionLabel extends StatelessWidget {
  const _AssignmentOptionLabel({
    required this.title,
    required this.subtitle,
    required this.enabled,
  });

  final String title;
  final String subtitle;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final titleColor = enabled ? AppColors.textPrimary : AppColors.textTertiary;
    final subtitleColor = enabled ? AppColors.textSecondary : AppColors.line;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: titleColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: subtitleColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

bool _isCancelledDetailStatus(String status) {
  final normalized = status.trim().toLowerCase().replaceAll('-', '_');
  return normalized == 'cancelled' || normalized == 'canceled';
}

String _detailInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'C';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
      .toUpperCase();
}
