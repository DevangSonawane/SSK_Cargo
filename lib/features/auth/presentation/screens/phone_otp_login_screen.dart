import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gadidost/core/theme/app_icons.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/auth_models.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_verification_view.dart';

/// Route `extra` for `/login/otp`.
class PhoneOtpLoginArgs {
  const PhoneOtpLoginArgs({required this.phone, required this.role});

  final String phone;
  final AppRole role;
}

/// Second step of "Login with phone": enter the OTP, then sign in.
class PhoneOtpLoginScreen extends ConsumerWidget {
  const PhoneOtpLoginScreen({
    super.key,
    required this.phone,
    required this.expectedRole,
  });

  final String phone;
  final AppRole expectedRole;

  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(switch (expectedRole) {
      AppRole.broker => '/broker/login',
      AppRole.driver => '/driver/login',
      _ => '/login',
    });
  }

  Future<void> _signIn(
    BuildContext context,
    WidgetRef ref,
    String idToken,
  ) async {
    final auth = ref.read(authSessionProvider.notifier);
    final AuthSession session;
    try {
      session = await auth.loginWithFirebasePhone(idToken: idToken);
    } on ApiException catch (error) {
      // firebase-login is login-only: an unknown number 404s.
      if (error.statusCode == 404 &&
          expectedRole == AppRole.client &&
          context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No account with this number yet.'),
            action: SnackBarAction(
              label: 'Create account',
              onPressed: () => context.go('/signup'),
            ),
          ),
        );
      }
      rethrow;
    }
    final role = appRoleFromApiRole(session.user.role);
    if (role != expectedRole) {
      await auth.forceLocalLogout();
      throw StateError(
        'This number is registered as ${session.user.role}. '
        'Please use the ${expectedRole.name} login.',
      );
    }
    ref.read(selectedRoleProvider.notifier).state = role;
    ref.read(authExpiredMessageProvider.notifier).state = null;
    if (role == AppRole.client) {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
    if (!context.mounted) return;
    context.go(switch (session.user.role) {
      'client' => '/client/home',
      'broker' => '/broker/home',
      'driver' => '/driver/home',
      _ => '/gps/dashboard',
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -80,
            child: IgnorePointer(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2FA56E).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 56,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: OtpVerificationView(
                    phone: phone,
                    onChangeNumber: () => _back(context),
                    onVerified: (idToken) => _signIn(context, ref, idToken),
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: IconButton(
                onPressed: () => _back(context),
                icon: const Icon(AppIcons.arrow_back_rounded),
                color: const Color(0xFF1B2A3A),
                tooltip: 'Back',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
