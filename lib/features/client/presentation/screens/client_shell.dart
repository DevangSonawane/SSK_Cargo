import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/widgets/client_verification_gate.dart';
import '../widgets/client_flow_widgets.dart';

class ClientShell extends ConsumerStatefulWidget {
  const ClientShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends ConsumerState<ClientShell> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isBottomNavVisible = ref.watch(bottomNavVisibleProvider);
    final currentIndex = _visibleTabIndex(widget.navigationShell.currentIndex);
    // Home and Profile remain reachable while KYC is pending; deliveries and
    // tracking are part of the client-wide verification lock.
    final gated =
        widget.navigationShell.currentIndex == 1 ||
        widget.navigationShell.currentIndex == 2 ||
        widget.navigationShell.currentIndex == 3;

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: gated
                ? ClientVerificationGate(child: widget.navigationShell)
                : widget.navigationShell,
          ),
          if (isBottomNavVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClientBottomBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  // Use locations rather than a hard branch index. It stays
                  // safe if the shell is restored from a previous app build.
                  final location = switch (index) {
                    0 => '/client/home',
                    1 => '/client/delivery',
                    2 => '/client/wallet',
                    3 => '/client/profile',
                    _ => '/client/home',
                  };
                  context.go(location);
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
    case 4:
      return 3;
    default:
      return 0;
  }
}

