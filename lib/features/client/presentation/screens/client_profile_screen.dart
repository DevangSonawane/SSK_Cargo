import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ClientProfileScreen extends ConsumerStatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  ConsumerState<ClientProfileScreen> createState() =>
      _ClientProfileScreenState();
}

class _ClientProfileScreenState extends ConsumerState<ClientProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshProfile();
    });
  }

  Future<void> _refreshProfile() async {
    try {
      await ref.read(authSessionProvider.notifier).refreshProfile();
    } catch (_) {
      // Best effort only; the screen can still render from the cached session.
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    Text(
                      displayName.contains(' ')
                          ? displayName.split(' ').skip(1).join(' ')
                          : 'Profile',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                  ],
                ),
                const Spacer(),
                SskProfileAvatar(imageUrl: user?.profileImage, size: 62),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? 'No account connected yet',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            ),
            const SizedBox(height: 16),
            const Divider(color: Color(0xFFE8EDF2), height: 1),
            const SizedBox(height: 16),
            _ProfileMenuTile(
              title: 'Notifications',
              icon: Icons.notifications_active_rounded,
              onTap: () => context.push('/client/notifications'),
              titleColor: const Color(0xFF101828),
              iconColor: const Color(0xFF2FA56E),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Chats',
              icon: Icons.chat_bubble_outline_rounded,
              onTap: () => context.push('/chats'),
              titleColor: const Color(0xFF101828),
              iconColor: const Color(0xFF1F88C9),
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
              title: 'Saved Addresses',
              icon: Icons.location_on_outlined,
              onTap: () => context.push('/client/saved-addresses'),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Payment Methods',
              icon: Icons.credit_card_outlined,
              onTap: () => context.push('/client/payment-methods'),
            ),
            const SizedBox(height: 18),
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
