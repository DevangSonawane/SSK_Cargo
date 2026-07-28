import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';

class GpsSidebarDrawer extends ConsumerWidget {
  const GpsSidebarDrawer({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final userName = session?.user.displayName ?? 'Gadidost';
    final userEmail = session?.user.email ?? 'sskcargoservices@gmail.com';
    final initial = userName.trim().isNotEmpty
        ? userName.trim()[0].toUpperCase()
        : 'G';

    return Drawer(
      width: MediaQuery.sizeOf(context).width * 0.82,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(0),
            bottomRight: Radius.circular(0),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                removeBottom: true,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SidebarHero(
                        userName: userName,
                        userEmail: userEmail,
                        initial: initial,
                      ),
                      const SizedBox(height: 4),
                      _SidebarNavTile(
                        icon: Icons.grid_view_rounded,
                        label: 'Dashboard',
                        selected: currentRoute == '/gps/dashboard',
                        onTap: () => _go(context, '/gps/dashboard'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.local_shipping_rounded,
                        label: 'My Fleet',
                        selected: currentRoute == '/gps/vehicles',
                        onTap: () => _go(context, '/gps/vehicles'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.map_outlined,
                        label: 'Live Map',
                        selected: false,
                        onTap: () => _showComingSoon(context, 'Live Map'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.insert_chart_rounded,
                        label: 'Reports',
                        selected: currentRoute == '/gps/reports',
                        onTap: () => _go(context, '/gps/reports'),
                      ),
                      const _SectionHeader(label: 'Modules'),
                      _SidebarNavTile(
                        icon: Icons.gps_fixed_rounded,
                        label: 'Geofences',
                        selected: currentRoute == '/gps/geofences',
                        onTap: () => _go(context, '/gps/geofences'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.account_balance_wallet_rounded,
                        label: 'Wallet & Billing',
                        selected: currentRoute == '/gps/wallet-billing',
                        onTap: () => _go(context, '/gps/wallet-billing'),
                      ),
                      const _SectionHeader(label: 'Account'),
                      _SidebarNavTile(
                        icon: Icons.person_rounded,
                        label: 'Profile',
                        selected: currentRoute == '/gps/profile',
                        onTap: () => _go(context, '/gps/profile'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        selected: false,
                        onTap: () => _showComingSoon(context, 'Settings'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.palette_outlined,
                        label: 'Appearance',
                        selected: false,
                        onTap: () => _showComingSoon(context, 'Appearance'),
                      ),
                      _SidebarNavTile(
                        icon: Icons.logout_rounded,
                        label: 'Logout',
                        selected: false,
                        danger: true,
                        onTap: () async {
                          await ref.read(authSessionProvider.notifier).logout();
                          if (!context.mounted) return;
                          context.go('/gps/login');
                        },
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F7FC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'App Version 2.4.0',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF72809B),
                                ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String route) {
    Navigator.of(context).pop();
    context.go(route);
  }

  void _showComingSoon(BuildContext context, String name) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$name screen coming next.')),
    );
  }
}

class _SidebarHero extends StatelessWidget {
  const _SidebarHero({
    required this.userName,
    required this.userEmail,
    required this.initial,
  });

  final String userName;
  final String userEmail;
  final String initial;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 188,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/gps_tracking_screen_fotos/sidebar_image.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF081633).withValues(alpha: 0.12),
                  const Color(0xFF081633).withValues(alpha: 0.32),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            left: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF1E63D8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.82),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF19C37D),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      userEmail,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.84),
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarNavTile extends StatelessWidget {
  const _SidebarNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger
        ? const Color(0xFFE23A4B)
        : selected
            ? const Color(0xFF2D6EF2)
            : const Color(0xFF24324B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      child: Material(
        color: selected ? const Color(0xFFEAF1FF) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEAF1FF) : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: fg,
                        ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF8A96AB),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 3),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF8492AA),
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
