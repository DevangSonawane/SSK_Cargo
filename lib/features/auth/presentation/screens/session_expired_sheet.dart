import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../controllers/auth_controller.dart';

/// Inline re-login sheet shown over the current page when the session dies
/// (web `SessionExpiredModal.jsx` parity). Deliberately does NOT log out or
/// reroute — the user keeps their place; only a successful sign-in (or an
/// explicit logout elsewhere) changes the session.
///
/// Returns true when the user signed back in.
Future<bool> showSessionExpiredSheet(
  BuildContext context, {
  String? message,
}) async {
  final signedIn = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: _SessionExpiredSheet(message: message),
    ),
  );
  return signedIn == true;
}

class _SessionExpiredSheet extends ConsumerStatefulWidget {
  const _SessionExpiredSheet({this.message});

  final String? message;

  @override
  ConsumerState<_SessionExpiredSheet> createState() =>
      _SessionExpiredSheetState();
}

class _SessionExpiredSheetState extends ConsumerState<_SessionExpiredSheet> {
  late final TextEditingController _emailController;
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    final email =
        ref.read(authSessionProvider).valueOrNull?.user.email ?? '';
    _emailController = TextEditingController(text: email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_loading) return;
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      await ref
          .read(authSessionProvider.notifier)
          .login(email: email, password: password);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.brandFill,
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.lock_outline_rounded,
                color: colors.brandEmphasis,
                size: 22,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your session has expired',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.message?.trim().isNotEmpty == true
                  ? widget.message!.trim()
                  : 'Please sign in again to continue where you left off.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Email Address',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Enter your email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(AppIcons.mail_outline_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Password',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _passwordController,
              obscureText: !_showPassword,
              onSubmitted: (_) => _signIn(),
              decoration: InputDecoration(
                hintText: 'Enter your password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(AppIcons.lock_outline_rounded),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _showPassword = !_showPassword),
                  icon: Icon(
                    _showPassword
                        ? AppIcons.visibility_off_outlined
                        : AppIcons.visibility_outlined,
                  ),
                ),
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: colors.dangerEmphasis.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colors.dangerEmphasis.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  _error,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.dangerEmphasis,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _loading ? null : _signIn,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
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
                    : const Text(
                        'Sign In',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
