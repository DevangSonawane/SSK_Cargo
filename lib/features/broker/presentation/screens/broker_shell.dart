import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerShell extends ConsumerWidget {
  const BrokerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(
      brokerJobRequestsProvider((page: 1, limit: 100)),
    );
    final activeJobsCount =
        ref.watch(brokerActiveJobsCountProvider).valueOrNull ?? 0;
    final pendingCount =
        requestsAsync.valueOrNull
            ?.where(isBrokerJobRequestAttentionCount)
            .length ??
        0;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName;
    final location = GoRouterState.of(context).uri.path;
    final showHeader =
        location != '/broker/profile' &&
        location != '/broker/earnings' &&
        location != '/broker/home' &&
        location != '/broker/active-jobs' &&
        !location.startsWith('/broker/vehicles') &&
        !location.startsWith('/broker/tracking') &&
        !location.startsWith('/broker/history');
    final showBottomNav =
        location != '/broker/profile' &&
        location != '/broker/earnings' &&
        !location.startsWith('/broker/history/');
    final currentTab = navigationShell.currentIndex;
    final headerTitle = switch (currentTab) {
      0 =>
        displayName == null
            ? 'Good morning, Aman'
            : 'Good morning, ${displayName.split(' ').first}',
      1 => 'Active Jobs',
      2 => 'Vehicles',
      3 => 'Tracking',
      4 => 'History',
      _ => 'Broker',
    };
    final headerSubtitle = switch (currentTab) {
      0 => 'New bookings waiting for you',
      1 => 'Jobs currently in progress',
      2 => 'Manage your fleet at a glance',
      3 => 'Monitor driver movement',
      4 => 'Review recent bookings',
      _ => null,
    };

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        extendBody: true,
        backgroundColor: AppColors.canvas,
        body: Stack(
          children: [
            Positioned.fill(
              child: Column(
                children: [
                  if (showHeader) ...[
                    BrokerHeader(
                      highlighted: true,
                      title: headerTitle,
                      subtitle: headerSubtitle,
                      pendingRequestsCount: pendingCount,
                      onAvatarTap: () => context.push('/broker/profile'),
                      onNotificationsTap: () =>
                          context.push('/broker/notifications'),
                      onChatTap: () => context.push('/broker/chats'),
                      chatUnreadCount: ref.watch(chatUnreadCountProvider),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Expanded(child: navigationShell),
                ],
              ),
            ),
            if (showBottomNav)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BrokerBottomBar(
                  currentIndex: navigationShell.currentIndex,
                  pendingRequestsCount: pendingCount,
                  activeJobsCount: activeJobsCount,
                  onTap: (index) {
                    final route = switch (index) {
                      0 => '/broker/home',
                      1 => '/broker/active-jobs',
                      2 => '/broker/vehicles',
                      3 => '/broker/tracking',
                      4 => '/broker/history',
                      _ => '/broker/home',
                    };
                    context.go(route);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
