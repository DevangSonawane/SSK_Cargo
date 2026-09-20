import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_tokens.dart';

class ClientSettingsScreen extends ConsumerWidget {
  const ClientSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final themeMode = ref.watch(themeModeProvider);
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              _AppearanceCard(
                selected: themeMode,
                onChanged: (mode) =>
                    ref.read(themeModeProvider.notifier).state = mode,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.line),
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
                  title: 'Chats',
                  subtitle: 'View conversations from all your bookings',
                  icon: AppIcons.chat_bubble_outline_rounded,
                  iconBackgroundColor: const Color(0xFFDDEBFF),
                  iconColor: const Color(0xFF1F88C9),
                  onTap: () => context.push('/chats'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Notifications',
                  subtitle: 'Review booking updates and invoice alerts',
                  icon: AppIcons.notifications_active_outlined,
                  iconBackgroundColor: const Color(0xFFE0F4E8),
                  iconColor: const Color(0xFF2FA56E),
                  onTap: () => context.push('/client/notifications'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Change password',
                  subtitle: 'Update the password for this account',
                  icon: AppIcons.password_rounded,
                  iconBackgroundColor: const Color(0xFFDDEBFF),
                  iconColor: const Color(0xFF2D6EF2),
                  onTap: () => context.push('/change-password'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Manage account',
                  subtitle: 'Update your name, email, phone, and photo',
                  icon: AppIcons.manage_accounts_rounded,
                  iconBackgroundColor: const Color(0xFFF2E8FF),
                  iconColor: const Color(0xFF7A4FD6),
                  onTap: () => context.push('/manage-account'),
                ),
                const SizedBox(height: 12),
                _SettingsMenuTile(
                  title: 'Saved Addresses',
                  subtitle: 'Manage pickup and drop locations',
                  icon: AppIcons.location_on_outlined,
                  iconBackgroundColor: const Color(0xFFE0F4E8),
                  iconColor: const Color(0xFF2FA56E),
                  onTap: () => context.push('/client/saved-addresses'),
                ),
                  ],
                ),
              ),
            ],
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
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.fillSubtle,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.line),
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
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevron_right_rounded,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.selected, required this.onChanged});

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Choose how the app looks on this device',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                label: Text('Light'),
                icon: Icon(AppIcons.light_mode_rounded, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text('Auto'),
                icon: Icon(AppIcons.settings_suggest_rounded, size: 16),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text('Dark'),
                icon: Icon(AppIcons.dark_mode_rounded, size: 16),
              ),
            ],
            selected: {selected},
            onSelectionChanged: (selection) => onChanged(selection.first),
            style: SegmentedButton.styleFrom(
              backgroundColor: colors.fillSubtle,
              foregroundColor: colors.textSecondary,
              selectedBackgroundColor: colors.brandFill,
              selectedForegroundColor: colors.textPrimary,
              side: BorderSide(color: colors.line),
            ),
          ),
        ],
      ),
    );
  }
}
