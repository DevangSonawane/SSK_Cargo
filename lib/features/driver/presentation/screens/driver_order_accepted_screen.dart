import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_location_tracker_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_request_models.dart';

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
  bool _accepted = false;
  bool _trackRideReady = false;
  bool _counterLocked = false;
  bool _brokerHandoffVisible = false;
  late double _counterAmount;
  int _secondsUntilBrokerHandoff = 120;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  Timer? _handoffTimer;
  String _resolvedTripId = '';
  String _resolvedTripStatus = '';

  DriverRequestItem get _request =>
      DriverRequestItem.fromExtra(widget.initialRequest);

  @override
  void initState() {
    super.initState();
    final request = DriverRequestItem.fromExtra(widget.initialRequest);
    _counterAmount = request.amount > 0 ? request.amount : 1000;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_startLiveUpdates());
      }
    });
  }

  @override
  void dispose() {
    _driverRequestSubscription?.cancel();
    _handoffTimer?.cancel();
    super.dispose();
  }

  bool _payloadMatchesTarget(Map<String, dynamic> payload) {
    final values = <String>{
      _readPayloadString(payload, const [
        'id',
        'request_id',
        'driver_request_id',
      ]),
      _readPayloadString(payload, const ['bookingId', 'booking_id']),
      _readPayloadString(payload, const ['bookingNumber', 'booking_number']),
      _readPayloadString(payload, const ['tripId', 'trip_id']),
    }..removeWhere((value) => value.isEmpty);

    final request = _request;
    final targetValues = <String>{
      request.id,
      request.bookingId,
      request.bookingNumber,
      request.tripId,
    }..removeWhere((value) => value.isEmpty);
    return values.any(targetValues.contains);
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

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );
    if (!mounted) {
      return;
    }

    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      if (!mounted || !_payloadMatchesTarget(payload)) {
        return;
      }
      unawaited(_handleLivePayload(payload));
    });

    _handoffTimer?.cancel();
    _handoffTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      if (_secondsUntilBrokerHandoff <= 0) {
        if (!_brokerHandoffVisible) {
          setState(() {
            _brokerHandoffVisible = true;
          });
        }
        return;
      }

      setState(() {
        _secondsUntilBrokerHandoff -= 1;
        if (_secondsUntilBrokerHandoff <= 0) {
          _secondsUntilBrokerHandoff = 0;
          _brokerHandoffVisible = true;
        }
      });
    });
  }

  Future<void> _handleLivePayload(Map<String, dynamic> payload) async {
    final status = _readPayloadString(payload, const [
      'status',
      'requestStatus',
      'request_status',
      'clientStatus',
      'client_status',
    ]).trim().toLowerCase();
    final effectiveTripId = _extractTripId(payload, _request.tripId).trim();

    if (_isAcceptedStatus(status) && effectiveTripId.isNotEmpty) {
      await _resolveTripAndShowTrackOption(fallbackTripId: effectiveTripId);
      return;
    }

    if (_isRejectedStatus(status)) {
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
      final payload = _extractPayload(response);
      final request = DriverRequestItem.fromMap(payload);
      final effectiveTripId = _extractTripId(payload, request.tripId).trim();

      if (isCounter && mounted) {
        setState(() {
          _counterLocked = true;
        });
      }

      if (resolveTripOnSuccess && effectiveTripId.isNotEmpty) {
        await _resolveTripAndShowTrackOption(fallbackTripId: effectiveTripId);
        return;
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request updated successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _resolveTripAndShowTrackOption({
    required String fallbackTripId,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      return;
    }

    String tripId = fallbackTripId;
    String tripStatus = '';
    try {
      final response = await ref
          .read(apiClientProvider)
          .getUpcomingTrip(accessToken: session.tokens.accessToken);
      final data = response['data'];
      final trip = data is Map<String, dynamic>
          ? (data['trip'] is Map<String, dynamic>
                ? data['trip'] as Map<String, dynamic>
                : data)
          : response;
      tripId = _extractTripId(trip, fallbackTripId).trim();
      tripStatus = _readPayloadString(trip, const [
        'status',
        'rawStatus',
      ]).trim().toLowerCase();
    } catch (_) {
      // Fall back to the trip id already known from the negotiation payload.
    }

    if (tripId.isEmpty || !mounted) {
      return;
    }

    ref.read(driverLocationTrackerProvider).setActiveTripId(tripId);
    final readyToTrack = tripStatus == 'confirmed' || tripStatus == 'accepted';
    if (!mounted) return;
    setState(() {
      _accepted = true;
      _resolvedTripId = tripId;
      _resolvedTripStatus = tripStatus;
      _trackRideReady = readyToTrack;
    });
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final baseAmount = request.amount > 0 ? request.amount : 1000.0;
    final minOffer = math.max(1.0, baseAmount * 0.7);
    final maxOffer = math.max(minOffer + 1, baseAmount * 1.3);
    final selectedAmount = _counterAmount.clamp(minOffer, maxOffer).toDouble();
    final handoffExpired =
        _brokerHandoffVisible ||
        request.driverTimedOut ||
        _secondsUntilBrokerHandoff <= 0;
    final actionLocked = _submitting || _counterLocked || handoffExpired;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Driver request'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: handoffExpired
                    ? const Color(0xFFFFF7ED)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: handoffExpired
                      ? const Color(0xFFFECF9E)
                      : const Color(0xFFB7D7F0),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    handoffExpired
                        ? Icons.support_agent_rounded
                        : Icons.timer_outlined,
                    color: handoffExpired
                        ? const Color(0xFFB54708)
                        : const Color(0xFF1F88C9),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          handoffExpired
                              ? 'Broker will take over negotiation'
                              : 'Client is waiting for your request',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: handoffExpired
                                    ? const Color(0xFF9A5B13)
                                    : const Color(0xFF1F88C9),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          handoffExpired
                              ? 'The driver window is up. Broker will negotiate now, kindly wait.'
                              : 'This request waits for 2 minutes before broker handoff.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: handoffExpired
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
                      handoffExpired
                          ? 'Now waiting'
                          : '00:${_secondsUntilBrokerHandoff.toString().padLeft(2, '0')}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: handoffExpired
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
                              'Request ready',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Review the request, send a counter, or accept it to unlock the trip screens.',
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
                          onChanged: _submitting
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
                            : handoffExpired
                            ? 'Broker takeover'
                            : _counterLocked
                            ? 'Counter sent'
                            : 'Send counter',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting || handoffExpired
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
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF2FA56E),
                            side: const BorderSide(color: Color(0xFFB7E1C8)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_accepted) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7EF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _trackRideReady
                                ? 'Request accepted. Your trip is ready to track.'
                                : 'Request accepted. Waiting for the trip to be ready.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF2FA56E),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          if (_resolvedTripStatus.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Trip status: ${_titleCase(_resolvedTripStatus)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF40916C),
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                          if (_trackRideReady) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: FilledButton(
                                onPressed: _resolvedTripId.isEmpty
                                    ? null
                                    : () {
                                        context.go(
                                          '/driver/delivery-details/$_resolvedTripId',
                                        );
                                      },
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1F88C9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  'Track your ride',
                                  style: TextStyle(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
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

String _extractTripId(Map<String, dynamic> payload, String fallback) {
  final trip = payload['trip'];
  if (trip is Map<String, dynamic>) {
    final nested = trip['id']?.toString().trim();
    if (nested != null && nested.isNotEmpty) {
      return nested;
    }
  }

  for (final key in const ['tripId', 'trip_id', 'tripID']) {
    final value = payload[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return fallback.trim();
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
