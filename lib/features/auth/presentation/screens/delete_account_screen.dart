import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import 'package:gadidost/l10n/app_localizations.dart';
import '../controllers/auth_controller.dart';

/// Authenticated account-deletion request, shared by client / broker / driver.
///
/// Flow: settings "Delete Account" tile -> this form (same card UI as Manage
/// Account; name/email/phone are read-only because the backend takes them
/// from the verified account, not user input) -> red Delete button ->
/// confirm dialog -> POST /api/account-deletion-requests/me -> success card.
/// The account stays active until an admin approves it — no logout here.
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _reasonController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;
  String? _errorMessage;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndSubmit() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        title: Text(l10n.deleteAccountConfirmTitle),
        content: Text(l10n.deleteAccountConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE23A4B),
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _submit();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      setState(() => _errorMessage = l10n.deleteAccountNoSession);
      return;
    }
    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await ref.read(apiClientProvider).requestAccountDeletion(
        accessToken: session.tokens.accessToken,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      setState(() => _submitted = true);
    } on ApiException catch (error) {
      developer.log(
        'Account deletion request failed status=${error.statusCode}',
        name: 'SSK.Auth',
      );
      if (!mounted) return;
      setState(() => _errorMessage = error.message);
    } catch (error) {
      developer.log(
        'Account deletion request unexpected error: $error',
        name: 'SSK.Auth',
      );
      if (!mounted) return;
      setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authSessionProvider).valueOrNull?.user;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                title: l10n.deleteAccountTitle,
                subtitle: l10n.deleteAccountFormSubtitle,
                onBack: () => context.pop(),
              ),
              if (_submitted)
                _SuccessCard(onDone: () => context.pop())
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: _WarningBanner(message: l10n.deleteAccountWarning),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _InlineError(message: _errorMessage!),
                  ),
                ],
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: AppColors.brandBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ReadOnlyField(
                          label: l10n.manageAccountFullNameLabel,
                          icon: AppIcons.person_rounded,
                          value: user?.displayName ?? '',
                        ),
                        const SizedBox(height: 14),
                        _ReadOnlyField(
                          label: l10n.manageAccountEmailLabel,
                          icon: AppIcons.email_rounded,
                          value: user?.email ?? '',
                        ),
                        const SizedBox(height: 14),
                        _ReadOnlyField(
                          label: l10n.manageAccountPhoneLabel,
                          icon: AppIcons.phone_rounded,
                          value: user?.phone ?? '',
                        ),
                        const SizedBox(height: 14),
                        _ReasonField(controller: _reasonController),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _confirmAndSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE23A4B),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.button,
                                ),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        AppIcons.delete_outline_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        l10n.delete,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              AppIcons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
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

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerFill,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.error_outline_rounded,
            size: 18,
            color: AppColors.dangerIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dangerText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dangerFill,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.dangerBorder),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.error_outline_rounded,
            size: 18,
            color: AppColors.dangerIcon,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.dangerText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7F9),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDF2)),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF98A2B3)),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  value.isEmpty ? '—' : value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF101828),
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

class _ReasonField extends StatelessWidget {
  const _ReasonField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              l10n.reason,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.manageAccountOptionalTag,
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFEAEDF2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            maxLength: 2000,
            cursorColor: AppColors.brand,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF101828),
            ),
            decoration: InputDecoration(
              hintText: l10n.deleteAccountReasonHint,
              hintStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF98A2B3),
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
              counterText: '',
            ),
          ),
        ),
      ],
    );
  }
}

class _SuccessCard extends StatelessWidget {
  const _SuccessCard({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.brandBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE0F4E8),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.verified_rounded,
                color: Color(0xFF2FA56E),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountSuccessTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.deleteAccountSuccessBody,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: onDone,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                child: Text(
                  l10n.done,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
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
