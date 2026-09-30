import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/l10n/app_localizations.dart';

import '../providers/kyc_status_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';

class KycGateCopy {
  const KycGateCopy({
    required this.title,
    required this.body,
    required this.action,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final String body;
  final String action;
  final IconData icon;
  final Color color;
  final Color background;
}

KycGateCopy kycGateCopyFor(String status, AppLocalizations l10n) {
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return KycGateCopy(
        title: l10n.coreKycUnderReviewTitle,
        body: l10n.coreKycUnderReviewBody,
        action: l10n.coreKycViewStatusAction,
        icon: AppIcons.hourglass_top_rounded,
        color: Color(0xFFD97706),
        background: Color(0xFFFFF7E8),
      );
    case 'rejected':
      return KycGateCopy(
        title: l10n.coreKycRejectedTitle,
        body: l10n.coreKycRejectedBody,
        action: l10n.coreKycResubmitAction,
        icon: AppIcons.error_outline_rounded,
        color: AppColors.dangerIcon,
        background: AppColors.dangerFill,
      );
    default:
      return KycGateCopy(
        title: l10n.coreKycIncompleteTitle,
        body: l10n.coreKycIncompleteBody,
        action: l10n.coreKycCompleteAction,
        icon: AppIcons.verified_user_outlined,
        color: AppColors.brand,
        background: AppColors.brandTint,
      );
  }
}

Future<bool> ensureKycVerifiedForAccept({
  required BuildContext context,
  required WidgetRef ref,
  required String role,
}) async {
  String status;
  try {
    status = await ref.read(kycStatusProvider.future);
  } catch (_) {
    status = 'pending';
  }

  if (status == 'verified') {
    return true;
  }

  if (!context.mounted) {
    return false;
  }

  await showKycGateDialog(context: context, status: status, role: role);
  return false;
}

Future<void> showKycGateDialog({
  required BuildContext context,
  required String status,
  required String role,
}) {
  final l10n = AppLocalizations.of(context)!;
  final copy = kycGateCopyFor(status, l10n);
  final path = role == 'broker'
      ? '/broker/kyc-registration'
      : '/driver/kyc-registration';

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        title: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: copy.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(copy.icon, color: copy.color, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              copy.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          copy.body,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.45),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(dialogContext)!.coreKycNotNow),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push(path);
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
            child: Text(copy.action),
          ),
        ],
      );
    },
  );
}
