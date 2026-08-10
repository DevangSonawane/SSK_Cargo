import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_location_tracker_provider.dart';
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
  late double _counterAmount;

  DriverRequestItem get _request =>
      DriverRequestItem.fromExtra(widget.initialRequest);

  @override
  void initState() {
    super.initState();
    final request = DriverRequestItem.fromExtra(widget.initialRequest);
    _counterAmount = request.amount > 0 ? request.amount : 1000;
  }

  Future<void> _runAction(
    Future<Map<String, dynamic>> Function(String accessToken) action, {
    bool navigateOnSuccess = false,
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

      if (navigateOnSuccess && effectiveTripId.isNotEmpty) {
        ref
            .read(driverLocationTrackerProvider)
            .setActiveTripId(effectiveTripId);
      }

      if (!mounted) return;

      if (navigateOnSuccess && effectiveTripId.isNotEmpty) {
        setState(() {
          _accepted = true;
        });
        context.go('/driver/delivery-details/$effectiveTripId');
        return;
      }

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

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final baseAmount = request.amount > 0 ? request.amount : 1000.0;
    final minOffer = math.max(1.0, baseAmount * 0.7);
    final maxOffer = math.max(minOffer + 1, baseAmount * 1.3);
    final selectedAmount = _counterAmount.clamp(minOffer, maxOffer).toDouble();

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
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                                  ?.copyWith(
                                    color: const Color(0xFF98A2B3),
                                  ),
                            ),
                            Text(
                              '₹${maxOffer.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF98A2B3),
                                  ),
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
                      onPressed: _submitting
                          ? null
                          : () => _runAction(
                              (token) => ref
                                  .read(apiClientProvider)
                                  .counterDriverRequestAsDriver(
                                    accessToken: token,
                                    id: request.id,
                                    amount: selectedAmount,
                                  ),
                            ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F88C9),
                        disabledBackgroundColor: const Color(0xFFD0D5DD),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        _submitting ? 'Saving...' : 'Send counter',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => _runAction(
                                  (token) => ref
                                      .read(apiClientProvider)
                                      .acceptDriverRequestAsDriver(
                                        accessToken: token,
                                        id: request.id,
                                      ),
                                  navigateOnSuccess: true,
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
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
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
                            foregroundColor: const Color(0xFFE23A4B),
                            side: const BorderSide(color: Color(0xFFF5B7BF)),
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
                      child: Text(
                        'Request accepted. Your trip screens are now unlocked.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF2FA56E),
                          fontWeight: FontWeight.w700,
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
