import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gadidost/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gadidost/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/otp_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/liquid_segmented_toggle.dart';
import 'phone_otp_login_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, required this.expectedRole});

  final AppRole expectedRole;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const String _googleWebClientId =
      '567655647497-ukofai8a0hq0hr5pg1ppr1no0bvsp14k.apps.googleusercontent.com';
  static const String _registerUrl = 'https://gadidostbroker.asynk.in/register';

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  Future<void>? _googleSignInInitialization;
  bool _isSubmitting = false;
  bool _isGoogleSubmitting = false;
  bool _obscurePassword = true;
  bool _isSendingOtp = false;
  _LoginMode _mode = _LoginMode.email;

  @override
  void initState() {
    super.initState();
    ref.read(selectedRoleProvider.notifier).state = widget.expectedRole;
    developer.log(
      'Initializing Google Sign-In for package=com.gadidost.play',
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
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendLoginOtp() async {
    if (_isSendingOtp) return;
    final phone = normalizeIndianPhone(_phoneController.text);
    if (phone.length != 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid 10-digit mobile number.'),
          backgroundColor: Color(0xFFE23A4B),
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isSendingOtp = true);
    try {
      await ref.read(otpServiceProvider).sendOtp(phone: phone);
      if (!mounted) return;
      context.push(
        '/login/otp',
        extra: PhoneOtpLoginArgs(phone: phone, role: widget.expectedRole),
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
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _setMode(_LoginMode mode) {
    FocusScope.of(context).unfocus();
    setState(() => _mode = mode);
  }

  Widget _buildAuthForm(AppLocalizations l10n) {
    final isPhone = _mode == _LoginMode.phone;
    final busy = isPhone ? _isSendingOtp : _isSubmitting;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LiquidSegmentedToggle(
            labels: const ['Email', 'Phone'],
            selectedIndex: _mode.index,
            onChanged: (i) => _setMode(_LoginMode.values[i]),
          ),
          const SizedBox(height: 18),
          AnimatedSize(
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topCenter,
                children: [...previous, ?current],
              ),
              transitionBuilder: (child, animation) {
                // Incoming fields slide in from the side of the tab tapped;
                // outgoing ones slide away the opposite way.
                final fromRight =
                    (child.key == const ValueKey(_LoginMode.phone));
                final dx = fromRight ? 0.18 : -0.18;
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(dx, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isPhone ? _phoneFields() : _emailFields(l10n),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 54,
            child: FilledButton(
              style: FilledButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: const StadiumBorder(),
                backgroundColor: const Color(0xFF2FA56E),
                elevation: 0,
              ),
              onPressed: busy ? null : (isPhone ? _sendLoginOtp : _submit),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.85, end: 1.0).animate(animation),
                    child: child,
                  ),
                ),
                child: busy
                    ? const SizedBox(
                        key: ValueKey('loading'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        key: ValueKey(_mode),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isPhone ? 'Send OTP' : l10n.login,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          if (isPhone) ...[
                            const SizedBox(width: 8),
                            const Icon(
                              AppIcons.arrow_forward_rounded,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emailFields(AppLocalizations l10n) {
    return Column(
      key: const ValueKey(_LoginMode.email),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Email Address'),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          style: const TextStyle(color: Color(0xFF1B2A3A)),
          cursorColor: const Color(0xFF2FA56E),
          decoration: _softDecoration(
            hint: 'you@example.com',
            icon: AppIcons.mail_outline_rounded,
          ),
        ),
        const SizedBox(height: 14),
        _FieldLabel(l10n.password),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) => _submit(),
          style: const TextStyle(color: Color(0xFF1B2A3A)),
          cursorColor: const Color(0xFF2FA56E),
          decoration: _softDecoration(
            hint: '••••••••',
            icon: AppIcons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? AppIcons.visibility_off_outlined
                    : AppIcons.visibility_outlined,
              ),
              tooltip: _obscurePassword ? l10n.showPassword : l10n.hidePassword,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _isSubmitting ? null : _openForgotPasswordSheet,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFF2FA56E),
            ),
            child: const Text(
              'Forgot password?',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneFields() {
    return Column(
      key: const ValueKey(_LoginMode.phone),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel('Mobile Number'),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          onSubmitted: (_) => _sendLoginOtp(),
          style: const TextStyle(
            color: Color(0xFF1B2A3A),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
          cursorColor: const Color(0xFF2FA56E),
          decoration: _softDecoration(
            hint: '98765 43210',
            icon: AppIcons.phone_outlined,
            prefix: const _CountryCode(),
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final l10n = AppLocalizations.of(context)!;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.enterEmailAndPassword)));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      developer.log('Submitting shared login for $email', name: 'SSK.Auth');
      final session = await ref
          .read(authSessionProvider.notifier)
          .login(email: email, password: password);

      final role = appRoleFromApiRole(session.user.role);
      if (role != widget.expectedRole) {
        await ref.read(authSessionProvider.notifier).forceLocalLogout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This account is registered as ${session.user.role}. Please use the ${widget.expectedRole.name} login.',
            ),
            backgroundColor: const Color(0xFFE23A4B),
          ),
        );
        return;
      }
      ref.read(selectedRoleProvider.notifier).state = role;
      ref.read(authExpiredMessageProvider.notifier).state = null;
      if (role == AppRole.client) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      }

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

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isGoogleSubmitting = true);
    try {
      await _googleSignInInitialization;
      developer.log('Starting Google sign-in', name: 'SSK.Auth');

      final account = await _googleSignIn.authenticate();
      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(l10n.googleNoIdToken);
      }

      final session = await ref
          .read(authSessionProvider.notifier)
          .loginWithGoogle(idToken: idToken, role: widget.expectedRole.name);

      final role = appRoleFromApiRole(session.user.role);
      if (role != widget.expectedRole) {
        await ref.read(authSessionProvider.notifier).forceLocalLogout();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'This account is registered as ${session.user.role}. Please use the ${widget.expectedRole.name} login.',
            ),
            backgroundColor: const Color(0xFFE23A4B),
          ),
        );
        return;
      }
      ref.read(selectedRoleProvider.notifier).state = role;
      ref.read(authExpiredMessageProvider.notifier).state = null;
      if (role == AppRole.client) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      }

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
          ? l10n.googleSignInCancelled
          : error.description ?? l10n.googleSignInFailed;
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

  Future<void> _openRegister() async {
    final uri = Uri.parse(_registerUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotOpenRegistration),
        ),
      );
    }
  }

  /// Forgot-password OTP flow (web parity: `Login.jsx` forgot sheet —
  /// `POST /api/auth/forgot-password` then `POST /api/auth/reset-password`).
  Future<void> _openForgotPasswordSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => const _ForgotPasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final expiredMessage = ref.watch(authExpiredMessageProvider);
    final l10n = AppLocalizations.of(context)!;
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    // These are the original role-specific login backgrounds from the
    // historical client / broker / driver login screens.
    final backgroundImage = switch (widget.expectedRole) {
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
                  Colors.white.withValues(alpha: 0.18),
                  Colors.white.withValues(alpha: 0.10),
                  Colors.black.withValues(alpha: 0.06),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/role-login'),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF1B2A3A),
                    ),
                    tooltip: 'Back',
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (expiredMessage != null) ...[
                              _SessionExpiredBanner(
                                message: expiredMessage,
                                onDismiss: () =>
                                    ref
                                            .read(
                                              authExpiredMessageProvider
                                                  .notifier,
                                            )
                                            .state =
                                        null,
                              ),
                              const SizedBox(height: 12),
                            ],
                            Container(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                18,
                                24,
                                16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.80),
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
                                  const SizedBox(height: 4),
                                  _buildAuthForm(l10n),
                                  const SizedBox(height: 16),
                                  const _OrDivider(),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isGoogleSubmitting
                                              ? null
                                              : _submitWithGoogle,
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF1B2A3A,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD7DDE5),
                                            ),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.82),
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(
                                              double.infinity,
                                              52,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 180,
                                            ),
                                            child: _isGoogleSubmitting
                                                ? const SizedBox(
                                                    key: ValueKey(
                                                      'google-loading',
                                                    ),
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Color(
                                                            0xFF1B2A3A,
                                                          ),
                                                        ),
                                                  )
                                                : const _SocialLabel(
                                                    key: ValueKey(
                                                      'google-icon',
                                                    ),
                                                    asset:
                                                        'assets/google_logo.svg',
                                                    label: 'Google',
                                                  ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: Text(
                                                  l10n.appleSignInComingSoon,
                                                ),
                                              ),
                                            );
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(
                                              0xFF1B2A3A,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD7DDE5),
                                            ),
                                            backgroundColor: Colors.white
                                                .withValues(alpha: 0.82),
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(
                                              double.infinity,
                                              52,
                                            ),
                                            shape: const StadiumBorder(),
                                          ),
                                          child: const _SocialLabel(
                                            asset: 'assets/apple_logo.svg',
                                            label: 'Apple',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (widget.expectedRole ==
                                      AppRole.client) ...[
                                    const SizedBox(height: 18),
                                    Center(
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        spacing: 6,
                                        children: [
                                          Text(
                                            l10n.dontHaveAccount,
                                            style: const TextStyle(
                                              color: Color(0xFF1B2A3A),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                context.go('/signup'),
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
                                            child: Text(
                                              l10n.createAccount,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
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
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!keyboardVisible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: widget.expectedRole == AppRole.client
                        // Keep the same reserved footer height as the other
                        // roles, so the centered login card does not move.
                        ? const SizedBox(height: 52)
                        : Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.66),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.14,
                                      ),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: TextButton(
                                    onPressed: _openRegister,
                                    style: TextButton.styleFrom(
                                      foregroundColor: const Color(0xFF2FA56E),
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      l10n.registerAsBrokerDriver,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One-shot banner shown after a global 401 logout: carries the server's
/// own message (session reset vs natural expiry) so the driver knows why.
class _SessionExpiredBanner extends StatelessWidget {
  const _SessionExpiredBanner({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCD34D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              AppIcons.warning_amber_rounded,
              color: Color(0xFFB45309),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7A4A0A),
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
          InkWell(
            onTap: onDismiss,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(
                AppIcons.close_rounded,
                color: Color(0xFFB45309),
                size: 16,
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

/// Forgot-password bottom sheet (web parity: `Login.jsx` forgot sheet).
/// Stage 1: phone → OTP is sent. Stage 2: OTP + new password → reset.
class _ForgotPasswordSheet extends ConsumerStatefulWidget {
  const _ForgotPasswordSheet();

  @override
  ConsumerState<_ForgotPasswordSheet> createState() =>
      _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends ConsumerState<_ForgotPasswordSheet> {
  bool _otpSent = false;
  bool _loading = false;
  bool _obscureNew = true;
  String? _error;
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _digits(String value) => value.replaceAll(RegExp(r'\D'), '');

  Future<void> _sendOtp() async {
    final phone = _digits(_phoneController.text);
    if (phone.length < 10) {
      setState(() => _error = 'Enter a valid phone number.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).forgotPassword(phone: phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent — check your phone.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  Future<void> _resetPassword() async {
    final phone = _digits(_phoneController.text);
    final otp = _otpController.text.trim();
    final next = _newPasswordController.text;
    if (otp.isEmpty) {
      setState(() => _error = 'Enter the OTP sent to your phone.');
      return;
    }
    if (next.length < 6) {
      setState(() => _error = 'New password must be at least 6 characters.');
      return;
    }
    if (next != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .resetPassword(phone: phone, otp: otp, newPassword: next);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset — please sign in.')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('ApiException: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5ECF3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Forgot password?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1B2A3A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _otpSent
                  ? 'Enter the OTP and choose a new password.'
                  : 'Enter your phone number and we will send you an OTP.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            if (!_otpSent) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _sendOtp(),
                decoration: _pillDecoration(
                  label: 'Phone number',
                  icon: AppIcons.phone_rounded,
                ),
              ),
            ] else ...[
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: _pillDecoration(
                  label: 'OTP',
                  icon: AppIcons.confirmation_number_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.next,
                decoration: _pillDecoration(
                  label: 'New password',
                  icon: AppIcons.lock_rounded,
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                    icon: Icon(
                      _obscureNew
                          ? AppIcons.visibility_off_outlined
                          : AppIcons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureNew,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _resetPassword(),
                decoration: _pillDecoration(
                  label: 'Confirm new password',
                  icon: AppIcons.lock_rounded,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFE23A4B),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 52,
              width: double.infinity,
              child: FilledButton(
                onPressed: _loading
                    ? null
                    : (_otpSent ? _resetPassword : _sendOtp),
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  backgroundColor: const Color(0xFF2FA56E),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _otpSent ? 'Reset password' : 'Send OTP',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
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
    prefixIcon: Icon(icon, size: 20),
    prefixIconColor: const Color(0xFF667085),
    suffixIconColor: const Color(0xFF667085),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF7FAFD),
    isDense: true,
    labelStyle: const TextStyle(color: Color(0xFF667085), fontSize: 14),
    floatingLabelStyle: const TextStyle(color: Color(0xFF2FA56E)),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFFE5ECF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: const BorderSide(color: Color(0xFF2FA56E), width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
  );
}

enum _LoginMode { email, phone }

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 7),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.normal,
          color: Color(0xFF1B2A3A),
        ),
      ),
    );
  }
}

class _CountryCode extends StatelessWidget {
  const _CountryCode();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇮🇳', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          const Text(
            '+91',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF1B2A3A),
              fontSize: 15,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1.2, height: 22, color: const Color(0xFFD7DDE5)),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(
      child: Divider(color: Color(0xFFDDE3EA), thickness: 1, height: 1),
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          line,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'Or continue with',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          line,
        ],
      ),
    );
  }
}

class _SocialLabel extends StatelessWidget {
  const _SocialLabel({super.key, required this.asset, required this.label});

  final String asset;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(asset, width: 20, height: 20),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

/// Soft filled field from the login card design: no resting border, green
/// ring on focus.
InputDecoration _softDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
  Widget? prefix,
}) {
  final radius = BorderRadius.circular(18);
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(
      color: Color(0xFF98A2B3),
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    ),
    prefixIcon: prefix ?? Icon(icon, size: 20),
    prefixIconConstraints: prefix == null
        ? null
        : const BoxConstraints(minWidth: 0, minHeight: 0),
    prefixIconColor: const Color(0xFF667085),
    suffixIconColor: const Color(0xFF667085),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF2F5F8),
    border: OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: Colors.transparent),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: radius,
      borderSide: const BorderSide(color: Color(0xFF2FA56E), width: 1.6),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
  );
}
