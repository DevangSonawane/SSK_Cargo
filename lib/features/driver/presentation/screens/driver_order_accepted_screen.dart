import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/negotiation_timer.dart';
import '../../../../core/widgets/map_route_card.dart';
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
  Timer? _requestRefreshTimer;
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

  bool get _shouldRefreshNegotiationState {
    final status = _latestStatus.trim().toLowerCase();
    return status == 'pending' ||
        status == 'countered' ||
        status == 'awaiting_confirmation';
  }

  String get _currentPendingConfirmationBy =>
      _latestPendingConfirmationBy.isNotEmpty
      ? _latestPendingConfirmationBy
      : _request.pendingConfirmationBy.trim().toLowerCase();

  bool _refreshingRequestState = false;

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
    _dismissClientConfirmationDialog();
    _driverRequestSubscription?.cancel();
    _countdownTimer?.cancel();
    _requestRefreshTimer?.cancel();
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
      if (status == 'awaiting_confirmation' &&
          pendingConfirmationBy == 'client') {
        _counterLocked = false;
      }
      if (_isAcceptedStatus(status) || _isRejectedStatus(status)) {
        _counterLocked = false;
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

  bool _hasPendingConfirmationParty(Map<String, dynamic> payload) {
    return _readPayloadString(payload, const [
      'pendingConfirmationBy',
      'pending_confirmation_by',
    ]).trim().isNotEmpty;
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
                              icon: const Icon(AppIcons.close_rounded),
                              color: AppColors.textTertiary,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: AppColors.brandTint,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.handshake_rounded,
                            color: AppColors.brand,
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
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The client accepted your offer. Please confirm to finalize the booking or reject to decline it.',
                          textAlign: TextAlign.center,
                          style: Theme.of(overlayContext).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
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
                                    : () async {
                                        _suppressClientConfirmationDialog =
                                            true;
                                        _dismissClientConfirmationDialog();
                                        await _runAction(
                                          (token) => ref
                                              .read(apiClientProvider)
                                              .rejectDriverRequestAsDriver(
                                                accessToken: token,
                                                id: _request.id,
                                              ),
                                        );
                                      },
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.dangerText,
                                  side: const BorderSide(
                                    color: AppColors.dangerBorder,
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
                                    : () async {
                                        _suppressClientConfirmationDialog =
                                            true;
                                        _dismissClientConfirmationDialog();
                                        await _runAction(
                                          (token) => ref
                                              .read(apiClientProvider)
                                              .acceptDriverRequestAsDriver(
                                                accessToken: token,
                                                id: _request.id,
                                              ),
                                          resolveTripOnSuccess: true,
                                        );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brand,
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

    _requestRefreshTimer?.cancel();
    _requestRefreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_shouldRefreshNegotiationState) {
        unawaited(_refreshRequestStateFromServer());
      }
    });
  }

  Future<void> _refreshRequestStateFromServer() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final requestId = _request.id.trim();
    if (!mounted ||
        session == null ||
        requestId.isEmpty ||
        _refreshingRequestState ||
        !_shouldRefreshNegotiationState) {
      return;
    }

    _refreshingRequestState = true;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getDriverRequestById(
            accessToken: session.tokens.accessToken,
            id: requestId,
          );
      if (!mounted) {
        return;
      }
      await _handleLivePayload(response);
    } catch (error, stackTrace) {
      developer.log(
        'Driver request refresh failed while waiting for client response.',
        name: 'driver.orderAccepted',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _refreshingRequestState = false;
    }
  }

  Future<void> _goBackToHome() async {
    _forceDismissClientConfirmationDialog();
    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _requestRefreshTimer?.cancel();
    _requestRefreshTimer = null;
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

  Future<void> _completeTripHandoff({
    required String tripId,
    String? bookingId,
    String? bookingNumber,
    String? status,
    String? paymentStatus,
  }) async {
    final resolvedTripId = tripId.trim();
    if (resolvedTripId.isEmpty || !mounted) {
      return;
    }

    _setTripSession(
      tripId: resolvedTripId,
      bookingId: bookingId,
      bookingNumber: bookingNumber,
      status: status,
      paymentStatus: paymentStatus,
    );
    ref.invalidate(driverDashboardProvider);
    _forceDismissClientConfirmationDialog();
    _handoffPollTimer?.cancel();
    _handoffPollTimer = null;
    if (!mounted) {
      return;
    }
    context.go('/driver/active');
  }

  void _goToDriverActiveTab() {
    if (!mounted) {
      return;
    }
    _forceDismissClientConfirmationDialog();
    _requestRefreshTimer?.cancel();
    _requestRefreshTimer = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
    ref.invalidate(driverDashboardProvider);
    context.go('/driver/active');
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
        await _completeTripHandoff(
          tripId: requestTripId,
          bookingId: _request.bookingId,
          bookingNumber: _request.bookingNumber,
          status: requestStatus,
        );
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
            await _completeTripHandoff(
              tripId: bookingTripId,
              bookingId: bookingId,
              bookingNumber: _request.bookingNumber,
              status: bookingStatus,
              paymentStatus: paymentStatus,
            );
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
          await _completeTripHandoff(
            tripId: tripId,
            bookingId: _request.bookingId,
            bookingNumber: _request.bookingNumber,
            status: _readPayloadString(trip, const ['status', 'rawStatus']),
          );
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

  Future<void> _handleLivePayload(Map<String, dynamic> payload) async {
    final normalizedPayload = Map<String, dynamic>.from(
      _extractPayload(payload),
    );
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

    if (status == 'awaiting_confirmation' &&
        !_hasPendingConfirmationParty(normalizedPayload) &&
        _currentPendingConfirmationBy == 'respondent') {
      normalizedPayload['pendingConfirmationBy'] = 'client';
      developer.log(
        'Inferred client confirmation from partial live payload.',
        name: 'driver.orderAccepted',
      );
    }

    _syncLiveRequestState(normalizedPayload);

    if (_isAcceptedStatus(status)) {
      developer.log(
        'Accepted status received from socket. Moving to active trip tab.',
        name: 'driver.orderAccepted',
      );
      _dismissClientConfirmationDialog();
      if (effectiveTripId.isNotEmpty) {
        _setTripSession(
          tripId: effectiveTripId,
          bookingId: _request.bookingId,
          bookingNumber: _request.bookingNumber,
          status: status,
        );
      }
      _stopTripHandoff();
      _goToDriverActiveTab();
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
      _requestRefreshTimer?.cancel();
      _requestRefreshTimer = null;
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
          if (_latestStatus == 'awaiting_confirmation' &&
              _latestPendingConfirmationBy == 'client') {
            _counterLocked = false;
          }
          if (_isAcceptedStatus(_latestStatus) ||
              _isRejectedStatus(_latestStatus)) {
            _counterLocked = false;
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
              responseStatus == 'assigned' ||
              responseStatus == 'awaiting_confirmation')) {
        _dismissClientConfirmationDialog();
        developer.log(
          'Negotiation accepted locally. Moving to active trip tab.',
          name: 'driver.orderAccepted',
        );
        if (effectiveTripId.isNotEmpty) {
          _setTripSession(
            tripId: effectiveTripId,
            bookingId: _request.bookingId,
            bookingNumber: _request.bookingNumber,
            status: responseStatus,
          );
        }
        _stopTripHandoff();
        _goToDriverActiveTab();
        return;
      }

      if (!mounted) return;

      if (responseStatus == 'awaiting_confirmation') {
        _goToDriverActiveTab();
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
            backgroundColor: AppColors.dangerIcon,
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

  Widget _buildStatusPanel({
    required IconData icon,
    required String title,
    required String subtitle,
    bool showSpinner = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner) ...[
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 14),
          ] else ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.brandTint,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: AppColors.brand, size: 26),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoffPanel() {
    if (_handoffTripId?.trim().isNotEmpty ?? true) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.fillSubtle,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _handoffBookingReady
                  ? 'Booking confirmed'
                  : 'Booking is still syncing.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _handoffBookingReady
                  ? 'We are opening the active trip view as soon as the trip is ready.'
                  : 'We check the request, booking, and trip APIs every 5 seconds.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (!_handoffBookingReady) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _refreshTripForHandoff,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brandBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text(
                    'Check now',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }
    return _buildStatusPanel(
      icon: AppIcons.play_circle_fill_rounded,
      title: 'Booking finalized',
      subtitle: 'Opening the active trip view.',
    );
  }

  Widget _buildActionPanel({
    required bool showCounterControls,
    required bool actionLocked,
    required double baseAmount,
    required double minOffer,
    required double maxOffer,
    required double selectedAmount,
  }) {
    final request = _request;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showCounterControls) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Your offer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Base ₹${baseAmount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '₹',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  selectedAmount.toStringAsFixed(0),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Slider(
              value: selectedAmount.clamp(minOffer, maxOffer),
              min: minOffer,
              max: maxOffer,
              divisions: 24,
              activeColor: AppColors.brand,
              inactiveColor: AppColors.line,
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  '₹${maxOffer.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          if (_handoffInProgress) ...[
            _buildHandoffPanel(),
          ] else if (_awaitingDriverConfirmation) ...[
            _buildStatusPanel(
              icon: AppIcons.handshake_rounded,
              title: 'Client accepted your request',
              subtitle:
                  'Confirm or decline from the prompt that appeared above.',
            ),
          ] else if (_waitingOnClient) ...[
            _buildStatusPanel(
              showSpinner: true,
              icon: AppIcons.hourglass_top_rounded,
              title: 'Accepted - waiting for the client to confirm.',
              subtitle: 'We update this in real time.',
            ),
          ] else if (_counterLocked) ...[
            _buildStatusPanel(
              showSpinner: true,
              icon: AppIcons.send_rounded,
              title: 'Counter sent. Waiting for client response...',
              subtitle:
                  'We will unlock the tracking button once the client accepts the offer.',
            ),
          ] else if (showCounterControls) ...[
            SizedBox(
              width: double.infinity,
              height: 56,
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
                  backgroundColor: AppColors.brand,
                  disabledBackgroundColor: AppColors.line,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  _submitting ? 'Saving...' : 'Send counter',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
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
    final actionLocked =
        _submitting ||
        _counterLocked ||
        serverTimedOut ||
        _waitingOnClient ||
        _awaitingDriverConfirmation;
    final brokerAssigned = request.jobRequestId.isNotEmpty;
    final showCounterControls =
        !_handoffInProgress &&
        !_awaitingDriverConfirmation &&
        !_waitingOnClient &&
        !_counterLocked;
    final heroShowCountdown = showCounterControls && !serverTimedOut;
    final String heroTitle;
    if (serverTimedOut) {
      heroTitle = 'Handed over to broker';
    } else if (_handoffInProgress) {
      heroTitle = 'Finalizing the trip';
    } else if (showCounterControls) {
      heroTitle = 'Set your counter offer';
    } else {
      heroTitle = 'Negotiating with the client';
    }
    final String heroChipLabel;
    if (serverTimedOut) {
      heroChipLabel = 'Handed over';
    } else if (_handoffInProgress) {
      heroChipLabel = 'Handoff';
    } else if (showCounterControls) {
      heroChipLabel = _countdownLabel;
    } else {
      heroChipLabel = 'Locked';
    }
    final double? heroProgressValue = heroShowCountdown && remaining != null
        ? (remaining.inMilliseconds / const Duration(minutes: 2).inMilliseconds)
              .clamp(0.0, 1.0)
              .toDouble()
        : null;

    if (brokerAssigned) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(AppIcons.arrow_back_rounded),
            onPressed: () => context.go('/driver/home'),
          ),
          title: const Text('Assigned request'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const _StatusHero(
                icon: AppIcons.assignment_turned_in_rounded,
                title: 'Broker-assigned trip',
                subtitle:
                    'Already agreed with the broker - accept or decline, no counter-offers.',
                chipLabel: 'Fixed price',
              ),
              const SizedBox(height: 14),
              MapRouteCard(
                pickup: request.pickup.isEmpty ? '-' : request.pickup,
                drop: request.drop.isEmpty ? '-' : request.drop,
                showRouteLabels: false,
              ),
              const SizedBox(height: 14),
              _RequestRouteCard(
                refText: request.displayRef,
                amountLabel: 'AGREED AMOUNT',
                amountText: '₹${baseAmount.toStringAsFixed(0)}',
                pickup: request.pickup.isEmpty ? '-' : request.pickup,
                drop: request.drop.isEmpty ? '-' : request.drop,
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fillSubtle,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      AppIcons.info_outline_rounded,
                      size: 18,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This trip was assigned by the broker at the agreed amount. You can decline it if you are not available.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting || serverTimedOut
                          ? null
                          : () => _runAction(
                              (token) => ref
                                  .read(apiClientProvider)
                                  .rejectDriverRequestAsDriver(
                                    accessToken: token,
                                    id: request.id,
                                  ),
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.dangerText,
                        side: const BorderSide(color: AppColors.dangerBorder),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _submitting || serverTimedOut
                          ? null
                          : () => _runAction(
                              (token) => ref
                                  .read(apiClientProvider)
                                  .acceptDriverRequestAsDriver(
                                    accessToken: token,
                                    id: request.id,
                                  ),
                              resolveTripOnSuccess: true,
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(AppIcons.arrow_back_rounded),
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
              _StatusHero(
                isWarning: serverTimedOut,
                icon: serverTimedOut
                    ? AppIcons.support_agent_rounded
                    : AppIcons.handshake_rounded,
                title: heroTitle,
                subtitle: serverTimedOut
                    ? 'Broker controls this request now - waiting for new leads.'
                    : null,
                chipLabel: heroShowCountdown ? null : heroChipLabel,
                clockLabel: heroShowCountdown ? _countdownLabel : null,
                clockFraction: heroProgressValue,
              ),
              const SizedBox(height: 14),
              MapRouteCard(
                pickup: request.pickup.isEmpty ? '-' : request.pickup,
                drop: request.drop.isEmpty ? '-' : request.drop,
                showRouteLabels: false,
              ),
              const SizedBox(height: 14),
              _RequestRouteCard(
                refText: request.displayRef,
                amountLabel: 'BASE OFFER',
                amountText: '₹${baseAmount.toStringAsFixed(0)}',
                pickup: request.pickup.isEmpty ? '-' : request.pickup,
                drop: request.drop.isEmpty ? '-' : request.drop,
                metaChips: [
                  if (serverTimedOut)
                    _MetaChip(
                      icon: AppIcons.support_agent_rounded,
                      text: 'Broker handling',
                    )
                  else if (_clientDecisionReady)
                    _MetaChip(
                      icon: AppIcons.handshake_rounded,
                      text: 'Client responded',
                    )
                  else if (showCounterControls)
                    _MetaChip(
                      icon: AppIcons.bolt_rounded,
                      text: 'Counter window',
                    )
                  else
                    _MetaChip(
                      icon: AppIcons.timer_outlined,
                      text: 'Awaiting response',
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _buildActionPanel(
                showCounterControls: showCounterControls,
                actionLocked: actionLocked,
                baseAmount: baseAmount,
                minOffer: minOffer,
                maxOffer: maxOffer,
                selectedAmount: selectedAmount,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({
    required this.icon,
    required this.title,
    this.subtitle,
    this.chipLabel,
    this.clockLabel,
    this.clockFraction,
    this.isWarning = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? chipLabel;
  final String? clockLabel;
  final double? clockFraction;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final accent = isWarning ? AppColors.warningText : AppColors.brandDark;
    final textColor = isWarning ? AppColors.warningText : Colors.white;
    final iconBg = isWarning
        ? AppColors.warningBorder.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.16);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: isWarning
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brand, AppColors.brandDark],
              ),
        color: isWarning ? AppColors.warningFill : null,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: isWarning ? Border.all(color: AppColors.warningBorder) : null,
        boxShadow: isWarning ? null : AppShadows.brandGlow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: textColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textColor.withValues(alpha: 0.9),
                          height: 1.4,
                        ),
                      ),
                  ],
                ),
              ),
              if (clockLabel != null) ...[
                const SizedBox(width: 10),
                _CountdownClock(
                  label: clockLabel!,
                  fraction: clockFraction ?? 0,
                ),
              ] else if (chipLabel != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    chipLabel!,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _RequestRefChip extends StatelessWidget {
  const _RequestRefChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            AppIcons.assignment_outlined,
            size: 15,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteConnector extends StatelessWidget {
  const _RouteConnector({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 2,
      height: height,
      child: CustomPaint(painter: _DashedLinePainter(color: AppColors.divider)),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    var y = 0.0;
    while (y < size.height) {
      final end = y + dash;
      canvas.drawLine(
        Offset(0, y),
        Offset(0, end > size.height ? size.height : end),
        paint,
      );
      y = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _RouteLabel extends StatelessWidget {
  const _RouteLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: AppColors.textTertiary,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _RouteText extends StatelessWidget {
  const _RouteText({
    required this.title,
    required this.subtitle,
    required this.fallback,
  });

  final String title;
  final String subtitle;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.isEmpty ? fallback : title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            height: 1.25,
          ),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestRouteCard extends StatelessWidget {
  const _RequestRouteCard({
    required this.refText,
    required this.amountLabel,
    required this.amountText,
    required this.pickup,
    required this.drop,
    this.metaChips = const [],
  });

  final String refText;
  final String amountLabel;
  final String amountText;
  final String pickup;
  final String drop;
  final List<Widget> metaChips;

  @override
  Widget build(BuildContext context) {
    final pickupParts = _splitAddress(pickup);
    final dropParts = _splitAddress(drop);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _RequestRefChip(text: refText),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    amountText,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.brand,
                    ),
                  ),
                  const _RouteConnector(height: 36),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.dangerIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _RouteLabel(label: 'Pickup'),
                    const SizedBox(height: 6),
                    _RouteText(
                      title: pickupParts.title,
                      subtitle: pickupParts.subtitle,
                      fallback: 'Pickup location',
                    ),
                    const SizedBox(height: 18),
                    const _RouteLabel(label: 'Drop off'),
                    const SizedBox(height: 6),
                    _RouteText(
                      title: dropParts.title,
                      subtitle: dropParts.subtitle,
                      fallback: 'Drop location',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (metaChips.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: metaChips),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressParts {
  const _AddressParts({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

_AddressParts _splitAddress(String raw) {
  final value = raw.trim();
  if (value.isEmpty) {
    return const _AddressParts(title: '', subtitle: '');
  }
  const separators = ['\n', ' - ', ' | ', ', '];
  for (final separator in separators) {
    final index = value.indexOf(separator);
    if (index > 0) {
      final title = value.substring(0, index).trim();
      final subtitle = value.substring(index + separator.length).trim();
      if (title.isNotEmpty) {
        return _AddressParts(title: title, subtitle: subtitle);
      }
    }
  }
  return _AddressParts(title: value, subtitle: '');
}

Map<String, dynamic> _extractPayload(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    final nestedRequest = _nestedRequestPayload(data);
    if (nestedRequest != null) return nestedRequest;
    return data;
  }

  final request = _nestedRequestPayload(response);
  if (request != null) return request;

  return response;
}

Map<String, dynamic>? _nestedRequestPayload(Map<String, dynamic> source) {
  for (final key in const [
    'request',
    'driverRequest',
    'driver_request',
    'jobRequest',
    'job_request',
  ]) {
    final request = source[key];
    if (request is Map<String, dynamic>) {
      return request;
    }
    if (request is Map) {
      return request.cast<String, dynamic>();
    }
  }
  return null;
}

class _CountdownClock extends StatefulWidget {
  const _CountdownClock({required this.label, required this.fraction});

  final String label;
  final double fraction;

  @override
  State<_CountdownClock> createState() => _CountdownClockState();
}

class _CountdownClockState extends State<_CountdownClock>
    with SingleTickerProviderStateMixin {
  static const Color _green = Color(0xFF22C55E);
  static const Color _amber = Color(0xFFF57C00);
  static const Color _red = Color(0xFFDC2626);

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static Color _zoneColor(double fraction) {
    if (fraction > 0.45) return _green;
    if (fraction > 0.2) return _amber;
    return _red;
  }

  @override
  Widget build(BuildContext context) {
    final fraction = widget.fraction.clamp(0.0, 1.0).toDouble();
    final urgent = fraction <= 0.2;
    return TweenAnimationBuilder<Color>(
      tween: Tween<Color>(begin: _green, end: _zoneColor(fraction)),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, color, child) {
        return AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            final scale = urgent ? 1.0 + _pulseController.value * 0.08 : 1.0;
            return Transform.scale(scale: scale, child: child);
          },
          child: SizedBox(
            width: 66,
            height: 66,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    shape: BoxShape.circle,
                  ),
                ),
                CustomPaint(
                  size: const Size(66, 66),
                  painter: _CountdownRingPainter(
                    color: color,
                    fraction: fraction,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.timer_outlined, size: 13, color: color),
                    Text(
                      widget.label,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: color,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({required this.color, required this.fraction});

  final Color color;
  final double fraction;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 5.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFDFE6EC);
    canvas.drawCircle(center, radius, trackPaint);

    final progress = fraction.clamp(0.0, 1.0);
    if (progress > 0) {
      final arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = color;
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.fraction != fraction;
}
