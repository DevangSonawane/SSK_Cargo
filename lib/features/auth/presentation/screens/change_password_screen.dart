import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../controllers/auth_controller.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String _loginRouteForRole(String? role) {
    return '/login';
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final role = ref.read(authSessionProvider).valueOrNull?.user.role;

    if (currentPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All password fields are required.')),
      );
      return;
    }

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      developer.log('Submitting password change', name: 'SSK.Auth');
      await ref
          .read(authSessionProvider.notifier)
          .changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password changed successfully. You will be logged out now.',
          ),
          backgroundColor: Color(0xFF2FA56E),
          duration: Duration(seconds: 2),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await ref.read(authSessionProvider.notifier).logout();

      if (!mounted) return;
      context.go(_loginRouteForRole(role));
    } on ApiException catch (error) {
      developer.log(
        'Change password failed status=${error.statusCode} message=${error.message}',
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
      developer.log(
        'Change password unexpected error: $error',
        name: 'SSK.Auth',
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _roundIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: const Color(0xFF0F1D43),
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Keep your account secure',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF5E6E91),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: 54,
                    height: 76,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF2FF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      color: Color(0xFF1764E8),
                      size: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF416DAA).withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEFF4FF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF1764E8),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update your password',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF101B43),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Enter your current password and choose a new one.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: const Color(0xFF667391),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _passwordField(
                      label: 'Current password',
                      hint: 'Enter your current password',
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      onToggle: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 16),
                    _passwordField(
                      label: 'New password',
                      hint: 'Enter your new password',
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      onChanged: (_) => setState(() {}),
                      onToggle: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 18),
                    _PasswordStrengthMeter(
                      password: _newPasswordController.text,
                    ),
                    const SizedBox(height: 18),
                    _passwordField(
                      label: 'Confirm new password',
                      hint: 'Confirm your new password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onToggle: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    const SizedBox(height: 22),
                    Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF12B978), Color(0xFF1098B5)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF13A78C,
                            ).withValues(alpha: 0.22),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Change password',
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                  ),
                                  const SizedBox(width: 18),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ],
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
    );
  }

  Widget _roundIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 58,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF45638F).withValues(alpha: 0.09),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: const Color(0xFF0F1D43), size: 24),
      ),
    );
  }

  Widget _passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF354267),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(color: Color(0xFF182344), fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF7783A2)),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF657291),
              size: 22,
            ),
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF3E4867),
                size: 22,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFFCFDFF),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: Color(0xFFD5E0F3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: Color(0xFF1764E8),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({required this.password});

  final String password;

  int get _score {
    if (password.isEmpty) return 0;

    final checks = [
      password.length >= 8,
      RegExp(r'[A-Z]').hasMatch(password),
      RegExp(r'[a-z]').hasMatch(password),
      RegExp(r'\d').hasMatch(password),
      RegExp(r'[^A-Za-z0-9]').hasMatch(password),
    ];

    return checks.where((passed) => passed).length.clamp(1, 4);
  }

  Color get _color {
    return switch (_score) {
      0 => const Color(0xFF98A2B3),
      1 => const Color(0xFFE23A4B),
      2 => const Color(0xFFF59E0B),
      3 => const Color(0xFF1764E8),
      _ => const Color(0xFF13A86B),
    };
  }

  String get _label {
    return switch (_score) {
      0 => 'Password strength',
      1 => 'Weak password',
      2 => 'Fair password',
      3 => 'Good password',
      _ => 'Strong password',
    };
  }

  String get _hint {
    if (password.isEmpty) return 'Type a new password to check strength.';
    if (password.length < 8) return 'Use at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Add an uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Add a lowercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(password)) return 'Add a number.';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(password)) {
      return 'Add a symbol for extra protection.';
    }
    return 'Nice. This password has a strong mix.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _score;
    final color = _color;

    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(
            score >= 4 ? Icons.verified_user_outlined : Icons.shield_outlined,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF354267),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (password.isNotEmpty)
                    Text(
                      '$score/4',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _hint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF5C6B8C),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      height: 7,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 8),
                      decoration: BoxDecoration(
                        color: index < score ? color : const Color(0xFFE0E7F3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
