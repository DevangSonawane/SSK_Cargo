import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/kyc_gate_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/controllers/client_notifications_controller.dart';
import '../widgets/broker_flow_widgets.dart';
import 'package:ssk/l10n/app_localizations.dart';

class BrokerDriverRequestsScreen extends ConsumerStatefulWidget {
  const BrokerDriverRequestsScreen({super.key});

  @override
  ConsumerState<BrokerDriverRequestsScreen> createState() =>
      _BrokerDriverRequestsScreenState();
}

class _BrokerDriverRequestsScreenState
    extends ConsumerState<BrokerDriverRequestsScreen> {
  static const _query = (page: 1, limit: 100);
  final Set<String> _actioningIds = <String>{};

  Future<void> _refresh() async {
    ref.invalidate(brokerDriverRequestsProvider(_query));
    await ref.read(brokerDriverRequestsProvider(_query).future);
  }

  bool _isActioning(String id) => _actioningIds.contains(id);

  Future<void> _runAction({
    required BrokerDriverRequest request,
    required Future<void> Function(SskApiClient api, String token) action,
    required String successMessage,
  }) async {
    if (_isActioning(request.id)) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _actioningIds.add(request.id));
    try {
      await action(ref.read(apiClientProvider), session.tokens.accessToken);
      ref.invalidate(brokerDriverRequestsProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: AppColors.brand,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _actioningIds.remove(request.id));
      }
    }
  }

  Future<void> _acceptRequest(BrokerDriverRequest request) async {
    if (!await ensureKycVerifiedForAccept(
      context: context,
      ref: ref,
      role: 'broker',
    )) {
      return;
    }
    if (!mounted) return;
    return _runAction(
      request: request,
      successMessage: AppLocalizations.of(context)!
          .brokerDriverRequestsAccepted,
      action: (api, token) {
        return api.acceptDriverRequestAsDriver(
          accessToken: token,
          id: request.id,
        );
      },
    );
  }

  Future<void> _declineRequest(BrokerDriverRequest request) {
    return _runAction(
      request: request,
      successMessage: AppLocalizations.of(context)!
          .brokerDriverRequestsDeclined,
      action: (api, token) {
        return api.rejectDriverRequest(accessToken: token, id: request.id);
      },
    );
  }

  Future<void> _openCounterSheet(BrokerDriverRequest request) async {
    if (_isActioning(request.id)) return;

    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (_) => _BrokerCounterSheet(request: request),
    );

    if (amount == null) return;

    await _runAction(
      request: request,
      successMessage: 'Fare change sent.',
      action: (api, token) {
        return api.counterDriverRequest(
          accessToken: token,
          id: request.id,
          amount: amount,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(brokerDriverRequestsProvider(_query));
    final notificationsAsync = ref.watch(clientNotificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: Text(l10n.brokerDriverReqDriverRequests),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: requestsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            children: [Center(child: CircularProgressIndicator())],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            children: [
              _EmptyState(
                title: l10n.brokerDriverReqCouldNotLoadDriverRequests,
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (requests) {
            final notificationRequests =
                notificationsAsync.valueOrNull
                    ?.where(
                      (notification) =>
                          brokerLooksLikeTimedOutNegotiationPayload(
                            notification.raw,
                          ),
                    )
                    .map(
                      (notification) =>
                          brokerDriverRequestFromNotificationPayload(
                            notification.raw,
                          ),
                    )
                    .toList() ??
                const <BrokerDriverRequest>[];

            final mergedRequests = <BrokerDriverRequest>[
              ...requests,
              ...notificationRequests,
            ];
            final visibleRequests = <BrokerDriverRequest>[];
            final seenKeys = <String>{};
            for (final request in mergedRequests) {
              if (!isActiveBrokerDriverRequest(request)) {
                continue;
              }
              final key = [
                request.id,
                request.bookingId,
                request.bookingNumber,
              ].where((value) => value.isNotEmpty).join('|');
              if (key.isNotEmpty && seenKeys.add(key)) {
                visibleRequests.add(request);
              }
            }

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.brokerDriverReqNegotiationCards,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _refresh,
                      icon: const Icon(AppIcons.refresh_rounded),
                      label: Text(AppLocalizations.of(context)!.brokerDriverReqReload),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (visibleRequests.isEmpty)
                  _EmptyState(
                    title: AppLocalizations.of(context)!.brokerDriverReqNoDriverRequestsYet,
                    subtitle:
                        AppLocalizations.of(context)!.brokerDriverReqWhenADriverTimesOutTheRequest,
                  )
                else
                  ...visibleRequests.asMap().entries.expand((entry) {
                    final request = entry.value;
                    return [
                      _BrokerRequestTile(
                        request: request,
                        busy: _isActioning(request.id),
                        onAccept: () => _acceptRequest(request),
                        onCounter: () => _openCounterSheet(request),
                        onDecline: () => _declineRequest(request),
                      ),
                      if (entry.key != visibleRequests.length - 1)
                        const SizedBox(height: 12),
                    ];
                  }),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BrokerRequestTile extends StatelessWidget {
  const _BrokerRequestTile({
    required this.request,
    required this.busy,
    required this.onAccept,
    required this.onCounter,
    required this.onDecline,
  });

  final BrokerDriverRequest request;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingText = request.bookingNumber.isNotEmpty
        ? request.bookingNumber
        : request.bookingId;
    final status = request.status.trim().toLowerCase();
    final pendingConfirmationBy = request.pendingConfirmationBy
        .trim()
        .toLowerCase();
    final awaitingConfirmation = status == 'awaiting_confirmation';
    final waitingOnClient =
        awaitingConfirmation && pendingConfirmationBy == 'broker';
    final yourTurn = awaitingConfirmation && pendingConfirmationBy == 'client';
    final brokerAssigned = request.jobRequestId.isNotEmpty;
    final canAct =
        !busy &&
        (status.isEmpty ||
            status == 'requested' ||
            status == 'pending' ||
            awaitingConfirmation);
    final canCounter = canAct && !brokerAssigned;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.brokerDriverReqBookingID,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookingText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (brokerAssigned) ...[
                    _BrokerAssignedBadge(),
                    const SizedBox(height: 6),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: request.driverTimedOut
                          ? AppColors.warningFill
                          : AppColors.brandFill,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      request.driverTimedOut
                          ? AppLocalizations.of(context)!
                                .brokerDriverRequestsTimedOut
                          : AppLocalizations.of(context)!.live,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: request.driverTimedOut
                            ? AppColors.warningText
                            : AppColors.accentBlue,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteRow(
            label: AppLocalizations.of(context)!.brokerDriverReqPickup,
            value: request.pickup.isNotEmpty ? request.pickup : 'Pickup',
            icon: AppIcons.radio_button_checked_rounded,
            color: AppColors.brand,
          ),
          const SizedBox(height: 10),
          _RouteRow(
            label: AppLocalizations.of(context)!.brokerDriverReqDrop,
            value: request.drop.isNotEmpty ? request.drop : 'Drop',
            icon: AppIcons.location_on_rounded,
            color: AppColors.dangerIcon,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.fillSubtle,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: AppColors.brandFill,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.local_shipping_rounded,
                    color: AppColors.accentBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.driverName.isNotEmpty
                            ? request.driverName
                            : 'Driver',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (request.truckType.isNotEmpty) request.truckType,
                          if (request.truckReg.isNotEmpty) request.truckReg,
                          if (request.weight.isNotEmpty) request.weight,
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (waitingOnClient) ...[
            _WaitingBadge(
              label: AppLocalizations.of(context)!.brokerDriverReqAcceptedWaitingForTheClientToConfirm,
            ),
          ] else if (yourTurn) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqConfirm,
                    icon: AppIcons.check_circle_rounded,
                    color: AppColors.brand,
                    backgroundColor: AppColors.brandFill,
                    onPressed: canAct ? onAccept : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqDecline,
                    icon: AppIcons.cancel_rounded,
                    color: AppColors.dangerIcon,
                    backgroundColor: const Color(0xFFFDECEC),
                    onPressed: canAct ? onDecline : null,
                  ),
                ),
              ],
            ),
          ] else if (brokerAssigned) ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqAccept,
                    icon: AppIcons.check_circle_rounded,
                    color: AppColors.brand,
                    backgroundColor: AppColors.brandFill,
                    onPressed: canAct ? onAccept : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqDecline,
                    icon: AppIcons.cancel_rounded,
                    color: AppColors.dangerIcon,
                    backgroundColor: const Color(0xFFFDECEC),
                    onPressed: canAct ? onDecline : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.brokerDriverReqAlreadyAgreedWithTheBrokerAcceptOr,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqAccept,
                    icon: AppIcons.check_circle_rounded,
                    color: AppColors.brand,
                    backgroundColor: AppColors.brandFill,
                    onPressed: canAct ? onAccept : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqChangeFare,
                    icon: AppIcons.payments_rounded,
                    color: AppColors.accentBlue,
                    backgroundColor: AppColors.brandFill,
                    onPressed: canCounter ? onCounter : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionButton(
                    label: AppLocalizations.of(context)!.brokerDriverReqDecline,
                    icon: AppIcons.cancel_rounded,
                    color: AppColors.dangerIcon,
                    backgroundColor: const Color(0xFFFDECEC),
                    onPressed: canAct ? onDecline : null,
                  ),
                ),
              ],
            ),
          ],
          if (request.driverTimedOut) ...[
            const SizedBox(height: 10),
            Text(
              AppLocalizations.of(context)!.brokerDriverReqDriverTimedOutBrokerTakeoverActive,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.warningText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WaitingBadge extends StatelessWidget {
  const _WaitingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brandFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC7DAFF)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.accentBlue,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BrokerAssignedBadge extends StatelessWidget {
  _BrokerAssignedBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.brandFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: Text(
        l10n.brokerDriverReqBrokerAssigned,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.brand,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: 46,
      child: FilledButton.tonal(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: color,
          disabledBackgroundColor: AppColors.fillSubtle,
          disabledForegroundColor: AppColors.textTertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerCounterSheet extends StatefulWidget {
  const _BrokerCounterSheet({required this.request});

  final BrokerDriverRequest request;

  @override
  State<_BrokerCounterSheet> createState() => _BrokerCounterSheetState();
}

class _BrokerCounterSheetState extends State<_BrokerCounterSheet> {
  late double _value;

  @override
  void initState() {
    super.initState();
    final base = (widget.request.amount > 0 ? widget.request.amount : 1000)
        .toDouble();
    _value = base;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final base = (widget.request.amount > 0 ? widget.request.amount : 1000)
        .toDouble();
    final min = math.max(1.0, base * 0.75);
    final max = math.max(min + 1.0, base * 1.25);
    final clamped = _value.clamp(min, max).toDouble();
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        // viewPadding keeps buttons above system nav + floating BrokerBottomBar area,
        // viewInsets keeps them above the keyboard.
        bottom: media.viewInsets.bottom + media.viewPadding.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.brokerDriverReqChangeFare2,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              widget.request.bookingNumber.isNotEmpty
                  ? widget.request.bookingNumber
                  : widget.request.bookingId,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.fillSubtle,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.brokerDriverReqSetFareAmount,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '₹${clamped.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: AppColors.accentBlue,
                    ),
                  ),
                  Slider(
                    value: clamped,
                    min: min,
                    max: max,
                    divisions: 100,
                    activeColor: AppColors.accentBlue,
                    onChanged: (value) {
                      setState(() => _value = value);
                    },
                  ),
                  Row(
                    children: [
                      Text(
                        '₹${min.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${max.toStringAsFixed(0)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(AppLocalizations.of(context)!.brokerDriverReqCancel),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(clamped),
                    child: Text(
                      AppLocalizations.of(context)!.brokerDriverReqChangeFare,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}