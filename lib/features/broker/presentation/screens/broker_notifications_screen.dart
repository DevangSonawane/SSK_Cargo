import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
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
    final groups = _groupByDate(filtered);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: RefreshIndicator(
                color: AppColors.brand,
                onRefresh: _refresh,
                child: ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                  children: [
                    _NotificationsHeader(
                      unreadCount: unreadCount,
                      markingAllRead: _markingAllRead,
                      onMarkAllRead: unreadCount > 0 ? _markAllRead : null,
                      onBack: () => context.pop(),
                    ),
                    const SizedBox(height: 22),
                    _NotificationTabs(
                      selected: _tab,
                      counts: _tabsEnabled(notifications),
                      onChanged: (tab) => setState(() => _tab = tab),
                    ),
                    const SizedBox(height: 22),
                    ..._buildSection(notificationsAsync, groups),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<_NotificationTab, int> _tabsEnabled(List<ClientNotification> all) {
    final counts = {for (final tab in _NotificationTab.values) tab: 0};
    for (final notification in all) {
      counts[_categoryFor(notification)] = counts[_categoryFor(notification)]! + 1;
    }
    counts[_NotificationTab.all] = all.length;
    return counts;
  }

  List<Widget> _buildSection(
    AsyncValue<List<ClientNotification>> notificationsAsync,
    List<_NotificationGroup> groups,
  ) {
    if (notificationsAsync.isLoading) {
      return const [
        _NotificationSkeletonList(),
        SizedBox(height: 24),
      ];
    }
    if (notificationsAsync.hasError) {
      return [
        _NotificationEmptyState(
          icon: AppIcons.inbox_outlined,
          title: "Couldn't load your notifications",
          subtitle: notificationsAsync.error
              .toString()
              .replaceFirst('Exception: ', ''),
          actionLabel: 'Retry',
          onAction: _refresh,
        ),
        const SizedBox(height: 24),
      ];
    }
    if (groups.isEmpty) {
      return const [
        _NotificationEmptyState(
          icon: AppIcons.notifications_none_rounded,
          title: 'You are all caught up!',
          subtitle: 'Alerts and updates about your fleet will show up here.',
        ),
        SizedBox(height: 24),
      ];
    }

    final widgets = <Widget>[];
    for (final group in groups) {
      widgets.add(_NotificationSectionHeader(title: group.title));
      const gap = SizedBox(height: 6);
      widgets.add(gap);
      for (final notification in group.items) {
        widgets.add(_NotificationCard(
          notification: notification,
          onTap: () => _markRead(notification),
          onAction: _actionLabel(notification) == null
              ? null
              : () => _openNotification(notification),
        ));
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(const SizedBox(height: 18));
    }
    return widgets;
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader({
    required this.unreadCount,
    required this.markingAllRead,
    required this.onMarkAllRead,
    required this.onBack,
  });

  final int unreadCount;
  final bool markingAllRead;
  final VoidCallback? onMarkAllRead;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BrokerBackButton(onTap: onBack),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  if (unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$unreadCount new',
                        style: const TextStyle(
                          color: AppColors.brandInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  if (unreadCount > 0) const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      'Stay on top of your fleet activity.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (unreadCount > 0)
          InkWell(
            onTap: markingAllRead ? null : onMarkAllRead,
            borderRadius: BorderRadius.circular(999),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: markingAllRead
                    ? AppColors.brandFill
                    : AppColors.brandTint,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.brandBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 15,
                    height: 15,
                    child: markingAllRead
                        ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brand,
                          )
                        : const Icon(
                            AppIcons.done_all_rounded,
                            size: 15,
                            color: AppColors.brandInk,
                          ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    markingAllRead ? 'Saving' : 'Mark all read',
                    style: const TextStyle(
                      color: AppColors.brandInk,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationTabs extends StatelessWidget {
  const _NotificationTabs({
    required this.selected,
    required this.counts,
    required this.onChanged,
  });

  final _NotificationTab selected;
  final Map<_NotificationTab, int> counts;
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
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            for (final tab in tabs)
              _NotificationTabButton(
                label: tab.$2,
                count: counts[tab.$1] ?? 0,
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
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.brandInk : AppColors.textTertiary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.brandTint
                      : AppColors.fillSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? AppColors.brandInk
                        : AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NotificationSectionHeader extends StatelessWidget {
  const _NotificationSectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
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
    final isRead = notification.isRead;
    final title = notification.title.isEmpty
        ? 'Notification'
        : notification.title;
    final message = notification.message;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 14 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
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
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _NotificationIconChip(meta: meta, isRead: isRead),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: isRead
                                      ? AppColors.fillSubtle
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  _timeAgo(notification.createdAt),
                                  style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              if (!isRead) ...[
                                const SizedBox(width: 5),
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
                        ],
                      ),
                      const SizedBox(height: 5),
                      if (message.isNotEmpty)
                        Text(
                          message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (actionLabel != null && onAction != null) ...[
                        const SizedBox(height: 12),
                        _NotificationActionButton(
                          label: actionLabel,
                          onPressed: () => onAction!(),
                        ),
                      ],
                    ],
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

class _NotificationIconChip extends StatelessWidget {
  const _NotificationIconChip({required this.meta, required this.isRead});

  final _NotificationMeta meta;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isRead
              ? [meta.background, meta.background]
              : [meta.background, meta.selected ?? meta.background],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: meta.color.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(meta.icon, color: meta.color, size: 21),
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.brandFill,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.brandBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.brandInk,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 5),
            const Icon(
              AppIcons.arrow_forward_rounded,
              size: 13,
              color: AppColors.brandInk,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSkeletonList extends StatefulWidget {
  const _NotificationSkeletonList();

  @override
  State<_NotificationSkeletonList> createState() =>
      _NotificationSkeletonListState();
}

class _NotificationSkeletonListState extends State<_NotificationSkeletonList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 4; i++) ...[
          FadeTransition(
            opacity: Tween(begin: 0.45, end: 1.0).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
            ),
            child: Container(
              height: 104,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 150,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppColors.fillSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.fillSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          width: 100,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.fillSubtle,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.brandTint, AppColors.brandFill],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.14),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, size: 34, color: AppColors.brand),
          ),
          const SizedBox(height: 20),
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
              iconAlignment: IconAlignment.end,
              icon: const Icon(AppIcons.refresh_rounded, size: 16),
              label: Text(actionLabel!),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                textStyle: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
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
    this.selected,
  });

  final IconData icon;
  final Color color;
  final Color background;
  final Color? selected;
}

class _NotificationGroup {
  const _NotificationGroup({required this.title, required this.items});

  final String title;
  final List<ClientNotification> items;
}

List<_NotificationGroup> _groupByDate(List<ClientNotification> items) {
  if (items.isEmpty) return const [];

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final grouped = <String, List<ClientNotification>>{};
  for (final item in items) {
    final date = item.createdAt?.toLocal();
    final day = date == null
        ? null
        : DateTime(date.year, date.month, date.day);
    final key = day == null
        ? 'Earlier'
        : day.isAfter(yesterday)
        ? (day.isAtSameMomentAs(today) ? 'Today' : 'Yesterday')
        : 'Earlier';
    grouped.putIfAbsent(key, () => []).add(item);
  }

  const order = ['Today', 'Yesterday', 'Earlier'];
  final result = <_NotificationGroup>[];
  for (final key in order) {
    final items = grouped[key];
    if (items != null && items.isNotEmpty) {
      result.add(_NotificationGroup(title: key, items: items));
    }
  }
  return result;
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
        color: AppColors.brandDark,
        background: AppColors.brandTint,
        selected: AppColors.brandFill,
      );
    case 'incident':
      return const _NotificationMeta(
        icon: AppIcons.build_rounded,
        color: AppColors.warningText,
        background: AppColors.warningFill,
        selected: Colors.white,
      );
    case 'chat':
      return const _NotificationMeta(
        icon: AppIcons.chat_bubble_rounded,
        color: AppColors.accentBlue,
        background: Color(0xFFE8F1F8),
        selected: Color(0xFFD7E7F4),
      );
    case 'payment':
      return const _NotificationMeta(
        icon: AppIcons.receipt_long_rounded,
        color: AppColors.brandInk,
        background: AppColors.brandTint,
        selected: AppColors.brandFill,
      );
    case 'dispute':
      return const _NotificationMeta(
        icon: AppIcons.report_problem_rounded,
        color: AppColors.dangerIcon,
        background: AppColors.dangerFill,
        selected: Colors.white,
      );
    case 'kyc':
      return const _NotificationMeta(
        icon: AppIcons.verified_user_rounded,
        color: AppColors.accentBlue,
        background: Color(0xFFE8F1F8),
        selected: Color(0xFFD7E7F4),
      );
    default:
      return const _NotificationMeta(
        icon: AppIcons.notifications_rounded,
        color: AppColors.textSecondary,
        background: AppColors.fillSubtle,
        selected: Colors.white,
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
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = now.difference(local);

  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  if (day.isAtSameMomentAs(today)) {
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '$hour:$minute';
  }
  if (diff.inHours < 48) return 'Yesterday';
  return '$hour:$minute, ${local.day}/${local.month}';
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