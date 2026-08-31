import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientSettingsScreen extends StatelessWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE8EDF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                _SettingsMenuTile(
                  title: 'Notifications',
                  subtitle: 'Review booking updates and invoice alerts',
                  icon: Icons.notifications_active_outlined,
                  iconBackgroundColor: const Color(0xFFE0F4E8),
                  iconColor: const Color(0xFF2FA56E),
                  onTap: () => context.push('/client/notifications'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Change password',
                  subtitle: 'Update the password for this account',
                  icon: Icons.password_rounded,
                  iconBackgroundColor: const Color(0xFFDDEBFF),
                  iconColor: const Color(0xFF2D6EF2),
                  onTap: () => context.push('/change-password'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Manage account',
                  subtitle: 'Update your name, email, phone, and photo',
                  icon: Icons.manage_accounts_rounded,
                  iconBackgroundColor: const Color(0xFFF2E8FF),
                  iconColor: const Color(0xFF7A4FD6),
                  onTap: () => context.push('/manage-account'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Saved Addresses',
                  subtitle: 'Manage pickup and drop locations',
                  icon: Icons.location_on_outlined,
                  iconBackgroundColor: const Color(0xFFE0F4E8),
                  iconColor: const Color(0xFF2FA56E),
                  onTap: () => context.push('/client/saved-addresses'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Payment Methods',
                  subtitle: 'Save UPI IDs, cards, banks, and wallets',
                  icon: Icons.credit_card_outlined,
                  iconBackgroundColor: const Color(0xFFE0F4E8),
                  iconColor: const Color(0xFF2FA56E),
                  onTap: () => context.push('/client/payment-methods'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsMenuTile extends StatelessWidget {
  const _SettingsMenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}
