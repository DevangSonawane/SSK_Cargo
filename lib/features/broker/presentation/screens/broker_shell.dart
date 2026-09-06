import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final pendingCount =
        requestsAsync.valueOrNull?.where(isPendingBookingRequest).length ?? 0;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName;
    final location = GoRouterState.of(context).uri.path;
    final showHeader =
        location != '/broker/profile' &&
        location != '/broker/home' &&
        location != '/broker/vehicles' &&
        location != '/broker/tracking' &&
        location != '/broker/history';
    final showBottomNav = location != '/broker/profile';
    final currentTab = navigationShell.currentIndex;
    final headerTitle = switch (currentTab) {
      0 =>
        displayName == null
            ? 'Good morning, Aman'
            : 'Good morning, ${displayName.split(' ').first}',
      1 => 'Vehicles',
      2 => 'Tracking',
      3 => 'History',
      _ => 'Broker',
    };
    final headerSubtitle = switch (currentTab) {
      0 => 'New bookings waiting for you',
      1 => 'Manage your fleet at a glance',
      2 => 'Monitor driver movement',
      3 => 'Review recent bookings',
      _ => null,
    };

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          if (showHeader) ...[
            BrokerHeader(
              highlighted: true,
              title: headerTitle,
              subtitle: headerSubtitle,
              pendingRequestsCount: pendingCount,
              onAvatarTap: () => context.push('/broker/profile'),
              onNotificationsTap: () => context.push('/broker/notifications'),
              onChatTap: () => context.push('/broker/chats'),
              chatUnreadCount: ref.watch(chatUnreadCountProvider),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: showBottomNav
          ? BrokerBottomBar(
              currentIndex: navigationShell.currentIndex,
              pendingRequestsCount: pendingCount,
              onTap: (index) {
                final route = switch (index) {
                  0 => '/broker/home',
                  1 => '/broker/vehicles',
                  2 => '/broker/tracking',
                  3 => '/broker/history',
                  _ => '/broker/home',
                };
                context.go(route);
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
