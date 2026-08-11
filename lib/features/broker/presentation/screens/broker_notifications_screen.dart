import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/controllers/client_notifications_controller.dart';
import '../../../../core/network/api_client.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerNotificationsScreen extends ConsumerStatefulWidget {
  const BrokerNotificationsScreen({super.key});

  @override
  ConsumerState<BrokerNotificationsScreen> createState() =>
      _BrokerNotificationsScreenState();
}

class _BrokerNotificationsScreenState
    extends ConsumerState<BrokerNotificationsScreen> {
  bool _markingAllRead = false;

  Future<void> _refresh() async {
    ref.invalidate(clientNotificationsProvider);
    await ref.read(clientNotificationsProvider.future);
  }

  Future<void> _markAllRead() async {
    if (_markingAllRead) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _markingAllRead = true);
    try {
      await ref
          .read(apiClientProvider)
          .markAllNotificationsRead(accessToken: session.tokens.accessToken);
      ref.invalidate(clientNotificationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _markingAllRead = false);
      }
    }
  }

  Future<void> _openNotification(ClientNotification notification) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    if (!notification.isRead) {
      try {
        await ref
            .read(apiClientProvider)
            .markNotificationRead(
              accessToken: session.tokens.accessToken,
              id: notification.id,
            );
      } catch (_) {}
      ref.invalidate(clientNotificationsProvider);
      final timedOutRequest = await _resolveTimedOutDriverRequest(notification);
      if (timedOutRequest != null) {
        if (!mounted) return;
        context.push('/broker/request', extra: timedOutRequest);
        return;
      }
    }

    final timedOutRequest = await _resolveTimedOutDriverRequest(notification);
    if (timedOutRequest != null) {
      if (!mounted) return;
      context.push('/broker/request', extra: timedOutRequest);
      return;
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
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
                  notification.title.isEmpty
                      ? 'Notification'
                      : notification.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message.isEmpty
                      ? 'No message available.'
                      : notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF344054),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F88C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _looksLikeTimedOutNegotiation(ClientNotification notification) {
    final payload = notification.raw;
    final combinedText = '${notification.title} ${notification.message}'
        .toLowerCase();
    return combinedText.contains('timed out') ||
        combinedText.contains('broker handoff') ||
        combinedText.contains('negotiation') ||
        payload['driverTimedOut'] == true ||
        payload['driver_timed_out'] == true ||
        _extractNotificationId(payload, const [
          'bookingId',
          'booking_id',
        ]).isNotEmpty ||
        _extractNotificationId(payload, const [
          'request_id',
          'driver_request_id',
        ]).isNotEmpty;
  }

  String _extractNotificationId(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  Future<BrokerDriverRequest?> _resolveTimedOutDriverRequest(
    ClientNotification notification,
  ) async {
    if (!_looksLikeTimedOutNegotiation(notification)) {
      return null;
    }

    final payload = notification.raw;
    final bookingId = _extractNotificationId(payload, const [
      'bookingId',
      'booking_id',
    ]);
    final requestId = _extractNotificationId(payload, const [
      'request_id',
      'driver_request_id',
      'id',
    ]);

    try {
      final requests = await ref.read(
        brokerDriverRequestsProvider((page: 1, limit: 100)).future,
      );
      for (final request in requests) {
        final matchesBooking =
            bookingId.isNotEmpty &&
            (request.bookingId == bookingId ||
                request.id == bookingId ||
                request.bookingNumber == bookingId);
        final matchesRequest =
            requestId.isNotEmpty &&
            (request.id == requestId || request.bookingId == requestId);
        if (matchesBooking || matchesRequest || request.driverTimedOut) {
          return request;
        }
      }
    } catch (_) {
      // Fall back to the generic notification sheet if the request list fails.
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(clientNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markingAllRead ? null : _markAllRead,
            child: Text(
              _markingAllRead ? 'Saving...' : 'Mark all read',
              style: const TextStyle(color: Color(0xFF1F88C9)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            children: [
              _EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Could not load notifications',
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                children: const [
                  _EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    subtitle:
                        'Booking, invoice, and system updates will appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openNotification(notification),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white
                          : const Color(0xFFF7FBF9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EDF2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notification.isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: const Color(0xFF1F88C9),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notification.title.isEmpty
                                    ? 'Notification'
                                    : notification.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF101828),
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF667085), size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}
