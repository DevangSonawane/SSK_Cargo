import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

KycGateCopy kycGateCopyFor(String status) {
  switch (status.trim().toLowerCase()) {
    case 'submitted':
      return const KycGateCopy(
        title: 'KYC Under Review',
        body:
            "Your documents are being reviewed by our team. You'll be able to accept jobs once verified - usually within 24-48 hours.",
        action: 'View KYC Status',
        icon: AppIcons.hourglass_top_rounded,
        color: Color(0xFFD97706),
        background: Color(0xFFFFF7E8),
      );
    case 'rejected':
      return const KycGateCopy(
        title: 'KYC Rejected',
        body:
            'Your last submission was rejected. Please review the reason and resubmit your documents to continue.',
        action: 'Resubmit KYC',
        icon: AppIcons.error_outline_rounded,
        color: AppColors.dangerIcon,
        background: AppColors.dangerFill,
      );
    default:
      return const KycGateCopy(
        title: 'Complete Your KYC First',
        body:
            'You need to verify your PAN, Aadhaar, and license details before you can accept jobs on the platform. Most checks clear instantly.',
        action: 'Complete KYC',
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
  final copy = kycGateCopyFor(status);
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
            child: const Text('Not now'),
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
