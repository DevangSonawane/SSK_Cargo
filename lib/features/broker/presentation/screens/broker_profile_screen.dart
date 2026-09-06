import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class BrokerProfileScreen extends ConsumerStatefulWidget {
  const BrokerProfileScreen({super.key});

  @override
  ConsumerState<BrokerProfileScreen> createState() =>
      _BrokerProfileScreenState();
}

class _BrokerProfileScreenState extends ConsumerState<BrokerProfileScreen> {
  bool _kycApproved = false;
  bool _loadingKyc = true;
  String? _activeUserId;
  bool _sessionSyncQueued = false;

  @override
  void initState() {
    super.initState();
    _activeUserId = ref.read(authSessionProvider).valueOrNull?.user.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadKycStatus();
    });
  }

  bool _isApprovedStatus(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('verified') ||
        normalized.contains('approved') ||
        normalized.contains('complete');
  }

  Future<void> _loadKycStatus() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _kycApproved = false;
        _loadingKyc = false;
      });
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getKycStatusForUser(
            accessToken: session.tokens.accessToken,
            userId: session.user.id,
          );
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final status = data['kyc_status']?.toString() ?? '';
      if (!mounted) return;
      setState(() {
        _kycApproved = _isApprovedStatus(status);
        _loadingKyc = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _kycApproved = false;
        _loadingKyc = false;
      });
    }
  }

  void _syncKycStateForSession(String? userId) {
    _sessionSyncQueued = false;
    _activeUserId = userId;
    setState(() {
      _kycApproved = false;
      _loadingKyc = true;
    });

    if (userId == null) {
      setState(() {
        _loadingKyc = false;
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadKycStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final currentUserId = user?.id;
    if (currentUserId != _activeUserId && !_sessionSyncQueued) {
      _sessionSyncQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncKycStateForSession(currentUserId);
      });
    }
    final title = user?.displayName ?? 'Broker operations';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileHeader(
              user: user,
              title: title,
              onBack: () => context.go('/broker/home'),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileActionCard(
                          title: 'Manage account',
                          subtitle:
                              'Update your profile, security & preferences',
                          icon: Icons.handshake_rounded,
                          backgroundColor: const Color(0xFFF5F7FB),
                          iconColor: const Color(0xFF1F88C9),
                          onTap: () => context.push('/manage-account'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ProfileActionCard(
                          title: 'Support',
                          subtitle: 'Get help and contact support',
                          icon: Icons.support_agent_rounded,
                          backgroundColor: const Color(0xFFF5F7FB),
                          iconColor: const Color(0xFF2FA56E),
                          onTap: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(title: 'Finance'),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Invoices',
                    icon: Icons.receipt_long_rounded,
                    onTap: () => context.push('/broker/settings/invoices'),
                    titleColor: const Color(0xFF1F88C9),
                    iconColor: const Color(0xFF1F88C9),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Settlements',
                    icon: Icons.payments_rounded,
                    onTap: () => context.push('/broker/settings/settlements'),
                    titleColor: const Color(0xFF1F88C9),
                    iconColor: const Color(0xFF1F88C9),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Analytics',
                    icon: Icons.bar_chart_rounded,
                    onTap: () => context.push('/broker/settings/analytics'),
                    titleColor: const Color(0xFF1F88C9),
                    iconColor: const Color(0xFF1F88C9),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle(title: 'Inbox'),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Notifications',
                    icon: Icons.notifications_active_rounded,
                    onTap: () => context.push('/broker/notifications'),
                    titleColor: const Color(0xFF1F88C9),
                    iconColor: const Color(0xFF1F88C9),
                  ),
                  const SizedBox(height: 22),
                  _ProfileMenuTile(
                    title: 'Manage Drivers',
                    icon: Icons.people_alt_rounded,
                    onTap: () => context.go('/broker/tracking'),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Manage Vehicles',
                    icon: Icons.local_shipping_rounded,
                    onTap: () => context.go('/broker/vehicles'),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Create driver credentials',
                    icon: Icons.badge_rounded,
                    onTap: () => context.go('/broker/drivers/add'),
                    titleColor: const Color(0xFF1F88C9),
                    iconColor: const Color(0xFF1F88C9),
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'KYC registration',
                    icon: Icons.verified_user_rounded,
                    onTap: () => context.push('/broker/kyc-registration'),
                    completed: !_loadingKyc && _kycApproved,
                  ),
                  const SizedBox(height: 10),
                  _ProfileMenuTile(
                    title: 'Change password',
                    icon: Icons.password_rounded,
                    onTap: () => context.push('/change-password'),
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
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.user,
    required this.title,
    required this.onBack,
  });

  final SskUser? user;
  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF075FC7), Color(0xFF147FE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: onBack,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SskProfileAvatar(
                imageUrl: user?.profileImage,
                size: 64,
                borderColor: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Broker account',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'No account connected yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 24,
          decoration: BoxDecoration(
            color: const Color(0xFF1769D1),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10245B),
                ),
              ),
            ],
          ),
        ),
      ],
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
    this.subtitle,
  });

  final String title;
  final String? subtitle;
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
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E8F3)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1769D1).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: iconColor),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  height: 1.25,
                  color: const Color(0xFF667085),
                ),
              ),
            ],
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
    this.completed = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E8F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: completed
                    ? const Color(0xFFE8F8F0)
                    : const Color(0xFFEAF3FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                completed ? Icons.check_rounded : icon,
                color: completed ? const Color(0xFF2FA56E) : iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: completed ? const Color(0xFF1F7A52) : titleColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
