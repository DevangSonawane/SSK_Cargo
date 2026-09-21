import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/driver_dashboard_models.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/driver_flow_widgets.dart';
import '../../../../core/theme/app_tokens.dart';

class DriverShell extends ConsumerStatefulWidget {
  const DriverShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<DriverShell> createState() => _DriverShellState();
}

class _DriverShellState extends ConsumerState<DriverShell> {
  @override
  void didUpdateWidget(covariant DriverShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.navigationShell.currentIndex !=
            widget.navigationShell.currentIndex &&
        widget.navigationShell.currentIndex == 1) {
      ref.invalidate(driverDashboardProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName;
    final firstName = displayName?.split(' ').first ?? 'Driver';
    final headerTitle = 'Good ${_timeOfDayLabel()}';

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
                        colors: [AppColors.brand, AppColors.brandDark],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(AppRadius.card),
                        bottomRight: Radius.circular(AppRadius.card),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
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
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
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
                          borderRadius: BorderRadius.circular(AppRadius.pill),
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
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: DriverBottomBar(
                currentIndex: widget.navigationShell.currentIndex,
                onTap: (index) {
                  if (index == widget.navigationShell.currentIndex) return;
                  widget.navigationShell.goBranch(
                    index,
                    initialLocation: false,
                  );
                },
              ),
            ),
          ],
        ),
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
