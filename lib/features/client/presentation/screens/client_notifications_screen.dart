import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/client_booking_models.dart';
import '../controllers/client_notifications_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';

enum _InboxFilter { all, unread }

enum _NotifKind { booking, payment, offer, system }

class ClientNotificationsScreen extends ConsumerStatefulWidget {
  const ClientNotificationsScreen({super.key});

  @override
  ConsumerState<ClientNotificationsScreen> createState() =>
      _ClientNotificationsScreenState();
}

class _ClientNotificationsScreenState
    extends ConsumerState<ClientNotificationsScreen> {
  bool _markingAllRead = false;
  _InboxFilter _filter = _InboxFilter.all;
  final Set<String> _optimisticReadIds = <String>{};

  bool _isEffectivelyRead(ClientNotification n) =>
      n.isRead || _optimisticReadIds.contains(n.id);

  Future<void> _refresh() async {
    ref.invalidate(clientNotificationsProvider);
    try {
      await ref.read(clientNotificationsProvider.future);
    } catch (_) {
      // Error UI is driven by provider state.
    }
  }

  Future<void> _markAllRead() async {
    if (_markingAllRead) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final current = ref.read(clientNotificationsProvider).valueOrNull;
    if (current != null && current.isNotEmpty) {
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
      ref.invalidate(clientNotificationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All caught up — inbox marked as read.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _markingAllRead = false);
      }
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
      ref.invalidate(clientNotificationsProvider);
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colors = context.colors;
        final kind = _kindFor(notification);
        final tint = _tintFor(kind, colors);
        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 14,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: colors.line),
              boxShadow: AppShadows.float,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: tint.bg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: tint.border),
                      ),
                      child: Icon(kind.icon, color: tint.fg, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tint.bg,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: tint.border),
                            ),
                            child: Text(
                              kind.label.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: tint.fg,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _timeAgo(notification.createdAt),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  notification.title.isEmpty
                      ? 'Notification'
                      : notification.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  notification.message.isEmpty
                      ? 'No message available.'
                      : notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2FA56E), Color(0xFF1E7A4C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x402FA56E),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Got it',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final notificationsAsync = ref.watch(clientNotificationsProvider);
    final all = notificationsAsync.valueOrNull ?? const <ClientNotification>[];
    final unreadCount = all.where((n) => !_isEffectivelyRead(n)).length;
    final isBackgroundRefresh =
        (notificationsAsync.isRefreshing || notificationsAsync.isReloading) &&
        notificationsAsync.hasValue;

    final visible = _filter == _InboxFilter.all
        ? all
        : all.where((n) => !_isEffectivelyRead(n)).toList(growable: false);
    final groups = _groupByDate(visible);

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2FA56E),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              _Header(
                markingAllRead: _markingAllRead,
                hasUnread: unreadCount > 0,
                onMarkAllRead: _markAllRead,
                onBack: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/client/home');
                  }
                },
              ),
              if (isBackgroundRefresh) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  color: Color(0xFF2FA56E),
                  backgroundColor: Color(0xFFEAF8EF),
                  borderRadius: BorderRadius.all(Radius.circular(999)),
                ),
              ],
              const SizedBox(height: 14),
              _FilterRow(
                filter: _filter,
                allCount: all.length,
                unreadCount: unreadCount,
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(height: 18),
              ..._buildBody(
                context,
                notificationsAsync,
                groups,
                visible,
                unreadCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBody(
    BuildContext context,
    AsyncValue<List<ClientNotification>> async,
    List<_DateGroup> groups,
    List<ClientNotification> visible,
    int unreadCount,
  ) {
    if (async.isLoading && !async.hasValue) {
      return const [_SkeletonList()];
    }
    if (async.hasError && !async.hasValue) {
      return [
        _StateCard(
          icon: AppIcons.notifications_off_outlined,
          title: 'Could not load notifications',
          subtitle: async.error.toString().replaceFirst('Exception: ', ''),
          actionLabel: 'Try again',
          onAction: _refresh,
        ),
      ];
    }
    if (visible.isEmpty) {
      if (_filter == _InboxFilter.unread && unreadCount == 0) {
        return const [
          _StateCard(
            icon: AppIcons.notifications_none_rounded,
            title: 'All caught up',
            subtitle:
                'No unread updates. New booking, payment and trip alerts will land here.',
          ),
        ];
      }
      return const [
        _StateCard(
          icon: AppIcons.notifications_none_rounded,
          title: 'No notifications yet',
          subtitle:
              'Updates about bookings, invoices, and activity will appear here.',
        ),
      ];
    }
    final widgets = <Widget>[];
    for (final group in groups) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Row(
            children: [
              Text(
                group.label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: context.colors.fillSubtle,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: context.colors.line),
                ),
                child: Text(
                  '${group.items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
      for (final n in group.items) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _NotificationCard(
              notification: n,
              isRead: _isEffectivelyRead(n),
              onTap: () => _openNotification(n),
            ),
          ),
        );
      }
    }
    return widgets;
  }
}

// ---------- header / filter ----------

class _Header extends StatelessWidget {
  const _Header({
    required this.markingAllRead,
    required this.hasUnread,
    required this.onMarkAllRead,
    required this.onBack,
  });

  final bool markingAllRead;
  final bool hasUnread;
  final VoidCallback onMarkAllRead;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        InkWell(
          onTap: onBack,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: colors.line),
              boxShadow: AppShadows.card,
            ),
            child: Icon(
              Icons.arrow_back_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Notifications',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(
          onPressed: markingAllRead || !hasUnread ? null : onMarkAllRead,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF167247),
            backgroundColor: colors.brandFill,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
              side: BorderSide(color: colors.brandBorder),
            ),
          ),
          child: Text(
            markingAllRead ? 'Saving…' : 'Mark all read',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
          ),
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.filter,
    required this.allCount,
    required this.unreadCount,
    required this.onChanged,
  });

  final _InboxFilter filter;
  final int allCount;
  final int unreadCount;
  final ValueChanged<_InboxFilter> onChanged;

  static const double innerHeight = 44;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.7),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SizedBox(
            height: innerHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final segmentWidth = constraints.maxWidth / 2;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOutCubic,
                      left: filter == _InboxFilter.all ? 0 : segmentWidth,
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
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onChanged(_InboxFilter.all),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              height: innerHeight,
                              alignment: Alignment.center,
                              child: _SegmentLabel(
                                label: 'All',
                                count: allCount,
                                selected: filter == _InboxFilter.all,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => onChanged(_InboxFilter.unread),
                            behavior: HitTestBehavior.opaque,
                            child: Container(
                              height: innerHeight,
                              alignment: Alignment.center,
                              child: _SegmentLabel(
                                label: 'Unread',
                                count: unreadCount,
                                selected: filter == _InboxFilter.unread,
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

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: selected ? AppColors.brandDark : AppColors.textSecondary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
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
    );
  }
}

// ---------- cards / states ----------

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  final ClientNotification notification;
  final bool isRead;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final kind = _kindFor(notification);
    final tint = _tintFor(kind, colors);
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead ? colors.surface : colors.brandFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isRead ? colors.line : colors.brandBorder,
          ),
          boxShadow: AppShadows.card,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: tint.bg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: tint.border),
                  ),
                  child: Icon(kind.icon, color: tint.fg, size: 22),
                ),
                if (!isRead)
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA56E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                    ),
                  ),
              ],
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
                          notification.title.isEmpty
                              ? 'Notification'
                              : notification.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: isRead
                                    ? FontWeight.w700
                                    : FontWeight.w800,
                                fontSize: 15,
                                color: colors.textPrimary,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    notification.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.textSecondary,
                      height: 1.5,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tint.bg,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tint.border),
                        ),
                        child: Text(
                          kind.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: tint.fg,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 17,
                        color: colors.textSecondary.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
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
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: colors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF8EF), Color(0xFFDFF0E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: colors.brandBorder),
            ),
            child: Icon(icon, size: 36, color: const Color(0xFF2FA56E)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 18),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 13,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: List.generate(
        5,
        (i) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: colors.fillSubtle,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 13,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.fillSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 11,
                      width: MediaQuery.of(context).size.width * 0.5,
                      decoration: BoxDecoration(
                        color: colors.fillSubtle,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
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

// ---------- helpers ----------

class _KindTint {
  const _KindTint({required this.bg, required this.border, required this.fg});
  final Color bg;
  final Color border;
  final Color fg;
}

_KindTint _tintFor(_NotifKind kind, AppColorScheme colors) {
  final isDark = colors.canvas.computeLuminance() < 0.25;
  switch (kind) {
    case _NotifKind.booking:
      return _KindTint(
        bg: colors.brandFill,
        border: colors.brandBorder,
        fg: colors.brandEmphasis,
      );
    case _NotifKind.payment:
      return isDark
          ? const _KindTint(
              bg: Color(0xFF14222E),
              border: Color(0xFF23405A),
              fg: Color(0xFF53B1FD),
            )
          : const _KindTint(
              bg: Color(0xFFEFF6FF),
              border: Color(0xFFD7E7F4),
              fg: Color(0xFF1F88C9),
            );
    case _NotifKind.offer:
      return isDark
          ? const _KindTint(
              bg: Color(0xFF2E2111),
              border: Color(0xFF5C441A),
              fg: Color(0xFFFDB022),
            )
          : const _KindTint(
              bg: Color(0xFFFFF0DB),
              border: Color(0xFFFCD34D),
              fg: Color(0xFFB45309),
            );
    case _NotifKind.system:
      return _KindTint(
        bg: colors.fillSubtle,
        border: colors.line,
        fg: colors.textSecondary,
      );
  }
}

extension on _NotifKind {
  String get label {
    switch (this) {
      case _NotifKind.booking:
        return 'Booking';
      case _NotifKind.payment:
        return 'Payment';
      case _NotifKind.offer:
        return 'Offer';
      case _NotifKind.system:
        return 'Update';
    }
  }

  IconData get icon {
    switch (this) {
      case _NotifKind.booking:
        return AppIcons.notifications_active_rounded;
      case _NotifKind.payment:
        return Icons.receipt_long_rounded;
      case _NotifKind.offer:
        return Icons.local_offer_outlined;
      case _NotifKind.system:
        return AppIcons.notifications_none_rounded;
    }
  }
}

_NotifKind _kindFor(ClientNotification n) {
  final text = '${n.title} ${n.message}'.toLowerCase();
  if (text.contains('pay') ||
      text.contains('invoice') ||
      text.contains('refund') ||
      text.contains('amount') ||
      text.contains('upi') ||
      text.contains('razorpay')) {
    return _NotifKind.payment;
  }
  if (text.contains('offer') ||
      text.contains('discount') ||
      text.contains('coupon') ||
      text.contains('promo') ||
      text.contains('% off')) {
    return _NotifKind.offer;
  }
  if (text.contains('book') ||
      text.contains('truck') ||
      text.contains('trip') ||
      text.contains('driver') ||
      text.contains('pickup') ||
      text.contains('deliver')) {
    return _NotifKind.booking;
  }
  return _NotifKind.system;
}

String _timeAgo(DateTime? dt) {
  if (dt == null) return 'Just now';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return diff.inDays == 1 ? 'Yesterday' : '${diff.inDays}d ago';
  return '${dt.toLocal().day}/${dt.toLocal().month}/${dt.toLocal().year}';
}

class _DateGroup {
  _DateGroup(this.label, this.items);
  final String label;
  final List<ClientNotification> items;
}

List<_DateGroup> _groupByDate(List<ClientNotification> items) {
  final today = <ClientNotification>[];
  final yesterday = <ClientNotification>[];
  final earlier = <ClientNotification>[];
  final now = DateTime.now();
  for (final n in items) {
    final dt = n.createdAt?.toLocal();
    if (dt == null) {
      today.add(n);
      continue;
    }
    final dayDiff = DateTime(
      now.year,
      now.month,
      now.day,
    ).difference(DateTime(dt.year, dt.month, dt.day)).inDays;
    if (dayDiff <= 0) {
      today.add(n);
    } else if (dayDiff == 1) {
      yesterday.add(n);
    } else {
      earlier.add(n);
    }
  }
  final groups = <_DateGroup>[];
  if (today.isNotEmpty) groups.add(_DateGroup('Today', today));
  if (yesterday.isNotEmpty) groups.add(_DateGroup('Yesterday', yesterday));
  if (earlier.isNotEmpty) groups.add(_DateGroup('Earlier', earlier));
  return groups;
}
