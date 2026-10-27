import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';

/// The original asset-based access-control presentation, connected to the
/// current safe role-specific login routes.
class RoleLoginScreen extends ConsumerWidget {
  const RoleLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Stack(
        children: [
          const _BackgroundDecor(),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bannerHeight = (constraints.maxHeight * 0.36).clamp(
                  270.0,
                  330.0,
                );
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, -18),
                            child: SizedBox(
                              height: bannerHeight,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.asset(
                                    'assets/Delivering Trust Across Miles.png',
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                  ),
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      height: 132,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            const Color(
                                              0xFFF7FAFC,
                                            ).withValues(alpha: 0.14),
                                            const Color(0xFFF7FAFC),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Welcome!',
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: const Color(0xFF111827),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Choose how you want to continue',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.2,
                                    fontWeight: FontWeight.w400,
                                    color: const Color(0xFF4B5563),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _AccessChoiceCard(
                                  title: 'Client',
                                  description:
                                      'Book truck, manage shipments & more',
                                  imagePath:
                                      'assets/client/Smart Logistics Booking at Gadidost.png',
                                  onTap: () =>
                                      _continueAs(context, ref, AppRole.client),
                                ),
                                const SizedBox(height: 12),
                                _AccessChoiceCard(
                                  title: 'Broker',
                                  description:
                                      'Connect with transporters, grow your business',
                                  imagePath:
                                      'assets/selectionscreen/broker.png',
                                  onTap: () =>
                                      _continueAs(context, ref, AppRole.broker),
                                ),
                                const SizedBox(height: 12),
                                _AccessChoiceCard(
                                  title: 'Driver',
                                  description:
                                      'View assigned trips and delivery tasks',
                                  imagePath: 'assets/driverloginscreen.png',
                                  onTap: () =>
                                      _continueAs(context, ref, AppRole.driver),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _continueAs(BuildContext context, WidgetRef ref, AppRole role) {
    ref.read(selectedRoleProvider.notifier).state = role;
    context.go(switch (role) {
      AppRole.client => '/login',
      AppRole.broker => '/broker/login',
      AppRole.driver => '/driver/login',
      AppRole.admin => '/login',
    });
  }
}

class _AccessChoiceCard extends StatelessWidget {
  const _AccessChoiceCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onTap,
  });

  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF6AAE5B);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 110,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3E8EF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 10,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(18.8),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        alignment: Alignment.centerLeft,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 124,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.22),
                                Colors.white,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 10,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF111827),
                            ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        width: 22,
                        height: 3,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontSize: 10,
                          height: 1.15,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: accent,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundDecor extends StatelessWidget {
  const _BackgroundDecor();

  @override
  Widget build(BuildContext context) => Positioned(
    top: -90,
    right: -60,
    child: IgnorePointer(
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF6AAE5B).withValues(alpha: 0.10),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
  );
}
