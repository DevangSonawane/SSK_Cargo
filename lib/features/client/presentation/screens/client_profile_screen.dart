import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/l10n/app_localizations.dart';

import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/providers/locale_provider.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';

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
      ref.invalidate(
        clientBookingsProvider((status: null, page: 1, limit: 100)),
      );
    } catch (_) {
      // Cached session data is enough for this screen to remain useful.
    }
  }

  Future<void> _signOut() async {
    await ref.read(authSessionProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final bookingsState = ref.watch(
      clientBookingsProvider((status: null, page: 1, limit: 100)),
    );
    final bookings = bookingsState.valueOrNull?.bookings ?? const [];
    final stats = _ProfileStats.fromBookings(bookings);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2FA56E),
          onRefresh: _refreshProfile,
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    Text(
                      l10n.myProfile,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: colors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 14),
                    _ProfileHeroCard(
                      user: user,
                      stats: stats,
                      loadingStats: bookingsState.isLoading,
                      onEdit: () => context.push('/manage-account'),
                    ),
                    const SizedBox(height: 14),
                    _AccountInfoCard(
                      user: user,
                      stats: stats,
                      loading: bookingsState.isLoading,
                      hasError: bookingsState.hasError,
                      onRetry: _refreshProfile,
                    ),
                    const SizedBox(height: 22),
                    _ProfileSection(
                      title: l10n.shipments,
                      children: [
                        _ProfileMenuTile(
                          icon: AppIcons.inventory_2_outlined,
                          title: l10n.myBookings,
                          onTap: () => context.go('/client/delivery'),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.calendar_month_outlined,
                          title: l10n.monthlyVehicleHiring,
                          subtitle: l10n.monthlyVehicleHiringSubtitle,
                          onTap: () => context.push('/client/monthly-hiring'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ProfileSection(
                      title: l10n.account,
                      children: [
                        _ProfileMenuTile(
                          icon: AppIcons.location_on_outlined,
                          title: l10n.savedAddresses,
                          onTap: () => context.push('/client/saved-addresses'),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.notifications_active_outlined,
                          title: l10n.notifications,
                          onTap: () => context.push('/client/notifications'),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.key_rounded,
                          title: l10n.changePasswordTitleCase,
                          onTap: () => context.push('/change-password'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ProfileSection(
                      title: l10n.preferences,
                      children: const [_AppearanceTile(), _LanguageTile()],
                    ),
                    const SizedBox(height: 18),
                    _ProfileSection(
                      title: l10n.help,
                      children: [
                        _ProfileMenuTile(
                          icon: AppIcons.headset_mic_outlined,
                          title: l10n.helpSupport,
                          subtitle: l10n.comingSoon,
                          onTap: () => _showComingSoon(context),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.description_outlined,
                          title: l10n.termsPrivacy,
                          subtitle: l10n.comingSoon,
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SignOutTile(onTap: _signOut),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        l10n.sskVersion,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textTertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.featureComingSoon)),
    );
  }
}

class _ProfileStats {
  const _ProfileStats({
    required this.totalBookings,
    required this.delivered,
    required this.activeShipments,
    required this.totalSpent,
  });

  factory _ProfileStats.fromBookings(List<ClientBooking> bookings) {
    var totalSpent = 0.0;
    var delivered = 0;
    var active = 0;

    for (final booking in bookings) {
      final status = booking.status.toLowerCase();
      if (!status.contains('cancel')) {
        totalSpent += _amountValue(booking.amountText);
      }
      if (status.contains('deliver') || status.contains('complete')) {
        delivered += 1;
      }
      if (status.contains('transit') ||
          status.contains('assigned') ||
          status.contains('active') ||
          status.contains('started')) {
        active += 1;
      }
    }

    return _ProfileStats(
      totalBookings: bookings.length,
      delivered: delivered,
      activeShipments: active,
      totalSpent: totalSpent,
    );
  }

  final int totalBookings;
  final int delivered;
  final int activeShipments;
  final double totalSpent;
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.user,
    required this.stats,
    required this.loadingStats,
    required this.onEdit,
  });

  final SskUser? user;
  final _ProfileStats stats;
  final bool loadingStats;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = user?.displayName ?? l10n.client;
    final initials = _initials(name);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF101828),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.18),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: -44,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2FA56E).withValues(alpha: 0.18),
              ),
            ),
          ),
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.22),
                        border: Border.all(
                          color: const Color(
                            0xFF2FA56E,
                          ).withValues(alpha: 0.42),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _HeroContactLine(
                      icon: AppIcons.phone_rounded,
                      value: _fallback(user?.phone, l10n.notProvided),
                    ),
                    const SizedBox(height: 4),
                    _HeroContactLine(
                      icon: AppIcons.mail_rounded,
                      value: _fallback(user?.email, l10n.notProvided),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: onEdit,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(AppIcons.edit_rounded, size: 16),
                      label: Text(l10n.editProfile),
                    ),
                  ],
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 15,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _HeroStat(
                          value: loadingStats
                              ? '--'
                              : stats.totalBookings.toString(),
                          label: l10n.bookings,
                        ),
                      ),
                      _HeroDivider(),
                      Expanded(
                        child: _HeroStat(
                          value: loadingStats
                              ? '--'
                              : _compactCurrency(stats.totalSpent),
                          label: l10n.spent,
                        ),
                      ),
                      _HeroDivider(),
                      Expanded(
                        child: _HeroStat(
                          value: loadingStats
                              ? '--'
                              : stats.delivered.toString(),
                          label: l10n.delivered,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroContactLine extends StatelessWidget {
  const _HeroContactLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.52)),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.58),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.42),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Colors.white.withValues(alpha: 0.10),
    );
  }
}

class _AccountInfoCard extends StatelessWidget {
  const _AccountInfoCard({
    required this.user,
    required this.stats,
    required this.loading,
    required this.hasError,
    required this.onRetry,
  });

  final SskUser? user;
  final _ProfileStats stats;
  final bool loading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(context.colors),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.accountInfo,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (loading)
            const _AccountInfoLoading()
          else if (hasError)
            Center(
              child: TextButton(
                onPressed: onRetry,
                child: Text(l10n.retryAccountStats),
              ),
            )
          else ...[
            _InfoRow(
              icon: AppIcons.calendar_month_rounded,
              iconColor: const Color(0xFF2FA56E),
              label: l10n.memberSince,
              value: _formatDate(user?.createdAt, l10n),
            ),
            const SizedBox(height: 13),
            _InfoRow(
              icon: AppIcons.inventory_2_rounded,
              iconColor: const Color(0xFF1F88C9),
              label: l10n.activeShipments,
              value: stats.activeShipments.toString(),
            ),
            const SizedBox(height: 13),
            _InfoRow(
              icon: AppIcons.account_balance_wallet_rounded,
              iconColor: const Color(0xFFE6A700),
              label: l10n.lifetimeValue,
              value: _formatCurrency(stats.totalSpent),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountInfoLoading extends StatelessWidget {
  const _AccountInfoLoading();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
          child: Container(
            height: 42,
            decoration: BoxDecoration(
              color: context.colors.fillSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 9),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: context.colors.textTertiary,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: _surfaceDecoration(context.colors),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, indent: 56, color: context.colors.line),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        child: Row(
          children: [
            Icon(icon, size: 21, color: context.colors.textTertiary),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              AppIcons.chevron_right_rounded,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppearanceTile extends ConsumerWidget {
  const _AppearanceTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(
            isDark ? AppIcons.dark_mode_rounded : AppIcons.light_mode_rounded,
            size: 21,
            color: colors.textTertiary,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appearance,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDark
                      ? l10n.appearanceDarkSubtitle
                      : l10n.appearanceLightSubtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _LiquidGlassAppearanceSwitch(
            value: isDark,
            onChanged: (value) {
              ref.read(themeModeProvider.notifier).state = value
                  ? ThemeMode.dark
                  : ThemeMode.light;
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageTile extends ConsumerWidget {
  const _LanguageTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final locale = ref.watch(localeProvider);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Icon(AppIcons.language_rounded, size: 21, color: colors.textTertiary),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.language,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.languageSubtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 132,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.line.withValues(alpha: 0.75)),
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
                initialValue: locale.languageCode,
                isExpanded: true,
                borderRadius: BorderRadius.circular(16),
                dropdownColor: colors.surface,
                icon: Icon(
                  AppIcons.keyboard_arrow_down_rounded,
                  color: colors.brandEmphasis,
                  size: 20,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  filled: true,
                  fillColor: Colors.transparent,
                  contentPadding: EdgeInsets.fromLTRB(14, 11, 10, 11),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
                items: [
                  DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                  DropdownMenuItem(value: 'hi', child: Text(l10n.hindi)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(localeProvider.notifier).setLanguageCode(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidGlassAppearanceSwitch extends StatelessWidget {
  const _LiquidGlassAppearanceSwitch({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: AppLocalizations.of(context)!.liquidGlassAppearance,
      toggled: value,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 64,
          height: 36,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: value
                  ? const [Color(0xFF111827), Color(0xFF2F4858)]
                  : const [Color(0xFFFFFFFF), Color(0xFFE9F8F0)],
            ),
            border: Border.all(
              color: value
                  ? Colors.white.withValues(alpha: 0.18)
                  : colors.line.withValues(alpha: 0.9),
            ),
            boxShadow: [
              BoxShadow(
                color: (value ? Colors.black : const Color(0xFF2FA56E))
                    .withValues(alpha: value ? 0.18 : 0.14),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Icon(
                  AppIcons.light_mode_rounded,
                  size: 14,
                  color: value
                      ? Colors.white.withValues(alpha: 0.38)
                      : const Color(0xFF2FA56E),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Icon(
                  AppIcons.dark_mode_rounded,
                  size: 14,
                  color: value
                      ? Colors.white.withValues(alpha: 0.9)
                      : colors.textTertiary.withValues(alpha: 0.42),
                ),
              ),
              AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: value ? const Color(0xFF172033) : Colors.white,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: value ? 0.22 : 0.9),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.16),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    value
                        ? AppIcons.dark_mode_rounded
                        : AppIcons.light_mode_rounded,
                    size: 15,
                    color: value ? Colors.white : const Color(0xFF2FA56E),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutTile extends StatelessWidget {
  const _SignOutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 56,
        decoration: _surfaceDecoration(context.colors),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.logout_rounded, color: Color(0xFFE23A4B)),
            const SizedBox(width: 9),
            Text(
              AppLocalizations.of(context)!.signOut,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFFE23A4B),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _surfaceDecoration(AppColorScheme colors) {
  return BoxDecoration(
    color: colors.surface,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: colors.line),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'CL';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}

String _fallback(String? value, String fallback) {
  final text = value?.trim() ?? '';
  return text.isEmpty ? fallback : text;
}

double _amountValue(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

String _formatCurrency(double amount) {
  final rounded = amount.round();
  final text = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final fromEnd = text.length - i;
    buffer.write(text[i]);
    if (fromEnd > 1 && fromEnd % 2 == 0 && fromEnd != text.length) {
      buffer.write(',');
    }
  }
  return '₹$buffer';
}

String _compactCurrency(double amount) {
  if (amount >= 100000) {
    final lakhs = amount / 100000;
    return '₹${lakhs.toStringAsFixed(lakhs >= 10 ? 0 : 1)}L';
  }
  if (amount >= 1000) {
    final thousands = amount / 1000;
    return '₹${thousands.toStringAsFixed(thousands >= 10 ? 0 : 1)}K';
  }
  return _formatCurrency(amount);
}

String _formatDate(DateTime? value, AppLocalizations l10n) {
  if (value == null) return '—';
  final months = [
    l10n.monthJan,
    l10n.monthFeb,
    l10n.monthMar,
    l10n.monthApr,
    l10n.monthMay,
    l10n.monthJun,
    l10n.monthJul,
    l10n.monthAug,
    l10n.monthSep,
    l10n.monthOct,
    l10n.monthNov,
    l10n.monthDec,
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
