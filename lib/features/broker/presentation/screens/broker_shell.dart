import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerShell extends ConsumerWidget {
  const BrokerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
    final brokerName = displayName?.split(' ').first ?? 'Aman';
    final headerTitle = switch (currentTab) {
      0 => l10n.goodMorningName(brokerName),
      1 => l10n.activeJobs,
      2 => l10n.navVehicles,
      3 => l10n.navTracking,
      4 => l10n.navHistory,
      _ => l10n.broker,
    };
    final headerSubtitle = switch (currentTab) {
      0 => l10n.newBookingsWaiting,
      1 => l10n.jobsInProgress,
      2 => l10n.manageFleetAtGlance,
      3 => l10n.monitorDriverMovement,
      4 => l10n.reviewRecentBookings,
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
