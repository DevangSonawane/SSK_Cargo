import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../widgets/broker_flow_widgets.dart';

enum _NotificationTab { all, operations, system, financial }

final _brokerNotificationsProvider =
    FutureProvider.autoDispose<List<ClientNotification>>((ref) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) throw StateError('No active session');
      final response = await ref
          .watch(apiClientProvider)
          .getNotifications(
            accessToken: session.tokens.accessToken,
            limit: 100,
          );
      return _notificationsFromResponse(response);
    });

class BrokerNotificationsScreen extends ConsumerStatefulWidget {
  const BrokerNotificationsScreen({super.key});

  @override
  ConsumerState<BrokerNotificationsScreen> createState() =>
      _BrokerNotificationsScreenState();
}

class _BrokerNotificationsScreenState
    extends ConsumerState<BrokerNotificationsScreen> {
  _NotificationTab _tab = _NotificationTab.all;
  bool _markingAllRead = false;

  Future<void> _refresh() async {
    ref.invalidate(_brokerNotificationsProvider);
    await ref.read(_brokerNotificationsProvider.future);
  }

  Future<void> _markRead(ClientNotification notification) async {
    if (notification.isRead) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    try {
      await ref
          .read(apiClientProvider)
          .markNotificationRead(
            accessToken: session.tokens.accessToken,
            id: notification.id,
          );
    } catch (_) {
      // Optimistic in the React app too; a future refresh will resync.
    }
    ref.invalidate(_brokerNotificationsProvider);
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
      ref.invalidate(_brokerNotificationsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _markingAllRead = false);
    }
  }

  Future<void> _openNotification(ClientNotification notification) async {
    await _markRead(notification);

    final request = await _resolveNegotiationTarget(notification);
    if (request != null) {
      if (!mounted) return;
      context.push('/broker/request', extra: request);
      return;
    }

    final route = _routeForNotification(notification);
    if (route != null && mounted) {
      context.push(route);
    }
  }

  Future<BrokerDriverRequest?> _resolveNegotiationTarget(
    ClientNotification notification,
  ) async {
    if (!brokerLooksLikeTimedOutNegotiationPayload(notification.raw)) {
      return null;
    }

    final request = await _resolveTimedOutDriverRequest(notification);
    return request ??
        brokerDriverRequestFromNotificationPayload(notification.raw);
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
    } catch (_) {}

    return null;
  }

  List<ClientNotification> _filtered(List<ClientNotification> notifications) {
    if (_tab == _NotificationTab.all) return notifications;
    return notifications
        .where((notification) => _categoryFor(notification) == _tab)
        .toList();
  }

  String _extractNotificationId(
    Map<String, dynamic> payload,
    List<String> keys,
  ) {
    final meta = _asMap(payload['meta']);
    for (final source in [payload, meta]) {
      for (final key in keys) {
        final value = source[key]?.toString().trim();
        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() != 'null') {
          return value;
        }
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(_brokerNotificationsProvider);
    final notifications =
        notificationsAsync.valueOrNull ?? const <ClientNotification>[];
    final unreadCount = notifications.where((item) => !item.isRead).length;
    final filtered = _filtered(notifications);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2152D0),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              _NotificationsHeader(
                unreadCount: unreadCount,
                markingAllRead: _markingAllRead,
                onMarkAllRead: unreadCount > 0 ? _markAllRead : null,
              ),
              const SizedBox(height: 18),
              _NotificationTabs(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 16),
              notificationsAsync.when(
                loading: () => const _NotificationSkeletonList(),
                error: (error, _) => _NotificationEmptyState(
                  title: "Couldn't load your notifications",
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                  actionLabel: 'Retry',
                  onAction: _refresh,
                ),
                data: (_) {
                  if (filtered.isEmpty) {
                    return const _NotificationEmptyState(
                      title: 'No notifications here yet.',
                      subtitle: 'Alerts and system updates will appear here.',
                    );
                  }
                  return Column(
                    children: [
                      for (final notification in filtered) ...[
                        _NotificationCard(
                          notification: notification,
                          onTap: () => _markRead(notification),
                          onAction: _actionLabel(notification) == null
                              ? null
                              : () => _openNotification(notification),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.markingAllRead,
    required this.onMarkAllRead,
  });

  final int unreadCount;
  final bool markingAllRead;
  final VoidCallback? onMarkAllRead;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your alerts and system updates.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (unreadCount > 0)
          OutlinedButton.icon(
            onPressed: markingAllRead ? null : onMarkAllRead,
            icon: const Icon(AppIcons.done_all_rounded, size: 16),
            label: Text(markingAllRead ? 'Saving...' : 'Mark all read'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF475569),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFE2E8F0)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationTabs extends StatelessWidget {
  const _NotificationTabs({required this.selected, required this.onChanged});

  final _NotificationTab selected;
  final ValueChanged<_NotificationTab> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = [
      (_NotificationTab.all, 'All'),
      (_NotificationTab.operations, 'Operations'),
      (_NotificationTab.system, 'System'),
      (_NotificationTab.financial, 'Financial'),
    ];
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs)
              _NotificationTabButton(
                label: tab.$2,
                selected: selected == tab.$1,
                onTap: () => onChanged(tab.$1),
              ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTabButton extends StatelessWidget {
  const _NotificationTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        margin: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF2152D0) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF2152D0) : const Color(0xFF94A3B8),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onAction,
  });

  final ClientNotification notification;
  final VoidCallback onTap;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(notification);
    final actionLabel = _actionLabel(notification);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          clipBehavior: Clip.antiAlias,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  color: notification.isRead ? Colors.transparent : meta.color,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _NotificationCardBody(
                      notification: notification,
                      meta: meta,
                      actionLabel: actionLabel,
                      onAction: onAction,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationCardBody extends StatelessWidget {
  const _NotificationCardBody({
    required this.notification,
    required this.meta,
    required this.actionLabel,
    required this.onAction,
  });

  final ClientNotification notification;
  final _NotificationMeta meta;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: meta.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(meta.icon, color: meta.color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      notification.title.isEmpty
                          ? 'Notification'
                          : notification.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1E293B),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _timeAgo(notification.createdAt),
                    style: const TextStyle(
                      color: Color(0xFFCBD5E1),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                notification.message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.35,
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: onAction,
                  iconAlignment: IconAlignment.end,
                  icon: const Icon(AppIcons.arrow_forward_rounded, size: 14),
                  label: Text(actionLabel!),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2152D0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _NotificationSkeletonList extends StatelessWidget {
  const _NotificationSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF3F8),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _NotificationMeta {
  const _NotificationMeta({
    required this.icon,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final Color color;
  final Color background;
}

List<ClientNotification> _notificationsFromResponse(Map<String, dynamic> json) {
  final data = _asMap(json['data']);
  final items =
      data['notifications'] ??
      data['items'] ??
      json['notifications'] ??
      json['items'] ??
      const [];
  if (items is! List) return const [];
  return items
      .whereType<Map>()
      .map((item) => ClientNotification.fromJson(_asMap(item)))
      .toList();
}

_NotificationTab _categoryFor(ClientNotification notification) {
  switch (_notificationType(notification)) {
    case 'booking':
    case 'incident':
    case 'chat':
      return _NotificationTab.operations;
    case 'payment':
      return _NotificationTab.financial;
    case 'dispute':
    case 'kyc':
    case 'general':
    default:
      return _NotificationTab.system;
  }
}

_NotificationMeta _metaFor(ClientNotification notification) {
  switch (_notificationType(notification)) {
    case 'booking':
      return const _NotificationMeta(
        icon: AppIcons.local_shipping_rounded,
        color: Color(0xFF2152D0),
        background: Color(0xFFEAF2FF),
      );
    case 'incident':
      return const _NotificationMeta(
        icon: AppIcons.build_rounded,
        color: Color(0xFFB7791F),
        background: Color(0xFFFFF7E6),
      );
    case 'chat':
      return const _NotificationMeta(
        icon: AppIcons.chat_bubble_rounded,
        color: Color(0xFF2152D0),
        background: Color(0xFFEAF2FF),
      );
    case 'payment':
      return const _NotificationMeta(
        icon: AppIcons.receipt_long_rounded,
        color: Color(0xFF2FA56E),
        background: Color(0xFFEAF7EF),
      );
    case 'dispute':
      return const _NotificationMeta(
        icon: AppIcons.gpp_maybe_rounded,
        color: Color(0xFFE23A4B),
        background: Color(0xFFFDECEC),
      );
    case 'kyc':
      return const _NotificationMeta(
        icon: AppIcons.verified_user_rounded,
        color: Color(0xFF2152D0),
        background: Color(0xFFEAF2FF),
      );
    default:
      return const _NotificationMeta(
        icon: AppIcons.notifications_rounded,
        color: Color(0xFF64748B),
        background: Color(0xFFF1F5F9),
      );
  }
}

String? _actionLabel(ClientNotification notification) {
  switch (_notificationType(notification)) {
    case 'booking':
      return 'View Details';
    case 'incident':
      return 'View Trip';
    case 'chat':
      return 'Open Chat';
    default:
      return null;
  }
}

String? _routeForNotification(ClientNotification notification) {
  final type = _notificationType(notification);
  final meta = _asMap(notification.raw['meta']);
  switch (type) {
    case 'booking':
      if (_readString(meta, const ['driver_request_id']).isNotEmpty) {
        return '/broker/driver-requests';
      }
      if (_readString(meta, const ['job_request_id']).isNotEmpty) {
        return '/broker/home';
      }
      if (_readString(meta, const ['trip_id']).isNotEmpty) {
        return '/broker/active-jobs';
      }
      return '/broker/home';
    case 'incident':
      return '/broker/active-jobs';
    case 'chat':
      return '/broker/chats';
    default:
      return null;
  }
}

String _notificationType(ClientNotification notification) {
  return _readString(notification.raw, const [
    'type',
    'notification_type',
  ]).trim().toLowerCase();
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inHours < 48) return 'Yesterday';
  return '${diff.inDays}d ago';
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}
