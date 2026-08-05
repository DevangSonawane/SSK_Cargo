import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/driver_location_tracker_provider.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/driver_flow_widgets.dart';

class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncTracking(ref.read(driverOnlineProvider)));
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && ref.read(driverOnlineProvider)) {
      unawaited(_syncTracking(true, restart: true));
    }
  }

  Future<void> _syncTracking(bool isOnline, {bool restart = false}) async {
    final tracker = ref.read(driverLocationTrackerProvider);
    String? message;
    if (isOnline) {
      message = restart
          ? await tracker.restartTracking()
          : await tracker.startTracking();
    } else {
      await tracker.stopTracking();
    }

    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () => Geolocator.openLocationSettings(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(ref.read(driverLocationTrackerProvider).stopTracking());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(driverOnlineProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(_syncTracking(next));
    });

    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName;
    final firstName = displayName?.split(' ').first ?? 'Driver';
    final headerTitle = 'Good ${_timeOfDayLabel()}';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              18,
              MediaQuery.of(context).padding.top + 8,
              18,
              10,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2FA56E), Color(0xFF1F88C9)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1F88C9).withValues(alpha: 0.18),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headerTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        firstName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: () => context.push('/driver/profile'),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: SskProfileAvatar(
                      imageUrl: session?.user.profileImage,
                      size: 46,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
      bottomNavigationBar: DriverBottomBar(
        currentIndex: widget.navigationShell.currentIndex,
        onTap: (index) {
          if (index == widget.navigationShell.currentIndex) return;
          widget.navigationShell.goBranch(index, initialLocation: false);
        },
      ),
    );
  }
}

String _timeOfDayLabel() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'morning';
  if (hour < 17) return 'afternoon';
  return 'evening';
}
