import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/data/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_dashboard_models.dart';

class DriverProfileScreen extends ConsumerStatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  ConsumerState<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState extends ConsumerState<DriverProfileScreen> {
  bool _kycApproved = false;
  bool _loadingKyc = true;
  bool _openingBrokerChat = false;
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

  Future<void> _openBrokerChat() async {
    if (_openingBrokerChat) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _openingBrokerChat = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBrokerDirectChatThread(accessToken: session.tokens.accessToken);
      final data = response['data'];
      final thread = data is Map<String, dynamic>
          ? (data['thread'] is Map
                ? (data['thread'] as Map).cast<String, dynamic>()
                : data)
          : response['thread'] is Map
          ? (response['thread'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final threadId = thread['id']?.toString().trim().isNotEmpty == true
          ? thread['id'].toString().trim()
          : thread['threadId']?.toString().trim() ?? '';
      if (!mounted) return;
      if (threadId.isEmpty) {
        throw StateError('Chat thread unavailable.');
      }
      context.push('/driver/chats/direct/$threadId');
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _openingBrokerChat = false);
      }
    }
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
          .getKycStatus(accessToken: session.tokens.accessToken);
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
    final dashboard = ref.watch(driverDashboardProvider).valueOrNull;
    final user = session?.user;
    final currentUserId = user?.id;
    if (currentUserId != _activeUserId && !_sessionSyncQueued) {
      _sessionSyncQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncKycStateForSession(currentUserId);
      });
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/driver/home'),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Back'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 10),
            _ProfileCard(
              user: user,
              kycApproved: !_loadingKyc && _kycApproved,
              truckType: _truckTypeLabel(dashboard?.assignedTruck),
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'Account',
              children: [
                _ProfileMenuTile(
                  title: 'Manage Account',
                  subtitle: 'Profile details, security, and preferences',
                  icon: Icons.person_outline_rounded,
                  onTap: () => context.push('/manage-account'),
                ),
                _ProfileMenuTile(
                  title: 'KYC Registration',
                  subtitle: _loadingKyc
                      ? 'Checking verification status'
                      : _kycApproved
                      ? 'Verified'
                      : 'Complete your driver verification',
                  icon: _kycApproved
                      ? Icons.verified_rounded
                      : Icons.verified_user_outlined,
                  accent: _kycApproved
                      ? const Color(0xFF2FA56E)
                      : const Color(0xFF2152D0),
                  onTap: () => context.push('/driver/kyc-registration'),
                ),
                _ProfileMenuTile(
                  title: 'Earnings',
                  subtitle: 'Trip payouts and completed delivery earnings',
                  icon: Icons.trending_up_rounded,
                  accent: const Color(0xFF2FA56E),
                  onTap: () => context.go('/driver/earnings'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'Communication',
              children: [
                _ProfileMenuTile(
                  title: _openingBrokerChat
                      ? 'Opening chat...'
                      : 'Message My Broker',
                  subtitle: 'Open your direct broker conversation',
                  icon: Icons.chat_bubble_outline_rounded,
                  accent: const Color(0xFF2152D0),
                  onTap: _openingBrokerChat ? null : _openBrokerChat,
                ),
                _ProfileMenuTile(
                  title: 'All Chats',
                  subtitle: 'View every driver conversation',
                  icon: Icons.forum_outlined,
                  accent: const Color(0xFF2152D0),
                  onTap: () => context.push('/driver/chats'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _ProfileSection(
              title: 'Security',
              children: [
                _ProfileMenuTile(
                  title: 'Change Password',
                  subtitle: 'Update your sign-in credentials',
                  icon: Icons.lock_outline_rounded,
                  onTap: () => context.push('/change-password'),
                ),
                _ProfileMenuTile(
                  title: 'Logout',
                  subtitle: 'Sign out from this device',
                  icon: Icons.logout_rounded,
                  accent: const Color(0xFFE23A4B),
                  onTap: () async {
                    await ref.read(authSessionProvider.notifier).logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.user,
    required this.kycApproved,
    required this.truckType,
  });

  final SskUser? user;
  final bool kycApproved;
  final String truckType;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName.trim()
        : 'Driver account';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2454),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F2454).withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2152D0).withValues(alpha: 0.25),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.32),
                width: 2,
              ),
            ),
            child: SskProfileAvatar(imageUrl: user?.profileImage, size: 72),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            user?.phone.trim().isNotEmpty == true
                ? user!.phone
                : user?.email ?? 'No account connected',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileChip(
                icon: kycApproved
                    ? Icons.verified_rounded
                    : Icons.hourglass_top_rounded,
                label: kycApproved ? 'Verified' : 'KYC Pending',
              ),
              const _ProfileChip(
                icon: Icons.local_shipping_outlined,
                label: 'Driver',
              ),
              if (truckType.isNotEmpty)
                _ProfileChip(icon: Icons.fire_truck_outlined, label: truckType),
            ],
          ),
        ],
      ),
    );
  }
}

String _truckTypeLabel(Map<String, dynamic>? truck) {
  if (truck == null || truck.isEmpty) {
    return '';
  }
  return _firstTruckValue(truck, const [
    'category',
    'type',
    'vehicleType',
    'vehicle_type',
    'truckType',
    'truck_type',
    'model',
    'registration',
    'registrationNumber',
    'registration_number',
  ]);
}

String _firstTruckValue(Map<String, dynamic> value, List<String> keys) {
  for (final key in keys) {
    final raw = value[key]?.toString().trim();
    if (raw != null && raw.isNotEmpty && raw.toLowerCase() != 'null') {
      return raw;
    }
  }
  return '';
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                children[index],
                if (index != children.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 62,
                    color: Color(0xFFE2E8F0),
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
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accent = const Color(0xFF2152D0),
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFCBD5E1),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
