import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/l10n/app_localizations.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../../../shared/data/trip_route_stop.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../widgets/broker_flow_widgets.dart';

final _historyBookingDetailProvider = FutureProvider.autoDispose
    .family<ClientBooking, String>((ref, bookingId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookingById(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      final data = _asMap(response['data']);
      final booking = _asMap(data['booking']).isNotEmpty
          ? _asMap(data['booking'])
          : _asMap(response['booking']);
      if (booking.isEmpty) {
        throw const ApiException('Job not found');
      }
      return ClientBooking.fromJson(booking);
    });

final _historyReassignmentProvider = FutureProvider.autoDispose
    .family<List<_ReassignmentEntry>, String>((ref, bookingId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) return const <_ReassignmentEntry>[];
      try {
        final response = await ref
            .watch(apiClientProvider)
            .getBookingReassignmentHistory(
              accessToken: session.tokens.accessToken,
              bookingId: bookingId,
            );
        final data = _asMap(response['data']);
        final items = data['history'] is List
            ? data['history'] as List
            : response['history'] is List
            ? response['history'] as List
            : const [];
        return items
            .map((item) => _ReassignmentEntry.fromJson(_asMap(item)))
            .toList();
      } catch (_) {
        return const <_ReassignmentEntry>[];
      }
    });

class BrokerHistoryDetailScreen extends ConsumerStatefulWidget {
  const BrokerHistoryDetailScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  final String bookingId;
  final ClientBooking? initialBooking;

  @override
  ConsumerState<BrokerHistoryDetailScreen> createState() =>
      _BrokerHistoryDetailScreenState();
}

class _BrokerHistoryDetailScreenState
    extends ConsumerState<BrokerHistoryDetailScreen> {
  static const MethodChannel _shareChannel = MethodChannel(
    'plugins.flutter.io/share',
  );
  static const _tripStatusOrder = [
    'confirmed',
    'en_route_pickup',
    'picked_up',
    'in_transit',
    'delivered',
    'completed',
  ];

  bool _deleting = false;
  bool _downloading = false;
  bool _emailing = false;
  bool _notifying = false;
  bool _collecting = false;

  // Take-over panel state (web `JobDetail.jsx` override parity).
  bool _takeoverOpen = false;
  bool _tripLoading = false;
  Map<String, dynamic>? _trip;
  String _forceStatus = '';
  int? _completingStopIndex;
  bool _applyingForce = false;

  StreamSubscription<Map<String, dynamic>>? _tripSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_connectTripSocket());
    });
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    super.dispose();
  }

  /// Live push when this job's trip status changes (web `useTripStatusSocket`
  /// parity) — silent refresh, no spinner.
  Future<void> _connectTripSocket() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) return;
    final sockets = ref.read(appSocketServiceProvider);
    await sockets.ensureConnected(accessToken: session.tokens.accessToken);
    if (!mounted) return;
    await _tripSubscription?.cancel();
    _tripSubscription = sockets.tripStatusStream.listen((payload) {
      if (!mounted) return;
      final bookingId = _payloadBookingId(payload);
      if (bookingId.isNotEmpty && bookingId == widget.bookingId) {
        unawaited(_refresh(silent: true));
      }
    });
  }

  String _payloadBookingId(Map<String, dynamic> payload) {
    for (final key in const ['bookingId', 'booking_id']) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  Future<void> _refresh({bool silent = false}) async {
    ref.invalidate(_historyBookingDetailProvider(widget.bookingId));
    ref.invalidate(_historyReassignmentProvider(widget.bookingId));
    try {
      await ref.read(_historyBookingDetailProvider(widget.bookingId).future);
    } catch (_) {
      // Error UI is handled by the provider watcher.
    }
    if (_trip != null && mounted) {
      await _loadTrip(silent: silent);
    }
  }

  Future<void> _deleteBooking(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _deleting) return;
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.removeFromMyList),
        content: Text(l10n.removeFromMyListDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerIcon,
            ),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await ref
          .read(apiClientProvider)
          .deleteBooking(
            accessToken: session.tokens.accessToken,
            id: booking.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.bookingRemovedFromList),
          backgroundColor: AppColors.brand,
        ),
      );
      context.go('/broker/history');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.dangerIcon : null,
      ),
    );
  }

  Future<void> _downloadInvoice(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _downloading) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _downloading = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: booking.id,
          );
      final bytes = response.data ?? const <int>[];
      if (bytes.isEmpty) {
        _snack(l10n.invoiceFileEmpty, error: true);
        return;
      }
      final refText = _bookingRef(booking).replaceFirst('#', '');
      final fileName =
          'invoice-${refText.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')}.pdf';
      String savedPath = '';
      try {
        savedPath =
            await _shareChannel.invokeMethod<String>('downloadFile', {
              'bytes': Uint8List.fromList(bytes),
              'fileName': fileName,
              'mimeType': 'application/pdf',
            }) ??
            '';
      } catch (_) {
        savedPath = '';
      }
      var sharedFallback = false;
      if (savedPath.isEmpty) {
        try {
          sharedFallback =
              await _shareChannel.invokeMethod<bool>('shareFile', {
                'bytes': Uint8List.fromList(bytes),
                'fileName': fileName,
                'mimeType': 'application/pdf',
                'subject': l10n.invoiceForBooking(refText),
              }) ??
              false;
        } catch (_) {
          sharedFallback = false;
        }
      }
      if (savedPath.isNotEmpty) {
        _snack(l10n.invoiceDownloadedTo(savedPath));
      } else if (sharedFallback) {
        _snack(l10n.invoiceReadyToSaveOrShare);
      } else {
        _snack(l10n.invoiceDownloadFailedTryAgain, error: true);
      }
    } on ApiException catch (error) {
      _snack(error.message, error: true);
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _emailInvoice(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _emailing) return;
    final l10n = AppLocalizations.of(context)!;
    final refText = booking.bookingNumber.isNotEmpty
        ? booking.bookingNumber
        : booking.id;
    final draft = await showDialog<_InvoiceEmailDraft>(
      context: context,
      builder: (dialogContext) => _InvoiceEmailDialog(
        initialTo: session.user.email ?? '',
        defaultSubject: l10n.invoiceForBooking(refText),
        defaultMessage: l10n.invoiceEmailDefaultMessage(refText),
      ),
    );
    if (draft == null || !mounted) return;
    setState(() => _emailing = true);
    try {
      await ref
          .read(apiClientProvider)
          .emailBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: booking.id,
            to: draft.to,
            subject: draft.subject,
            message: draft.message,
          );
      _snack(l10n.invoiceEmailedSuccessfully);
    } on ApiException catch (error) {
      _snack(error.message, error: true);
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _emailing = false);
    }
  }

  Future<void> _notifyClient(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _notifying) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _notifying = true);
    try {
      await ref
          .read(apiClientProvider)
          .notifyBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: booking.id,
          );
      _snack(l10n.clientNotifiedInvoiceShared);
    } on ApiException catch (error) {
      _snack(error.message, error: true);
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _notifying = false);
    }
  }

  Map<String, dynamic>? _tripFromResponse(Map<String, dynamic> response) {
    final data = _asMap(response['data']);
    final trip = _asMap(data['trip']);
    if (trip.isNotEmpty) return trip;
    if (data['id'] != null) return data;
    return null;
  }

  String _tripString(Map<String, dynamic>? trip, List<String> keys) {
    if (trip == null) return '';
    for (final key in keys) {
      final value = trip[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  Future<bool> _loadTrip({bool silent = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return false;
    if (!silent && mounted) setState(() => _tripLoading = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getTripForBooking(
            accessToken: session.tokens.accessToken,
            bookingId: widget.bookingId,
          );
      final trip = _tripFromResponse(response);
      if (!mounted) return trip != null;
      setState(() => _trip = trip);
      return trip != null;
    } on ApiException catch (error) {
      if (!silent) _snack(error.message, error: true);
      return false;
    } catch (_) {
      return false;
    } finally {
      if (!silent && mounted) setState(() => _tripLoading = false);
    }
  }

  Future<void> _toggleTakeover() async {
    final next = !_takeoverOpen;
    setState(() => _takeoverOpen = next);
    if (next && _trip == null && !_tripLoading) {
      await _loadTrip();
    }
  }

  List<String> _forwardStatuses() {
    final raw = _tripString(_trip, const ['status']).toLowerCase();
    final index = _tripStatusOrder.indexOf(raw);
    final forward = index == -1
        ? <String>[]
        : _tripStatusOrder.sublist(index + 1);
    return [...forward, 'cancelled'];
  }

  Future<void> _completeOverrideStop(int index) async {
    final trip = _trip;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (trip == null || session == null || _completingStopIndex != null) {
      return;
    }
    final tripId = _tripString(trip, const ['id']);
    if (tripId.isEmpty) return;
    setState(() => _completingStopIndex = index);
    try {
      final response = await ref
          .read(apiClientProvider)
          .completeTripStop(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            index: index,
          );
      final updated = _tripFromResponse(response);
      if (!mounted) return;
      if (updated != null) setState(() => _trip = updated);
      _snack(AppLocalizations.of(context)!.stopMarkedComplete);
    } on ApiException catch (error) {
      _snack(error.message, error: true);
    } finally {
      if (mounted) setState(() => _completingStopIndex = null);
    }
  }

  Future<void> _applyForceStatus() async {
    final trip = _trip;
    final session = ref.read(authSessionProvider).valueOrNull;
    final options = _forwardStatuses();
    final effective = _forceStatus.isNotEmpty
        ? _forceStatus
        : (options.isNotEmpty ? options.first : '');
    if (trip == null ||
        session == null ||
        effective.isEmpty ||
        _applyingForce) {
      return;
    }
    final tripId = _tripString(trip, const ['id']);
    if (tripId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.forceTripStatus),
        content: Text(
          AppLocalizations.of(context)!.forceTripStatusDescription(effective),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.warningText,
            ),
            child: Text(AppLocalizations.of(context)!.apply),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _applyingForce = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .updateTripStatus(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            status: effective,
          );
      final updated = _tripFromResponse(response);
      if (!mounted) return;
      if (updated != null) {
        setState(() {
          _trip = updated;
          _forceStatus = '';
        });
      }
      _snack(AppLocalizations.of(context)!.tripStatusUpdated);
      unawaited(_refresh(silent: true));
    } on ApiException catch (error) {
      _snack(error.message, error: true);
    } finally {
      if (mounted) setState(() => _applyingForce = false);
    }
  }

  Future<void> _collectPayment(String mode) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _collecting) return;
    final paymentRecordedMessage = AppLocalizations.of(
      context,
    )!.paymentRecorded;
    setState(() => _collecting = true);
    try {
      final tripResponse = await ref
          .read(apiClientProvider)
          .getTripForBooking(
            accessToken: session.tokens.accessToken,
            bookingId: widget.bookingId,
          );
      final trip = _tripFromResponse(tripResponse);
      final tripId = _tripString(trip, const ['id']);
      if (tripId.isEmpty) throw const ApiException('Trip not found');
      await ref
          .read(apiClientProvider)
          .collectTripPayment(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            mode: mode,
          );
      _snack(paymentRecordedMessage);
      unawaited(_refresh(silent: true));
    } on ApiException catch (error) {
      _snack(error.message, error: true);
    } finally {
      if (mounted) setState(() => _collecting = false);
    }
  }

  Future<void> _openCompletion() async {
    // On-behalf completion runs through the same guarded take-over actions:
    // load the trip and open the panel so the broker finishes it there.
    final loaded = await _loadTrip();
    if (!mounted) return;
    if (!loaded) {
      _snack(AppLocalizations.of(context)!.tripNotFound, error: true);
      return;
    }
    setState(() => _takeoverOpen = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bookingAsync = ref.watch(
      _historyBookingDetailProvider(widget.bookingId),
    );
    final fallback = widget.initialBooking;
    final booking = bookingAsync.valueOrNull ?? fallback;
    final reassignments =
        ref.watch(_historyReassignmentProvider(widget.bookingId)).valueOrNull ??
        const <_ReassignmentEntry>[];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              _DetailBackRow(onBack: () => context.go('/broker/history')),
              const SizedBox(height: 14),
              bookingAsync.when(
                loading: () => booking == null
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildContent(context, booking, reassignments),
                error: (error, _) => booking == null
                    ? _DetailEmptyState(
                        title: l10n.couldNotLoadJobDetails,
                        subtitle: error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        onRetry: _refresh,
                      )
                    : _buildContent(context, booking, reassignments),
                data: (loaded) => _buildContent(context, loaded, reassignments),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClientBooking booking,
    List<_ReassignmentEntry> reassignments,
  ) {
    final shipment = trackingShipmentFromBooking(booking);
    final statusColor = _statusKey(booking.status) == 'completed'
        ? AppColors.brandInk
        : AppColors.dangerIcon;
    final amount = _amount(booking);
    final fee = _platformFee(booking);
    final statusKey = _statusKey(booking.status);
    final showTakeover = !const {
      'delivered',
      'completed',
      'cancelled',
    }.contains(statusKey);
    final extraStops = booking.stops.where((s) => s.isExtraStop).toList();
    final session = ref.read(authSessionProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailTopCard(
          booking: booking,
          statusColor: statusColor,
          onChat: () => context.push('/broker/chats/${booking.id}'),
          onDownloadInvoice: () => _downloadInvoice(booking),
          downloading: _downloading,
          onEmailInvoice: () => _emailInvoice(booking),
          emailing: _emailing,
          onNotifyClient: () => _notifyClient(booking),
          notifying: _notifying,
          onDelete: () => _deleteBooking(booking),
          deleting: _deleting,
          showCompleteDelivery: statusKey == 'delivered',
          onCompleteDelivery: _openCompletion,
        ),
        const SizedBox(height: 14),
        Container(
          height: 310,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: TrackingRouteMapView(shipment: shipment, liveMode: true),
        ),
        const SizedBox(height: 14),
        _DetailInfoCard(booking: booking),
        if (showTakeover) ...[
          const SizedBox(height: 14),
          _TakeoverCard(
            open: _takeoverOpen,
            loadingTrip: _tripLoading,
            trip: _trip,
            forceStatus: _forceStatus,
            forwardStatuses: _forwardStatuses(),
            completingStopIndex: _completingStopIndex,
            applyingForce: _applyingForce,
            onToggle: _toggleTakeover,
            onForceStatusChanged: (value) =>
                setState(() => _forceStatus = value ?? ''),
            onCompleteStop: _completeOverrideStop,
            onApplyForceStatus: _applyForceStatus,
          ),
        ],
        if (extraStops.isNotEmpty) ...[
          const SizedBox(height: 14),
          _StopsCard(stops: extraStops),
        ],
        const SizedBox(height: 14),
        _PaymentCard(
          booking: booking,
          amount: amount,
          fee: fee,
          collecting: _collecting,
          onCollect: _collectPayment,
        ),
        if (shipment.podMedia.isNotEmpty) ...[
          const SizedBox(height: 14),
          _BrokerPodCard(
            shipment: shipment,
            accessToken: session?.tokens.accessToken,
          ),
        ],
        if (reassignments.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ReassignmentCard(entries: reassignments),
        ],
      ],
    );
  }
}

class _DetailBackRow extends StatelessWidget {
  const _DetailBackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BrokerBackButton(onTap: onBack);
  }
}

class _DetailTopCard extends StatelessWidget {
  const _DetailTopCard({
    required this.booking,
    required this.statusColor,
    required this.onChat,
    required this.onDownloadInvoice,
    required this.downloading,
    required this.onEmailInvoice,
    required this.emailing,
    required this.onNotifyClient,
    required this.notifying,
    required this.onDelete,
    required this.deleting,
    required this.showCompleteDelivery,
    required this.onCompleteDelivery,
  });

  final ClientBooking booking;
  final Color statusColor;
  final VoidCallback onChat;
  final VoidCallback onDownloadInvoice;
  final bool downloading;
  final VoidCallback onEmailInvoice;
  final bool emailing;
  final VoidCallback onNotifyClient;
  final bool notifying;
  final VoidCallback onDelete;
  final bool deleting;
  final bool showCompleteDelivery;
  final VoidCallback onCompleteDelivery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 7,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                _bookingRef(booking),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                ),
              ),
              _DetailPill(
                label: bookingStatusDisplay(
                  AppLocalizations.of(context)!,
                  booking.displayStatusLabel,
                ),
                color: statusColor,
              ),
              if (booking.isExpress) const ExpressBadge(compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.routeTo(
              _lead(booking.pickupLocation, l10n),
              _lead(booking.dropoffLocation, l10n),
            ),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
          if (showCompleteDelivery) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCompleteDelivery,
                icon: const Icon(
                  AppIcons.assignment_turned_in_rounded,
                  size: 17,
                ),
                label: Text(l10n.completeDelivery),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WrapAction(
                icon: AppIcons.chat_bubble_outline_rounded,
                label: l10n.chat,
                onTap: onChat,
              ),
              _WrapAction(
                icon: AppIcons.download_rounded,
                label: downloading ? l10n.saving : l10n.invoice,
                onTap: downloading ? null : onDownloadInvoice,
              ),
              _WrapAction(
                icon: AppIcons.mail_outline_rounded,
                label: emailing ? l10n.sending : l10n.emailAction,
                onTap: emailing ? null : onEmailInvoice,
              ),
              _WrapAction(
                icon: AppIcons.send_rounded,
                label: notifying ? l10n.sending : l10n.notify,
                onTap: notifying ? null : onNotifyClient,
              ),
              _WrapAction(
                icon: AppIcons.delete_outline_rounded,
                label: deleting ? l10n.removing : l10n.remove,
                color: AppColors.dangerIcon,
                onTap: deleting ? null : onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WrapAction extends StatelessWidget {
  const _WrapAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.brand,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: color.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({required this.booking});

  final ClientBooking booking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DetailSection(
      title: l10n.jobDetails,
      children: [
        _DetailRow(
          icon: AppIcons.local_shipping_rounded,
          label: l10n.truck,
          value: _truckReg(booking).isEmpty ? '-' : _truckReg(booking),
        ),
        _DetailRow(
          icon: AppIcons.person_rounded,
          label: l10n.driver,
          value: _driverName(booking).isEmpty ? '-' : _driverName(booking),
        ),
        _DetailRow(
          icon: AppIcons.calendar_today_rounded,
          label: l10n.date,
          value: _formatDate(booking.requestedAt),
        ),
        _DetailRow(
          icon: AppIcons.route_rounded,
          label: l10n.distance,
          value: _distance(booking),
        ),
        _DetailRow(
          icon: AppIcons.inventory_2_rounded,
          label: l10n.cargo,
          value: _cargo(booking),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.booking,
    required this.amount,
    required this.fee,
    required this.collecting,
    required this.onCollect,
  });

  final ClientBooking booking;
  final double amount;
  final double fee;
  final bool collecting;
  final ValueChanged<String> onCollect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final paymentStatus = _paymentStatus(booking);
    final bookingStatus = _statusKey(booking.status);
    final showCollect =
        const {'pending', 'partial'}.contains(paymentStatus) &&
        !const {'requested', 'confirmed', 'cancelled'}.contains(bookingStatus);
    final haltingCharge = booking.haltingCharge;
    final slaCharge = booking.slaOverageCharge ?? 0;
    return _DetailSection(
      title: l10n.earningsPayment,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MoneyTile(
              label: l10n.amount,
              value: _formatRupees(amount),
              footnote: _overageFootnote(
                booking,
                haltingCharge,
                slaCharge,
                l10n,
              ),
            ),
            _MoneyTile(
              label: l10n.platformFee,
              value: _formatRupees(fee),
              color: AppColors.dangerIcon,
            ),
            _MoneyTile(
              label: l10n.netEarnings,
              value: _formatRupees(amount - fee),
              color: AppColors.brandInk,
              background: AppColors.brandFill,
            ),
            _MoneyTile(label: l10n.payment, value: _paymentStatus(booking)),
            _MoneyTile(label: l10n.mode, value: _paymentMode(booking, l10n)),
            _MoneyTile(label: l10n.timeTaken, value: _duration(booking)),
          ],
        ),
        if (showCollect) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: collecting ? null : () => onCollect('upi'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandInk,
                    side: const BorderSide(color: AppColors.successBorder),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: Text(collecting ? l10n.recording : 'UPI'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: collecting ? null : () => onCollect('cash'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                  child: Text(collecting ? l10n.recording : l10n.cash),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String? _overageFootnote(
  ClientBooking booking,
  double haltingCharge,
  double slaCharge,
  AppLocalizations l10n,
) {
  final parts = <String>[];
  if (haltingCharge > 0) {
    parts.add(
      l10n.includedHaltingCharge(
        booking.haltingHours.toString(),
        _formatRupees(haltingCharge),
      ),
    );
  }
  if (slaCharge > 0) {
    parts.add(
      l10n.includedDelayCharge(
        (booking.slaOverageHours ?? 0).toString(),
        _formatRupees(slaCharge),
      ),
    );
  }
  if (parts.isEmpty) return null;
  return parts.join('\n');
}

/// Driver-unreachable take-over panel (web `JobDetail.jsx` override parity):
/// complete loading/unloading stops and force the trip status forward, all
/// on the driver's behalf.
class _TakeoverCard extends StatelessWidget {
  const _TakeoverCard({
    required this.open,
    required this.loadingTrip,
    required this.trip,
    required this.forceStatus,
    required this.forwardStatuses,
    required this.completingStopIndex,
    required this.applyingForce,
    required this.onToggle,
    required this.onForceStatusChanged,
    required this.onCompleteStop,
    required this.onApplyForceStatus,
  });

  final bool open;
  final bool loadingTrip;
  final Map<String, dynamic>? trip;
  final String forceStatus;
  final List<String> forwardStatuses;
  final int? completingStopIndex;
  final bool applyingForce;
  final VoidCallback onToggle;
  final ValueChanged<String?> onForceStatusChanged;
  final ValueChanged<int> onCompleteStop;
  final VoidCallback onApplyForceStatus;

  List<TripRouteStop> get _stops {
    if (trip == null) return const [];
    return TripRouteStop.extraStopsFromJson(trip!['stops']);
  }

  String _statusLabel(String status) {
    final cleaned = status.trim().replaceAll(RegExp(r'[_-]+'), ' ');
    if (cleaned.isEmpty) return status;
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final effectiveForce = forceStatus.isNotEmpty
        ? forceStatus
        : (forwardStatuses.isNotEmpty ? forwardStatuses.first : '');
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    AppIcons.warning_amber_rounded,
                    color: AppColors.warningText,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.driverTakeoverTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    open ? l10n.hide : l10n.show,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      AppIcons.keyboard_arrow_down_rounded,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (open) ...[
            Container(height: 1, color: AppColors.line),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.driverTakeoverDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (loadingTrip)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (trip == null)
                    TextButton(
                      onPressed: onToggle,
                      child: Text(l10n.retryLoadingTrip),
                    )
                  else ...[
                    if (_stops.isNotEmpty) ...[
                      Text(
                        l10n.loadingUnloadingStops,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final stop in _stops)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: _TakeoverStopRow(
                            stop: stop,
                            actionable:
                                stop.index ==
                                TripRouteStop.nextActionableIndex(
                                  _stops,
                                  stop.type,
                                ),
                            busy: completingStopIndex == stop.index,
                            onComplete: () => onCompleteStop(stop.index),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      l10n.forceStatus,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: effectiveForce.isEmpty
                                ? null
                                : effectiveForce,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                            ),
                            items: [
                              for (final status in forwardStatuses)
                                DropdownMenuItem(
                                  value: status,
                                  child: Text(_statusLabel(status)),
                                ),
                            ],
                            onChanged: onForceStatusChanged,
                          ),
                        ),
                        const SizedBox(width: 10),
                        FilledButton(
                          onPressed: (effectiveForce.isEmpty || applyingForce)
                              ? null
                              : onApplyForceStatus,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.warningText,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                          ),
                          child: Text(
                            applyingForce ? l10n.applying : l10n.apply,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TakeoverStopRow extends StatelessWidget {
  const _TakeoverStopRow({
    required this.stop,
    required this.actionable,
    required this.busy,
    required this.onComplete,
  });

  final TripRouteStop stop;
  final bool actionable;
  final bool busy;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: stop.isDone ? AppColors.brandFill : AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            stop.isDone
                ? AppIcons.check_circle_rounded
                : stop.isLoading
                ? AppIcons.inventory_2_rounded
                : AppIcons.inventory_2_outlined,
            size: 16,
            color: stop.isDone ? AppColors.brandInk : AppColors.textTertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stop.location.isEmpty ? '—' : stop.location,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (stop.isDone)
            Text(
              l10n.done,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.brandInk,
              ),
            )
          else
            TextButton(
              onPressed: (!actionable || busy) ? null : onComplete,
              style: TextButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                busy
                    ? '...'
                    : stop.isLoading
                    ? l10n.markLoaded
                    : l10n.markUnloaded,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Read-only loading/unloading stops (web `JobDetail.jsx` parity).
class _StopsCard extends StatelessWidget {
  const _StopsCard({required this.stops});

  final List<TripRouteStop> stops;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DetailSection(
      title: l10n.loadingUnloadingStopsTitle,
      children: [
        for (final stop in stops)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: stop.isDone ? AppColors.brandFill : AppColors.fillSubtle,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    stop.isDone
                        ? AppIcons.check_circle_rounded
                        : AppIcons.radio_button_unchecked_rounded,
                    size: 16,
                    color: stop.isDone
                        ? AppColors.brandInk
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      stop.location.isEmpty ? '—' : stop.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    stop.isDone ? l10n.done : l10n.pending,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: stop.isDone
                          ? AppColors.brandInk
                          : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Read-only POD gallery with client-review badges (web `JobDetail.jsx`
/// parity — brokers review, never approve).
class _BrokerPodCard extends StatelessWidget {
  const _BrokerPodCard({required this.shipment, required this.accessToken});

  final TrackingDemoShipment shipment;
  final String? accessToken;

  String get _status => (shipment.podStatus ?? '').trim().toLowerCase();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DetailSection(
      title: l10n.proofOfDelivery,
      children: [
        if (_status == 'pending_verification')
          _PodBadge(
            label: l10n.awaitingClientReview,
            background: AppColors.warningFill,
            foreground: AppColors.warningText,
          ),
        if (_status == 'verified')
          _PodBadge(
            label: l10n.clientApproved,
            background: AppColors.brandFill,
            foreground: AppColors.brandInk,
          ),
        if (_status == 'rejected')
          _PodBadge(
            label: l10n.clientRejectedReuploading,
            background: AppColors.dangerFill,
            foreground: AppColors.dangerText,
          ),
        if (_status.isNotEmpty &&
            _status != 'pending_verification' &&
            _status != 'verified' &&
            _status != 'rejected')
          const SizedBox(height: 10),
        if (_status == 'pending_verification' ||
            _status == 'verified' ||
            _status == 'rejected')
          const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: shipment.podMedia.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            final media = shipment.podMedia[index];
            return InkWell(
              onTap: media.isVideo
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      builder: (dialogContext) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            media.url,
                            fit: BoxFit.contain,
                            headers: accessToken != null
                                ? {'Authorization': 'Bearer $accessToken'}
                                : null,
                          ),
                        ),
                      ),
                    ),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.fillSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.line),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: media.isVideo
                      ? const ColoredBox(
                          color: Color(0xFF111827),
                          child: Center(
                            child: Icon(
                              AppIcons.play_circle_fill_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        )
                      : Image.network(
                          media.url,
                          fit: BoxFit.cover,
                          headers: accessToken != null
                              ? {'Authorization': 'Bearer $accessToken'}
                              : null,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(
                              AppIcons.error_outline_rounded,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ),
                ),
              ),
            );
          },
        ),
        if (_status == 'rejected' &&
            (shipment.podRejectionReason ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            l10n.clientReason(shipment.podRejectionReason!.trim()),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}

class _PodBadge extends StatelessWidget {
  const _PodBadge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _InvoiceEmailDraft {
  const _InvoiceEmailDraft({
    required this.to,
    required this.subject,
    required this.message,
  });

  final String to;
  final String subject;
  final String message;
}

class _InvoiceEmailDialog extends StatefulWidget {
  const _InvoiceEmailDialog({
    required this.initialTo,
    required this.defaultSubject,
    required this.defaultMessage,
  });

  final String initialTo;
  final String defaultSubject;
  final String defaultMessage;

  @override
  State<_InvoiceEmailDialog> createState() => _InvoiceEmailDialogState();
}

class _InvoiceEmailDialogState extends State<_InvoiceEmailDialog> {
  late final TextEditingController _toController;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.initialTo);
    _subjectController = TextEditingController(text: widget.defaultSubject);
    _messageController = TextEditingController(text: widget.defaultMessage);
  }

  @override
  void dispose() {
    _toController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(l10n.sendInvoiceByEmail),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _toController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: l10n.to,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: l10n.subject,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: l10n.message,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            final to = _toController.text.trim();
            if (to.isEmpty) return;
            Navigator.of(context).pop(
              _InvoiceEmailDraft(
                to: to,
                subject: _subjectController.text.trim(),
                message: _messageController.text.trim(),
              ),
            );
          },
          child: Text(l10n.send),
        ),
      ],
    );
  }
}

class _ReassignmentCard extends StatelessWidget {
  const _ReassignmentCard({required this.entries});

  final List<_ReassignmentEntry> entries;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _DetailSection(
      title: l10n.reassignmentHistory,
      children: [
        for (final entry in entries) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.repeat_rounded,
                color: AppColors.brand,
                size: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.fromDriverName.isEmpty ? l10n.unassigned : entry.fromDriverName} → ${entry.toDriverName.isEmpty ? l10n.unknown : entry.toDriverName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (entry.reason.isNotEmpty)
                      Text(
                        entry.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Text(
                      l10n.reassignedBy(
                        entry.reassignedByName.isEmpty
                            ? '-'
                            : entry.reassignedByName,
                        _formatDate(entry.createdAt),
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry != entries.last) const Divider(height: 20),
        ],
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
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

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
    this.background = AppColors.fillSubtle,
    this.footnote,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (footnote != null && footnote!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              footnote!,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.warningText,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: Text(AppLocalizations.of(context)!.retry),
          ),
        ],
      ),
    );
  }
}

class _ReassignmentEntry {
  const _ReassignmentEntry({
    required this.id,
    required this.fromDriverName,
    required this.toDriverName,
    required this.reason,
    required this.reassignedByName,
    required this.createdAt,
  });

  factory _ReassignmentEntry.fromJson(Map<String, dynamic> json) {
    return _ReassignmentEntry(
      id: _readString(json, const ['id']),
      fromDriverName: _readString(json, const [
        'fromDriverName',
        'from_driver_name',
      ]),
      toDriverName: _readString(json, const ['toDriverName', 'to_driver_name']),
      reason: _readString(json, const ['reason']),
      reassignedByName: _readString(json, const [
        'reassignedByName',
        'reassigned_by_name',
      ]),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  final String id;
  final String fromDriverName;
  final String toDriverName;
  final String reason;
  final String reassignedByName;
  final DateTime? createdAt;
}

String _statusKey(String status) {
  return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _bookingRef(ClientBooking booking) {
  final ref = booking.bookingNumber.isNotEmpty
      ? booking.bookingNumber
      : (booking.bookingRef.isNotEmpty ? booking.bookingRef : booking.id);
  return '#${ref.toUpperCase()}';
}

String _lead(String value, AppLocalizations l10n) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return l10n.locationPending;
  final index = trimmed.indexOf(',');
  if (index <= 0) return trimmed;
  return trimmed.substring(0, index).trim();
}

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _duration(ClientBooking booking) {
  final minutes = _readDouble(booking.raw, const [
    'timeTakenMinutes',
    'time_taken_minutes',
  ]);
  if (minutes == null || minutes <= 0) return '-';
  final hours = minutes ~/ 60;
  final mins = minutes.round() % 60;
  if (hours <= 0) return '${mins}m';
  return '${hours}h ${mins}m';
}

String _distance(ClientBooking booking) {
  final distance = _readDouble(booking.raw, const [
    'distance',
    'route_distance',
  ]);
  if (distance == null || distance <= 0) return '-';
  return '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km';
}

String _cargo(ClientBooking booking) {
  final material = booking.material.isEmpty
      ? booking.packageName
      : booking.material;
  final weight = booking.weight;
  if (material.isEmpty && weight.isEmpty) return '-';
  if (material.isEmpty) return weight;
  if (weight.isEmpty) return material;
  return '$material · $weight';
}

double _amount(ClientBooking booking) {
  return _readDouble(booking.raw, const ['amount', 'price', 'fare', 'value']) ??
      _amountFromText(booking.amountText);
}

double _platformFee(ClientBooking booking) {
  return _readDouble(booking.raw, const [
        'platformFee',
        'platform_fee',
        'commission',
        'brokerage',
      ]) ??
      0;
}

String _truckReg(ClientBooking booking) {
  final truck = _asMap(booking.raw['truck']);
  return _firstNonEmpty([
    _readString(booking.raw, const ['truckReg', 'truck_reg', 'truckNumber']),
    _readString(truck, const ['registration', 'plate_number', 'plate']),
  ]);
}

String _driverName(ClientBooking booking) {
  final driver = _asMap(booking.raw['driver']);
  return _firstNonEmpty([
    _readString(booking.raw, const ['driverName', 'driver_name']),
    _readString(driver, const ['name', 'full_name', 'display_name']),
  ]);
}

String _paymentStatus(ClientBooking booking) {
  return _firstNonEmpty([
    _readString(booking.raw, const ['paymentStatus', 'payment_status']),
    'pending',
  ]).toLowerCase();
}

String _paymentMode(ClientBooking booking, AppLocalizations l10n) {
  final mode = _firstNonEmpty([
    _readString(booking.raw, const ['paymentMode', 'payment_mode']),
  ]).toLowerCase();
  switch (mode) {
    case 'upi':
      return 'UPI';
    case 'cash':
      return l10n.cash;
    case 'razorpay':
      return 'Razorpay';
    case 'fake':
      return l10n.online;
    case '':
      return '—';
    default:
      return mode[0].toUpperCase() + mode.substring(1);
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(
      value?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '',
    );
    if (parsed != null) return parsed;
  }
  return null;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

double _amountFromText(String value) {
  return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}

String _formatRupees(double amount) {
  final fixed = amount.round().toString();
  if (fixed.length <= 3) return '₹$fixed';
  final suffix = fixed.substring(fixed.length - 3);
  var prefix = fixed.substring(0, fixed.length - 3);
  final groups = <String>[];
  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }
  if (prefix.isNotEmpty) groups.insert(0, prefix);
  return '₹${groups.join(',')},$suffix';
}
