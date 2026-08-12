import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';

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
  bool _sharing = false;
  bool _notifying = false;
  String? _error;

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

        if (mounted) {
          setState(() {
            _booking = booking;
            _shipment = shipment;
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

  Future<void> _shareViaWhatsApp() async {
    if (_sharing) return;

    final bookingId = _bookingId;
    if (bookingId.isEmpty) return;

    final shipment = _shipment;
    final text =
        'Invoice for $_displayBookingRef (${shipment?.fromLocation ?? 'Pickup'} → ${shipment?.toLocation ?? 'Drop'}).';

    setState(() => _sharing = true);
    try {
      final uri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        _showSnack('Could not open WhatsApp on this device.');
      }
    } catch (error) {
      if (mounted) {
        _showSnack(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
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
      backgroundColor: const Color(0xFFF5F7FB),
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
                    color: const Color(0xFF2FA56E),
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
                                  onBack: () => context.pop(),
                                ),
                                const SizedBox(height: 16),
                                _RouteSummaryCard(
                                  pickup: shipment?.fromLocation ??
                                      'Pickup unavailable',
                                  drop: shipment?.toLocation ??
                                      'Drop unavailable',
                                  status: _statusLabel,
                                  truckImage: 'assets/driver/active_truck_driver.png',
                                ),
                                const SizedBox(height: 16),
                                _ActionRow(
                                  onDownload:
                                      _downloading ? null : _downloadInvoice,
                                  onEmail: _emailing ? null : _emailInvoice,
                                  onShare: _sharing ? null : _shareViaWhatsApp,
                                  onNotify: _notifying ? null : _notifyClient,
                                  downloading: _downloading,
                                  emailing: _emailing,
                                  sharing: _sharing,
                                  notifying: _notifying,
                                ),
                                const SizedBox(height: 16),
                                _MapPanel(shipment: shipment),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'Trip Details',
                                  accentColor: const Color(0xFF2FA56E),
                                  child: _TripDetailsGrid(
                                    bookingTime: _bookingTimeValue,
                                    expectedDelivery: _expectedDeliveryValue,
                                    deliveredOn: _deliveredOnValue,
                                    distanceTravelled: _distanceTravelledValue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _SectionCard(
                                  title: 'Earnings',
                                  accentColor: const Color(0xFF2FA56E),
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
      _shipment?.status.isNotEmpty == true ? _activeStatusLabel(_shipment!.status) : '',
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
              decoration: const InputDecoration(
                labelText: 'To',
                hintText: 'recipient@example.com',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(labelText: 'Subject'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 3,
              maxLines: 5,
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
        FilledButton(
          onPressed: _submit,
          child: const Text('Send'),
        ),
      ],
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.bookingRef,
    required this.status,
    required this.onBack,
  });

  final String bookingRef;
  final String status;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
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
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF101828),
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
                    color: const Color(0xFF98A2B3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bookingRef,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
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
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final truckWidth = constraints.maxWidth < 560
              ? constraints.maxWidth * 0.22
              : constraints.maxWidth * 0.28;

          final routeWidget = _PickupDropColumn(
            pickup: pickup,
            drop: drop,
          );

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
    required this.onShare,
    required this.onNotify,
    required this.downloading,
    required this.emailing,
    required this.sharing,
    required this.notifying,
  });

  final VoidCallback? onDownload;
  final VoidCallback? onEmail;
  final VoidCallback? onShare;
  final VoidCallback? onNotify;
  final bool downloading;
  final bool emailing;
  final bool sharing;
  final bool notifying;

  @override
  Widget build(BuildContext context) {
    final buttons = [
      _ActionButton(
        label: downloading ? 'Downloading...' : 'Invoice',
        svgIcon: _invoiceSvg,
        onPressed: onDownload,
      ),
      _ActionButton(
        label: emailing ? 'Sending...' : 'Email',
        svgIcon: _emailSvg,
        onPressed: onEmail,
      ),
      _ActionButton(
        label: sharing ? 'Preparing...' : 'WhatsApp',
        svgIcon: _whatsappSvg,
        onPressed: onShare,
      ),
      _ActionButton(
        label: notifying ? 'Sending...' : 'Notify',
        svgIcon: _notifySvg,
        onPressed: onNotify,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = (constraints.maxWidth - 10) / 2;
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: SizedBox(width: cellWidth, child: buttons[0])),
                const SizedBox(width: 10),
                Expanded(child: SizedBox(width: cellWidth, child: buttons[1])),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: SizedBox(width: cellWidth, child: buttons[2])),
                const SizedBox(width: 10),
                Expanded(child: SizedBox(width: cellWidth, child: buttons[3])),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.svgIcon,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? svgIcon;

  @override
  Widget build(BuildContext context) {
    final leading = svgIcon == null
        ? null
        : SvgPicture.string(
            svgIcon!,
            width: 16,
            height: 16,
            colorFilter: ColorFilter.mode(
              Theme.of(context).colorScheme.primary,
              BlendMode.srcIn,
            ),
          );

    return SizedBox(
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
          ),
          foregroundColor: Theme.of(context).colorScheme.primary,
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
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
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                  foregroundColor: const Color(0xFF101828),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.navigation_rounded, size: 14),
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
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
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
                  color: accentColor ?? const Color(0xFF2FA56E),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
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
                color: const Color(0xFF2FA56E),
                icon: Icons.arrow_upward_rounded,
              ),
              const SizedBox(height: 14),
              _LocationBlock(
                label: 'Drop',
                value: drop,
                color: const Color(0xFFF59E0B),
                icon: Icons.location_on_rounded,
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
                  color: const Color(0xFF101828),
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
  });

  final String bookingTime;
  final String expectedDelivery;
  final String deliveredOn;
  final String distanceTravelled;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tiles = [
          _DetailStatTile(
            icon: Icons.calendar_month_outlined,
            label: 'Booking Time',
            value: bookingTime,
            iconColor: const Color(0xFF2FA56E),
          ),
          _DetailStatTile(
            icon: Icons.access_time_rounded,
            label: 'Expected Delivery',
            value: expectedDelivery,
            iconColor: const Color(0xFF2FA56E),
          ),
          _DetailStatTile(
            icon: Icons.local_shipping_outlined,
            label: 'Delivered On',
            value: deliveredOn,
            iconColor: const Color(0xFF2FA56E),
          ),
          _DetailStatTile(
            icon: Icons.route_outlined,
            label: 'Distance Travelled',
            value: distanceTravelled,
            iconColor: const Color(0xFF2FA56E),
          ),
        ];

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: tiles[0]),
                const SizedBox(width: 12),
                Expanded(child: tiles[1]),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: tiles[2]),
                const SizedBox(width: 12),
                Expanded(child: tiles[3]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _DetailStatTile extends StatelessWidget {
  const _DetailStatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 102,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFECEFF3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF101828),
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningsPanel extends StatelessWidget {
  const _EarningsPanel({
    required this.earningsValue,
    required this.isPaid,
  });

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
            color: const Color(0xFFF8FAFD),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFECEFF3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Total Earnings',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                earningsValue,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF2FA56E),
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
              color: const Color(0xFFEAF8EF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF2FA56E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Paid to Driver',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  earningsValue,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2FA56E),
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
      'completed' ||
      'delivered' ||
      'paid' ||
      'settled' => const Color(0xFF2FA56E),
      'cancelled' ||
      'canceled' ||
      'declined' ||
      'rejected' ||
      'expired' => const Color(0xFFE23A4B),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF667085),
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
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 36,
              color: Color(0xFFE23A4B),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF101828),
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

const String _invoiceSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="currentColor" d="M6 3h9l5 5v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1z"/>
  <path fill="#fff" d="M15 3v5h5"/>
  <path fill="currentColor" d="M8 12h8v1.5H8zm0 3.5h8V17H8z"/>
</svg>
''';

const String _emailSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="currentColor" d="M4 5h16a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V6a1 1 0 0 1 1-1z"/>
  <path fill="#fff" d="m5 7 7 5 7-5v2l-7 5-7-5z"/>
</svg>
''';

const String _whatsappSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="#25D366" d="M12 2C6.48 2 2 6.34 2 11.69c0 1.92.58 3.71 1.57 5.22L2.5 22l5.3-1.03A10.2 10.2 0 0 0 12 21.38c5.52 0 10-4.34 10-9.69S17.52 2 12 2z"/>
  <path fill="#fff" d="M16.84 14.73c-.22-.11-1.29-.64-1.49-.72-.2-.08-.35-.11-.5.11-.15.22-.57.72-.7.87-.13.16-.26.18-.48.06-.22-.11-.93-.35-1.77-1.12-.65-.58-1.09-1.31-1.22-1.53-.13-.22-.01-.34.1-.45.1-.1.22-.26.33-.39.11-.13.15-.22.23-.37.08-.16.04-.3-.02-.42-.06-.11-.5-1.2-.68-1.63-.18-.42-.36-.36-.5-.37h-.43c-.15 0-.39.05-.59.26-.2.22-.76.74-.76 1.8 0 1.06.78 2.08.89 2.22.11.15 1.53 2.33 3.72 3.26.52.22.92.35 1.23.45.52.17.99.15 1.36.09.42-.06 1.29-.53 1.47-1.05.18-.52.18-.96.13-1.05-.05-.08-.2-.13-.42-.24z"/>
</svg>
''';

const String _notifySvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24">
  <path fill="currentColor" d="M12 3a6 6 0 0 0-6 6v3.1L4.7 14.4A1 1 0 0 0 5.6 16h12.8a1 1 0 0 0 .9-1.6L18 12.1V9a6 6 0 0 0-6-6z"/>
  <path fill="currentColor" d="M10 18a2 2 0 0 0 4 0z"/>
</svg>
''';


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
