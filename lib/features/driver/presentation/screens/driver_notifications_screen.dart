import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';

enum _DriverNotificationFilter { all, trips, chat, system }

final _driverNotificationsProvider =
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

class DriverNotificationsScreen extends ConsumerStatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  ConsumerState<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState
    extends ConsumerState<DriverNotificationsScreen> {
  _DriverNotificationFilter _filter = _DriverNotificationFilter.all;
  bool _markingAllRead = false;
  final Set<String> _optimisticReadIds = <String>{};

  bool _isEffectivelyRead(ClientNotification notification) {
    return notification.isRead || _optimisticReadIds.contains(notification.id);
  }

  Future<void> _refresh() async {
    ref.invalidate(_driverNotificationsProvider);
    try {
      await ref.read(_driverNotificationsProvider.future);
    } catch (_) {
      // Error UI is driven by provider state.
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAllRead) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final current = ref.read(_driverNotificationsProvider).valueOrNull;
    if (current != null) {
      setState(() {
        _markingAllRead = true;
        _optimisticReadIds.addAll(
          current.where((n) => !_isEffectivelyRead(n)).map((n) => n.id),
        );
      });
    } else {
      setState(() => _markingAllRead = true);
    }

    try {
      await ref
          .read(apiClientProvider)
          .markAllNotificationsRead(accessToken: session.tokens.accessToken);
      ref.invalidate(_driverNotificationsProvider);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _markingAllRead = false);
    }
  }

  Future<void> _openNotification(ClientNotification notification) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    if (!_isEffectivelyRead(notification)) {
      setState(() => _optimisticReadIds.add(notification.id));
      try {
        await ref
            .read(apiClientProvider)
            .markNotificationRead(
              accessToken: session.tokens.accessToken,
              id: notification.id,
            );
      } catch (_) {
        // Optimistic state stays; refresh will resync.
      }
      ref.invalidate(_driverNotificationsProvider);
    }

    final route = _routeForNotification(notification);
    if (route != null && mounted) {
      context.push(route);
    }
  }

  List<ClientNotification> _filtered(List<ClientNotification> notifications) {
    if (_filter == _DriverNotificationFilter.all) return notifications;
    return notifications
        .where((notification) => _filterFor(notification) == _filter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final notificationsAsync = ref.watch(_driverNotificationsProvider);
    final notifications =
        notificationsAsync.valueOrNull ?? const <ClientNotification>[];
    final unreadCount = notifications
        .where((item) => !_isEffectivelyRead(item))
        .length;
    final filtered = _filtered(notifications);
    final isBackgroundRefresh =
        (notificationsAsync.isRefreshing || notificationsAsync.isReloading) &&
        notificationsAsync.hasValue;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(AppIcons.arrow_back_rounded),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.brokerNotifNotifications,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          unreadCount > 0
                              ? l10n.brokerNotifUnreadCount(unreadCount)
                              : l10n.brokerNotifTotalCount(
                                  notifications.length,
                                ),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markingAllRead ? null : _markAllRead,
                      child: Text(
                        _markingAllRead
                            ? l10n.saving
                            : l10n.brokerNotificationsMarkAllRead,
                      ),
                    ),
                ],
              ),
              if (isBackgroundRefresh) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  color: AppColors.brand,
                  backgroundColor: AppColors.brandTint,
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
              const SizedBox(height: 18),
              _FilterChips(
                selected: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
                counts: _countsFor(notifications),
              ),
              const SizedBox(height: 18),
              ..._buildList(notificationsAsync, filtered),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildList(
    AsyncValue<List<ClientNotification>> notificationsAsync,
    List<ClientNotification> filtered,
  ) {
    if (notificationsAsync.isLoading && !notificationsAsync.hasValue) {
      return const [_NotificationsSkeleton()];
    }

    if (notificationsAsync.hasError && !notificationsAsync.hasValue) {
      return [
        _EmptyState(
          icon: AppIcons.inbox_outlined,
          title: AppLocalizations.of(
            context,
          )!.brokerNotifCouldnTLoadYourNotifications,
          subtitle: notificationsAsync.error.toString().replaceFirst(
            'Exception: ',
            '',
          ),
          actionLabel: AppLocalizations.of(context)!.brokerNotifRetryAction,
          onAction: _refresh,
        ),
      ];
    }

    if (filtered.isEmpty) {
      return [
        _EmptyState(
          icon: AppIcons.notifications_none_rounded,
          title: AppLocalizations.of(context)!.brokerNotifNoNotifications,
          subtitle: AppLocalizations.of(
            context,
          )!.brokerNotifNewAlertsWillAppearHere,
        ),
      ];
    }

    return [
      for (final notification in filtered) ...[
        _NotificationTile(
          notification: notification,
          isRead: _isEffectivelyRead(notification),
          onTap: () => _openNotification(notification),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.selected,
    required this.onChanged,
    required this.counts,
  });

  final _DriverNotificationFilter selected;
  final ValueChanged<_DriverNotificationFilter> onChanged;
  final Map<_DriverNotificationFilter, int> counts;

  static const double _innerHeight = 44;

  int get _selectedIndex => switch (selected) {
    _DriverNotificationFilter.all => 0,
    _DriverNotificationFilter.trips => 1,
    _DriverNotificationFilter.chat => 2,
    _DriverNotificationFilter.system => 3,
  };

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_DriverNotificationFilter.all, 'All'),
      (_DriverNotificationFilter.trips, 'Trips'),
      (_DriverNotificationFilter.chat, 'Chat'),
      (_DriverNotificationFilter.system, 'System'),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: _innerHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / tabs.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: _selectedIndex * segmentWidth,
                      top: 0,
                      bottom: 0,
                      width: segmentWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white, Color(0xFFEAF3EE)],
                          ),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (final tab in tabs)
                          Expanded(
                            child: GestureDetector(
                              onTap: () => onChanged(tab.$1),
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                height: _innerHeight,
                                alignment: Alignment.center,
                                child: _FilterSegmentLabel(
                                  label: tab.$2,
                                  count: counts[tab.$1] ?? 0,
                                  selected: selected == tab.$1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSegmentLabel extends StatelessWidget {
  const _FilterSegmentLabel({
    required this.label,
    required this.count,
    required this.selected,
  });

  final String label;
  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: selected ? AppColors.brandDark : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.brandTint
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? AppColors.brandDark : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final ClientNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(notification);
    final title = notification.title.trim().isEmpty
        ? 'Notification'
        : notification.title.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : AppColors.brandTint,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isRead ? AppColors.line : AppColors.brandBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: meta.background,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(meta.icon, color: meta.color, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight: isRead
                                  ? FontWeight.w800
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _timeAgo(notification.createdAt),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (!isRead) ...[
                          const SizedBox(width: 7),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.brand,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.message.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        notification.message.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationsSkeleton extends StatelessWidget {
  const _NotificationsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < 4; index++) ...[
          Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.line),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Icon(icon, size: 42, color: AppColors.brand),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              height: 1.45,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(AppIcons.refresh_rounded, size: 16),
              label: Text(actionLabel!),
            ),
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

Map<_DriverNotificationFilter, int> _countsFor(
  List<ClientNotification> notifications,
) {
  final counts = {
    for (final filter in _DriverNotificationFilter.values) filter: 0,
  };
  counts[_DriverNotificationFilter.all] = notifications.length;
  for (final notification in notifications) {
    final filter = _filterFor(notification);
    counts[filter] = (counts[filter] ?? 0) + 1;
  }
  return counts;
}

_DriverNotificationFilter _filterFor(ClientNotification notification) {
  switch (_notificationType(notification)) {
    case 'booking':
    case 'trip':
    case 'driver_request':
    case 'job_request':
    case 'incident':
    case 'payment':
      return _DriverNotificationFilter.trips;
    case 'chat':
      return _DriverNotificationFilter.chat;
    default:
      return _DriverNotificationFilter.system;
  }
}

_NotificationMeta _metaFor(ClientNotification notification) {
  switch (_notificationType(notification)) {
    case 'booking':
    case 'trip':
    case 'driver_request':
    case 'job_request':
      return const _NotificationMeta(
        icon: AppIcons.local_shipping_rounded,
        color: AppColors.brandDark,
        background: AppColors.brandTint,
      );
    case 'incident':
      return const _NotificationMeta(
        icon: AppIcons.report_problem_rounded,
        color: AppColors.warningText,
        background: AppColors.warningFill,
      );
    case 'payment':
      return const _NotificationMeta(
        icon: AppIcons.receipt_long_rounded,
        color: AppColors.brandInk,
        background: AppColors.brandFill,
      );
    case 'chat':
      return const _NotificationMeta(
        icon: AppIcons.chat_bubble_rounded,
        color: AppColors.accentBlue,
        background: Color(0xFFE8F1F8),
      );
    case 'kyc':
      return const _NotificationMeta(
        icon: AppIcons.verified_user_rounded,
        color: AppColors.accentBlue,
        background: Color(0xFFE8F1F8),
      );
    default:
      return const _NotificationMeta(
        icon: AppIcons.notifications_rounded,
        color: AppColors.textSecondary,
        background: AppColors.fillSubtle,
      );
  }
}

String? _routeForNotification(ClientNotification notification) {
  final type = _notificationType(notification);
  final meta = _asMap(notification.raw['meta']);
  final bookingId = _readString(meta, const ['bookingId', 'booking_id']);
  final tripId = _readString(meta, const ['tripId', 'trip_id']);

  switch (type) {
    case 'chat':
      if (bookingId.isNotEmpty) return '/driver/chats/$bookingId';
      return '/driver/chats';
    case 'booking':
    case 'trip':
    case 'incident':
      if (bookingId.isNotEmpty) return '/driver/deliveries/$bookingId';
      if (tripId.isNotEmpty) return '/driver/delivery-details/$tripId';
      return '/driver/active';
    case 'driver_request':
    case 'job_request':
      return '/driver/home';
    case 'payment':
      return '/driver/earnings';
    case 'kyc':
      return '/driver/kyc-registration';
    default:
      return null;
  }
}

List<ClientNotification> _notificationsFromResponse(Map<String, dynamic> json) {
  final data = _asMap(json['data']);
  final items =
      data['notifications'] ??
      data['items'] ??
      data['results'] ??
      json['notifications'] ??
      json['items'] ??
      json['results'] ??
      const [];
  if (items is! List) return const [];
  return items
      .whereType<Map>()
      .map((item) => ClientNotification.fromJson(_asMap(item)))
      .where((notification) => notification.id.isNotEmpty)
      .toList();
}

String _notificationType(ClientNotification notification) {
  return _readString(notification.raw, const [
    'type',
    'notification_type',
  ]).trim().toLowerCase();
}

String _timeAgo(DateTime? date) {
  if (date == null) return '';
  final local = date.toLocal();
  final now = DateTime.now();
  final diff = now.difference(local);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${local.day}/${local.month}';
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
