import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AccessEntryScreen extends StatelessWidget {
  const AccessEntryScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                final bannerHeight = (constraints.maxHeight * 0.36).clamp(270.0, 330.0);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Transform.translate(
                          offset: const Offset(0, -18),
                          child: SizedBox(
                            height: bannerHeight,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  'assets/selectionscreen/banner.png',
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Color(0xFFEAF2FA), Color(0xFFDDEAF7)],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    );
                                  },
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
                                          const Color(0xFFF7FAFC).withValues(alpha: 0.14),
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
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Welcome!',
                                style: theme.textTheme.headlineMedium?.copyWith(
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
                                description: 'Book truck, manage shipments & more',
                                imagePath: 'assets/selectionscreen/client.png',
                                icon: Icons.person_rounded,
                                accentColor: const Color(0xFF6AAE5B),
                                arrowIcon: Icons.chevron_right_rounded,
                                onTap: () => context.go('/login'),
                              ),
                              const SizedBox(height: 12),
                              _AccessChoiceCard(
                                title: 'Broker',
                                description: 'Connect with transporters, grow your business',
                                imagePath: 'assets/selectionscreen/broker.png',
                                icon: Icons.handshake_rounded,
                                accentColor: const Color(0xFF6AAE5B),
                                arrowIcon: Icons.chevron_right_rounded,
                                onTap: () => context.go('/broker/login'),
                              ),
                              const SizedBox(height: 12),
                              _TrackingChoiceCard(
                                title: 'GPS Tracking',
                                description: 'Track your vehicle in real-time',
                                imagePath: 'assets/selectionscreen/gps.png',
                                arrowIcon: Icons.chevron_right_rounded,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
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
}

class _AccessChoiceCard extends StatelessWidget {
  const _AccessChoiceCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.accentColor,
    required this.arrowIcon,
    required this.onTap,
  });

  final String title;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color accentColor;
  final IconData arrowIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceCardFrame(
      onTap: onTap,
      fixedHeight: 110,
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18.8)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 124,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                      color: accentColor,
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                arrowIcon,
                color: accentColor,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingChoiceCard extends StatelessWidget {
  const _TrackingChoiceCard({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.arrowIcon,
    required this.onTap,
  });

  final String title;
  final String description;
  final String imagePath;
  final IconData arrowIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFF6AAE5B);

    return _ChoiceCardFrame(
      onTap: onTap,
      fixedHeight: 110,
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18.8)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 124,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF111827),
                        ),
                  ),
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
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                arrowIcon,
                color: accentColor,
                size: 28,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCardFrame extends StatelessWidget {
  const _ChoiceCardFrame({
    required this.child,
    required this.onTap,
    required this.fixedHeight,
  });

  final Widget child;
  final VoidCallback onTap;
  final double fixedHeight;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: fixedHeight,
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFE3E8EF),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Container(
                  margin: const EdgeInsets.all(1.2),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18.8),
                  ),
                  child: child,
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
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -90,
            right: -60,
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
        ],
      ),
    );
  }
}
