import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoggingIn = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_isLoggingIn) {
      return;
    }

    setState(() => _isLoggingIn = true);
    await Future<void>.delayed(const Duration(milliseconds: 550));
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

    context.go('/gps/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/gps_tracking_screen_fotos/loginpage_gps.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: const Color(0xFF1B2A3A));
            },
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.20),
                  Colors.white.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.06),
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
                                color: Colors.black,
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
                                    16,
                                    20,
                                    8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.62),
                                    borderRadius: BorderRadius.circular(34),
                                    border: Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.66,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.18,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: 48,
                                        child: Center(
                                          child: Transform.translate(
                                            offset: const Offset(0, -8),
                                            child: Transform.scale(
                                              scale: 5.30,
                                              child: Image.asset(
                                                'assets/Logo.png',
                                                width: 200,
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 18),
                                      TextField(
                                        controller: _emailController,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        textInputAction: TextInputAction.next,
                                        decoration: _pillDecoration(
                                          label: 'Email',
                                          icon: Icons.email_rounded,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) => _login(),
                                        decoration: _pillDecoration(
                                          label: 'Password',
                                          icon: Icons.lock_rounded,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(
                                                () => _obscurePassword =
                                                    !_obscurePassword,
                                              );
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                            ),
                                            tooltip: _obscurePassword
                                                ? 'Show password'
                                                : 'Hide password',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          style: FilledButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                          onPressed: _isLoggingIn
                                              ? null
                                              : _login,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child: _isLoggingIn
                                                ? const SizedBox(
                                                    key: ValueKey('loading'),
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Text(
                                                    'Login',
                                                    key: ValueKey('label'),
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _login,
                                              icon: SvgPicture.asset(
                                                'assets/google_logo.svg',
                                                width: 18,
                                                height: 18,
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF1B2A3A,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFFD7DDE5),
                                                ),
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.82),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: const StadiumBorder(),
                                              ),
                                              label: const Text(
                                                'Google',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: _login,
                                              icon: const Icon(
                                                Icons.apple,
                                                size: 22,
                                                color: Color(0xFF1B2A3A),
                                              ),
                                              label: const Text(
                                                'Apple',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: const Color(
                                                  0xFF1B2A3A,
                                                ),
                                                side: const BorderSide(
                                                  color: Color(0xFFD7DDE5),
                                                ),
                                                backgroundColor: Colors.white
                                                    .withValues(alpha: 0.82),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: const StadiumBorder(),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 18),
                                      Center(
                                        child: Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 6,
                                          children: [
                                            const Text(
                                              "Don't have an account?",
                                              style: TextStyle(
                                                color: Color(0xFF1B2A3A),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  context.go('/access'),
                                              style: TextButton.styleFrom(
                                                padding: EdgeInsets.zero,
                                                minimumSize: Size.zero,
                                                tapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                foregroundColor: const Color(
                                                  0xFF2FA56E,
                                                ),
                                              ),
                                              child: const Text(
                                                'Create one',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
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

InputDecoration _pillDecoration({
  required String label,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF7FAFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(color: Color(0xFFE5ECF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(999),
      borderSide: const BorderSide(color: Color(0xFF2FA56E), width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}
