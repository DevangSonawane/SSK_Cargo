import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerProfileScreen extends ConsumerWidget {
  const BrokerProfileScreen({super.key});

  Future<void> _openAccountDetails(BuildContext context, WidgetRef ref) async {
    try {
      final session = await ref.read(authSessionProvider.notifier).refreshProfile();
      final user = session.user;

      if (!context.mounted) {
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Account details',
                          style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _BrokerAccountDetailRow(label: 'Name', value: user.displayName),
                  _BrokerAccountDetailRow(label: 'Email', value: user.email ?? '-'),
                  _BrokerAccountDetailRow(label: 'Phone', value: user.phone.isEmpty ? '-' : user.phone),
                  _BrokerAccountDetailRow(label: 'Role', value: user.role),
                  _BrokerAccountDetailRow(label: 'Status', value: user.status),
                  _BrokerAccountDetailRow(
                    label: 'Phone verified',
                    value: user.isPhoneVerified ? 'Yes' : 'No',
                  ),
                  _BrokerAccountDetailRow(
                    label: 'Email verified',
                    value: user.isEmailVerified ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Last login: ${user.lastLoginAt?.toLocal().toString() ?? '-'}',
                    style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } on ApiException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final user = session?.user;
    final title = user?.displayName ?? 'Broker operations';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
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
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                        Text(
                          user?.role == 'broker' ? 'Broker account' : 'Profile',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F4F8),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE5EAF0), width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: user?.profileImage == null
                        ? Image.asset('assets/user.png', fit: BoxFit.cover)
                        : Image.network(
                            user!.profileImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset('assets/user.png', fit: BoxFit.cover);
                            },
                          ),
                  ),
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
                      onTap: () => _openAccountDetails(context, ref),
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
                title: 'Settings',
                icon: Icons.settings_rounded,
                onTap: () {},
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

class _BrokerAccountDetailRow extends StatelessWidget {
  const _BrokerAccountDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
