import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gadidost/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gadidost/l10n/app_localizations.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../data/otp_service.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_verification_view.dart';

const _ink = Color(0xFF111827);
const _muted = Color(0xFF6B7280);
const _faint = Color(0xFF9CA3AF);
const _line = Color(0xFFE5E7EB);
const _green = Color(0xFF149468);
const _red = Color(0xFFDC2626);

enum _SignupStep { details, verify }

/// Client sign-up in two steps: account details → phone OTP. The new account
/// is signed in straight away after verification.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  _SignupStep _step = _SignupStep.details;
  bool _forward = true;
  bool _isSendingOtp = false;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _phone => normalizeIndianPhone(_phoneController.text);

  void _goTo(_SignupStep step) {
    FocusScope.of(context).unfocus();
    setState(() {
      _forward = step.index > _step.index;
      _step = step;
      _error = null;
    });
  }

  void _back() {
    if (_step == _SignupStep.details) {
      context.go('/login');
    } else {
      _goTo(_SignupStep.values[_step.index - 1]);
    }
  }

  void _fail(String message) {
    HapticFeedback.mediumImpact();
    setState(() => _error = message);
  }

  Future<void> _sendOtp() async {
    if (_isSendingOtp) return;
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (name.isEmpty ||
        email.isEmpty ||
        _phoneController.text.isEmpty ||
        password.isEmpty) {
      return _fail(l10n.signupAllFieldsRequired);
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return _fail('Enter a valid email address.');
    }
    if (_phone.length != 10) {
      return _fail('Enter a valid 10-digit mobile number.');
    }
    if (password.length < 8) return _fail(l10n.signupPasswordHelper);

    setState(() {
      _isSendingOtp = true;
      _error = null;
    });
    try {
      await ref.read(otpServiceProvider).sendOtp(phone: _phone);
      if (mounted) _goTo(_SignupStep.verify);
    } catch (error) {
      if (mounted) _fail(error.toString());
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  Future<void> _createAccount() async {
    if (_isSubmitting) return;
    final password = _passwordController.text;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final email = _emailController.text.trim();
    final auth = ref.read(authSessionProvider.notifier);
    try {
      await auth.register(
        name: _nameController.text.trim(),
        email: email,
        phone: _phone,
        password: password,
        role: 'client',
      );
      final session = await auth.login(email: email, password: password);
      ref.read(selectedRoleProvider.notifier).state = appRoleFromApiRole(
        session.user.role,
      );
      ref.read(authExpiredMessageProvider.notifier).state = null;
      ref.read(bottomNavVisibleProvider.notifier).state = true;
      if (!mounted) return;
      context.go('/client/home');
    } on ApiException catch (error) {
      if (mounted) _fail(error.message);
    } catch (error) {
      if (mounted) _fail(error.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopBar(step: _step, onBack: _isSubmitting ? null : _back),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 360),
                  reverseDuration: const Duration(milliseconds: 160),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeIn,
                  layoutBuilder: (current, previous) =>
                      Stack(children: [...previous, ?current]),
                  transitionBuilder: (child, animation) {
                    final isIncoming =
                        child.key == ValueKey<_SignupStep>(_step);
                    final dir = _forward == isIncoming ? 1.0 : -1.0;
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: Offset(0.06 * dir, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<_SignupStep>(_step),
                    child: _stepBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepBody() {
    final l10n = AppLocalizations.of(context)!;
    return switch (_step) {
      _SignupStep.details => _detailsStep(l10n),
      _SignupStep.verify => Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: OtpVerificationView(
              phone: _phone,
              showBadge: false,
              title: 'Verify your number',
              continuingLabel: 'Verified',
              onChangeNumber: () => _goTo(_SignupStep.details),
              onVerified: (_) => _createAccount(),
            ),
          ),
        ),
      ),
    };
  }

  Widget _detailsStep(AppLocalizations l10n) {
    return _StepLayout(
      title: 'Create your account',
      subtitle: 'Book trucks and track every shipment in one place.',
      error: _error,
      button: _PrimaryButton(
        label: 'Create account',
        loading: _isSendingOtp,
        onPressed: _sendOtp,
      ),
      below: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            l10n.signupAlreadyHaveAccount,
            style: const TextStyle(color: _muted, fontSize: 13.5),
          ),
          TextButton(
            onPressed: () => context.go('/login'),
            style: TextButton.styleFrom(
              foregroundColor: _ink,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              l10n.signupLoginAction,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
                decorationColor: _ink,
              ),
            ),
          ),
        ],
      ),
      children: [
        _Field(
          label: 'Full name',
          controller: _nameController,
          hint: 'Your name',
          keyboardType: TextInputType.name,
          capitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name],
        ),
        _Field(
          label: 'Email',
          controller: _emailController,
          hint: 'name@company.com',
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
        ),
        _Field(
          label: 'Mobile number',
          controller: _phoneController,
          hint: '98765 43210',
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumberNational],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          prefixText: '+91',
          action: TextInputAction.next,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 1, bottom: 12),
          child: Text(
            'We\'ll text you a code to confirm this number.',
            style: TextStyle(color: _faint, fontSize: 12.5),
          ),
        ),
        _Field(
          label: 'Password',
          controller: _passwordController,
          hint: 'At least 8 characters',
          obscure: _obscurePassword,
          autofillHints: const [AutofillHints.newPassword],
          action: TextInputAction.done,
          onSubmitted: (_) => _sendOtp(),
          suffix: GestureDetector(
            onTap: () => setState(() => _obscurePassword = !_obscurePassword),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                _obscurePassword ? 'Show' : 'Hide',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Back arrow, two hairline step markers and a step count.
class _TopBar extends StatelessWidget {
  const _TopBar({required this.step, required this.onBack});

  final _SignupStep step;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 24, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(AppIcons.arrow_back_rounded, size: 22),
            color: _ink,
            tooltip: 'Back',
          ),
          const Spacer(),
          for (var i = 0; i < _SignupStep.values.length; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.only(left: 4),
              width: i == step.index ? 22 : 10,
              height: 3,
              decoration: BoxDecoration(
                color: i <= step.index ? _ink : _line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          const SizedBox(width: 12),
          Text(
            '0${step.index + 1} / 02',
            style: const TextStyle(
              color: _faint,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Heading, fields, then the button pinned to the bottom of the screen.
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.subtitle,
    required this.children,
    required this.button,
    this.below,
    this.error,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget button;
  final Widget? below;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 24),
                ...children,
              ],
            ),
          ),
        ),
        SliverFillRemaining(
          hasScrollBody: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: error == null
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: _red,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                ),
                button,
                if (below != null) ...[const SizedBox(height: 14), below!],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.prefixText,
    this.suffix,
    this.obscure = false,
    this.action = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final Widget? suffix;
  final bool obscure;
  final TextInputAction action;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            textCapitalization: capitalization,
            textInputAction: action,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            obscureText: obscure,
            onSubmitted: onSubmitted,
            cursorColor: _ink,
            cursorWidth: 1.4,
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.normal,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: _faint, fontSize: 14),
              isDense: true,
              prefixIcon: prefixText == null
                  ? null
                  : Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Text(
                        prefixText!,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
              prefixIconConstraints: const BoxConstraints(),
              suffixIcon: suffix,
              suffixIconConstraints: const BoxConstraints(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: _line),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: radius,
                borderSide: const BorderSide(color: _ink, width: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onPressed,
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: _green,
          disabledBackgroundColor: _green.withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  key: const ValueKey('label'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.normal,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
        ),
      ),
    );
  }
}
