import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/broker_flow_widgets.dart';

class BrokerHomeScreen extends ConsumerStatefulWidget {
  const BrokerHomeScreen({super.key});

  @override
  ConsumerState<BrokerHomeScreen> createState() => _BrokerHomeScreenState();
}

class _BrokerHomeScreenState extends ConsumerState<BrokerHomeScreen> {
  static const _requestsQuery = (page: 1, limit: 100);

  Future<void> _refresh() async {
    ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
    await ref.read(brokerJobRequestsProvider(_requestsQuery).future);
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(brokerJobRequestsProvider(_requestsQuery));
    final requests = requestsAsync.valueOrNull ?? const <BookingRequest>[];
    final pendingRequests = requests.where(isPendingBookingRequest).toList();
    final visibleRequests = requests;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF1F88C9),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(
            children: [
              Text(
                'New booking requests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              StatusPill(
                label: '${pendingRequests.length} pending',
                backgroundColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1F88C9),
                icon: Icons.inbox_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          requestsAsync.when(
            data: (_) {
              if (visibleRequests.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE8EDF2)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inbox_rounded,
                          color: Color(0xFF1F88C9),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'No new requests',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF101828),
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Fresh bookings will appear here as soon as clients send them.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  for (
                    var index = 0;
                    index < visibleRequests.length;
                    index++
                  ) ...[
                    BrokerRequestCard(
                      request: visibleRequests[index],
                      onTap: () => context.push(
                        '/broker/request',
                        extra: visibleRequests[index],
                      ),
                    ),
                    if (index != visibleRequests.length - 1)
                      const SizedBox(height: 12),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Text(
                error.toString().replaceFirst('Exception: ', ''),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFB42318),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload requests'),
            ),
          ),
        ],
      ),
    );
  }
}
