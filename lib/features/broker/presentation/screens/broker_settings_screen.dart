import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/providers/locale_provider.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/l10n/app_localizations.dart';

class BrokerSettingsScreen extends ConsumerWidget {
  const BrokerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          _LanguageCard(
            selected: locale.languageCode,
            onChanged: (languageCode) {
              ref.read(localeProvider.notifier).setLanguageCode(languageCode);
            },
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.finance,
            subtitle: l10n.financeSubtitle,
            children: [
              _SettingsTile(
                title: l10n.invoices,
                subtitle: l10n.invoicesSubtitle,
                icon: AppIcons.receipt_long_rounded,
                onTap: () => context.push('/broker/settings/invoices'),
              ),
              const SizedBox(height: 10),
              _SettingsTile(
                title: l10n.settlements,
                subtitle: l10n.settlementsSubtitle,
                icon: AppIcons.payments_rounded,
                onTap: () => context.push('/broker/settings/settlements'),
              ),
              const SizedBox(height: 10),
              _SettingsTile(
                title: l10n.analytics,
                subtitle: l10n.analyticsSubtitle,
                icon: AppIcons.bar_chart_rounded,
                onTap: () => context.push('/broker/settings/analytics'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: l10n.notifications,
            subtitle: l10n.brokerNotificationsSectionSubtitle,
            children: [
              _SettingsTile(
                title: l10n.notifications,
                subtitle: l10n.brokerNotificationsSubtitle,
                icon: AppIcons.notifications_active_rounded,
                onTap: () => context.push('/broker/notifications'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.language,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.languageSubtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.75)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.7),
                  blurRadius: 1,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButtonFormField<String>(
                initialValue: selected,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: Colors.white,
                icon: const Icon(
                  AppIcons.keyboard_arrow_down_rounded,
                  color: AppColors.brand,
                  size: 20,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.fromLTRB(14, 12, 10, 12),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                  DropdownMenuItem(value: 'hi', child: Text(l10n.hindi)),
                ],
                onChanged: (value) {
                  if (value != null) onChanged(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.brandFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.accentBlue),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              AppIcons.chevron_right_rounded,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
