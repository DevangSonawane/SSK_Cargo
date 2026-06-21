import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/broker_flow_widgets.dart';

class BrokerShell extends ConsumerWidget {
  const BrokerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(brokerPendingRequestsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BrokerHeader(
              pendingRequestsCount: pendingCount,
              onAvatarTap: () => context.push('/broker/profile'),
            ),
            const SizedBox(height: 8),
            Expanded(child: navigationShell),
          ],
        ),
      ),
      bottomNavigationBar: BrokerBottomBar(
        currentIndex: navigationShell.currentIndex,
        pendingRequestsCount: pendingCount,
        onTap: (index) {
          if (index == navigationShell.currentIndex) {
            return;
          }
          navigationShell.goBranch(index, initialLocation: index == navigationShell.currentIndex);
        },
      ),
    );
  }
}
