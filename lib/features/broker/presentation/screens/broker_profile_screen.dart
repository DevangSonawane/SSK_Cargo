import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/profile_avatar.dart';
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
          .getBrokerKycStatus(accessToken: session.tokens.accessToken);
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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/broker/home'),
        ),
        title: const Text('Profile'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                        Text(
                          user?.role == 'broker' ? 'Broker account' : 'Profile',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SskProfileAvatar(imageUrl: user?.profileImage, size: 62),
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
                    child: BrokerProfileActionCard(
                      title: 'Manage account',
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
                      icon: Icons.support_agent_rounded,
                      backgroundColor: const Color(0xFFF5F7FB),
                      iconColor: const Color(0xFF2FA56E),
                      onTap: () {},
                    ),
                  ),
                ],
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
                    context.go('/broker/login');
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
