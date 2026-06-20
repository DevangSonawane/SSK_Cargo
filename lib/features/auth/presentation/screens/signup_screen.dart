import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SignupRole { broker, client, driver }

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  SignupRole _role = SignupRole.client;

  static const _roleData = <SignupRole, _RoleMeta>{
    SignupRole.broker: _RoleMeta(
      title: 'Broker',
      subtitle: 'Manage loads, rates, and booking operations.',
      accent: Color(0xFF1F88C9),
      icon: Icons.handshake_rounded,
      fields: [
        _FieldMeta('Full name', Icons.person_rounded, TextInputType.name),
        _FieldMeta('Company name', Icons.domain_rounded, TextInputType.text),
        _FieldMeta('Business email', Icons.email_rounded, TextInputType.emailAddress),
        _FieldMeta('Phone number', Icons.phone_rounded, TextInputType.phone),
        _FieldMeta('GST / tax ID', Icons.badge_rounded, TextInputType.text),
        _FieldMeta('Password', Icons.lock_rounded, TextInputType.visiblePassword, obscure: true),
      ],
    ),
    SignupRole.client: _RoleMeta(
      title: 'Client',
      subtitle: 'Book vehicles and track shipments with ease.',
      accent: Color(0xFF2FA56E),
      icon: Icons.person_rounded,
      fields: [
        _FieldMeta('Full name', Icons.person_rounded, TextInputType.name),
        _FieldMeta('Email address', Icons.email_rounded, TextInputType.emailAddress),
        _FieldMeta('Phone number', Icons.phone_rounded, TextInputType.phone),
        _FieldMeta('Company / organization', Icons.apartment_rounded, TextInputType.text),
        _FieldMeta('Password', Icons.lock_rounded, TextInputType.visiblePassword, obscure: true),
      ],
    ),
    SignupRole.driver: _RoleMeta(
      title: 'Driver',
      subtitle: 'Accept trips, manage routes, and update deliveries.',
      accent: Color(0xFF7A5AF8),
      icon: Icons.local_shipping_rounded,
      fields: [
        _FieldMeta('Full name', Icons.person_rounded, TextInputType.name),
        _FieldMeta('Mobile number', Icons.phone_rounded, TextInputType.phone),
        _FieldMeta('Driver license no.', Icons.badge_rounded, TextInputType.text),
        _FieldMeta('Vehicle type', Icons.local_shipping_rounded, TextInputType.text),
        _FieldMeta('Password', Icons.lock_rounded, TextInputType.visiblePassword, obscure: true),
      ],
    ),
  };

  void _setRole(SignupRole role) {
    if (_role == role) return;
    setState(() => _role = role);
  }

  @override
  Widget build(BuildContext context) {
    final meta = _roleData[_role]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      body: Stack(
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _DecorBlob(
              color: meta.accent.withValues(alpha: 0.10),
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
                            onPressed: () => context.go('/login'),
                            icon: const Icon(Icons.arrow_back_rounded),
                            tooltip: 'Back to login',
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Create account',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  color: const Color(0xFF17324D),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose a role and we’ll tailor the signup flow to it.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.black54,
                            ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
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
                            Row(
                              children: SignupRole.values
                                  .map(
                                    (role) => Expanded(
                                      child: Padding(
                                        padding: EdgeInsets.only(
                                          right: role == SignupRole.values.last ? 0 : 8,
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
                            ...meta.fields.map(
                              (field) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: TextField(
                                  keyboardType: field.keyboardType,
                                  obscureText: field.obscure,
                                  decoration: _fieldDecoration(
                                    label: field.label,
                                    icon: field.icon,
                                    accent: meta.accent,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: meta.accent,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/login'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF17324D),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              child: const Text('Already have an account? Login'),
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
    required this.fields,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final List<_FieldMeta> fields;
}

class _FieldMeta {
  const _FieldMeta(
    this.label,
    this.icon,
    this.keyboardType, {
    this.obscure = false,
  });

  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscure;
}

InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
  required Color accent,
}) {
  return InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon),
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
      borderSide: BorderSide(color: accent, width: 1.4),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
  );
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? meta.accent.withValues(alpha: 0.10) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? meta.accent.withValues(alpha: 0.24) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          children: [
            Icon(meta.icon, size: 20, color: selected ? meta.accent : const Color(0xFF94A3B8)),
            const SizedBox(height: 6),
            Text(
              meta.title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12,
                    color: const Color(0xFF17324D),
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DecorBlob extends StatelessWidget {
  const _DecorBlob({
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
