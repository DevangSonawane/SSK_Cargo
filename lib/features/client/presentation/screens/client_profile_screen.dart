import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ClientProfileScreen extends ConsumerWidget {
  const ClientProfileScreen({super.key});

  Future<void> _openAccountDetails(BuildContext context, WidgetRef ref) async {
    try {
      final session = await ref.read(authSessionProvider.notifier).refreshProfile();
      final user = session.user;
      final nameController = TextEditingController(text: user.displayName);
      final emailController = TextEditingController(text: user.email ?? '');
      final profileImageController = TextEditingController(text: user.profileImage ?? '');

      if (!context.mounted) {
        nameController.dispose();
        emailController.dispose();
        profileImageController.dispose();
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final formKey = GlobalKey<FormState>();
          var isSaving = false;

          return StatefulBuilder(
            builder: (sheetContext, setState) {
              Future<void> saveProfile() async {
                if (!(formKey.currentState?.validate() ?? false)) {
                  return;
                }

                setState(() => isSaving = true);
                try {
                  await ref.read(authSessionProvider.notifier).updateProfile(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        profileImage: profileImageController.text.trim().isEmpty
                            ? null
                            : profileImageController.text.trim(),
                      );
                  if (sheetContext.mounted) {
                    Navigator.of(sheetContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully.'),
                        backgroundColor: Color(0xFF2FA56E),
                      ),
                    );
                  }
                } on ApiException catch (error) {
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(error.message),
                      backgroundColor: const Color(0xFFE23A4B),
                    ),
                  );
                } catch (error) {
                  if (!sheetContext.mounted) return;
                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                    SnackBar(
                      content: Text(error.toString()),
                      backgroundColor: const Color(0xFFE23A4B),
                    ),
                  );
                } finally {
                  if (sheetContext.mounted) {
                    setState(() => isSaving = false);
                  }
                }
              }

              return SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(12),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    18,
                    20,
                    24 + MediaQuery.of(sheetContext).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Manage account',
                                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF101828),
                                      ),
                                ),
                              ),
                              IconButton(
                                onPressed: isSaving ? null : () => Navigator.of(sheetContext).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(labelText: 'Full name'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(labelText: 'Email'),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter an email';
                              }
                              if (!value.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: profileImageController,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(
                              labelText: 'Profile image URL',
                              helperText: 'Optional',
                            ),
                          ),
                          const SizedBox(height: 16),
                          _AccountDetailRow(label: 'Phone', value: user.phone.isEmpty ? '-' : user.phone),
                          _AccountDetailRow(label: 'Role', value: user.role),
                          _AccountDetailRow(label: 'Status', value: user.status),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isSaving ? null : saveProfile,
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text('Save changes'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      );

      nameController.dispose();
      emailController.dispose();
      profileImageController.dispose();
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
    final displayName = user?.displayName ?? 'Client';

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName.split(' ').first,
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    Text(
                      displayName.contains(' ') ? displayName.split(' ').skip(1).join(' ') : 'Profile',
                      textAlign: TextAlign.left,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                  ],
                ),
                const Spacer(),
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
                  child: _ProfileActionCard(
                    title: 'Help',
                    icon: Icons.support_agent_rounded,
                    backgroundColor: const Color(0xFFF5F7FB),
                    iconColor: const Color(0xFF2D6EF2),
                    onTap: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProfileActionCard(
                    title: 'Safety',
                    icon: Icons.shield_rounded,
                    backgroundColor: const Color(0xFFF5F7FB),
                    iconColor: const Color(0xFF2FA56E),
                    onTap: () {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _ProfileMenuTile(
              title: 'Settings',
              icon: Icons.settings_rounded,
              onTap: () {},
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Change password',
              icon: Icons.password_rounded,
              onTap: () => context.push('/change-password'),
            ),
            const SizedBox(height: 10),
            _ProfileMenuTile(
              title: 'Manage account',
              icon: Icons.manage_accounts_rounded,
              onTap: () => _openAccountDetails(context, ref),
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
  });

  final String title;
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
        height: 86,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
            ),
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
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}

class _AccountDetailRow extends StatelessWidget {
  const _AccountDetailRow({
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
