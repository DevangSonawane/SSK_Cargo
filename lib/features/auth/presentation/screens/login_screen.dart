import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../controllers/auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
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
    if (_isSubmitting) {
      return;
    }

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
      developer.log('Submitting shared login for $email', name: 'SSK.Auth');
      final session = await ref
          .read(authSessionProvider.notifier)
          .login(email: email, password: password);

      final role = appRoleFromApiRole(session.user.role);
      ref.read(selectedRoleProvider.notifier).state = role;

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

  Future<void> _submitWithGoogle() async {
    if (_isGoogleSubmitting) {
      return;
    }

    setState(() => _isGoogleSubmitting = true);
    try {
      await _googleSignInInitialization;
      developer.log('Starting Google sign-in', name: 'SSK.Auth');

      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Google did not return an ID token.');
      }

      final session = await ref
          .read(authSessionProvider.notifier)
          .loginWithGoogle(idToken: idToken, role: 'client');

      final role = appRoleFromApiRole(session.user.role);
      ref.read(selectedRoleProvider.notifier).state = role;

      if (!mounted) {
        return;
      }

      context.go(_routeForRole(session.user.role));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } on GoogleSignInException catch (error) {
      if (!mounted) return;
      final message = error.code == GoogleSignInExceptionCode.canceled
          ? 'Google sign-in was cancelled.'
          : error.description ?? 'Google sign-in failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
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
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/IMG_1750.PNG',
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
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.66),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: _pillDecoration(
                            label: 'Email',
                            icon: Icons.email_rounded,
                          ),
                        ),
                        const SizedBox(height: 14),
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
                                  foregroundColor: const Color(0xFF1B2A3A),
                                  side: const BorderSide(
                                    color: Color(0xFFD7DDE5),
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.82,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                                label: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 180),
                                  child: _isGoogleSubmitting
                                      ? const SizedBox(
                                          key: ValueKey('google-loading'),
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF1B2A3A),
                                          ),
                                        )
                                      : const Text(
                                          'Google',
                                          key: ValueKey('google-label'),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Apple sign-in is coming soon.',
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.apple,
                                  size: 22,
                                  color: Color(0xFF1B2A3A),
                                ),
                                label: const Text(
                                  'Apple',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF1B2A3A),
                                  side: const BorderSide(
                                    color: Color(0xFFD7DDE5),
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.82,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: const StadiumBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
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
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
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
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: const StadiumBorder(),
                              backgroundColor: const Color(0xFF2FA56E),
                            ),
                            onPressed: _isSubmitting ? null : _submit,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              child: _isSubmitting
                                  ? const SizedBox(
                                      key: ValueKey('loading'),
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      key: ValueKey('label'),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Center(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
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
                                onPressed: () => context.go('/signup'),
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: const Color(0xFF2FA56E),
                                ),
                                child: const Text(
                                  'Create account',
                                  style: TextStyle(fontWeight: FontWeight.w800),
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
    'admin' => '/gps/dashboard',
    _ => '/gps/dashboard',
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
      borderSide: const BorderSide(color: Color(0xFF2FA56E), width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}
