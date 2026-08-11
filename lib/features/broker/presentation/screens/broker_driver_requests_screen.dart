import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  Future<void> _refresh() async {
    ref.invalidate(brokerDriverRequestsProvider(_query));
    await ref.read(brokerDriverRequestsProvider(_query).future);
  }

  void _openRequest(BrokerDriverRequest request) {
    context.push('/broker/request', extra: request);
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
                        onTap: () => _openRequest(request),
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
  const _BrokerRequestTile({required this.request, required this.onTap});

  final BrokerDriverRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
              children: [
                Expanded(
                  child: Text(
                    request.bookingNumber.isEmpty
                        ? request.bookingId
                        : request.bookingNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
                  ),
                ),
                Text(
                  '₹${request.amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF101828),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              request.driverName.isNotEmpty ? request.driverName : 'Driver',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
            const SizedBox(height: 10),
            Text(
              '${request.pickup.isNotEmpty ? request.pickup : 'Pickup'} → ${request.drop.isNotEmpty ? request.drop : 'Drop'}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (request.truckType.isNotEmpty) request.truckType,
                if (request.weight.isNotEmpty) request.weight,
                if (request.truckReg.isNotEmpty) request.truckReg,
              ].join(' • '),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            ),
            if (request.driverTimedOut) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDF4E8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF4D3A5)),
                ),
                child: Text(
                  'Driver timed out. Broker can take over negotiation.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF9A5B13),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Tap to open negotiation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF1F88C9),
                fontWeight: FontWeight.w700,
              ),
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
