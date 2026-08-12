import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/controllers/client_notifications_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerDriverRequestsScreen extends ConsumerStatefulWidget {
  const BrokerDriverRequestsScreen({super.key});

  @override
  ConsumerState<BrokerDriverRequestsScreen> createState() =>
      _BrokerDriverRequestsScreenState();
}

class _BrokerDriverRequestsScreenState
    extends ConsumerState<BrokerDriverRequestsScreen> {
  static const _query = (page: 1, limit: 100);
  final Set<String> _actioningIds = <String>{};

  Future<void> _refresh() async {
    ref.invalidate(brokerDriverRequestsProvider(_query));
    await ref.read(brokerDriverRequestsProvider(_query).future);
  }

  bool _isActioning(String id) => _actioningIds.contains(id);

  Future<void> _runAction({
    required BrokerDriverRequest request,
    required Future<void> Function(SskApiClient api, String token) action,
    required String successMessage,
  }) async {
    if (_isActioning(request.id)) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _actioningIds.add(request.id));
    try {
      await action(ref.read(apiClientProvider), session.tokens.accessToken);
      ref.invalidate(brokerDriverRequestsProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF2FA56E),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _actioningIds.remove(request.id));
      }
    }
  }

  Future<void> _acceptRequest(BrokerDriverRequest request) {
    return _runAction(
      request: request,
      successMessage: 'Request accepted.',
      action: (api, token) {
        return api.acceptDriverRequestAsDriver(
          accessToken: token,
          id: request.id,
        );
      },
    );
  }

  Future<void> _declineRequest(BrokerDriverRequest request) {
    return _runAction(
      request: request,
      successMessage: 'Request declined.',
      action: (api, token) {
        return api.rejectDriverRequest(accessToken: token, id: request.id);
      },
    );
  }

  Future<void> _openCounterSheet(BrokerDriverRequest request) async {
    if (_isActioning(request.id)) return;

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BrokerCounterSheet(request: request),
    );

    if (amount == null) return;

    await _runAction(
      request: request,
      successMessage: 'Counter sent.',
      action: (api, token) {
        return api.counterDriverRequest(
          accessToken: token,
          id: request.id,
          amount: amount,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(brokerDriverRequestsProvider(_query));
    final notificationsAsync = ref.watch(clientNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Driver requests'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: requestsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            children: const [Center(child: CircularProgressIndicator())],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            children: [
              _EmptyState(
                title: 'Could not load driver requests',
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (requests) {
            final notificationRequests =
                notificationsAsync.valueOrNull
                    ?.where(
                      (notification) =>
                          brokerLooksLikeTimedOutNegotiationPayload(
                            notification.raw,
                          ),
                    )
                    .map(
                      (notification) =>
                          brokerDriverRequestFromNotificationPayload(
                            notification.raw,
                          ),
                    )
                    .toList() ??
                const <BrokerDriverRequest>[];

            final mergedRequests = <BrokerDriverRequest>[
              ...requests,
              ...notificationRequests,
            ];
            final visibleRequests = <BrokerDriverRequest>[];
            final seenKeys = <String>{};
            for (final request in mergedRequests) {
              if (!isActiveBrokerDriverRequest(request)) {
                continue;
              }
              final key = [
                request.id,
                request.bookingId,
                request.bookingNumber,
              ].where((value) => value.isNotEmpty).join('|');
              if (key.isNotEmpty && seenKeys.add(key)) {
                visibleRequests.add(request);
              }
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Negotiation cards',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Reload'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visibleRequests.isEmpty)
                  const _EmptyState(
                    title: 'No driver requests yet',
                    subtitle:
                        'When a driver times out, the request will appear here for broker takeover.',
                  )
                else
                  ...visibleRequests.asMap().entries.expand((entry) {
                    final request = entry.value;
                    return [
                      _BrokerRequestTile(
                        request: request,
                        busy: _isActioning(request.id),
                        onAccept: () => _acceptRequest(request),
                        onCounter: () => _openCounterSheet(request),
                        onDecline: () => _declineRequest(request),
                      ),
                      if (entry.key != visibleRequests.length - 1)
                        const SizedBox(height: 12),
                    ];
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrokerRequestTile extends StatelessWidget {
  const _BrokerRequestTile({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onCounter,
    required this.onDecline,
  });

  final BrokerDriverRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final bookingText = request.bookingNumber.isNotEmpty
        ? request.bookingNumber
        : request.bookingId;
    final status = request.status.trim().toLowerCase();
    final pendingConfirmationBy = request.pendingConfirmationBy
        .trim()
        .toLowerCase();
    final awaitingConfirmation = status == 'awaiting_confirmation';
    final waitingOnClient =
        awaitingConfirmation && pendingConfirmationBy == 'broker';
    final yourTurn = awaitingConfirmation && pendingConfirmationBy == 'client';
    final canAct =
        !busy &&
        (status.isEmpty ||
            status == 'requested' ||
            status == 'pending' ||
            awaitingConfirmation);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking ID',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookingText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF101828),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: request.driverTimedOut
                      ? const Color(0xFFFDF4E8)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.driverTimedOut ? 'Timed out' : 'Live',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: request.driverTimedOut
                        ? const Color(0xFFB54708)
                        : const Color(0xFF1F88C9),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteRow(
            label: 'Pickup',
            value: request.pickup.isNotEmpty ? request.pickup : 'Pickup',
            icon: Icons.radio_button_checked_rounded,
            color: const Color(0xFF2FA56E),
          ),
          const SizedBox(height: 10),
          _RouteRow(
            label: 'Drop',
            value: request.drop.isNotEmpty ? request.drop : 'Drop',
            icon: Icons.location_on_rounded,
            color: const Color(0xFFE23A4B),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF1F88C9),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.driverName.isNotEmpty
                            ? request.driverName
                            : 'Driver',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF101828),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (request.truckType.isNotEmpty) request.truckType,
                          if (request.truckReg.isNotEmpty) request.truckReg,
                          if (request.weight.isNotEmpty) request.weight,
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (waitingOnClient) ...[
            const _WaitingBadge(
              label: 'Accepted - waiting for the client to confirm',
            ),
          ] else if (yourTurn) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Confirm',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF2FA56E),
                    backgroundColor: const Color(0xFFEAF8EF),
                    onPressed: canAct ? onAccept : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFE23A4B),
                    backgroundColor: const Color(0xFFFDECEC),
                    onPressed: canAct ? onDecline : null,
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Accept',
                    icon: Icons.check_circle_rounded,
                    color: const Color(0xFF2FA56E),
                    backgroundColor: const Color(0xFFEAF8EF),
                    onPressed: canAct ? onAccept : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Counter',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF1F88C9),
                    backgroundColor: const Color(0xFFEFF6FF),
                    onPressed: canAct ? onCounter : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: 'Decline',
                    icon: Icons.cancel_rounded,
                    color: const Color(0xFFE23A4B),
                    backgroundColor: const Color(0xFFFDECEC),
                    onPressed: canAct ? onDecline : null,
                  ),
                ),
              ],
            ),
          ],
          if (request.driverTimedOut) ...[
            const SizedBox(height: 10),
            Text(
              'Driver timed out - broker takeover active.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF9A5B13),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaitingBadge extends StatelessWidget {
  const _WaitingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7DAFF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: const Color(0xFF1F88C9),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: color,
          disabledBackgroundColor: const Color(0xFFF2F4F7),
          disabledForegroundColor: const Color(0xFF98A2B3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerCounterSheet extends StatefulWidget {
  const _BrokerCounterSheet({required this.request});

  final BrokerDriverRequest request;

  @override
  State<_BrokerCounterSheet> createState() => _BrokerCounterSheetState();
}

class _BrokerCounterSheetState extends State<_BrokerCounterSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    final base = (widget.request.amount > 0 ? widget.request.amount : 1000)
        .toDouble();
    _value = base;
  }

  @override
  Widget build(BuildContext context) {
    final base = (widget.request.amount > 0 ? widget.request.amount : 1000)
        .toDouble();
    final min = math.max(1.0, base * 0.75);
    final max = math.max(min + 1.0, base * 1.25);
    final clamped = _value.clamp(min, max).toDouble();

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
                  color: const Color(0xFFE1E5EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Counter offer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.request.bookingNumber.isNotEmpty
                  ? widget.request.bookingNumber
                  : widget.request.bookingId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set counter amount',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${clamped.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF1F88C9),
                    ),
                  ),
                  Slider(
                    value: clamped,
                    min: min,
                    max: max,
                    divisions: 100,
                    activeColor: const Color(0xFF1F88C9),
                    onChanged: (value) {
                      setState(() => _value = value);
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${min.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${max.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    onPressed: () => Navigator.of(context).pop(clamped),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}
