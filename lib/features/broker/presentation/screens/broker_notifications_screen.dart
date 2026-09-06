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
      final request = await _resolveNegotiationTarget(notification);
      if (request != null) {
        if (!mounted) return;
        context.push('/broker/request', extra: request);
        return;
      }
    }

    final request = await _resolveNegotiationTarget(notification);
    if (request != null) {
      if (!mounted) return;
      context.push('/broker/request', extra: request);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          notification.message.isEmpty
              ? (notification.title.isEmpty
                    ? 'Notification opened.'
                    : notification.title)
              : notification.message,
        ),
      ),
    );
  }

  Future<BrokerDriverRequest?> _resolveNegotiationTarget(
    ClientNotification notification,
  ) async {
    if (!brokerLooksLikeTimedOutNegotiationPayload(notification.raw)) {
      return null;
    }

    final request = await _resolveTimedOutDriverRequest(notification);
    if (request != null) {
      return request;
    }

    return brokerDriverRequestFromNotificationPayload(notification.raw);
  }

  Future<BrokerDriverRequest?> _resolveTimedOutDriverRequest(
    ClientNotification notification,
  ) async {
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
      // Fall back to a synthesized request below.
    }

    return null;
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

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(clientNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FC),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notificationsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              _NotificationsHeader(),
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _NotificationsHeader(),
              const SizedBox(height: 24),
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
                children: const [
                  _NotificationsHeader(),
                  SizedBox(height: 24),
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: notifications.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _NotificationsHeader(
                    onMarkAllRead: _markingAllRead ? null : _markAllRead,
                    markingAllRead: _markingAllRead,
                  );
                }
                final notification = notifications[index - 1];
                return InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _openNotification(notification),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white
                          : const Color(0xFFF7FBF9),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFDCE8E5)),
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
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF101828),
                                    fontSize: 17,
                                    ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF64748B),
                                      fontSize: 14,
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

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    this.onMarkAllRead,
    this.markingAllRead = false,
  });

  final VoidCallback? onMarkAllRead;
  final bool markingAllRead;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        8,
        20,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: const SizedBox(
              width: 34,
              height: 34,
              child: Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF101828),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Notifications',
              style: TextStyle(
                color: Color(0xFF101828),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: onMarkAllRead,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              markingAllRead ? 'Saving...' : 'Mark all read',
              style: const TextStyle(
                color: Color(0xFF1683D0),
                fontSize: 14,
              ),
            ),
          ),
        ],
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
