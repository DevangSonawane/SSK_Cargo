import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'dart:developer' as developer;

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/auth_models.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AuthLoginScreen(role: AppRole.client);
  }
}

class BrokerLoginScreen extends ConsumerWidget {
  const BrokerLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AuthLoginScreen(role: AppRole.broker);
  }
}

class DriverLoginScreen extends ConsumerWidget {
  const DriverLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _AuthLoginScreen(role: AppRole.driver);
  }
}

class _AuthLoginScreen extends ConsumerStatefulWidget {
  const _AuthLoginScreen({required this.role});

  final AppRole role;

  @override
  ConsumerState<_AuthLoginScreen> createState() => _AuthLoginScreenState();
}

class _AuthLoginScreenState extends ConsumerState<_AuthLoginScreen> {
  static const String _googleWebClientId =
      '567655647497-ukofai8a0hq0hr5pg1ppr1no0bvsp14k.apps.googleusercontent.com';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInitialization;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    developer.log(
      'Initializing Google Sign-In for package=com.example.ssk',
      name: 'SSK.Auth',
    );
    _googleSignInInitialization = _googleSignIn.initialize(
      clientId: kIsWeb ? _googleWebClientId : null,
      serverClientId: _googleWebClientId,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter both email and password.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      developer.log(
        'Submitting login for $email as ${widget.role.name}',
        name: 'SSK.Auth',
      );
      final session = await ref
          .read(authSessionProvider.notifier)
          .login(email: email, password: password);

      ref.read(selectedRoleProvider.notifier).state = appRoleFromApiRole(
        session.user.role,
      );

      if (!mounted) {
        return;
      }

      developer.log(
        'Login success role=${session.user.role} route=${_routeForRole(session.user.role)}',
        name: 'SSK.Auth',
      );
      context.go(_routeForRole(session.user.role));
    } on ApiException catch (error) {
      developer.log(
        'Login failed status=${error.statusCode} message=${error.message}',
        name: 'SSK.Auth',
      );
      if (await _maybeBypassDriverVerification(error, email)) {
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      developer.log('Login unexpected error: $error', name: 'SSK.Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool> _maybeBypassDriverVerification(
    ApiException error,
    String email,
  ) async {
    final shouldBypass =
        kDebugMode &&
        widget.role == AppRole.driver &&
        error.statusCode == 403 &&
        error.message.toLowerCase().contains('phone not verified');

    if (!shouldBypass) {
      return false;
    }

    final normalizedEmail = email.isEmpty ? 'driver@ssklogistics.in' : email;
    final session = AuthSession(
      user: SskUser(
        id: 'debug-driver-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Driver Test',
        email: normalizedEmail,
        phone: '0000000000',
        role: 'driver',
        status: 'active',
        isPhoneVerified: true,
        isEmailVerified: true,
        profileImage: null,
        lastLoginAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      tokens: const AuthTokens(
        accessToken: 'debug-access-token',
        refreshToken: 'debug-refresh-token',
        tokenType: 'Bearer',
        expiresIn: 'debug',
      ),
    );

    ref.read(authSessionProvider.notifier).debugSetSession(session);
    ref.read(selectedRoleProvider.notifier).state = AppRole.driver;

    if (!mounted) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debug bypass enabled for driver login.'),
        backgroundColor: Color(0xFF2FA56E),
      ),
    );
    context.go('/driver/home');
    return true;
  }

  Future<void> _submitWithGoogle() async {
    if (widget.role == AppRole.admin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google sign-in is not available for admin accounts.'),
        ),
      );
      return;
    }

    setState(() => _isGoogleSubmitting = true);
    try {
      await _googleSignInInitialization;
      developer.log(
        'Starting Google sign-in for ${widget.role.name}',
        name: 'SSK.Auth',
      );

      final account = await _googleSignIn.authenticate();

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token.');
      }

      final session = await ref
          .read(authSessionProvider.notifier)
          .loginWithGoogle(
            idToken: idToken,
            role: switch (widget.role) {
              AppRole.broker => 'broker',
              AppRole.driver => 'driver',
              _ => 'client',
            },
          );

      ref.read(selectedRoleProvider.notifier).state = appRoleFromApiRole(
        session.user.role,
      );

      if (!mounted) {
        return;
      }

      final actualRole = appRoleFromApiRole(session.user.role);
      final requestedRole = widget.role;
      final isRoleMismatch = actualRole != requestedRole;

      if (isRoleMismatch) {
        final actualRoleLabel = session.user.role;
        final requestedRoleLabel = requestedRole.name;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This account is associated with $actualRoleLabel. Kindly use a different account for $requestedRoleLabel.',
            ),
            backgroundColor: const Color(0xFFE23A4B),
          ),
        );
        developer.log(
          'Google login role mismatch requested=${requestedRole.name} actual=${session.user.role} redirect=${_routeForRole(session.user.role)}',
          name: 'SSK.Auth',
        );
        context.go(_routeForRole(session.user.role));
        return;
      }

      if (session.isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Google account connected.'),
            backgroundColor: Color(0xFF2FA56E),
          ),
        );
      }
      if (session.needsPhone) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a phone number in your profile.'),
          ),
        );
      }

      developer.log(
        'Google login success role=${session.user.role} route=${_routeForRole(session.user.role)}',
        name: 'SSK.Auth',
      );
      context.go(_routeForRole(session.user.role));
    } on ApiException catch (error) {
      developer.log(
        'Google login failed status=${error.statusCode} message=${error.message}',
        name: 'SSK.Auth',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } on GoogleSignInException catch (error) {
      developer.log(
        'Google login exception code=${error.code} description=${error.description}',
        name: 'SSK.Auth',
      );
      if (!mounted) return;

      final message = error.code == GoogleSignInExceptionCode.canceled
          ? 'Google sign-in is not configured correctly for Android. Check the OAuth client, package name, and SHA-1/SHA-256 in Google Cloud Console.'
          : error.description ?? 'Google sign-in failed.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      developer.log('Google login unexpected error: $error', name: 'SSK.Auth');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGoogleSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backgroundImage = switch (widget.role) {
      AppRole.broker => 'assets/Gemini_Generated_Image_3yu2bb3yu2bb3yu2.png',
      AppRole.driver => 'assets/driverloginscreen.png',
      _ => 'assets/IMG_1750.PNG',
    };

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            backgroundImage,
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
                              onPressed: () => context.go(
                                widget.role == AppRole.driver
                                    ? '/broker/login'
                                    : '/access',
                              ),
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: widget.role == AppRole.driver
                                    ? Colors.white
                                    : Colors.black,
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
                                        onSubmitted: (_) => _submit(),
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
                                          onPressed: _isSubmitting
                                              ? null
                                              : _submit,
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child: _isSubmitting
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
                                              onPressed: _isGoogleSubmitting
                                                  ? null
                                                  : _submitWithGoogle,
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
                                              label: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 180,
                                                ),
                                                child: _isGoogleSubmitting
                                                    ? const SizedBox(
                                                        key: ValueKey(
                                                          'google-loading',
                                                        ),
                                                        width: 18,
                                                        height: 18,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              color: Color(
                                                                0xFF1B2A3A,
                                                              ),
                                                            ),
                                                      )
                                                    : const Text(
                                                        'Google',
                                                        key: ValueKey(
                                                          'google-label',
                                                        ),
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              onPressed: () {
                                                // TODO: wire Apple auth flow.
                                              },
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
                                      if (widget.role != AppRole.driver)
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
                                                onPressed: () => context.go(
                                                  widget.role == AppRole.broker
                                                      ? '/broker/signup'
                                                      : '/client/signup',
                                                ),
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
                                      if (widget.role == AppRole.broker) ...[
                                        const SizedBox(height: 8),
                                        Center(
                                          child: Wrap(
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 6,
                                            children: [
                                              const Text(
                                                'Rider?',
                                                style: TextStyle(
                                                  color: Color(0xFF1B2A3A),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    context.go('/driver/login'),
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
                                                  'Login here',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
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

String _routeForRole(String role) {
  return switch (role) {
    'client' => '/client/home',
    'broker' => '/broker/home',
    'driver' => '/driver/home',
    'admin' => '/broker/home',
    _ => '/client/home',
  };
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
      borderSide: BorderSide(color: const Color(0xFF2FA56E), width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}
