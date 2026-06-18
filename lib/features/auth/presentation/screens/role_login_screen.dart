import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/providers/app_providers.dart';

class RoleLoginScreen extends ConsumerWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(selectedRoleProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => context.go('/access'),
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(Icons.arrow_back_rounded, size: 20),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome to SSK',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 10),
              Text(
                'Choose the role you want to sign in as. Client flow is active for now.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.black54,
                    ),
              ),
              const SizedBox(height: 28),
              _RoleCard(
                title: 'Broker',
                subtitle: 'For rate management and shipment coordination.',
                icon: Icons.handshake_rounded,
                selected: selectedRole == AppRole.broker,
                onTap: () => ref.read(selectedRoleProvider.notifier).state = AppRole.broker,
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Driver',
                subtitle: 'For route updates and live trip tracking.',
                icon: Icons.directions_car_filled_rounded,
                selected: selectedRole == AppRole.driver,
                onTap: () => ref.read(selectedRoleProvider.notifier).state = AppRole.driver,
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Client',
                subtitle: 'Book trucks, track cargo, and manage deliveries.',
                icon: Icons.person_rounded,
                selected: selectedRole == AppRole.client,
                onTap: () => ref.read(selectedRoleProvider.notifier).state = AppRole.client,
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE7EEF5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Login',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Chip(
                          label: const Text('Client preview'),
                          side: BorderSide.none,
                          backgroundColor: scheme.primary.withValues(alpha: 0.12),
                          labelStyle: TextStyle(
                            color: scheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      decoration: _fieldDecoration(context, label: 'Mobile number'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: _fieldDecoration(context, label: 'Password'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          context.go('/client/home');
                        },
                        child: const Text('Continue as client'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Broker and driver screens can be wired later once their flows are ready.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? scheme.primary.withValues(alpha: 0.10) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? scheme.primary.withValues(alpha: 0.25)
                : const Color(0xFFE6EDF3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: scheme.secondary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: scheme.secondary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded, color: scheme.primary)
            else
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
}) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8FBFE),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE6EDF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary,
        width: 1.4,
      ),
    ),
  );
}
