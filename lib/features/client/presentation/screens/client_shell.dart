import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
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

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          Positioned.fill(child: widget.navigationShell),
          if (isBottomNavVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClientBottomBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  final branchIndex = _branchIndexForVisibleTab(index);
                  if (branchIndex == widget.navigationShell.currentIndex) {
                    return;
                  }
                  widget.navigationShell.goBranch(
                    branchIndex,
                    initialLocation:
                        branchIndex == widget.navigationShell.currentIndex,
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
