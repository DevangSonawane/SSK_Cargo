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
          const _BottomDecor(),
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
                                  color: const Color(0xFF4B5563),
                                ),
                              ),
                              const SizedBox(height: 10),
                              _AccessChoiceCard(
                                title: 'Continue as',
                                accentTitle: 'Client',
                                description: 'Book truck, manage shipments & more',
                                imagePath: 'assets/selectionscreen/client.png',
                                icon: Icons.person_rounded,
                                accentColor: const Color(0xFF6AAE5B),
                                onTap: () => context.go('/login'),
                              ),
                              const SizedBox(height: 8),
                              _AccessChoiceCard(
                                title: 'Continue as',
                                accentTitle: 'Broker',
                                description: 'Connect with transporters, grow your business',
                                imagePath: 'assets/selectionscreen/broker.png',
                                icon: Icons.handshake_rounded,
                                accentColor: const Color(0xFF6AAE5B),
                                onTap: () => context.go('/broker/login'),
                              ),
                              const SizedBox(height: 8),
                              _TrackingChoiceCard(
                                title: 'GPS Tracking',
                                description: 'Track your vehicle in real-time',
                                imagePath: 'assets/selectionscreen/gps.png',
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
    required this.accentTitle,
    required this.description,
    required this.imagePath,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final String accentTitle;
  final String description;
  final String imagePath;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _ChoiceCardFrame(
      onTap: onTap,
      fixedHeight: 110,
      child: Row(
        children: [
          Expanded(
            flex: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF111827),
                      ),
                ),
                Text(
                  accentTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF2E7D32),
                        height: 1.05,
                      ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 22,
                  height: 3,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 4),
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
          const SizedBox(width: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.22),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
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
    required this.onTap,
  });

  final String title;
  final String description;
  final String imagePath;
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
            flex: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    imagePath,
                    fit: BoxFit.cover,
                    alignment: Alignment.centerLeft,
                    width: double.infinity,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      width: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.transparent,
                            Colors.white.withValues(alpha: 0.10),
                            Colors.white.withValues(alpha: 0.28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
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
          const SizedBox(width: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: fixedHeight,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD5E7D2)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6AAE5B).withValues(alpha: 0.10),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
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
          Positioned(
            bottom: -40,
            left: -90,
            child: Container(
              width: 240,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
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

class _BottomDecor extends StatelessWidget {
  const _BottomDecor();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SizedBox(
          height: 120,
          width: double.infinity,
          child: Stack(
            children: [
              Positioned(
                bottom: -30,
                left: -20,
                child: _GlowCircle(
                  size: 110,
                  color: const Color(0xFF6AAE5B).withValues(alpha: 0.12),
                ),
              ),
              Positioned(
                bottom: -20,
                left: 92,
                child: _GlowCircle(
                  size: 70,
                  color: const Color(0xFF6AAE5B).withValues(alpha: 0.08),
                ),
              ),
              Positioned(
                bottom: -42,
                right: -12,
                child: _GlowCircle(
                  size: 140,
                  color: const Color(0xFF6AAE5B).withValues(alpha: 0.10),
                ),
              ),
              Positioned(
                bottom: 10,
                right: 84,
                child: _GlowCircle(
                  size: 48,
                  color: const Color(0xFF6AAE5B).withValues(alpha: 0.06),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
