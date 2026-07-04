import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../controllers/auth_controller.dart';

enum SignupRole { broker, client, driver }

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key, this.initialRole});

  final SignupRole? initialRole;

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  late SignupRole _role;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  bool get _isRoleLocked => widget.initialRole != null;
  SignupRole get _lockedRole => widget.initialRole ?? _role;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole ?? SignupRole.broker;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  static const _roleData = <SignupRole, _RoleMeta>{
    SignupRole.broker: _RoleMeta(
      title: 'Broker',
      subtitle: 'Register your transport business and start managing fleets.',
      accent: Color(0xFF1F88C9),
      icon: Icons.handshake_rounded,
      roleValue: 'broker',
    ),
    SignupRole.client: _RoleMeta(
      title: 'Client',
      subtitle: 'Book vehicles and track shipments with ease.',
      accent: Color(0xFF2FA56E),
      icon: Icons.person_rounded,
      roleValue: 'client',
    ),
    SignupRole.driver: _RoleMeta(
      title: 'Driver',
      subtitle: 'Create a driver account for broker-managed work.',
      accent: Color(0xFF7A5AF8),
      icon: Icons.local_shipping_rounded,
      roleValue: 'driver',
    ),
  };

  void _setRole(SignupRole role) {
    if (_role == role) return;
    setState(() => _role = role);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;
    final activeMeta = _roleData[_lockedRole]!;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, email, and password are required.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(authSessionProvider.notifier)
          .register(
            name: name,
            email: email,
            phone: phone.isEmpty ? null : phone,
            password: password,
            role: activeMeta.roleValue,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created. You can log in now.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );

      context.go(_loginRouteForRole(activeMeta.roleValue));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
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
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeMeta = _roleData[_lockedRole]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _DecorBlob(
              color: activeMeta.accent.withValues(alpha: 0.10),
              size: 180,
            ),
          ),
          Positioned(
            bottom: 90,
            left: -40,
            child: _DecorBlob(
              color: const Color(0xFF17324D).withValues(alpha: 0.05),
              size: 140,
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go(
                              _loginRouteForRole(activeMeta.roleValue),
                            ),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Back to login',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create account',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: const Color(0xFF17324D)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRoleLocked
                            ? 'Fill in the details for ${activeMeta.title.toLowerCase()}.'
                            : 'Choose a role and we’ll tailor the signup flow to it.',
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (!_isRoleLocked) ...[
                              Row(
                                children: SignupRole.values
                                    .map(
                                      (role) => Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                            right:
                                                role == SignupRole.values.last
                                                ? 0
                                                : 8,
                                          ),
                                          child: _RoleCard(
                                            meta: _roleData[role]!,
                                            selected: _role == role,
                                            onTap: () => _setRole(role),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                              const SizedBox(height: 14),
                            ],
                            TextField(
                              controller: _nameController,
                              keyboardType: TextInputType.name,
                              decoration: _fieldDecoration(
                                label: 'Full name',
                                icon: Icons.person_rounded,
                                accent: activeMeta.accent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: _fieldDecoration(
                                label: 'Email',
                                icon: Icons.email_rounded,
                                accent: activeMeta.accent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: _fieldDecoration(
                                label: 'Phone',
                                icon: Icons.phone_rounded,
                                accent: activeMeta.accent,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _submit(),
                              decoration: _fieldDecoration(
                                label: 'Password',
                                icon: Icons.lock_rounded,
                                accent: activeMeta.accent,
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
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
                            const SizedBox(height: 2),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFD6E3FF),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.verified_user_rounded,
                                    size: 18,
                                    color: Color(0xFF1F88C9),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'After signup, use the same email and password to log in.',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF1A365D),
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: activeMeta.accent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
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
                                          'Create Account',
                                          key: ValueKey('label'),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go(
                                _loginRouteForRole(activeMeta.roleValue),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF17324D),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              child: const Text(
                                'Already have an account? Login',
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
        ],
      ),
    );
  }
}

class _RoleMeta {
  const _RoleMeta({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.roleValue,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String roleValue;
}

String _loginRouteForRole(String roleValue) {
  return switch (roleValue) {
    'broker' => '/broker/login',
    'driver' => '/driver/login',
    _ => '/login',
  };
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final _RoleMeta meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected
                ? meta.accent.withValues(alpha: 0.10)
                : const Color(0xFFF7FAFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? meta.accent.withValues(alpha: 0.45)
                  : const Color(0xFFE5ECF3),
            ),
          ),
          child: Column(
            children: [
              Icon(meta.icon, color: meta.accent),
              const SizedBox(height: 8),
              Text(
                meta.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF17324D),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DecorBlob extends StatelessWidget {
  const _DecorBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  required Color accent,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFF7FAFD),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFE5ECF3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: accent, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
}
