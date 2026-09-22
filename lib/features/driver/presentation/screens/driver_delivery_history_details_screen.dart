import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../../../shared/presentation/widgets/halting_timer_card.dart';

class DriverDeliveryHistoryDetailsScreen extends ConsumerStatefulWidget {
  const DriverDeliveryHistoryDetailsScreen({
    super.key,
    required this.bookingId,
    this.initialSettlement,
  });

  final String bookingId;
  final BrokerSettlement? initialSettlement;

  @override
  ConsumerState<DriverDeliveryHistoryDetailsScreen> createState() =>
      _DriverDeliveryHistoryDetailsScreenState();
}

class _DriverDeliveryHistoryDetailsScreenState
    extends ConsumerState<DriverDeliveryHistoryDetailsScreen> {
  ClientBooking? _booking;
  TrackingDemoShipment? _shipment;
  bool _loading = true;
  bool _downloading = false;
  bool _emailing = false;
  bool _notifying = false;
  String? _error;
  List<_ReassignmentHistoryEntry> _reassignmentHistory = const [];

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  String get _bookingId => widget.bookingId.isNotEmpty
      ? widget.bookingId
      : (widget.initialSettlement?.bookingId ?? '');

  String get _displayBookingRef {
    final booking = _booking;
    if (booking != null) {
      if (booking.bookingNumber.isNotEmpty) return booking.bookingNumber;
      if (booking.bookingRef.isNotEmpty) return booking.bookingRef;
      return _shortId(booking.id);
    }

    final settlement = widget.initialSettlement;
    if (settlement != null) {
      if (settlement.bookingNumber.isNotEmpty) return settlement.bookingNumber;
      if (settlement.bookingId.isNotEmpty) return settlement.bookingId;
    }

    return _shortId(_bookingId);
  }

  String get _statusLabel {
    final booking = _booking;
    if (booking != null) {
      return booking.displayStatusLabel;
    }
    return widget.initialSettlement?.status.isNotEmpty == true
        ? _titleCase(widget.initialSettlement!.status)
        : 'Completed';
  }

  Future<void> _loadDetails() async {
    final bookingId = _bookingId;
    final session = ref.read(authSessionProvider).valueOrNull;

    if (bookingId.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Missing booking id.';
        _shipment = widget.initialSettlement == null
            ? null
            : _shipmentFromSettlement(widget.initialSettlement!);
      });
      return;
    }

    if (session == null) {
      setState(() {
        _loading = false;
        _error = 'Please sign in again to view delivery details.';
        _shipment = widget.initialSettlement == null
            ? null
            : _shipmentFromSettlement(widget.initialSettlement!);
      });
      return;
    }

    try {
      final client = ref.read(apiClientProvider);
      final bookingResponse = await client.getBookingById(
        accessToken: session.tokens.accessToken,
        id: bookingId,
      );
      final bookingData = bookingResponse['data'];
      final bookingJson = bookingData is Map<String, dynamic>
          ? bookingData['booking']
          : null;
      if (bookingJson is Map<String, dynamic>) {
        final booking = ClientBooking.fromJson(bookingJson);
        var shipment = trackingShipmentFromBooking(booking);

        try {
          final trackResponse = await client.getBookingTrack(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
          final trackData = trackResponse['data'];
          if (trackData is Map<String, dynamic>) {
            shipment = shipment.copyWith(
              liveLat: _readDouble(trackData, const [
                'driverLat',
                'driver_lat',
              ]),
              liveLng: _readDouble(trackData, const [
                'driverLng',
                'driver_lng',
              ]),
            );
          }
        } catch (_) {
          // Keep the booking details even if the live-track lookup fails.
        }

        var reassignmentHistory = const <_ReassignmentHistoryEntry>[];
        try {
          final historyResponse = await client.getBookingReassignmentHistory(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );
          final historyData = historyResponse['data'];
          final rawHistory = historyData is Map<String, dynamic>
              ? historyData['history']
              : historyResponse['history'];
          if (rawHistory is Iterable) {
            reassignmentHistory = rawHistory
                .whereType<Map>()
                .map(
                  (item) => _ReassignmentHistoryEntry.fromJson(
                    item.cast<String, dynamic>(),
                  ),
                )
                .toList();
          }
        } catch (_) {
          reassignmentHistory = const <_ReassignmentHistoryEntry>[];
        }

        if (mounted) {
          setState(() {
            _booking = booking;
            _shipment = shipment;
            _reassignmentHistory = reassignmentHistory;
            _loading = false;
          });
        }
        return;
      }
    } catch (error) {
      if (widget.initialSettlement == null) {
        if (mounted) {
          setState(() {
            _error = error.toString().replaceFirst('Exception: ', '');
            _loading = false;
          });
        }
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      if (widget.initialSettlement != null) {
        _shipment = _shipmentFromSettlement(widget.initialSettlement!);
      } else {
        _error = 'Unable to load delivery details.';
      }
      _loading = false;
    });
  }

  TrackingDemoShipment _shipmentFromSettlement(BrokerSettlement settlement) {
    final route = _splitRoute(settlement.route);
    return TrackingDemoShipment(
      packageName: settlement.bookingNumber.isNotEmpty
          ? settlement.bookingNumber
          : 'Completed trip',
      trackingId: settlement.bookingNumber.isNotEmpty
          ? settlement.bookingNumber
          : (settlement.bookingId.isNotEmpty
                ? settlement.bookingId
                : _shortId(settlement.id)),
      fromLocation: route.from,
      toLocation: route.to,
      status: _titleCase(
        settlement.status.isEmpty ? 'completed' : settlement.status,
      ),
      customerName: '',
      weight: '—',
      timeline: const [],
      amount: settlement.netEarnings > 0
          ? settlement.netEarnings
          : settlement.amount,
      paymentStatus: formatPaymentStatus(settlement.status),
      bookingId: settlement.bookingId.isNotEmpty ? settlement.bookingId : null,
      bookingStatus: settlement.status,
    );
  }

  Future<void> _downloadInvoice() async {
    final bookingId = _bookingId;
    if (bookingId.isEmpty || _downloading) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _showSnack('Please sign in again to download the invoice.');
      return;
    }

    setState(() => _downloading = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      final bytes = response.data ?? const <int>[];
      if (!mounted) return;
      _showSnack(
        bytes.isEmpty
            ? 'Invoice downloaded successfully.'
            : 'Invoice downloaded (${bytes.length} bytes).',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(error.message);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _downloading = false);
      }
    }
  }

  Future<void> _emailInvoice() async {
    final bookingId = _bookingId;
    if (bookingId.isEmpty || _emailing) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _showSnack('Please sign in again to email the invoice.');
      return;
    }

    try {
      final draft = await showDialog<_EmailInvoiceDraft>(
        context: context,
        builder: (dialogContext) {
          return _EmailInvoiceDialog(
            initialTo: session.user.email ?? '',
            defaultSubject: 'Invoice for booking $_displayBookingRef',
            defaultMessage:
                'Please find attached the invoice for booking $_displayBookingRef.',
          );
        },
      );

      if (draft == null) return;

      setState(() => _emailing = true);
      await ref
          .read(apiClientProvider)
          .emailBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: bookingId,
            to: draft.to,
            subject: draft.subject,
            message: draft.message,
          );
      if (!mounted) return;
      _showSnack('Invoice emailed successfully.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(error.message);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _emailing = false);
      }
    }
  }

  Future<void> _notifyClient() async {
    final bookingId = _bookingId;
    if (bookingId.isEmpty || _notifying) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _showSnack('Please sign in again to notify the client.');
      return;
    }

    setState(() => _notifying = true);
    try {
      await ref
          .read(apiClientProvider)
          .notifyBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      if (!mounted) return;
      _showSnack('Client notified successfully.');
    } on ApiException catch (error) {
      if (!mounted) return;
      _showSnack(error.message);
    } catch (error) {
      if (!mounted) return;
      _showSnack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() => _notifying = false);
      }
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _shipment;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null && shipment == null
            ? Padding(
                padding: const EdgeInsets.all(14),
                child: _ErrorState(message: _error!, onRetry: _loadDetails),
              )
            : LayoutBuilder(
                builder: (context, constraints) {
                  final pagePadding = constraints.maxWidth >= 900 ? 24.0 : 14.0;
                  final maxWidth = constraints.maxWidth >= 1024
                      ? 960.0
                      : double.infinity;

                  return RefreshIndicator(
                    onRefresh: _loadDetails,
                    color: AppColors.brand,
                    backgroundColor: Colors.white,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxWidth),
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              pagePadding,
                              12,
                              pagePadding,
                              16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _HeaderBar(
                                  bookingRef: _displayBookingRef,
                                  status: _statusLabel,
                                  isExpress: shipment?.isExpress == true,
                                  onBack: () => context.pop(),
                                ),
                                const SizedBox(height: 16),
                                _RouteSummaryCard(
                                  pickup:
                                      shipment?.fromLocation ??
                                      'Pickup unavailable',
                                  drop:
                                      shipment?.toLocation ??
                                      'Drop unavailable',
                                  status: _statusLabel,
                                  truckImage:
                                      'assets/driver/active_truck_driver.png',
                                ),
                                const SizedBox(height: 16),
                                _ActionRow(
                                  onDownload: _downloading
                                      ? null
                                      : _downloadInvoice,
                                  onEmail: _emailing ? null : _emailInvoice,
                                  onNotify: _notifying ? null : _notifyClient,
                                  downloading: _downloading,
                                  emailing: _emailing,
                                  notifying: _notifying,
                                ),
                                const SizedBox(height: 16),
                                _MapPanel(shipment: shipment),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'Trip Details',
                                  accentColor: AppColors.brand,
                                  child: _TripDetailsGrid(
                                    bookingTime: _bookingTimeValue,
                                    expectedDelivery: _expectedDeliveryValue,
                                    deliveredOn: _deliveredOnValue,
                                    distanceTravelled: _distanceTravelledValue,
                                    sla: _slaSummary(shipment),
                                  ),
                                ),
                                if (shipment?.haltingGraceHours != null &&
                                    (shipment?.tripStartedAt != null ||
                                        (shipment?.haltingCharge ?? 0) >
                                            0)) ...[
                                  const SizedBox(height: 16),
                                  HaltingTimerCard(
                                    status:
                                        shipment?.bookingStatus ?? _statusLabel,
                                    startedAt: shipment?.tripStartedAt,
                                    haltingGraceHours:
                                        shipment?.haltingGraceHours,
                                    haltingHours: shipment?.haltingHours ?? 0,
                                    haltingCharge: shipment?.haltingCharge ?? 0,
                                    showNotStarted: false,
                                    tickInterval: const Duration(seconds: 60),
                                  ),
                                ],
                                if (_reassignmentHistory.isNotEmpty) ...[
                                  const SizedBox(height: 16),
                                  _ReassignmentHistoryPanel(
                                    history: _reassignmentHistory,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'Earnings',
                                  accentColor: AppColors.brand,
                                  child: _EarningsPanel(
                                    earningsValue: _earningsValue,
                                    isPaid: _isPaidStatusText(_statusLabel),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  String get _bookingTimeValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final value = _readDateTime(booking, const [
      'createdAt',
      'created_at',
      'requestedAt',
      'requested_at',
      'startedAt',
      'started_at',
    ]);
    return value == null ? '—' : _formatFullDateTime(value);
  }

  String get _expectedDeliveryValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final etaText = _readFirstNonEmpty([
      _readString(booking, const ['eta_text', 'eta', 'eta_minutes']),
      _shipment?.status.isNotEmpty == true
          ? _activeStatusLabel(_shipment!.status)
          : '',
    ]);
    return etaText == '—' ? '—' : etaText;
  }

  String get _deliveredOnValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final value = _readDateTime(booking, const [
      'deliveredAt',
      'delivered_at',
      'completedAt',
      'completed_at',
    ]);
    return value == null ? '—' : _formatFullDateTime(value);
  }

  String get _distanceTravelledValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final distance = _readDouble(booking, const [
      'distance',
      'distance_km',
      'distanceKm',
      'route_distance',
    ]);
    return distance > 0
        ? '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km'
        : '—';
  }

  /// Inline SLA summary folded into Trip Details (no separate card).
  /// Returns null when there is nothing meaningful to show.
  ({String text, bool alert})? _slaSummary(TrackingDemoShipment? shipment) {
    if (shipment == null) return null;
    if (shipment.slaOverageCharge > 0) {
      final charge = shipment.slaOverageCharge;
      final hours = shipment.slaOverageHours;
      return (
        text:
            'Delayed — ₹${charge.toStringAsFixed(charge % 1 == 0 ? 0 : 2)} charge for ${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h over expected time.',
        alert: true,
      );
    }
    final expected = shipment.expectedDeliveryHours;
    if (expected == null) return null;
    return (
      text:
          'On track — expected within ~${expected.toStringAsFixed(expected % 1 == 0 ? 0 : 1)}h${shipment.isExpress ? ' (Express)' : ''}.',
      alert: false,
    );
  }

  String get _earningsValue {
    final amount =
        _shipment?.amount ??
        widget.initialSettlement?.netEarnings ??
        widget.initialSettlement?.amount ??
        0;
    return 'Rs ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }
}

class _EmailInvoiceDraft {
  const _EmailInvoiceDraft({
    required this.to,
    required this.subject,
    required this.message,
  });

  final String to;
  final String subject;
  final String message;
}

class _EmailInvoiceDialog extends StatefulWidget {
  const _EmailInvoiceDialog({
    required this.initialTo,
    required this.defaultSubject,
    required this.defaultMessage,
  });

  final String initialTo;
  final String defaultSubject;
  final String defaultMessage;

  @override
  State<_EmailInvoiceDialog> createState() => _EmailInvoiceDialogState();
}

class _EmailInvoiceDialogState extends State<_EmailInvoiceDialog> {
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

  void _submit() {
    Navigator.of(context).pop(
      _EmailInvoiceDraft(
        to: _toController.text.trim(),
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Email invoice'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _toController,
              keyboardType: TextInputType.emailAddress,
              cursorColor: AppColors.brand,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'recipient@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              cursorColor: AppColors.brand,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 5,
              cursorColor: AppColors.brand,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(labelText: 'Message'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Send')),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.bookingRef,
    required this.status,
    required this.isExpress,
    required this.onBack,
  });

  final String bookingRef;
  final String status;
  final bool isExpress;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.fillSubtle,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.divider),
              ),
              child: const Icon(
                AppIcons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Booking ID',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bookingRef,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (isExpress) ...[
            const ExpressBadge(compact: true),
            const SizedBox(width: 8),
          ],
          _StatusPill(status: status),
        ],
      ),
    );
  }
}

class _RouteSummaryCard extends StatelessWidget {
  const _RouteSummaryCard({
    required this.pickup,
    required this.drop,
    required this.status,
    required this.truckImage,
  });

  final String pickup;
  final String drop;
  final String status;
  final String truckImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final truckWidth = constraints.maxWidth < 560
              ? constraints.maxWidth * 0.22
              : constraints.maxWidth * 0.28;

          final routeWidget = _PickupDropColumn(pickup: pickup, drop: drop);

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                routeWidget,
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset(
                    truckImage,
                    width: truckWidth.clamp(96.0, 130.0),
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: routeWidget),
              const SizedBox(width: 14),
              SizedBox(
                width: truckWidth.clamp(100.0, 180.0),
                child: Image.asset(truckImage, fit: BoxFit.contain),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.onDownload,
    required this.onEmail,
    required this.onNotify,
    required this.downloading,
    required this.emailing,
    required this.notifying,
  });

  final VoidCallback? onDownload;
  final VoidCallback? onEmail;
  final VoidCallback? onNotify;
  final bool downloading;
  final bool emailing;
  final bool notifying;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: downloading ? 'Saving...' : 'Invoice',
            icon: AppIcons.receipt_long_rounded,
            tint: AppColors.brandFill,
            border: AppColors.brandBorder,
            iconColor: AppColors.brandDark,
            onPressed: onDownload,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: emailing ? 'Sending...' : 'Email',
            icon: AppIcons.mail_rounded,
            tint: const Color(0xFFEFF6FF),
            border: const Color(0xFFD7E7F4),
            iconColor: AppColors.accentBlue,
            onPressed: onEmail,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: notifying ? 'Sending...' : 'Notify',
            icon: AppIcons.notifications_active_rounded,
            tint: AppColors.warningFill,
            border: AppColors.warningBorder,
            iconColor: AppColors.warningText,
            onPressed: onNotify,
          ),
        ),
      ],
    );
  }
}

class _ReassignmentHistoryEntry {
  const _ReassignmentHistoryEntry({
    required this.fromDriverName,
    required this.toDriverName,
    required this.reason,
    required this.reassignedByName,
    required this.createdAt,
  });

  factory _ReassignmentHistoryEntry.fromJson(Map<String, dynamic> json) {
    return _ReassignmentHistoryEntry(
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
      createdAt: _readDateTime(json, const ['createdAt', 'created_at']),
    );
  }

  final String fromDriverName;
  final String toDriverName;
  final String reason;
  final String reassignedByName;
  final DateTime? createdAt;
}

class _ReassignmentHistoryPanel extends StatelessWidget {
  const _ReassignmentHistoryPanel({required this.history});

  final List<_ReassignmentHistoryEntry> history;

  @override
  Widget build(BuildContext context) {
    final sorted = [...history]
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });

    return _SectionCard(
      title: 'Driver Changed (${history.length})',
      accentColor: AppColors.brand,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var index = 0; index < sorted.length; index++) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.divider),
              ),
            Text(
              '${sorted[index].fromDriverName.isEmpty ? 'Previous driver' : sorted[index].fromDriverName} -> ${sorted[index].toDriverName.isEmpty ? 'New driver' : sorted[index].toDriverName}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (sorted[index].reason.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                sorted[index].reason,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              [
                if (sorted[index].reassignedByName.isNotEmpty)
                  'By ${sorted[index].reassignedByName}',
                if (sorted[index].createdAt != null)
                  _formatFullDateTime(sorted[index].createdAt!),
              ].join(' • '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.tint,
    required this.border,
    required this.iconColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color border;
  final Color iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 76,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: border),
          foregroundColor: AppColors.textPrimary,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: border),
              ),
              child: Icon(icon, size: 15, color: iconColor),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.shipment});

  final TrackingDemoShipment? shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: SizedBox(
        height: 280,
        child: Stack(
          children: [
            Positioned.fill(
              child: shipment == null
                  ? const Center(child: CircularProgressIndicator())
                  : TrackingRouteMapView(shipment: shipment!),
            ),
            Positioned(
              left: 12,
              bottom: 12,
              child: FilledButton.tonalIcon(
                onPressed: shipment == null
                    ? null
                    : () async {
                        final pickup = shipment!.pickupLat;
                        final pickupLng = shipment!.pickupLng;
                        if (pickup == null || pickupLng == null) return;
                        final uri = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=$pickup,$pickupLng',
                        );
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      },
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(AppIcons.navigation_rounded, size: 14),
                label: Text(
                  'Open in Maps',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.accentColor,
  });

  final String title;
  final Widget child;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: accentColor ?? AppColors.brand,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _PickupDropColumn extends StatelessWidget {
  const _PickupDropColumn({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocationBlock(
                label: 'Pickup',
                value: pickup,
                color: AppColors.brand,
                icon: AppIcons.arrow_upward_rounded,
              ),
              const SizedBox(height: 14),
              _LocationBlock(
                label: 'Drop',
                value: drop,
                color: AppColors.warningText,
                icon: AppIcons.location_on_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LocationBlock extends StatelessWidget {
  const _LocationBlock({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 15, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
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

class _TripDetailsGrid extends StatelessWidget {
  const _TripDetailsGrid({
    required this.bookingTime,
    required this.expectedDelivery,
    required this.deliveredOn,
    required this.distanceTravelled,
    required this.sla,
  });

  final String bookingTime;
  final String expectedDelivery;
  final String deliveredOn;
  final String distanceTravelled;
  final ({String text, bool alert})? sla;

  @override
  Widget build(BuildContext context) {
    final rows = [
      _TripRowData(
        icon: AppIcons.calendar_month_outlined,
        tint: AppColors.brandFill,
        border: AppColors.brandBorder,
        iconColor: AppColors.brandDark,
        label: 'Booking time',
        value: bookingTime,
      ),
      _TripRowData(
        icon: AppIcons.access_time_rounded,
        tint: const Color(0xFFEFF6FF),
        border: const Color(0xFFD7E7F4),
        iconColor: AppColors.accentBlue,
        label: 'Expected delivery',
        value: expectedDelivery,
      ),
      _TripRowData(
        icon: AppIcons.local_shipping_outlined,
        tint: AppColors.brandFill,
        border: AppColors.brandBorder,
        iconColor: AppColors.brandDark,
        label: 'Delivered on',
        value: deliveredOn,
      ),
      _TripRowData(
        icon: AppIcons.route_outlined,
        tint: AppColors.warningFill,
        border: AppColors.warningBorder,
        iconColor: AppColors.warningText,
        label: 'Distance travelled',
        value: distanceTravelled,
      ),
    ];

    return Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Divider(height: 1, thickness: 1, color: AppColors.line),
            ),
          _TripRow(data: rows[i]),
        ],
        if (sla != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            decoration: BoxDecoration(
              color: sla!.alert
                  ? AppColors.warningFill
                  : AppColors.brandFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: sla!.alert
                    ? AppColors.warningBorder
                    : AppColors.brandBorder,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  sla!.alert
                      ? AppIcons.warning_amber_rounded
                      : AppIcons.schedule_rounded,
                  size: 18,
                  color: sla!.alert
                      ? AppColors.warningText
                      : AppColors.brandDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sla!.text,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: sla!.alert
                          ? AppColors.warningText
                          : AppColors.brandDark,
                      height: 1.45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TripRowData {
  const _TripRowData({
    required this.icon,
    required this.tint,
    required this.border,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color tint;
  final Color border;
  final Color iconColor;
  final String label;
  final String value;
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.data});

  final _TripRowData data;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: data.tint,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: data.border),
          ),
          child: Icon(data.icon, size: 19, color: data.iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EarningsPanel extends StatelessWidget {
  const _EarningsPanel({required this.earningsValue, required this.isPaid});

  final String earningsValue;
  final bool isPaid;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.fillSubtle,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.fillSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total Earnings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                earningsValue,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (isPaid) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(AppIcons.verified_rounded, color: AppColors.brand),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paid to Driver',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  earningsValue,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.trim().toLowerCase();
    final color = switch (normalized) {
      'completed' || 'delivered' || 'paid' || 'settled' => AppColors.brand,
      'cancelled' ||
      'canceled' ||
      'declined' ||
      'rejected' ||
      'expired' => AppColors.dangerText,
      'pending' => AppColors.warningText,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.error_outline_rounded,
              size: 36,
              color: AppColors.dangerIcon,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

({String from, String to}) _splitRoute(String route) {
  final normalized = route.trim();
  if (normalized.isEmpty) {
    return (from: 'Route unavailable', to: 'Route unavailable');
  }

  const separators = [' → ', ' -> ', ' to ', ' - '];
  for (final separator in separators) {
    final parts = normalized.split(separator);
    if (parts.length >= 2) {
      return (
        from: parts.first.trim(),
        to: parts.sublist(1).join(separator).trim(),
      );
    }
  }

  return (from: normalized, to: 'Route unavailable');
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

String _readFirstNonEmpty(List<String> values) {
  for (final value in values) {
    final normalized = value.trim();
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    }
  }
  return '—';
}

String _activeStatusLabel(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) return 'In Progress';
  if (normalized == 'delivered') return 'Delivered';
  if (normalized == 'completed') return 'Completed';
  if (normalized == 'cancelled' || normalized == 'canceled') return 'Cancelled';
  if (normalized == 'pending') return 'Pending';
  if (normalized == 'accepted' ||
      normalized == 'confirmed' ||
      normalized == 'en_route_pickup' ||
      normalized == 'en route' ||
      normalized == 'en_route' ||
      normalized == 'in_transit' ||
      normalized == 'in transit' ||
      normalized == 'picked_up' ||
      normalized == 'picked up' ||
      normalized == 'ongoing') {
    return 'In Progress';
  }
  return _titleCase(normalized);
}

bool _isPaidStatusText(String status) {
  final normalized = status.trim().toLowerCase();
  return normalized == 'paid' || normalized == 'settled';
}

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

DateTime? _readDateTime(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final raw = json[key];
    if (raw == null) continue;
    if (raw is DateTime) return raw;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _formatDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final month = months[local.month - 1];
  final day = local.day.toString().padLeft(2, '0');
  return '$day $month ${local.year}';
}

String _formatFullDateTime(DateTime dateTime) {
  final local = dateTime.toLocal();
  final date = _formatDate(local);
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$date, ${hour.toString().padLeft(2, '0')}:$minute $period';
}

String _shortId(String id) {
  final normalized = id.replaceAll('-', '').trim();
  if (normalized.isEmpty) return '-';
  final tail = normalized.length <= 8
      ? normalized
      : normalized.substring(normalized.length - 8);
  return '#${tail.toUpperCase()}';
}

String _titleCase(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) return '—';
  return normalized
      .split(RegExp(r'[\s_-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}
