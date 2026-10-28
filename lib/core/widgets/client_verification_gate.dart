import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gadidost/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

import '../providers/client_kyc_gate_provider.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';

/// Route for the client verification screen (registered in app_router.dart).
const String kClientVerificationRoute = '/client/verification';

/// True when the signed-in client has NOT verified KYC (and the status is
/// no longer loading). Usage pattern:
/// ```dart
/// final gate = ref.watch(clientKycGateProvider);
/// if (gate.redirectToVerify) return ClientVerificationBlockedView(...);
/// ```
bool clientKycVerificationMissing(ClientKycGateState gate) =>
    !gate.loading && !gate.verified;

/// Fast-path check used right before opening a gated flow (web parity:
/// BookTruck.jsx `handleConfirm` checks `kycVerified === false` and opens
/// the KycRequiredSheet *before* calling the API). Loads the per-session
/// status when the view never triggered it. False when the user stayed
/// unverified (the sheet invites them to the verification screen) or the
/// context went away.
Future<bool> ensureClientVerified(
  BuildContext context,
  WidgetRef ref,
) async {
  await ref.read(clientKycGateProvider.notifier).ensureLoaded();
  if (ref.read(clientKycGateProvider).verified) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }
  await showClientVerificationSheet(context, ref);
  return false;
}

/// Bottom sheet (web `KycRequiredSheet` bottom sheet parity) shown when an
/// unverified client tries a gated action: "Verification required … Verify
/// Now" → pushes the client verification screen.
Future<void> showClientVerificationSheet(
  BuildContext context,
  WidgetRef ref,
) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
          decoration: BoxDecoration(
            color: sheetContext.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: sheetContext.colors.brandFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  AppIcons.verified_user_outlined,
                  color: AppColors.brand,
                  size: 30,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                l10n.clientVerificationBlockedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.clientVerificationBlockedBody,
                textAlign: TextAlign.center,
                style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    sheetContext.push(kClientVerificationRoute);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    l10n.clientVerificationAction,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(
                  l10n.clientVerificationNotNow,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// The full-screen block UI shared by every gated client screen — shown
/// instead of the actual screen content while `kyc_status != "verified"`
/// (web `KycGate` → Navigate('/verify') parity). The list of gated screens
/// mirrors the web app: Book a Truck, My Bookings, booking detail, Track
/// Shipment, Wallet, Saved Addresses, Payment Methods, Monthly Hiring and
/// Notifications; only Dashboard/Home, Profile, Chat and this verification
/// screen stay reachable.
class ClientVerificationGate extends ConsumerStatefulWidget {
  const ClientVerificationGate({super.key, required this.child, this.messageContext = 'generic'});

  /// The gated screen's content.
  final Widget child;

  /// 'wallet' swaps the blocked copy for the wallet-specific variant; default
  /// is the generic booking-section one.
  final String messageContext;

  @override
  ConsumerState<ClientVerificationGate> createState() =>
      _ClientVerificationGateState();
}

class _ClientVerificationGateState
    extends ConsumerState<ClientVerificationGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(clientKycGateProvider.notifier).ensureLoaded();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progression = ref.watch(clientKycGateProvider);
    if (!clientKycVerificationMissing(progression)) {
      // 'loading' keeps the real screen blank behind the gate rather than
      // flashing a false block view (web KycGate `if (loading) return null`).
      if (progression.loading) {
        return const Center(child: CircularProgressIndicator());
      }
      return widget.child;
    }
    return ClientVerificationBlockedView(
      messageContext: widget.messageContext,
    );
  }
}

/// Standalone blocked screen — also reachable directly (e.g. the booking
/// wizard draws it when its entry loading point never ran the fast path).
class ClientVerificationBlockedView extends StatelessWidget {
  const ClientVerificationBlockedView({super.key, this.messageContext});

  /// 'wallet' | generic.
  final String? messageContext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.colors.brandFill,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  AppIcons.verified_user_outlined,
                  color: AppColors.brand,
                  size: 38,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.clientVerificationBlockedTitle,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                messageContext == 'wallet'
                    ? l10n.clientVerificationBlockedWalletBody
                    : l10n.clientVerificationBlockedBody,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: () => context.push(kClientVerificationRoute),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    l10n.clientVerificationAction,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
