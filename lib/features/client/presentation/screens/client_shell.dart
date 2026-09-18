import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../widgets/client_flow_widgets.dart';

class ClientShell extends ConsumerWidget {
  const ClientShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBottomNavVisible = ref.watch(bottomNavVisibleProvider);
    final currentIndex = _visibleTabIndex(navigationShell.currentIndex);

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: navigationShell),
          if (isBottomNavVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClientBottomBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  final branchIndex = _branchIndexForVisibleTab(index);
                  if (branchIndex == navigationShell.currentIndex) {
                    return;
                  }
                  navigationShell.goBranch(
                    branchIndex,
                    initialLocation:
                        branchIndex == navigationShell.currentIndex,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

int _visibleTabIndex(int branchIndex) {
  switch (branchIndex) {
    case 0:
      return 0;
    case 1:
      return 1;
    case 3:
      return 2;
    default:
      return 0;
  }
}

int _branchIndexForVisibleTab(int visibleIndex) {
  switch (visibleIndex) {
    case 0:
      return 0;
    case 1:
      return 1;
    case 2:
      return 3;
    default:
      return 0;
  }
}
