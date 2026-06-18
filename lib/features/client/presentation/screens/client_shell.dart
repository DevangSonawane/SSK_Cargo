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

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: isBottomNavVisible
          ? ClientBottomBar(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) {
                if (index == navigationShell.currentIndex) {
                  return;
                }
                navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                );
              },
            )
          : const SizedBox.shrink(),
    );
  }
}
