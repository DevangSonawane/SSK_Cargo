import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GpsMapBottomNavBar extends StatelessWidget {
  const GpsMapBottomNavBar({super.key, required this.currentRoute});

  final String currentRoute;

  bool get _isMapsRoute => currentRoute.startsWith('/gps/maps');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.home_rounded,
                      label: 'Dashboard',
                      selected: currentRoute == '/gps/dashboard',
                      onTap: () => context.go('/gps/dashboard'),
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Vehicles',
                      selected: currentRoute == '/gps/vehicles',
                      onTap: () => context.go('/gps/vehicles'),
                    ),
                  ),
                  const Expanded(child: SizedBox(width: 58)),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.insert_chart_rounded,
                      label: 'Reports',
                      selected: currentRoute == '/gps/reports',
                      onTap: () => context.go('/gps/reports'),
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      selected: currentRoute == '/gps/profile',
                      onTap: () => context.go('/gps/profile'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -20,
              child: InkWell(
                onTap: () => context.go('/gps/maps'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: _isMapsRoute
                          ? [const Color(0xFF3D7BFF), const Color(0xFF1F4CD6)]
                          : [const Color(0xFF2E68F5), const Color(0xFF234CC8)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF234CC8).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsNavItem extends StatelessWidget {
  const _GpsNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2D6EF2) : const Color(0xFF8692A8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
