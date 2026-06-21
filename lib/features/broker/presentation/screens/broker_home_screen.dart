import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/broker_flow_widgets.dart';

class BrokerHomeScreen extends ConsumerStatefulWidget {
  const BrokerHomeScreen({super.key});

  @override
  ConsumerState<BrokerHomeScreen> createState() => _BrokerHomeScreenState();
}

class _BrokerHomeScreenState extends ConsumerState<BrokerHomeScreen> {
  late List<BookingRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = [...mockBrokerRequests];
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _requests = [...mockBrokerRequests];
    });
    ref.read(brokerPendingRequestsProvider.notifier).state = _requests.length;
  }

  void _acceptRequest(BookingRequest request) {
    setState(() {
      _requests.removeWhere((item) => item.id == request.id);
    });

    ref.read(brokerPendingRequestsProvider.notifier).state = _requests.length;
    final history = ref.read(brokerHistoryProvider.notifier);
    history.state = [
      bookingRequestToShipment(request, status: 'Accepted'),
      ...history.state,
    ];

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Accepted ${request.productName}'),
        backgroundColor: const Color(0xFF1F88C9),
      ),
    );
  }

  Future<void> _rejectRequest(BookingRequest request) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject request?'),
          content: Text('Reject the booking request for ${request.productName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE23A4B)),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) return;

    setState(() {
      _requests.removeWhere((item) => item.id == request.id);
    });
    ref.read(brokerPendingRequestsProvider.notifier).state = _requests.length;
    final history = ref.read(brokerHistoryProvider.notifier);
    history.state = [
      bookingRequestToShipment(request, status: 'Cancelled'),
      ...history.state,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _requests.isEmpty;

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
                label: '${_requests.length} pending',
                backgroundColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1F88C9),
                icon: Icons.inbox_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isEmpty)
            Container(
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
            )
          else
            ..._requests.asMap().entries.expand(
                  (entry) => [
                    BrokerRequestCard(
                      request: entry.value,
                      onAccept: () => _acceptRequest(entry.value),
                      onReject: () => _rejectRequest(entry.value),
                    ),
                    if (entry.key != _requests.length - 1) const SizedBox(height: 12),
                  ],
                ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload demo data'),
            ),
          ),
        ],
      ),
    );
  }
}
