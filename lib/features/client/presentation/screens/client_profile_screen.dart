import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
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
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final bookingsState = ref.watch(
      clientBookingsProvider((status: null, page: 1, limit: 100)),
    );
    final bookings = bookingsState.valueOrNull?.bookings ?? const [];
    final stats = _ProfileStats.fromBookings(bookings);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
                      'My Profile',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: const Color(0xFF101828),
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
                      title: 'Shipments',
                      children: [
                        _ProfileMenuTile(
                          icon: AppIcons.inventory_2_outlined,
                          title: 'My Bookings',
                          onTap: () => context.go('/client/delivery'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ProfileSection(
                      title: 'Account',
                      children: [
                        _ProfileMenuTile(
                          icon: AppIcons.location_on_outlined,
                          title: 'Saved Addresses',
                          onTap: () => context.push('/client/saved-addresses'),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.notifications_active_outlined,
                          title: 'Notifications',
                          onTap: () => context.push('/client/notifications'),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.key_rounded,
                          title: 'Change Password',
                          onTap: () => context.push('/change-password'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _ProfileSection(
                      title: 'Help',
                      children: [
                        _ProfileMenuTile(
                          icon: AppIcons.headset_mic_outlined,
                          title: 'Help & Support',
                          subtitle: 'Coming soon',
                          onTap: () => _showComingSoon(context),
                        ),
                        _ProfileMenuTile(
                          icon: AppIcons.description_outlined,
                          title: 'Terms & Privacy',
                          subtitle: 'Coming soon',
                          onTap: () => _showComingSoon(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _SignOutTile(onTap: _signOut),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'SSK Logistics v1.0.0',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF98A2B3),
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
      const SnackBar(content: Text('This feature is coming soon.')),
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
    final name = user?.displayName ?? 'Client';
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
                      value: _fallback(user?.phone, 'Not provided'),
                    ),
                    const SizedBox(height: 4),
                    _HeroContactLine(
                      icon: AppIcons.mail_rounded,
                      value: _fallback(user?.email, 'Not provided'),
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
                      label: const Text('Edit Profile'),
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
                          label: 'Bookings',
                        ),
                      ),
                      _HeroDivider(),
                      Expanded(
                        child: _HeroStat(
                          value: loadingStats
                              ? '--'
                              : _compactCurrency(stats.totalSpent),
                          label: 'Spent',
                        ),
                      ),
                      _HeroDivider(),
                      Expanded(
                        child: _HeroStat(
                          value: loadingStats
                              ? '--'
                              : stats.delivered.toString(),
                          label: 'Delivered',
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _surfaceDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Info',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: const Color(0xFF344054),
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
                child: const Text('Retry account stats'),
              ),
            )
          else ...[
            _InfoRow(
              icon: AppIcons.calendar_month_rounded,
              iconColor: const Color(0xFF2FA56E),
              label: 'Member Since',
              value: _formatDate(user?.createdAt),
            ),
            const SizedBox(height: 13),
            _InfoRow(
              icon: AppIcons.inventory_2_rounded,
              iconColor: const Color(0xFF1F88C9),
              label: 'Active Shipments',
              value: stats.activeShipments.toString(),
            ),
            const SizedBox(height: 13),
            _InfoRow(
              icon: AppIcons.account_balance_wallet_rounded,
              iconColor: const Color(0xFFE6A700),
              label: 'Lifetime Value',
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
              color: const Color(0xFFF2F4F7),
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
                  color: const Color(0xFF98A2B3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF344054),
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
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: _surfaceDecoration(),
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const Divider(
                    height: 1,
                    indent: 56,
                    color: Color(0xFFE8EDF2),
                  ),
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
            Icon(icon, size: 21, color: const Color(0xFF98A2B3)),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF344054),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              AppIcons.chevron_right_rounded,
              color: Color(0xFFD0D5DD),
            ),
          ],
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
        decoration: _surfaceDecoration(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(AppIcons.logout_rounded, color: Color(0xFFE23A4B)),
            const SizedBox(width: 9),
            Text(
              'Sign Out',
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

BoxDecoration _surfaceDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: const Color(0xFFE8EDF2)),
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

String _formatDate(DateTime? value) {
  if (value == null) return '—';
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
