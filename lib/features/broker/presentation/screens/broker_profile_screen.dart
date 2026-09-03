import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(
                user: user,
                title: title,
                onBack: () => context.go('/broker/home'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: BrokerProfileActionCard(
                      title: 'Manage account',
                      subtitle: 'Update your profile, security & preferences',
                      icon: Icons.handshake_rounded,
                      backgroundColor: const Color(0xFFF5F7FB),
                      iconColor: const Color(0xFF1F88C9),
                      onTap: () => context.push('/manage-account'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrokerProfileActionCard(
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
              _SectionTitle(
                title: 'Finance',
                subtitle: 'Invoices, settlements, and analytics.',
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Invoices',
                subtitle: 'View and download all invoices',
                icon: Icons.receipt_long_rounded,
                onTap: () => context.push('/broker/settings/invoices'),
                titleColor: const Color(0xFF1F88C9),
                iconColor: const Color(0xFF1F88C9),
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Settlements',
                subtitle: 'Track your settlements and payments',
                icon: Icons.payments_rounded,
                onTap: () => context.push('/broker/settings/settlements'),
                titleColor: const Color(0xFF1F88C9),
                iconColor: const Color(0xFF1F88C9),
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Analytics',
                subtitle: 'View performance and insights',
                icon: Icons.bar_chart_rounded,
                onTap: () => context.push('/broker/settings/analytics'),
                titleColor: const Color(0xFF1F88C9),
                iconColor: const Color(0xFF1F88C9),
              ),
              const SizedBox(height: 22),
              _SectionTitle(
                title: 'Inbox',
                subtitle: 'Open notifications and active broker updates.',
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Notifications',
                subtitle: 'View all notifications and updates',
                icon: Icons.notifications_active_rounded,
                onTap: () => context.push('/broker/notifications'),
                titleColor: const Color(0xFF1F88C9),
                iconColor: const Color(0xFF1F88C9),
              ),
              const SizedBox(height: 22),
              BrokerMenuTile(
                title: 'Manage Drivers',
                icon: Icons.people_alt_rounded,
                onTap: () => context.go('/broker/tracking'),
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Manage Vehicles',
                icon: Icons.local_shipping_rounded,
                onTap: () => context.go('/broker/vehicles'),
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Create driver credentials',
                icon: Icons.badge_rounded,
                onTap: () => context.go('/broker/drivers/add'),
                titleColor: const Color(0xFF1F88C9),
                iconColor: const Color(0xFF1F88C9),
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'KYC registration',
                icon: Icons.verified_user_rounded,
                onTap: () => context.push('/broker/kyc-registration'),
                completed: !_loadingKyc && _kycApproved,
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
                title: 'Change password',
                icon: Icons.password_rounded,
                onTap: () => context.push('/change-password'),
              ),
              const SizedBox(height: 10),
              BrokerMenuTile(
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
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 8,
        12,
        20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF075FC7), Color(0xFF147FE5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(42),
          bottomRight: Radius.circular(42),
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
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
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
                size: 58,
                borderColor: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Broker account',
                      style: TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user?.email ?? 'No account connected yet',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 10,
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
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
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
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10245B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 9,
                  color: const Color(0xFF6B7A98),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
