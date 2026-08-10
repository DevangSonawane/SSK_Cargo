import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  String get _routeText {
    final shipment = _shipment;
    if (shipment != null) {
      return '${shipment.fromLocation} → ${shipment.toLocation}';
    }
    final settlement = widget.initialSettlement;
    if (settlement != null && settlement.route.isNotEmpty) {
      return settlement.route;
    }
    return 'Route unavailable';
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

    final toController = TextEditingController(text: session.user.email);
    final subjectController = TextEditingController(
      text: 'Invoice for booking $_displayBookingRef',
    );
    final messageController = TextEditingController(
      text: 'Please find attached the invoice for booking $_displayBookingRef.',
    );

    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Email invoice'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: toController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'To',
                      hintText: 'recipient@example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subjectController,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Message'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );

      if (shouldSend != true) return;

      setState(() => _emailing = true);
      await ref
          .read(apiClientProvider)
          .emailBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: bookingId,
            to: toController.text.trim(),
            subject: subjectController.text.trim(),
            message: messageController.text.trim(),
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
      toController.dispose();
      subjectController.dispose();
      messageController.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null && _shipment == null
              ? _ErrorState(message: _error!, onRetry: _loadDetails)
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderBar(
                        bookingRef: _displayBookingRef,
                        status: _statusLabel,
                        onBack: () => context.pop(),
                      ),
                      const SizedBox(height: 16),
                      _RouteHeader(routeText: _routeText),
                      const SizedBox(height: 16),
                      _ActionRow(
                        onDownload: _downloading ? null : _downloadInvoice,
                        onEmail: _emailing ? null : _emailInvoice,
                        onShare: _sharing ? null : _shareViaWhatsApp,
                        onNotify: _notifying ? null : _notifyClient,
                        downloading: _downloading,
                        emailing: _emailing,
                        sharing: _sharing,
                        notifying: _notifying,
                      ),
                      const SizedBox(height: 16),
                      _MapPanel(shipment: _shipment),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Trip Details',
                        child: Column(
                          children: [
                            _DetailRow(
                              icon: Icons.local_shipping_outlined,
                              label: 'Truck',
                              value: _truckValue,
                            ),
                            _DetailRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Broker',
                              value: _brokerValue,
                            ),
                            _DetailRow(
                              icon: Icons.phone_outlined,
                              label: 'Broker Phone',
                              value: _brokerPhoneValue,
                            ),
                            _DetailRow(
                              icon: Icons.calendar_month_outlined,
                              label: 'Date',
                              value: _dateValue,
                            ),
                            _DetailRow(
                              icon: Icons.route_outlined,
                              label: 'Distance',
                              value: _distanceValue,
                            ),
                            _DetailRow(
                              icon: Icons.schedule_outlined,
                              label: 'Time Taken',
                              value: _timeTakenValue,
                            ),
                            _DetailRow(
                              icon: Icons.inventory_2_outlined,
                              label: 'Cargo',
                              value: _cargoValue,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        title: 'Earnings',
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final tileWidth = constraints.maxWidth >= 600
                                ? (constraints.maxWidth - 12) / 2
                                : constraints.maxWidth;
                            return Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                SizedBox(
                                  width: tileWidth,
                                  child: _MetricTile(
                                    label: 'Earnings',
                                    value: _earningsValue,
                                    accent: const Color(0xFF2FA56E),
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _MetricTile(
                                    label: 'Payment Status',
                                    value: _paymentStatusValue,
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _MetricTile(
                                    label: 'Started',
                                    value: _startedValue,
                                  ),
                                ),
                                SizedBox(
                                  width: tileWidth,
                                  child: _MetricTile(
                                    label: 'Delivered',
                                    value: _deliveredValue,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  String get _truckValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final settlementTruck = widget.initialSettlement?.truck ?? '';
    return _readFirstNonEmpty([
      _readString(booking, const [
        'truckReg',
        'truck_reg',
        'truckNumber',
        'truck_number',
        'vehicle_number',
        'number_plate',
        'reg_no',
      ]),
      settlementTruck,
      _shipment?.assignedTruckName ?? '',
    ]);
  }

  String get _brokerValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    return _readFirstNonEmpty([
      _readString(booking, const ['brokerName', 'broker_name']),
      _readNestedName(_mapFrom(booking['broker']), const [
        'name',
        'full_name',
        'display_name',
      ]),
      _readNestedName(_mapFrom(booking['brokerUser']), const [
        'name',
        'full_name',
        'display_name',
      ]),
      widget.initialSettlement?.driver ?? '',
    ]);
  }

  String get _brokerPhoneValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    return _readFirstNonEmpty([
      _readString(booking, const ['brokerPhone', 'broker_phone']),
      _readString(_mapFrom(booking['broker']), const ['phone', 'mobile']),
      _readString(_mapFrom(booking['brokerUser']), const ['phone', 'mobile']),
      '—',
    ]);
  }

  String get _dateValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final value = _readDateTime(booking, const [
      'startedAt',
      'started_at',
      'completedAt',
      'completed_at',
      'deliveredAt',
      'delivered_at',
      'createdAt',
      'created_at',
    ]);
    return value == null ? '—' : _formatDate(value);
  }

  String get _distanceValue {
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

  String get _timeTakenValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final minutes = _readInt(booking, const [
      'timeTakenMinutes',
      'time_taken_minutes',
      'duration_minutes',
      'durationMinutes',
    ]);
    return minutes == null ? '—' : _formatDuration(minutes);
  }

  String get _cargoValue {
    final booking = _booking;
    if (booking == null) return '—';
    final title = booking.displayTitle.isNotEmpty ? booking.displayTitle : '—';
    final weight = booking.weight.isNotEmpty ? booking.weight : '—';
    return '$title · ${_normalizeWeight(weight)}';
  }

  String get _earningsValue {
    final amount =
        _shipment?.amount ??
        widget.initialSettlement?.netEarnings ??
        widget.initialSettlement?.amount ??
        0;
    return 'Rs ${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  String get _paymentStatusValue {
    final booking = _booking;
    if (booking != null) {
      final raw = _readString(booking.raw, const [
        'payment_status',
        'paymentStatus',
      ]);
      if (raw.isNotEmpty) {
        return formatPaymentStatus(raw);
      }
    }
    return widget.initialSettlement != null
        ? _titleCase(widget.initialSettlement!.status)
        : (_shipment?.paymentStatus.isNotEmpty == true
              ? formatPaymentStatus(_shipment!.paymentStatus)
              : '—');
  }

  String get _startedValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final value = _readDateTime(booking, const ['startedAt', 'started_at']);
    return value == null ? '—' : _formatDate(value);
  }

  String get _deliveredValue {
    final booking = _booking?.raw ?? const <String, dynamic>{};
    final value = _readDateTime(booking, const [
      'deliveredAt',
      'delivered_at',
      'completedAt',
      'completed_at',
    ]);
    return value == null ? '—' : _formatDate(value);
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
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF101828),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          _StatusPill(status: status),
        ],
      ),
    );
  }
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.routeText});

  final String routeText;

  @override
  Widget build(BuildContext context) {
    return Text(
      routeText,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: const Color(0xFF101828),
        fontWeight: FontWeight.w900,
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
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionButton(
          label: downloading ? 'Downloading...' : 'Download Invoice',
          icon: Icons.download_rounded,
          onPressed: onDownload,
        ),
        _ActionButton(
          label: emailing ? 'Sending...' : 'Send by Email',
          icon: Icons.mail_outline_rounded,
          onPressed: onEmail,
        ),
        _ActionButton(
          label: sharing ? 'Preparing...' : 'Share via WhatsApp',
          icon: Icons.share_rounded,
          onPressed: onShare,
        ),
        _ActionButton(
          label: notifying ? 'Sending...' : 'Notify Client',
          icon: Icons.send_rounded,
          onPressed: onNotify,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.22),
        ),
        foregroundColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon, size: 16),
      label: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
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
        height: 270,
        child: shipment == null
            ? const Center(child: CircularProgressIndicator())
            : TrackingRouteMapView(shipment: shipment!),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

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
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          child,
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
          Icon(icon, size: 18, color: const Color(0xFF98A2B3)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF98A2B3),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w700,
                    height: 1.25,
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

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tileAccent = accent ?? const Color(0xFF667085);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECEFF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: tileAccent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
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

String _readNestedName(Map<String, dynamic> json, List<String> keys) {
  final direct = _readString(json, keys);
  if (direct.isNotEmpty) return direct;

  final nestedSources = <Map<String, dynamic>>[
    _mapFrom(json['user']),
    _mapFrom(json['broker']),
    _mapFrom(json['client']),
  ];
  for (final source in nestedSources) {
    final value = _readString(source, const [
      'name',
      'full_name',
      'display_name',
    ]);
    if (value.isNotEmpty) return value;
  }
  return '';
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
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

double _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
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

String _formatDuration(int minutes) {
  if (minutes < 0) return '—';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '${mins}m';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

String _normalizeWeight(String weight) {
  final trimmed = weight.trim();
  if (trimmed == '—' || trimmed.isEmpty) return '—';
  if (trimmed.toLowerCase().contains('ton')) return trimmed;
  final numeric = double.tryParse(trimmed);
  if (numeric != null) {
    return '${numeric.toStringAsFixed(numeric % 1 == 0 ? 0 : 2)} tons';
  }
  return '$trimmed tons';
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
