import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final displayName = user?.displayName ?? 'Client';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.split(' ').first,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    Text(
                      displayName.contains(' ') ? displayName.split(' ').skip(1).join(' ') : 'Profile',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F4F8),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE5EAF0), width: 1.2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: user?.profileImage == null
                      ? Image.asset('assets/user.png', fit: BoxFit.cover)
                      : Image.network(
                          user!.profileImage!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/user.png', fit: BoxFit.cover);
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No account connected yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Help',
                    icon: Icons.support_agent_rounded,
                    backgroundColor: const Color(0xFFF5F7FB),
                    iconColor: const Color(0xFF2D6EF2),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Safety',
                    icon: Icons.shield_rounded,
                    backgroundColor: const Color(0xFFF5F7FB),
                    iconColor: const Color(0xFF2FA56E),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _ProfileMenuTile(
              title: 'Settings',
              icon: Icons.settings_rounded,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Change password',
              icon: Icons.password_rounded,
              onTap: () => context.push('/change-password'),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Manage account',
              icon: Icons.manage_accounts_rounded,
              onTap: () => context.push('/manage-account'),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Logout',
              icon: Icons.logout_rounded,
              onTap: () async {
                await ref.read(authSessionProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              titleColor: const Color(0xFFE23A4B),
              iconColor: const Color(0xFFE23A4B),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.title,
    required this.icon,
    required this.onTap,
    this.titleColor = const Color(0xFF101828),
    this.iconColor = const Color(0xFF1C2430),
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}
