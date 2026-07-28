import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../data/auth_models.dart';
import '../controllers/auth_controller.dart';

class GpsTrackingLoginScreen extends ConsumerStatefulWidget {
  const GpsTrackingLoginScreen({super.key});

  @override
  ConsumerState<GpsTrackingLoginScreen> createState() =>
      _GpsTrackingLoginScreenState();
}

class _GpsTrackingLoginScreenState
    extends ConsumerState<GpsTrackingLoginScreen> {
  bool _isBootstrapping = true;
  bool _didAutoLogin = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_autoLogin());
    });
  }

  Future<void> _autoLogin() async {
    if (_didAutoLogin) {
      return;
    }
    _didAutoLogin = true;

    await Future<void>.delayed(const Duration(milliseconds: 800));
    if (!mounted) {
      return;
    }

    final now = DateTime.now();
    final session = AuthSession(
      user: SskUser(
        id: 'gps-demo-${now.millisecondsSinceEpoch}',
        name: 'GPS Tracking',
        email: 'gps@ssklogistics.in',
        phone: '0000000000',
        role: 'client',
        status: 'active',
        isPhoneVerified: true,
        isEmailVerified: true,
        profileImage: null,
        lastLoginAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      tokens: const AuthTokens(
        accessToken: 'gps-demo-access-token',
        refreshToken: 'gps-demo-refresh-token',
        tokenType: 'Bearer',
        expiresIn: 'demo',
      ),
    );

    ref.read(authSessionProvider.notifier).bootstrapSession(session);
    ref.read(selectedRoleProvider.notifier).state = AppRole.client;

    if (!mounted) {
      return;
    }

    setState(() => _isBootstrapping = false);
    context.go('/gps/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/gps.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFF102030));
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.16),
                  Colors.white.withValues(alpha: 0.08),
                  Colors.black.withValues(alpha: 0.08),
                ],
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go('/access'),
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white,
                              ),
                              tooltip: 'Back',
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned.fill(
                      top: 60,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - 100,
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(34),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    20,
                                    18,
                                    20,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.64),
                                    borderRadius: BorderRadius.circular(34),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.68,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: 52,
                                        child: Center(
                                          child: Transform.translate(
                                            offset: const Offset(0, -6),
                                            child: Image.asset(
                                              'assets/Logo.png',
                                              width: 190,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'GPS Tracking',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w900,
                                              color: const Color(0xFF111827),
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Signing you in automatically so you can jump straight into live tracking.',
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: const Color(0xFF4B5563),
                                              height: 1.35,
                                            ),
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF7FAFD),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          border: Border.all(
                                            color: const Color(0xFFE5ECF3),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFEAF7F0),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.gps_fixed_rounded,
                                                color: Color(0xFF2FA56E),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Live vehicle visibility',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: const Color(
                                                            0xFF111827,
                                                          ),
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Auto-login demo is ready',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: const Color(
                                                            0xFF667085,
                                                          ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        alignment: WrapAlignment.center,
                                        children: const [
                                          _Pill(
                                            icon: Icons.shield_outlined,
                                            label: 'Secure access',
                                          ),
                                          _Pill(
                                            icon: Icons.map_outlined,
                                            label: 'Route view',
                                          ),
                                          _Pill(
                                            icon: Icons.sensors_rounded,
                                            label: 'Live updates',
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF101828),
                                          borderRadius: BorderRadius.circular(
                                            22,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(
                                                0xFF101828,
                                              ).withValues(alpha: 0.18),
                                              blurRadius: 18,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 40,
                                              height: 40,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.12,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.all(10),
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _isBootstrapping
                                                        ? 'Logging in...'
                                                        : 'Redirecting...',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    'Please wait a moment while we open your tracking view.',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall
                                                        ?.copyWith(
                                                          color: Colors.white
                                                              .withValues(
                                                                alpha: 0.74,
                                                              ),
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5ECF3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2FA56E)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }
}
