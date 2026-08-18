import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/utils/negotiation_timer.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_dashboard_models.dart';
import '../../data/driver_request_models.dart';
import '../../data/driver_trip_handoff_utils.dart';

class DriverOrderAcceptedScreen extends ConsumerStatefulWidget {
  const DriverOrderAcceptedScreen({super.key, this.initialRequest});

  final Object? initialRequest;

  @override
  ConsumerState<DriverOrderAcceptedScreen> createState() =>
      _DriverOrderAcceptedScreenState();
}

class _DriverOrderAcceptedScreenState
    extends ConsumerState<DriverOrderAcceptedScreen> {
  bool _submitting = false;
  bool _resolvingTrip = false;
  bool _counterLocked = false;
  bool _handoffInProgress = false;
  bool _handoffBookingReady = false;
  bool _clientConfirmationDialogVisible = false;
  bool _suppressClientConfirmationDialog = false;
  late double _counterAmount;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  Timer? _countdownTimer;
  Timer? _handoffPollTimer;
  OverlayEntry? _clientConfirmationDialogEntry;
  String _latestStatus = '';
  String _latestPendingConfirmationBy = '';
  bool _latestDriverTimedOut = false;
  DateTime? _latestUpdatedAt;
  String? _handoffTripId;

  DriverRequestItem get _request =>
      DriverRequestItem.fromExtra(widget.initialRequest);

  bool get _clientDecisionReady =>
      _isAcceptedStatus(_latestStatus) ||
      _isRejectedStatus(_latestStatus) ||
      (_latestStatus == 'awaiting_confirmation' &&
          _currentPendingConfirmationBy == 'client');

  bool get _awaitingDriverConfirmation =>
      _latestStatus == 'awaiting_confirmation' &&
      _currentPendingConfirmationBy == 'client';

  bool get _waitingOnClient =>
      _latestStatus == 'awaiting_confirmation' &&
      _currentPendingConfirmationBy == 'respondent';

  String get _currentPendingConfirmationBy =>
      _latestPendingConfirmationBy.isNotEmpty
      ? _latestPendingConfirmationBy
      : _request.pendingConfirmationBy.trim().toLowerCase();

  @override
  void initState() {
    super.initState();
    final request = DriverRequestItem.fromExtra(widget.initialRequest);
    _counterAmount = request.amount > 0 ? request.amount : 1000;
    _latestStatus = request.status.trim().toLowerCase();
    _latestPendingConfirmationBy = request.pendingConfirmationBy
        .trim()
        .toLowerCase();
    _latestDriverTimedOut = request.driverTimedOut;
    _latestUpdatedAt = request.updatedAt ?? request.requestedAt;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_startLiveUpdates());
        if (_isAcceptedStatus(_latestStatus)) {
          unawaited(_beginTripHandoff(tripId: request.tripId.trim()));
        }
      }
    });
  }

  @override
  void dispose() {
    _driverRequestSubscription?.cancel();
    _countdownTimer?.cancel();
    _handoffPollTimer?.cancel();
    super.dispose();
  }

  bool _payloadMatchesTarget(Map<String, dynamic> payload) {
    final request = _request;
    return responseMatchesAnyReference(_extractPayload(payload), [
      request.id,
      request.bookingId,
      request.bookingNumber,
      request.tripId,
    ]);
  }

  String _readPayloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  bool _isAcceptedStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'accepted' ||
        normalized == 'confirmed' ||
        normalized == 'assigned';
  }

  bool _isRejectedStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'declined' ||
        normalized == 'rejected' ||
        normalized == 'cancelled' ||
        normalized == 'expired';
  }

  bool _readPayloadBool(Map<String, dynamic> payload, List<String> keys) {
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

  DateTime? _readPayloadDateTime(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
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

  bool get _serverTimedOut => _latestDriverTimedOut || _request.driverTimedOut;

  DateTime? get _countdownAnchor =>
      _latestUpdatedAt ?? _request.updatedAt ?? _request.requestedAt;

  Duration? get _negotiationRemaining => negotiationWindowRemaining(
    anchorAt: _countdownAnchor,
    driverTimedOut: _serverTimedOut,
  );

  String get _countdownLabel {
    if (_serverTimedOut) {
      return 'Broker takeover';
    }

    if (_counterLocked || _waitingOnClient || _awaitingDriverConfirmation) {
      return 'Locked';
    }

    final remaining = _negotiationRemaining;
    if (remaining == null) {
      return '2:00';
    }
    if (remaining <= Duration.zero) {
      return 'Any moment now';
    }
    return formatCountdown(remaining);
  }

  void _syncLiveRequestState(Map<String, dynamic> payload) {
    final status = _readPayloadString(payload, const [
      'status',
      'requestStatus',
      'request_status',
      'clientStatus',
      'client_status',
    ]).trim().toLowerCase();
    final pendingConfirmationBy = _readPayloadString(payload, const [
      'pendingConfirmationBy',
      'pending_confirmation_by',
    ]).trim().toLowerCase();
    final driverTimedOut = _readPayloadBool(payload, const [
      'driverTimedOut',
      'driver_timed_out',
    ]);
    final updatedAt = _readPayloadDateTime(payload, const [
      'updatedAt',
      'updated_at',
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      if (status.isNotEmpty) {
        _latestStatus = status;
      }
      if (pendingConfirmationBy.isNotEmpty) {
        _latestPendingConfirmationBy = pendingConfirmationBy;
      }
      if (driverTimedOut) {
        _latestDriverTimedOut = true;
      }
      if (updatedAt != null) {
        _latestUpdatedAt = updatedAt;
      }
    });

    if (_latestStatus != 'awaiting_confirmation' ||
        _currentPendingConfirmationBy != 'client') {
      _suppressClientConfirmationDialog = false;
    }

    _syncClientConfirmationDialogVisibility();
  }

  void _stopTripHandoff() {
    _handoffPollTimer?.cancel();
    _handoffPollTimer = null;
    if (!mounted) {
      return;
    }
    setState(() {
      _handoffInProgress = false;
      _handoffBookingReady = false;
      _handoffTripId = null;
    });
  }

  bool get _shouldShowClientConfirmationDialog =>
      !_suppressClientConfirmationDialog &&
      _latestStatus == 'awaiting_confirmation' &&
      _currentPendingConfirmationBy == 'client';

  void _syncClientConfirmationDialogVisibility() {
    if (!mounted) {
      return;
    }

    if (_shouldShowClientConfirmationDialog) {
      if (_clientConfirmationDialogEntry == null &&
          !_clientConfirmationDialogVisible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _shouldShowClientConfirmationDialog) {
            _showClientConfirmationDialog();
          }
        });
      }
      return;
    }

    _dismissClientConfirmationDialog();
  }

  void _showClientConfirmationDialog() {
    if (!mounted || !_shouldShowClientConfirmationDialog) {
      return;
    }
    if (_clientConfirmationDialogVisible) {
      return;
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    _clientConfirmationDialogVisible = true;
    _clientConfirmationDialogEntry?.remove();
    _clientConfirmationDialogEntry = OverlayEntry(
      builder: (overlayContext) {
        return Material(
          color: Colors.black.withValues(alpha: 0.42),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: _dismissClientConfirmationDialog,
                              icon: const Icon(Icons.close_rounded),
                              color: const Color(0xFF98A2B3),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF7EF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: Color(0xFF2FA56E),
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Client accepted the request',
                          textAlign: TextAlign.center,
                          style: Theme.of(overlayContext).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The client accepted your offer. Please confirm to finalize the booking or reject to decline it.',
                          textAlign: TextAlign.center,
                          style: Theme.of(overlayContext).textTheme.bodyMedium
                              ?.copyWith(
                                color: const Color(0xFF667085),
                                height: 1.45,
                              ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        _forceDismissClientConfirmationDialog();
                                        unawaited(
                                          _runAction(
                                            (token) => ref
                                                .read(apiClientProvider)
                                                .rejectDriverRequestAsDriver(
                                                  accessToken: token,
                                                  id: _request.id,
                                                ),
                                          ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE23A4B),
                                  side: const BorderSide(
                                    color: Color(0xFFF3B4B4),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Reject',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: _submitting
                                    ? null
                                    : () {
                                        _forceDismissClientConfirmationDialog();
                                        unawaited(
                                          _runAction(
                                            (token) => ref
                                                .read(apiClientProvider)
                                                .acceptDriverRequestAsDriver(
                                                  accessToken: token,
                                                  id: _request.id,
                                                ),
                                            resolveTripOnSuccess: true,
                                          ),
                                        );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2D6EF2),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.4,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Accept',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_clientConfirmationDialogEntry!);
  }

  void _dismissClientConfirmationDialog() {
    _clientConfirmationDialogEntry?.remove();
    _clientConfirmationDialogEntry = null;
    _clientConfirmationDialogVisible = false;
  }

  void _forceDismissClientConfirmationDialog() {
    _suppressClientConfirmationDialog = true;
    _dismissClientConfirmationDialog();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _suppressClientConfirmationDialog = true;
      _dismissClientConfirmationDialog();
    });
  }

  void _setTripSession({
    required String tripId,
    String? bookingId,
    String? bookingNumber,
    String? status,
    String? paymentStatus,
  }) {
    final resolvedTripId = tripId.trim();
    if (resolvedTripId.isEmpty) {
      return;
    }

    ref.read(driverActiveTripIdProvider.notifier).state = resolvedTripId;
    ref.read(driverTripSessionProvider.notifier).state = DriverTripSession(
      tripId: resolvedTripId,
      bookingId: bookingId?.trim().isNotEmpty == true
          ? bookingId!.trim()
          : null,
      bookingNumber: bookingNumber?.trim().isNotEmpty == true
          ? bookingNumber!.trim()
          : null,
      status: status?.trim().isNotEmpty == true ? status!.trim() : null,
      paymentStatus: paymentStatus?.trim().isNotEmpty == true
          ? paymentStatus!.trim()
          : null,
    );
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      developer.log(
        'Driver request live updates skipped: missing session or unmounted.',
        name: 'driver.orderAccepted',
      );
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    developer.log(
      'Subscribing to shared driver request websocket on negotiation screen.',
      name: 'driver.orderAccepted',
    );

    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      developer.log(
        'driver-request-updated received on negotiation screen: $payload',
        name: 'driver.orderAccepted',
      );
      if (!mounted || !_payloadMatchesTarget(payload)) {
        developer.log(
          'driver-request-updated ignored: no matching request context.',
          name: 'driver.orderAccepted',
        );
        return;
      }
      developer.log(
        'driver-request-updated matched current request. Handling live payload.',
        name: 'driver.orderAccepted',
      );
      unawaited(_handleLivePayload(payload));
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _goBackToHome() async {
    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _handoffPollTimer?.cancel();
    _handoffPollTimer = null;
    if (!mounted) return;
    context.go('/driver/home');
  }

  Future<void> _beginTripHandoff({
    String? tripId,
    bool preserveBookingReady = false,
  }) async {
    final effectiveTripId = tripId?.trim() ?? '';
    if (!mounted) return;

    setState(() {
      _handoffInProgress = true;
      _handoffBookingReady = preserveBookingReady || _handoffBookingReady;
      if (effectiveTripId.isNotEmpty) {
        _handoffTripId = effectiveTripId;
      }
    });

    _handoffPollTimer?.cancel();
    _handoffPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      unawaited(_refreshTripForHandoff());
    });

    unawaited(_refreshTripForHandoff());
  }

  Future<void> _refreshTripForHandoff() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (!mounted || session == null || _resolvingTrip) {
      return;
    }

    _resolvingTrip = true;
    try {
      final requestResponse = await ref
          .read(apiClientProvider)
          .getDriverRequestById(
            accessToken: session.tokens.accessToken,
            id: _request.id,
          );
      developer.log(
        'Handoff request response received: $requestResponse',
        name: 'driver.orderAccepted',
      );
      final requestPayload = _extractPayload(requestResponse);
      final requestTripId = extractTripId(requestPayload);
      final requestStatus = _readPayloadString(requestPayload, const [
        'status',
        'requestStatus',
        'request_status',
        'clientStatus',
        'client_status',
      ]).trim().toLowerCase();

      if (requestTripId.isNotEmpty && mounted) {
        setState(() {
          _handoffTripId = requestTripId;
          _handoffBookingReady = true;
          if (requestStatus.isNotEmpty) {
            _latestStatus = requestStatus;
          }
        });
        _setTripSession(
          tripId: requestTripId,
          bookingId: _request.bookingId,
          bookingNumber: _request.bookingNumber,
          status: requestStatus,
        );
        _handoffPollTimer?.cancel();
        _handoffPollTimer = null;
        return;
      }

      final bookingId = _request.bookingId.trim();
      if (bookingId.isNotEmpty) {
        final bookingResponse = await ref
            .read(apiClientProvider)
            .getBookingById(
              accessToken: session.tokens.accessToken,
              id: bookingId,
            );
        developer.log(
          'Handoff booking response received: $bookingResponse',
          name: 'driver.orderAccepted',
        );
        final bookingData = bookingResponse['data'];
        final booking = bookingData is Map<String, dynamic>
            ? (bookingData['booking'] is Map<String, dynamic>
                  ? bookingData['booking'] as Map<String, dynamic>
                  : bookingData)
            : bookingResponse;
        final bookingTripId = extractTripId(booking);
        final bookingStatus = _readPayloadString(booking, const [
          'status',
          'bookingStatus',
          'booking_status',
        ]).trim().toLowerCase();
        final paymentStatus = _readPayloadString(booking, const [
          'paymentStatus',
          'payment_status',
        ]).trim().toLowerCase();
        final bookingReady =
            bookingStatus == 'confirmed' ||
            bookingStatus == 'assigned' ||
            bookingStatus == 'paid' ||
            bookingStatus == 'completed' ||
            paymentStatus == 'paid' ||
            paymentStatus == 'confirmed' ||
            paymentStatus == 'settled';
        if (mounted && (bookingReady || bookingTripId.isNotEmpty)) {
          setState(() {
            _handoffBookingReady = true;
            if (bookingTripId.isNotEmpty) {
              _handoffTripId = bookingTripId;
            }
          });
          if (bookingTripId.isNotEmpty) {
            _setTripSession(
              tripId: bookingTripId,
              bookingId: bookingId,
              bookingNumber: _request.bookingNumber,
              status: bookingStatus,
              paymentStatus: paymentStatus,
            );
          }
          if (bookingTripId.isNotEmpty) {
            _handoffPollTimer?.cancel();
            _handoffPollTimer = null;
            return;
          }
        }
      }

      final response = await ref
          .read(apiClientProvider)
          .getActiveTrip(accessToken: session.tokens.accessToken);
      developer.log(
        'Handoff active trip response received: $response',
        name: 'driver.orderAccepted',
      );
      final trip = extractTripFromResponse(response);
      final tripId = trip == null ? '' : extractTripId(trip);
      if (trip != null && tripId.isNotEmpty) {
        final matchesRequest = tripMatchesContext(
          trip,
          bookingId: _request.bookingId,
          bookingNumber: _request.bookingNumber,
          tripId: _request.tripId,
        );
        if (!matchesRequest) {
          developer.log(
            'Handoff active trip matched a trip id but booking context differed. '
            'tripId=$tripId requestBookingId=${_request.bookingId} '
            'requestBookingNumber=${_request.bookingNumber} requestTripId=${_request.tripId}',
            name: 'driver.orderAccepted',
          );
        }
        if (mounted) {
          setState(() {
            _handoffTripId = tripId;
            _handoffBookingReady = true;
          });
          _setTripSession(
            tripId: tripId,
            bookingId: _request.bookingId,
            bookingNumber: _request.bookingNumber,
            status: _readPayloadString(trip, const ['status', 'rawStatus']),
          );
        }
        if (mounted) {
          _handoffPollTimer?.cancel();
          _handoffPollTimer = null;
        }
      }
    } catch (error) {
      developer.log(
        'Handoff trip lookup failed: $error',
        name: 'driver.orderAccepted',
      );
    } finally {
      _resolvingTrip = false;
    }
  }

  Future<void> _startDelivery() async {
    final tripId = _handoffTripId?.trim() ?? '';
    final bookingId = _request.bookingId.trim();
    if (tripId.isEmpty) {
      await _refreshTripForHandoff();
    }

    final resolvedTripId = _handoffTripId?.trim() ?? '';
    if (resolvedTripId.isNotEmpty) {
      _setTripSession(
        tripId: resolvedTripId,
        bookingId: bookingId,
        bookingNumber: _request.bookingNumber,
      );
    }

    _handoffPollTimer?.cancel();
    _handoffPollTimer = null;
    ref.invalidate(driverDashboardProvider);
    developer.log(
      'Start delivery moving driver to active tab. tripId=$resolvedTripId bookingId=$bookingId',
      name: 'driver.orderAccepted',
    );
    if (!mounted) return;
    context.go('/driver/active');
  }

  Future<void> _handleLivePayload(Map<String, dynamic> payload) async {
    final normalizedPayload = _extractPayload(payload);
    final status = _readPayloadString(normalizedPayload, const [
      'status',
      'requestStatus',
      'request_status',
      'clientStatus',
      'client_status',
    ]).trim().toLowerCase();
    final effectiveTripId = extractTripId(
      normalizedPayload,
      fallback: _request.tripId,
    );

    developer.log(
      'Handling live payload on negotiation screen. status=$status tripId=$effectiveTripId',
      name: 'driver.orderAccepted',
    );

    _syncLiveRequestState(normalizedPayload);

    if (_isAcceptedStatus(status)) {
      developer.log(
        'Accepted status received from socket. Starting trip polling.',
        name: 'driver.orderAccepted',
      );
      _dismissClientConfirmationDialog();
      await _beginTripHandoff(
        tripId: effectiveTripId.isNotEmpty ? effectiveTripId : null,
      );
      return;
    }

    if (_latestStatus == 'awaiting_confirmation' ||
        _latestStatus == 'countered' ||
        _latestStatus == 'pending') {
      _stopTripHandoff();
    }

    if (_isRejectedStatus(status)) {
      developer.log(
        'Rejected status received from socket. Sending driver back home.',
        name: 'driver.orderAccepted',
      );
      _dismissClientConfirmationDialog();
      if (!mounted) return;
      ref.invalidate(driverRequestsProvider);
      context.go('/driver/home');
      return;
    }

    if (mounted && (status == 'countered' || status == 'accepted')) {
      setState(() {
        _counterLocked = true;
      });
    }
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function(String accessToken) action, {
    bool resolveTripOnSuccess = false,
    bool isCounter = false,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final response = await action(session.tokens.accessToken);
      developer.log(
        'Negotiation action completed successfully. response=$response',
        name: 'driver.orderAccepted',
      );
      final payload = _extractPayload(response);
      final request = DriverRequestItem.fromMap(payload);
      final effectiveTripId = extractTripId(payload, fallback: request.tripId);
      developer.log(
        'Negotiation payload resolved. tripId=$effectiveTripId requestId=${request.id}',
        name: 'driver.orderAccepted',
      );

      if (mounted) {
        setState(() {
          if (request.status.trim().isNotEmpty) {
            _latestStatus = request.status.trim().toLowerCase();
          }
          if (request.pendingConfirmationBy.trim().isNotEmpty) {
            _latestPendingConfirmationBy = request.pendingConfirmationBy
                .trim()
                .toLowerCase();
          }
          if (request.driverTimedOut) {
            _latestDriverTimedOut = true;
          }
          if (request.updatedAt != null) {
            _latestUpdatedAt = request.updatedAt;
          }
        });
      }

      final responseStatus = request.status.trim().toLowerCase();
      if (responseStatus == 'awaiting_confirmation' && mounted) {
        setState(() {
          _counterLocked = true;
        });
        _stopTripHandoff();
        _syncClientConfirmationDialogVisibility();
      }

      if (isCounter && mounted) {
        setState(() {
          _counterLocked = true;
        });
      }

      if (resolveTripOnSuccess &&
          (responseStatus == 'accepted' ||
              responseStatus == 'confirmed' ||
              responseStatus == 'assigned')) {
        _dismissClientConfirmationDialog();
        developer.log(
          'Negotiation accepted locally. Starting trip polling.',
          name: 'driver.orderAccepted',
        );
        await _beginTripHandoff(
          tripId: effectiveTripId.isNotEmpty ? effectiveTripId : null,
          preserveBookingReady: true,
        );
        return;
      }

      if (!mounted) return;

      if (responseStatus == 'awaiting_confirmation') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accepted - waiting for the other side to confirm.'),
          ),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request updated successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (resolveTripOnSuccess &&
          (error.statusCode == 400 || error.statusCode == 409)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This offer is no longer available.'),
            backgroundColor: Color(0xFFE23A4B),
          ),
        );
        ref.invalidate(driverRequestFeedProvider);
        ref.invalidate(driverRequestsProvider);
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/driver/home');
        }
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      _forceDismissClientConfirmationDialog();
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final baseAmount = request.amount > 0 ? request.amount : 1000.0;
    final minOffer = math.max(1.0, baseAmount * 0.7);
    final maxOffer = math.max(minOffer + 1, baseAmount * 1.3);
    final selectedAmount = _counterAmount.clamp(minOffer, maxOffer).toDouble();
    final serverTimedOut = _serverTimedOut;
    final remaining = _negotiationRemaining;
    final handoffText = negotiationWindowStatusText(
      remaining: remaining,
      serverTimedOut: serverTimedOut,
      activeLabel: 'Broker handoff in',
      expiredLabel: 'Broker will take over negotiation',
      fallbackLabel: _counterLocked
          ? 'Counter sent. Waiting for the other side to respond.'
          : 'This request waits for 2 minutes before broker handoff.',
    );
    final actionLocked =
        _submitting ||
        _counterLocked ||
        serverTimedOut ||
        _waitingOnClient ||
        _awaitingDriverConfirmation;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBackToHome,
        ),
        title: const Text('Driver request'),
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          unawaited(_goBackToHome());
        },
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: serverTimedOut
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: serverTimedOut
                        ? const Color(0xFFFECF9E)
                        : const Color(0xFFB7D7F0),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      serverTimedOut
                          ? Icons.support_agent_rounded
                          : Icons.timer_outlined,
                      color: serverTimedOut
                          ? const Color(0xFFB54708)
                          : const Color(0xFF1F88C9),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serverTimedOut
                                ? 'Broker will take over negotiation'
                                : 'Client is waiting for your request',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: serverTimedOut
                                      ? const Color(0xFF9A5B13)
                                      : const Color(0xFF1F88C9),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            handoffText,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: serverTimedOut
                                      ? const Color(0xFF9A5B13)
                                      : const Color(0xFF406B8F),
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _countdownLabel,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: serverTimedOut
                                  ? const Color(0xFF9A5B13)
                                  : const Color(0xFF1F88C9),
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF7EF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.handshake_rounded,
                            color: Color(0xFF2FA56E),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _clientDecisionReady
                                    ? 'Client response received'
                                    : 'Request ready',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF101828),
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _clientDecisionReady
                                    ? 'Client has responded. Choose whether to continue or decline.'
                                    : 'Send a counter first. Accept and reject stay locked until the client responds.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF667085),
                                      height: 1.35,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _SummaryPill(label: 'Request', value: request.displayRef),
                    const SizedBox(height: 10),
                    _SummaryPill(
                      label: 'Pickup',
                      value: request.pickup.isNotEmpty ? request.pickup : '-',
                    ),
                    const SizedBox(height: 10),
                    _SummaryPill(
                      label: 'Drop',
                      value: request.drop.isNotEmpty ? request.drop : '-',
                    ),
                    const SizedBox(height: 10),
                    _SummaryPill(
                      label: 'Base offer',
                      value: '₹${baseAmount.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Counter amount',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Slide to set your counter amount before you confirm the request.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Offer price',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '₹${selectedAmount.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: const Color(0xFF2FA56E),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Slider(
                            value: selectedAmount.clamp(minOffer, maxOffer),
                            min: minOffer,
                            max: maxOffer,
                            divisions: 24,
                            activeColor: const Color(0xFF2FA56E),
                            inactiveColor: const Color(0xFFE4E7EC),
                            label: '₹${selectedAmount.toStringAsFixed(0)}',
                            onChanged: actionLocked
                                ? null
                                : (value) {
                                    setState(() {
                                      _counterAmount = value;
                                    });
                                  },
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '₹${minOffer.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF98A2B3)),
                              ),
                              Text(
                                '₹${maxOffer.toStringAsFixed(0)}',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: const Color(0xFF98A2B3)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_handoffInProgress) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_handoffTripId?.isEmpty ?? true) ...[
                              const SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.6,
                                  color: Color(0xFF1F88C9),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _handoffBookingReady
                                    ? 'Booking confirmed'
                                    : 'Booking is still syncing.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF101828),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _handoffBookingReady
                                    ? 'Tap start delivery to open the trip details while we finish resolving the trip.'
                                    : 'We check the request, booking, and trip APIs every 5 seconds.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF667085),
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: _handoffBookingReady
                                    ? FilledButton(
                                        onPressed: _startDelivery,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF1F88C9,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Start Delivery',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      )
                                    : OutlinedButton(
                                        onPressed: _refreshTripForHandoff,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF1F88C9,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFFB7D7F0),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Check now',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                              ),
                            ] else ...[
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF7EF),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: const Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Color(0xFF2FA56E),
                                  size: 30,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Booking finalized',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF101828),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap start delivery to open the trip details.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF667085),
                                      height: 1.35,
                                    ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _startDelivery,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F88C9),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    'Start Delivery',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ] else if (_waitingOnClient) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Color(0xFF1F88C9),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Accepted - waiting for the client to confirm.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_waitingOnClient) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Column(
                          children: [
                            const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Color(0xFF1F88C9),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Accepted - waiting for the other side to confirm.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else if (_counterLocked) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFD),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.6,
                                color: Color(0xFF1F88C9),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Counter sent. Waiting for client response...',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'We will unlock the tracking button once the client accepts the offer.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF667085),
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: actionLocked
                              ? null
                              : () => _runAction(
                                  (token) => ref
                                      .read(apiClientProvider)
                                      .counterDriverRequestAsDriver(
                                        accessToken: token,
                                        id: request.id,
                                        amount: selectedAmount,
                                      ),
                                  isCounter: true,
                                ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1F88C9),
                            disabledBackgroundColor: const Color(0xFFD0D5DD),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            _submitting
                                ? 'Saving...'
                                : serverTimedOut
                                ? 'Broker takeover'
                                : 'Send counter',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w700,
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Map<String, dynamic> _extractPayload(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    final nestedRequest = data['request'];
    if (nestedRequest is Map<String, dynamic>) {
      return nestedRequest;
    }
    return data;
  }

  final request = response['request'];
  if (request is Map<String, dynamic>) {
    return request;
  }

  return response;
}
