// Driver/broker Part-Load inbox — standalone second inbox, duplicated (not
// reusing driver_requests screens). Shows only trip-join requests with
// plain Accept / Decline, no negotiation. For brokers the same endpoint
// returns timed-out rows (role read from token server-side).
//
// Cards mirror _DeliveryOrderCard exactly: surface, AppRadius.card,
// divider border, AppShadows.card, _RoutePointCard route rows,
// warning-fill handoff box, _BrokerAssignedActions-style buttons.
// Content mirrors web TripJoinRequestCard: Part-Load badge, weight + client
// tiles, phone footer, locked banner when the driver timed out (broker acts),
// 30s poll + socket like web Requests.jsx.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssk/core/theme/app_icons.dart';

import '../../core/services/app_socket_service.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/kyc_gate_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'part_load_api.dart';
import 'part_load_models.dart';
import 'part_load_providers.dart';

class PartLoadDriverInboxScreen extends StatelessWidget {
  const PartLoadDriverInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: const Text('Shared-load requests'),
      ),
      body: const SafeArea(
        child: PartLoadInboxList(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 96),
        ),
      ),
    );
  }
}

/// Content-only inbox list (no Scaffold) so it can be embedded — e.g. as
/// the second tab of the broker requests screen or driver home — as well as
/// standalone. Set [embedded] when placing inside another scroll view.
class PartLoadInboxList extends ConsumerStatefulWidget {
  const PartLoadInboxList({super.key, this.padding, this.embedded = false});

  final EdgeInsetsGeometry? padding;
  final bool embedded;

  @override
  ConsumerState<PartLoadInboxList> createState() => _PartLoadInboxListState();
}

class _PartLoadInboxListState extends ConsumerState<PartLoadInboxList> {
  String? _actingId;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _pollTimer;

  String get _token =>
      ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';

  bool get _isBroker =>
      (ref.read(authSessionProvider).valueOrNull?.user.role ?? '')
          .trim()
          .toLowerCase() == 'broker';

  @override
  void initState() {
    super.initState();
    _listenSocket();
    // Web parity (Requests.jsx POLL_INTERVAL_MS): 30s refresh.
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) ref.invalidate(partLoadInboxProvider);
    });
  }

  Future<void> _listenSocket() async {
    final token = _token;
    if (token.isEmpty) return;
    await ref.read(appSocketServiceProvider).ensureConnected(accessToken: token);
    _socketSub = ref
        .read(appSocketServiceProvider)
        .tripJoinRequestStream
        .listen((_) {
      if (mounted) ref.invalidate(partLoadInboxProvider);
    });
  }

  Future<void> _act(String requestId, bool accept) async {
    // App convention (driver home, broker requests): accepting needs a
    // verified KYC. Web gates the whole requests page; here we gate the
    // accept itself so the list stays visible while blocked.
    if (accept &&
        !await ensureKycVerifiedForAccept(
          context: context,
          ref: ref,
          role: _isBroker ? 'broker' : 'driver',
        )) {
      return;
    }
    // Web parity (driver + broker Requests.jsx): declining a part-load
    // request asks first — the client must find a different truck.
    if (!accept) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Decline this part-load request?'),
          content: const Text(
            'The client will need to look for a different truck. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.dangerText,
              ),
              child: const Text('Decline'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }
    setState(() => _actingId = requestId);
    try {
      final api = ref.read(partLoadApiProvider);
      if (accept) {
        await api.acceptRequest(accessToken: _token, requestId: requestId);
      } else {
        await api.declineRequest(accessToken: _token, requestId: requestId);
      }
      ref.invalidate(partLoadInboxProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? 'Load added to your current trip.'
                : 'Request declined.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
      ref.invalidate(partLoadInboxProvider);
    } finally {
      if (mounted) setState(() => _actingId = null);
    }
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inboxAsync = ref.watch(partLoadInboxProvider);
    final broker = _isBroker;
    return inboxAsync.when(
      loading: () => widget.embedded
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator()),
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: widget.padding ?? const EdgeInsets.all(20),
              children: const [
                Center(child: CircularProgressIndicator()),
              ],
            ),
      error: (error, _) => widget.embedded
          ? _PartLoadEmptyStateCard(
              icon: AppIcons.wifi_off_rounded,
              title: 'Could not load requests',
              subtitle: error.toString().replaceFirst('Exception: ', ''),
            )
          : RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(partLoadInboxProvider),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: widget.padding ?? const EdgeInsets.all(20),
                children: [
                  _PartLoadEmptyStateCard(
                    icon: AppIcons.wifi_off_rounded,
                    title: 'Could not load requests',
                    subtitle:
                        error.toString().replaceFirst('Exception: ', ''),
                  ),
                ],
              ),
            ),
      data: (allItems) {
        // Web parity (driver/broker Requests.jsx part-load tab renders
        // pendingJoinRequests only): old accepted/declined rows belong to
        // trip history, never this inbox — otherwise stale requests linger
        // on the home page forever.
        final items =
            allItems.where((r) => r.isPending).toList(growable: false);
        if (items.isEmpty) {
          final empty = _PartLoadEmptyStateCard(
            icon: AppIcons.inbox_rounded,
            title: 'No shared-load requests',
            subtitle:
                'New requests appear here instantly once a client picks your truck.',
          );
          if (widget.embedded) return empty;
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(partLoadInboxProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: widget.padding ?? const EdgeInsets.all(20),
              children: [empty],
            ),
          );
        }
        if (widget.embedded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _PartLoadRequestTile(
                  request: items[i],
                  isBroker: broker,
                  busy: _actingId == items[i].id,
                  onAccept: () => _act(items[i].id, true),
                  onDecline: () => _act(items[i].id, false),
                ),
              ],
            ],
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(partLoadInboxProvider),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: widget.padding ?? const EdgeInsets.all(20),
            itemCount: items.length,
            itemBuilder: (_, i) {
              final r = items[i];
              return Padding(
                padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 14),
                child: _PartLoadRequestTile(
                  request: r,
                  isBroker: broker,
                  busy: _actingId == r.id,
                  onAccept: () => _act(r.id, true),
                  onDecline: () => _act(r.id, false),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

/// Same sizing as driver _EmptyStateCard: padding 24, radius 22,
// 72 circle icon, w800 title + centered subtitle.
class _PartLoadEmptyStateCard extends StatelessWidget {
  const _PartLoadEmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.fillSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 34),
          ),
          const SizedBox(height: 14),
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
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
          ),
        ],
      ),
    );
  }
}

/// Same sizing as _DeliveryOrderCard: padding 18, AppRadius.card,
/// divider border, AppShadows.card, route point cards, warning box,
// broker-assigned style accept/decline buttons. Content mirrors web
/// TripJoinRequestCard: Part-Load badge, weight + client tiles, phone
/// footer, locked banner when the driver timed out (broker takes over).
class _PartLoadRequestTile extends StatelessWidget {
  const _PartLoadRequestTile({
    required this.request,
    required this.isBroker,
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final PartLoadJoinRequest request;
  final bool isBroker;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Web parity: a timed-out driver loses the action — their broker acts.
    // (TripJoinRequestCard `locked`.)
    final locked =
        !isBroker && request.isPending && request.driverTimedOut;
    final canAct = request.isPending && !locked;
    final refText = request.bookingNumber.isNotEmpty
        ? request.bookingNumber
        : request.bookingId;
    final dateLabel = _formatDate(request.createdAt);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          refText.isEmpty ? '—' : refText,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.inventory_2_rounded,
                                size: 10,
                                color: AppColors.brand,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Part-Load',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.brand,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 10,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_shortLocation(request.pickup)} → ${_shortLocation(request.drop)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    request.amount.isNotEmpty
                        ? '₹${request.amount}'
                        : '—',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  if (dateLabel.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                          ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          _PartLoadRoutePoint(
            label: l10n.pickup,
            value: request.pickup,
            accentColor: AppColors.brand,
          ),
          const SizedBox(height: 10),
          _PartLoadRoutePoint(
            label: l10n.drop,
            value: request.drop,
            accentColor: AppColors.dangerIcon,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PartLoadInfoTile(
                  icon: AppIcons.inventory_2_rounded,
                  label: 'Weight',
                  value: request.weight.isNotEmpty ? request.weight : '—',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PartLoadInfoTile(
                  icon: AppIcons.person_rounded,
                  label: 'Client',
                  value: request.clientName.isNotEmpty
                      ? request.clientName
                      : '—',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (locked) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.fillSubtle,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.divider),
              ),
              child: Text(
                "You didn't respond in time — your broker has taken over this request.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ] else if (canAct) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy ? null : onAccept,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(AppIcons.check_rounded, size: 17),
                    label: Text(busy ? l10n.saving : l10n.accept),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand,
                      foregroundColor: AppColors.textOnBrand,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onDecline,
                    icon: const Icon(AppIcons.close_rounded, size: 17),
                    label: Text(l10n.decline),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.dangerText,
                      side: const BorderSide(color: AppColors.dangerBorder),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (isBroker && request.driverTimedOut) ...[
              const SizedBox(height: 8),
              Text(
                "Driver timed out — you're responding on their behalf.",
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.warningText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ] else if (request.isAccepted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppColors.successFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Text(
                'Accepted — added to your current trip',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.successText,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ] else ...[
            Text(
              'Declined.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
          if (request.clientName.isNotEmpty ||
              request.clientPhone.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  AppIcons.call_rounded,
                  size: 12,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    request.clientPhone.isNotEmpty
                        ? '${request.clientName}: ${request.clientPhone}'
                        : request.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _shortLocation(String value) {
  final raw = value.trim();
  if (raw.isEmpty) return '—';
  for (final sep in const [' - ', ' | ', ', ']) {
    final index = raw.indexOf(sep);
    if (index > 0) return raw.substring(0, index).trim();
  }
  return raw;
}

String _formatDate(String raw) {
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return '';
  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

/// Weight / Client mini-tiles — same as web's slate-50 grid tiles:
/// fillSubtle, radius 16, icon + uppercase label, bold value.
class _PartLoadInfoTile extends StatelessWidget {
  const _PartLoadInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 11, color: AppColors.textTertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

/// Same sizing as driver _RoutePointCard: padding 12, radius 18,
// divider border, dot + label row, w800 value text.
class _PartLoadRoutePoint extends StatelessWidget {
  const _PartLoadRoutePoint({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasValue ? value.trim() : '—',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
          ),
        ],
      ),
    );
  }
}
