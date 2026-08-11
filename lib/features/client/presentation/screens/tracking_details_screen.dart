import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

// ignore_for_file: unused_element

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../widgets/client_flow_widgets.dart';
import '../widgets/tracking_route_map_view.dart';

class TrackingDetailsScreen extends ConsumerStatefulWidget {
  const TrackingDetailsScreen({super.key, required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  ConsumerState<TrackingDetailsScreen> createState() =>
      _TrackingDetailsScreenState();
}

class _TrackingDetailsScreenState extends ConsumerState<TrackingDetailsScreen> {
  static const Duration _refreshInterval = Duration(seconds: 6);

  TrackingDemoShipment? _resolvedShipment;
  bool _isLiveTracking = false;
  bool _isCancelling = false;
  bool _isBookingCancelled = false;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;

  void _setBottomNavVisible(bool visible) {
    ref.read(bottomNavVisibleProvider.notifier).state = visible;
  }

  void _openLiveTracking() {
    _setBottomNavVisible(false);
    setState(() => _isLiveTracking = true);
  }

  void _closeLiveTracking() {
    _setBottomNavVisible(true);
    setState(() => _isLiveTracking = false);
  }

  TrackingDemoShipment get _shipment => _resolvedShipment ?? widget.shipment;

  @override
  void initState() {
    super.initState();
    _resolvedShipment = widget.shipment;
    _refreshShipment();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startLiveShipmentUpdates();
      }
    });
  }

  double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _refreshShipment() async {
    final bookingId = widget.shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
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
      if (bookingJson is! Map<String, dynamic>) {
        return;
      }

      final booking = ClientBooking.fromJson(bookingJson);
      var nextShipment = trackingShipmentFromBooking(booking);

      try {
        final trackResponse = await client.getBookingTrack(
          accessToken: session.tokens.accessToken,
          id: bookingId,
        );
        final trackData = trackResponse['data'];
        if (trackData is Map<String, dynamic>) {
          nextShipment = nextShipment.copyWith(
            liveLat: _toDouble(trackData['driverLat']),
            liveLng: _toDouble(trackData['driverLng']),
          );
        }
      } catch (_) {
        // Best effort: booking details still render even if live tracking fails.
      }

      if (mounted) {
        setState(() {
          _resolvedShipment = nextShipment;
        });
      }
    } catch (_) {
      // Keep the originally supplied shipment if the live refresh fails.
    }
  }

  String _readPayloadString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) {
        continue;
      }
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _driverRequestSubscription?.cancel();
    _setBottomNavVisible(true);
    super.dispose();
  }

  Future<void> _startLiveShipmentUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );

    _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      final bookingId = _readPayloadString(payload, const [
        'bookingId',
        'booking_id',
      ]);
      if (bookingId.isNotEmpty && bookingId == widget.shipment.bookingId) {
        _refreshShipment();
      }
    });

    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _refreshShipment();
      }
    });
  }

  bool get _canCancelBooking {
    final status = _shipment.bookingStatus?.toLowerCase();
    return _shipment.bookingId != null &&
        !_isBookingCancelled &&
        (status == null ||
            const {
              'pending',
              'confirmed',
              'assigned',
              'en_route_pickup',
            }.contains(status));
  }

  Future<void> _cancelBooking() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || _isCancelling || !_canCancelBooking) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to cancel this booking.'),
        ),
      );
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final reason = await _promptCancellationReason();
      if (reason == null) {
        return;
      }
      await ref
          .read(apiClientProvider)
          .cancelBooking(
            accessToken: session.tokens.accessToken,
            id: bookingId,
            reason: reason,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
      setState(() {
        _isBookingCancelled = true;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<String?> _promptCancellationReason() async {
    final controller = TextEditingController();
    try {
      return await showDialog<String?>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              final reason = controller.text.trim();
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Cancel booking'),
                content: TextField(
                  controller: controller,
                  minLines: 3,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Reason',
                    hintText:
                        'Tell the driver and broker why you are cancelling',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(null),
                    child: const Text('Keep booking'),
                  ),
                  FilledButton(
                    onPressed: reason.isEmpty
                        ? null
                        : () => Navigator.of(dialogContext).pop(reason),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE23A4B),
                    ),
                    child: const Text('Cancel booking'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmCancelBooking() async {
    if (!_canCancelBooking || _isCancelling) {
      return;
    }

    await _cancelBooking();
  }

  Future<void> _openNegotiationSheet() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _BookingNegotiationSheet(
          bookingId: bookingId,
          accessToken: session.tokens.accessToken,
        );
      },
    );
  }

  Future<void> _openChatSheet() async {
    final bookingId = _shipment.bookingId;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (bookingId == null || bookingId.isEmpty || session == null) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ClientBookingChatSheet(
          bookingId: bookingId,
          accessToken: session.tokens.accessToken,
          currentUserId: session.user.id,
        );
      },
    );
  }

  Future<void> _payBooking() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final shouldPay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Record payment?'),
        content: const Text(
          'This will mark the booking as paid on the backend. Continue only if the payment has been collected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Pay now'),
          ),
        ],
      ),
    );

    if (shouldPay != true) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .payBooking(accessToken: session.tokens.accessToken, id: bookingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _downloadInvoice() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      final bytes = response.data ?? const <int>[];
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bytes.isEmpty
                ? 'Invoice downloaded.'
                : 'Invoice downloaded (${bytes.length} bytes).',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _emailInvoice() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final defaultEmail = session.user.email;
    final toController = TextEditingController(text: defaultEmail);
    final subjectController = TextEditingController(
      text: 'Invoice for booking ${_shipment.trackingId}',
    );
    final messageController = TextEditingController(
      text:
          'Please find attached the invoice for booking ${_shipment.trackingId}.',
    );

    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
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
        },
      );

      if (shouldSend != true) {
        return;
      }

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice emailed successfully.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      toController.dispose();
      subjectController.dispose();
      messageController.dispose();
    }
  }

  Future<void> _rateBooking() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final reviewController = TextEditingController();
    var stars = 5;

    try {
      final shouldSubmit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Rate booking'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return IconButton(
                          onPressed: () => setState(() => stars = rating),
                          icon: Icon(
                            rating <= stars
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: const Color(0xFFF5B301),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: reviewController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Review',
                        hintText: 'Tell us how the delivery went',
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(dialogContext).pop(true),
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (shouldSubmit != true) {
        return;
      }

      await ref
          .read(apiClientProvider)
          .rateBooking(
            accessToken: session.tokens.accessToken,
            id: bookingId,
            stars: stars,
            review: reviewController.text.trim().isEmpty
                ? null
                : reviewController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thanks for your rating.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      reviewController.dispose();
    }
  }

  Future<void> _raiseDispute() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final descriptionController = TextEditingController();
    var issueType = 'billing';

    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Text('Raise dispute'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: issueType,
                        items: const [
                          DropdownMenuItem(
                            value: 'billing',
                            child: Text('Billing'),
                          ),
                          DropdownMenuItem(
                            value: 'damage',
                            child: Text('Damage'),
                          ),
                          DropdownMenuItem(
                            value: 'delay',
                            child: Text('Delay'),
                          ),
                          DropdownMenuItem(
                            value: 'other',
                            child: Text('Other'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => issueType = value);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Issue type',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Describe the issue in a few words',
                        ),
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
                    child: const Text('Submit'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (shouldSend != true) {
        return;
      }

      await ref
          .read(apiClientProvider)
          .raiseBookingDispute(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
            issueType: issueType,
            description: descriptionController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dispute submitted.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      descriptionController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = _shipment;
    debugPrint(
      '[TrackingDetails] build live=$_isLiveTracking '
      'bookingId=${shipment.bookingId} '
      'pickup=${shipment.pickupLat},${shipment.pickupLng} '
      'drop=${shipment.dropLat},${shipment.dropLng} '
      'live=${shipment.liveLat},${shipment.liveLng}',
    );
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isLiveTracking
            ? _LiveTrackingView(
                key: const ValueKey('live'),
                shipment: shipment,
                onBack: _closeLiveTracking,
                onChatTap: _openChatSheet,
              )
            : SafeArea(
                key: const ValueKey('details'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactSummaryCard(shipment: shipment),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tracking timeline',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF101828),
                                    ),
                              ),
                              const SizedBox(height: 14),
                              ...shipment.timeline.asMap().entries.map((entry) {
                                final isLast =
                                    entry.key == shipment.timeline.length - 1;
                                return _TimelineStepItem(
                                  step: entry.value,
                                  showConnector: !isLast,
                                );
                              }),
                              const SizedBox(height: 10),
                              Padding(
                                padding: EdgeInsets.only(
                                  bottom: MediaQuery.of(context).padding.bottom,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: FilledButton(
                                        onPressed: _openLiveTracking,
                                        style: FilledButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          backgroundColor: const Color(
                                            0xFF2FA56E,
                                          ),
                                        ),
                                        child: const Text(
                                          'Live Tracking',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    if (shipment.bookingId != null)
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: _canCancelBooking
                                            ? OutlinedButton(
                                                onPressed: _isCancelling
                                                    ? null
                                                    : _confirmCancelBooking,
                                                style: OutlinedButton.styleFrom(
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  side: const BorderSide(
                                                    color: Color(0xFFE23A4B),
                                                  ),
                                                  foregroundColor: const Color(
                                                    0xFFE23A4B,
                                                  ),
                                                  backgroundColor: Colors.white,
                                                ),
                                                child: Text(
                                                  _isCancelling
                                                      ? 'Cancelling...'
                                                      : 'Cancel booking',
                                                  style: const TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ),
                                  ],
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
      ),
    );
  }
}

class _LiveTrackingView extends StatefulWidget {
  const _LiveTrackingView({
    super.key,
    required this.shipment,
    required this.onBack,
    required this.onChatTap,
  });

  final TrackingDemoShipment shipment;
  final VoidCallback onBack;
  final VoidCallback onChatTap;

  @override
  State<_LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<_LiveTrackingView> {
  static const MethodChannel _mapsLauncherChannel = MethodChannel(
    'ssk/google_maps_launcher',
  );
  GoogleMapController? _mapController;

  Uri? get _googleMapsDirectionsUri {
    final pickupLat = widget.shipment.pickupLat;
    final pickupLng = widget.shipment.pickupLng;
    final dropLat = widget.shipment.dropLat;
    final dropLng = widget.shipment.dropLng;
    if (pickupLat == null ||
        pickupLng == null ||
        dropLat == null ||
        dropLng == null) {
      return null;
    }

    return Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=$pickupLat,$pickupLng'
      '&destination=$dropLat,$dropLng'
      '&travelmode=driving',
    );
  }

  Future<void> _openInGoogleMaps() async {
    final uri = _googleMapsDirectionsUri;
    if (uri == null) {
      return;
    }
    try {
      final opened = await _mapsLauncherChannel.invokeMethod<bool>(
        'openDirections',
        {
          'origin': '${widget.shipment.pickupLat},${widget.shipment.pickupLng}',
          'destination':
              '${widget.shipment.dropLat},${widget.shipment.dropLng}',
        },
      );
      if (opened != true) {
        debugPrint('[LiveTracking] maps launch returned false');
      }
    } catch (error) {
      debugPrint('[LiveTracking] maps launch failed: $error');
    }
  }

  Future<void> _zoomIn() async {
    final controller = _mapController;
    if (controller == null) {
      debugPrint('[LiveTracking] zoom in ignored: map controller not ready');
      return;
    }
    debugPrint('[LiveTracking] zoom in');
    await controller.animateCamera(CameraUpdate.zoomIn());
  }

  Future<void> _zoomOut() async {
    final controller = _mapController;
    if (controller == null) {
      debugPrint('[LiveTracking] zoom out ignored: map controller not ready');
      return;
    }
    debugPrint('[LiveTracking] zoom out');
    await controller.animateCamera(CameraUpdate.zoomOut());
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[LiveTracking] build bookingId=${widget.shipment.bookingId} '
      'pickup=${widget.shipment.pickupLat},${widget.shipment.pickupLng} '
      'drop=${widget.shipment.dropLat},${widget.shipment.dropLng} '
      'live=${widget.shipment.liveLat},${widget.shipment.liveLng}',
    );
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Stack(
      children: [
        Positioned.fill(
          child: TrackingRouteMapView(
            shipment: widget.shipment,
            liveMode: true,
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: true,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.05),
                    Colors.white.withValues(alpha: 0.14),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 14,
                top: 4,
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Live Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF111111),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 4,
                child: TextButton.icon(
                  onPressed: _googleMapsDirectionsUri == null
                      ? null
                      : _openInGoogleMaps,
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Maps'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    foregroundColor: const Color(0xFF1F88C9),
                    backgroundColor: Colors.white.withValues(alpha: 0.92),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 110,
                child: Column(
                  children: [
                    _ZoomButton(icon: Icons.remove, onTap: _zoomOut),
                    const SizedBox(height: 10),
                    _ZoomButton(icon: Icons.add, onTap: _zoomIn),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomInset + 24,
                child: _LiveInfoCard(
                  shipment: widget.shipment,
                  bottomInset: bottomInset,
                  onChatTap: widget.onChatTap,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveInfoCard extends StatelessWidget {
  const _LiveInfoCard({
    required this.shipment,
    required this.bottomInset,
    required this.onChatTap,
  });

  final TrackingDemoShipment shipment;
  final double bottomInset;
  final VoidCallback onChatTap;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.34;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 56,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E5EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Package information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4FA),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Delivery Type:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.black45,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Express delivery',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Package weight:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.black45,
                                      fontSize: 11,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                shipment.weight,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B0B14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF2FA56E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rahul Patil',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Delivery man',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        _ContactIconButton(
                          icon: Icons.chat_bubble_outline_rounded,
                          onTap: onChatTap,
                        ),
                        const SizedBox(width: 10),
                        _ContactIconButton(
                          icon: Icons.call_rounded,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F3F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tracking Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF0F3F7)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset('assets/package.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#Tracking ID: ${shipment.trackingId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.black54, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: Color(0xFF2FA56E),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECEFF3)),
            ),
            child: Column(
              children: [
                _InfoGrid(
                  leftLabel: 'From',
                  leftValue: shipment.fromLocation,
                  rightLabel: 'Destination',
                  rightValue: shipment.toLocation,
                ),
                const SizedBox(height: 10),
                _InfoGrid(
                  leftLabel: 'Customer',
                  leftValue: shipment.customerName,
                  rightLabel: 'Weight',
                  rightValue: shipment.weight,
                ),
                if ((shipment.assignedDriverName ?? '').isNotEmpty ||
                    (shipment.assignedTruckName ?? '').isNotEmpty) ...[
                  const SizedBox(height: 10),
                  _InfoGrid(
                    leftLabel: 'Driver',
                    leftValue: (shipment.assignedDriverName ?? '').isEmpty
                        ? 'Not assigned'
                        : shipment.assignedDriverName!,
                    rightLabel: 'Truck',
                    rightValue: (shipment.assignedTruckName ?? '').isEmpty
                        ? 'Not assigned'
                        : shipment.assignedTruckName!,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Status:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C2430),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2FA56E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Transit',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: const Color(0xFF1C2430),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                leftValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2430),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.black45,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                rightValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1C2430),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineStepItem extends StatelessWidget {
  const _TimelineStepItem({required this.step, required this.showConnector});

  final TrackingTimelineStep step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final activeColor = step.completed
        ? const Color(0xFF2FA56E)
        : const Color(0xFFE0F4E8);
    final connectorColor = step.completed
        ? const Color(0xFF2FA56E)
        : const Color(0xFFD9E2EC);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (showConnector)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: EdgeInsets.zero,
                      decoration: BoxDecoration(
                        color: connectorColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontSize: 11,
                    height: 1.3,
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

class _BookingActionsSheet extends StatelessWidget {
  const _BookingActionsSheet({
    required this.onChat,
    required this.onNegotiation,
    required this.onPay,
    required this.onRate,
    required this.onEmailInvoice,
    required this.onDownloadInvoice,
    required this.onDispute,
  });

  final Future<void> Function() onChat;
  final Future<void> Function() onNegotiation;
  final Future<void> Function() onPay;
  final Future<void> Function() onRate;
  final Future<void> Function() onEmailInvoice;
  final Future<void> Function() onDownloadInvoice;
  final Future<void> Function() onDispute;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E5EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Booking actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use the live APIs for chat, invoice, rating, payment, and disputes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 16),
              _ActionSheetTile(
                icon: Icons.chat_bubble_outline_rounded,
                title: 'Open chat',
                subtitle: 'Message the booking thread over Socket.IO',
                onTap: () => onChat(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.handshake_outlined,
                title: 'Negotiation & offers',
                subtitle: 'Review driver requests and broker offers',
                onTap: () => onNegotiation(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.receipt_long_rounded,
                title: 'Download invoice',
                subtitle: 'Fetch the PDF invoice stream',
                onTap: () => onDownloadInvoice(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.mail_outline_rounded,
                title: 'Email invoice',
                subtitle: 'Send the invoice PDF by email',
                onTap: () => onEmailInvoice(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.payments_outlined,
                title: 'Record payment',
                subtitle: 'Mark the booking as paid',
                onTap: () => onPay(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.star_outline_rounded,
                title: 'Rate booking',
                subtitle: 'Submit delivery feedback',
                onTap: () => onRate(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.report_gmailerrorred_outlined,
                title: 'Raise dispute',
                subtitle: 'Open a backend dispute record',
                onTap: () => onDispute(),
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final iconColor = destructive
        ? const Color(0xFFE23A4B)
        : const Color(0xFF2FA56E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: destructive
              ? const Color(0xFFFFF5F6)
              : const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: destructive
                    ? const Color(0xFFFDE8EB)
                    : const Color(0xFFE0F4E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}

class _ClientBookingChatSheet extends ConsumerStatefulWidget {
  const _ClientBookingChatSheet({
    required this.bookingId,
    required this.accessToken,
    required this.currentUserId,
  });

  final String bookingId;
  final String accessToken;
  final String currentUserId;

  @override
  ConsumerState<_ClientBookingChatSheet> createState() =>
      _ClientBookingChatSheetState();
}

class _ClientBookingChatSheetState
    extends ConsumerState<_ClientBookingChatSheet> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final Map<String, bool> _typingUsers = <String, bool>{};
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  String? _threadId;
  bool _loading = true;
  bool _loadError = false;
  bool _sending = false;
  io.Socket? _socket;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    try {
      setState(() {
        _loading = true;
        _loadError = false;
      });

      final api = ref.read(apiClientProvider);
      final threadResponse = await api.getChatThread(
        accessToken: widget.accessToken,
        bookingId: widget.bookingId,
      );
      final thread = _chatThreadFromResponse(threadResponse);
      final threadId = _chatReadString(thread, const [
        'id',
        'thread_id',
        'threadId',
      ]);
      if (threadId.isEmpty) {
        throw StateError('Chat thread unavailable');
      }

      final messagesResponse = await api.getChatMessages(
        accessToken: widget.accessToken,
        threadId: threadId,
        limit: 50,
      );
      final messages = _chatMessagesFromResponse(messagesResponse);

      if (!mounted) return;
      setState(() {
        _threadId = threadId;
        _messages = messages;
      });

      await api.markChatThreadRead(
        accessToken: widget.accessToken,
        threadId: threadId,
      );
      await _connectSocket(threadId);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _connectSocket(String threadId) async {
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': widget.accessToken})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      socket.emit('join-thread', {'threadId': threadId});
    });
    socket.on('new-message', (payload) {
      final message = _chatMessageFromPayload(payload);
      if (message == null ||
          _chatReadString(message, const ['threadId', 'thread_id']).trim() !=
              threadId) {
        return;
      }
      final messageId = _chatReadString(message, const [
        'id',
        'message_id',
        'uuid',
      ]);
      if (messageId.isNotEmpty &&
          _messages.any(
            (item) =>
                _chatReadString(item, const ['id', 'message_id', 'uuid']) ==
                messageId,
          )) {
        return;
      }
      if (!mounted) return;
      setState(() {
        _messages = [..._messages, message];
      });
      if (_chatReadString(message, const [
            'senderId',
            'sender_id',
            'user_id',
          ]) !=
          widget.currentUserId) {
        socket.emit('read', {'threadId': threadId});
      }
      _scrollToBottom();
    });
    socket.on('typing', (payload) {
      final data = _chatAsMap(payload);
      if (data == null) return;
      final userId = _chatReadString(data, const ['userId', 'user_id']);
      if (userId.isEmpty || userId == widget.currentUserId) return;
      final isTyping = _chatReadBool(data, const ['isTyping', 'is_typing']);
      if (!mounted) return;
      setState(() {
        _typingUsers[userId] = isTyping;
      });
    });
    socket.on('read-receipt', (payload) {
      final data = _chatAsMap(payload);
      if (data == null) return;
      final userId = _chatReadString(data, const ['userId', 'user_id']);
      if (userId.isEmpty || userId == widget.currentUserId) return;
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (message) =>
                  _chatReadString(message, const [
                        'senderId',
                        'sender_id',
                        'user_id',
                      ]) ==
                      widget.currentUserId
                  ? {...message, 'readAt': DateTime.now().toIso8601String()}
                  : message,
            )
            .toList();
      });
    });
    socket.onConnectError((error) {
      debugPrint('[ClientChat] connect error: $error');
    });
    socket.connect();

    _socket?.dispose();
    _socket = socket;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final socket = _socket;
    final threadId = _threadId;
    final message = _messageController.text.trim();
    if (socket == null || threadId == null || message.isEmpty || _sending) {
      return;
    }

    setState(() {
      _sending = true;
    });

    socket.emitWithAck(
      'send-message',
      {'threadId': threadId, 'message': message},
      ack: (ack) {
        if (!mounted) return;
        final success = ack is Map ? ack['success'] != false : true;
        setState(() {
          _sending = false;
        });
        if (success) {
          _messageController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message could not be sent.')),
          );
        }
      },
    );
  }

  void _handleTyping(String value) {
    final socket = _socket;
    final threadId = _threadId;
    if (socket == null || threadId == null) {
      return;
    }

    socket.emit('typing', {'threadId': threadId, 'isTyping': true});
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      socket.emit('typing', {'threadId': threadId, 'isTyping': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomInset),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E5EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking chat',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF101828),
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thread updates over REST + Socket.IO',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError
                    ? Center(
                        child: Text(
                          'Could not load this chat.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      )
                    : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      )
                    : ListView.separated(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _messages.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isMine =
                              _chatReadString(message, const [
                                'senderId',
                                'sender_id',
                                'user_id',
                              ]) ==
                              widget.currentUserId;
                          final createdAt = _chatParseDateTime(message, const [
                            'createdAt',
                            'created_at',
                          ]);
                          final messageText = _chatReadString(message, const [
                            'message',
                            'body',
                            'content',
                            'text',
                          ]);
                          final senderName = _chatReadString(message, const [
                            'senderName',
                            'sender_name',
                            'name',
                          ]);
                          final isRead =
                              _chatParseDateTime(message, const [
                                'readAt',
                                'read_at',
                              ]) !=
                              null;

                          return Row(
                            mainAxisAlignment: isMine
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.72,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMine
                                        ? const Color(0xFF2FA56E)
                                        : const Color(0xFFF5F7FB),
                                    borderRadius: BorderRadius.circular(18)
                                        .copyWith(
                                          bottomRight: Radius.circular(
                                            isMine ? 6 : 18,
                                          ),
                                          bottomLeft: Radius.circular(
                                            isMine ? 18 : 6,
                                          ),
                                        ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: isMine
                                        ? CrossAxisAlignment.end
                                        : CrossAxisAlignment.start,
                                    children: [
                                      if (!isMine && senderName.isNotEmpty)
                                        Text(
                                          senderName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: const Color(0xFF667085),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      if (!isMine && senderName.isNotEmpty)
                                        const SizedBox(height: 4),
                                      Text(
                                        messageText.isEmpty
                                            ? 'Message'
                                            : messageText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: isMine
                                                  ? Colors.white
                                                  : const Color(0xFF101828),
                                              height: 1.35,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        createdAt == null
                                            ? ''
                                            : createdAt
                                                  .toLocal()
                                                  .toString()
                                                  .substring(11, 16),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: isMine
                                                  ? Colors.white70
                                                  : const Color(0xFF98A2B3),
                                              fontSize: 10,
                                            ),
                                      ),
                                      if (isMine && isRead)
                                        Text(
                                          'Read',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.white70,
                                                fontSize: 10,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
              if (_typingUsers.values.any((value) => value))
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Typing...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _handleTyping,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF5F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(999),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: FilledButton(
                      onPressed: _sending ? null : _sendMessage,
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: const Color(0xFF2FA56E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 18),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingNegotiationSheet extends ConsumerStatefulWidget {
  const _BookingNegotiationSheet({
    required this.bookingId,
    required this.accessToken,
  });

  final String bookingId;
  final String accessToken;

  @override
  ConsumerState<_BookingNegotiationSheet> createState() =>
      _BookingNegotiationSheetState();
}

class _BookingNegotiationSheetState
    extends ConsumerState<_BookingNegotiationSheet> {
  static const Duration _refreshInterval = Duration(seconds: 6);

  bool _loading = true;
  bool _loadError = false;
  ClientBookingOffer? _driverRequest;
  List<ClientBookingOffer> _offers = const [];
  String? _errorMessage;
  bool _busy = false;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;

  @override
  void initState() {
    super.initState();
    _loadNegotiation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _startNegotiationUpdates();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _driverRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startNegotiationUpdates() async {
    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(accessToken: widget.accessToken);

    _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      final payloadMap = _chatAsMap(payload);
      if (payloadMap == null) {
        return;
      }

      final bookingId = _chatReadString(payloadMap, const [
        'bookingId',
        'booking_id',
      ]);
      final requestId = _chatReadString(payloadMap, const [
        'id',
        'request_id',
        'driver_request_id',
      ]);
      if (bookingId != widget.bookingId && requestId.isEmpty) {
        return;
      }

      if (bookingId == widget.bookingId || requestId.isNotEmpty) {
        _loadNegotiation(silent: true);
      }
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _loadNegotiation(silent: true);
      }
    });
  }

  Future<void> _loadNegotiation({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _loading = true;
          _loadError = false;
          _errorMessage = null;
        });
      }

      final api = ref.read(apiClientProvider);
      ClientBookingOffer? driverRequest;
      try {
        final requestResponse = await api.getDriverRequestByBooking(
          accessToken: widget.accessToken,
          bookingId: widget.bookingId,
        );
        driverRequest = _firstRequestFromResponse(requestResponse);
      } catch (_) {
        driverRequest = null;
      }

      final offersResponse = await api.getBookingOffers(
        accessToken: widget.accessToken,
        bookingId: widget.bookingId,
      );
      final offers = _bookingOffersFromResponse(offersResponse);

      if (!mounted) return;
      setState(() {
        _driverRequest = driverRequest;
        _offers = offers;
        if (silent) {
          _loadError = false;
          _errorMessage = null;
        }
      });
    } catch (error) {
      if (!mounted) return;
      if (silent) {
        return;
      }
      setState(() {
        _loadError = true;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && !silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptDriverRequest() async {
    final request = _driverRequest;
    if (request == null || _busy || !_isClientActionable(request)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .acceptDriverRequest(accessToken: widget.accessToken, id: request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Driver request accepted.')));
      if (mounted) Navigator.of(context).maybePop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejectDriverRequest() async {
    final request = _driverRequest;
    if (request == null || _busy || !_isClientActionable(request)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .rejectDriverRequest(accessToken: widget.accessToken, id: request.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Driver request declined.')));
      await _loadNegotiation();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _counterDriverRequest() async {
    final request = _driverRequest;
    if (request == null || _busy || !_isClientActionable(request)) return;

    final amountController = TextEditingController(text: request.amountText);
    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Counter driver request'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
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
        ),
      );
      if (shouldSend != true) return;

      final amount =
          double.tryParse(
            amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      if (amount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
        return;
      }

      setState(() => _busy = true);
      await ref
          .read(apiClientProvider)
          .counterDriverRequest(
            accessToken: widget.accessToken,
            id: request.id,
            amount: amount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Counter sent.')));
      await _loadNegotiation();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      amountController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _acceptOffer(ClientBookingOffer offer) async {
    if (_busy || !_isOfferActionable(offer)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .clientAcceptCounterOffer(
            accessToken: widget.accessToken,
            id: offer.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offer accepted.')));
      if (mounted) Navigator.of(context).maybePop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _rejectOffer(ClientBookingOffer offer) async {
    if (_busy || !_isOfferActionable(offer)) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(apiClientProvider)
          .clientRejectCounterOffer(
            accessToken: widget.accessToken,
            id: offer.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offer declined.')));
      await _loadNegotiation();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _counterOffer(ClientBookingOffer offer) async {
    if (_busy || !_isOfferActionable(offer)) return;
    final amountController = TextEditingController(text: offer.amountText);
    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Counter offer'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
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
        ),
      );
      if (shouldSend != true) return;

      final amount =
          double.tryParse(
            amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
      if (amount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
        return;
      }

      setState(() => _busy = true);
      await ref
          .read(apiClientProvider)
          .clientCounterOffer(
            accessToken: widget.accessToken,
            id: offer.id,
            amount: amount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Counter sent.')));
      await _loadNegotiation();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      amountController.dispose();
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E5EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Negotiation & offers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Driver requests and broker offers from the client flow.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _loadError
                    ? Center(
                        child: Text(
                          _errorMessage ?? 'Could not load negotiation data.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadNegotiation,
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 12),
                          children: [
                            if (_driverRequest != null) ...[
                              _NegotiationSectionTitle(
                                title: 'Direct driver request',
                                subtitle:
                                    'This is the truck-specific negotiation path.',
                              ),
                              const SizedBox(height: 10),
                              _NegotiationCard(
                                title: _driverRequest!.brokerName.isNotEmpty
                                    ? _driverRequest!.brokerName
                                    : 'Driver request',
                                subtitle: _driverRequest!.note.isNotEmpty
                                    ? _driverRequest!.note
                                    : 'Direct truck request',
                                amountText: _driverRequest!.amountText,
                                statusText: _driverRequestStatusText(
                                  _driverRequest!,
                                ),
                                note: _driverRequest!.note,
                                actions: _clientActionButtonsForDriverRequest(
                                  _driverRequest!,
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            _NegotiationSectionTitle(
                              title: 'Broker offers',
                              subtitle:
                                  'Counter-offers sent after the booking was broadcast.',
                            ),
                            const SizedBox(height: 10),
                            if (_offers.isEmpty)
                              _NegotiationEmptyState(
                                title: 'No broker offers yet',
                                subtitle:
                                    'Once a broker responds, the offers will appear here.',
                              )
                            else
                              ..._offers.map(
                                (offer) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _NegotiationCard(
                                    title: offer.brokerName.isNotEmpty
                                        ? offer.brokerName
                                        : 'Broker offer',
                                    subtitle: offer.note.isNotEmpty
                                        ? offer.note
                                        : 'Broker offer received',
                                    amountText: offer.amountText,
                                    statusText: offer.displayStatusLabel,
                                    note: offer.note,
                                    actions: _clientActionButtonsForOffer(
                                      offer,
                                    ),
                                  ),
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
    );
  }
}

extension on _BookingNegotiationSheetState {
  bool _isClientActionable(ClientBookingOffer request) {
    return request.status.trim().toLowerCase() == 'countered';
  }

  bool _isOfferActionable(ClientBookingOffer offer) {
    final status = offer.status.trim().toLowerCase();
    return status != 'declined' && status != 'accepted';
  }

  String _driverRequestStatusText(ClientBookingOffer request) {
    final status = request.status.trim().toLowerCase();
    if (status == 'countered') {
      return 'Your turn';
    }
    if (status == 'accepted') {
      return 'Confirmed';
    }
    if (status == 'declined') {
      return 'No longer available';
    }
    return 'Waiting for driver response';
  }

  List<Widget> _clientActionButtonsForDriverRequest(
    ClientBookingOffer request,
  ) {
    if (!_isClientActionable(request)) {
      return const [];
    }

    return [
      FilledButton(
        onPressed: _busy ? null : _acceptDriverRequest,
        child: const Text('Accept'),
      ),
      OutlinedButton(
        onPressed: _busy ? null : _counterDriverRequest,
        child: const Text('Counter'),
      ),
      TextButton(
        onPressed: _busy ? null : _rejectDriverRequest,
        child: const Text('Reject'),
      ),
    ];
  }

  List<Widget> _clientActionButtonsForOffer(ClientBookingOffer offer) {
    final buttons = <Widget>[];
    if (_isOfferActionable(offer)) {
      buttons.add(
        FilledButton(
          onPressed: _busy ? null : () => _acceptOffer(offer),
          child: const Text('Accept'),
        ),
      );
      buttons.add(
        OutlinedButton(
          onPressed: _busy ? null : () => _counterOffer(offer),
          child: const Text('Counter'),
        ),
      );
      if (offer.isCountered) {
        buttons.add(
          TextButton(
            onPressed: _busy ? null : () => _rejectOffer(offer),
            child: const Text('Reject'),
          ),
        );
      }
    }
    return buttons;
  }
}

class _NegotiationSectionTitle extends StatelessWidget {
  const _NegotiationSectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF101828),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
        ),
      ],
    );
  }
}

class _NegotiationCard extends StatelessWidget {
  const _NegotiationCard({
    required this.title,
    required this.subtitle,
    required this.amountText,
    required this.statusText,
    required this.note,
    required this.actions,
  });

  final String title;
  final String subtitle;
  final String amountText;
  final String statusText;
  final String note;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: Color(0xFF2FA56E),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    amountText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F4E8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF2FA56E),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              note,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF344054)),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ],
      ),
    );
  }
}

class _NegotiationEmptyState extends StatelessWidget {
  const _NegotiationEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, color: Color(0xFF98A2B3), size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

ClientBookingOffer? _firstRequestFromResponse(Map<String, dynamic> response) {
  final data = _chatAsMap(response['data']) ?? response;
  final request =
      _chatAsMap(data['request']) ??
      _chatAsMap(data['driverRequest']) ??
      _chatAsMap(data['item']) ??
      data;
  return _bookingOfferFromMap(request);
}

List<ClientBookingOffer> _bookingOffersFromResponse(
  Map<String, dynamic> response,
) {
  final data = _chatAsMap(response['data']) ?? response;
  final dynamic items =
      data['offers'] ??
      data['items'] ??
      data['results'] ??
      data['rows'] ??
      data['data'];
  final Iterable<dynamic> list = items is Iterable
      ? items.cast<dynamic>()
      : const <dynamic>[];
  return list
      .whereType<Map<String, dynamic>>()
      .map(_bookingOfferFromMap)
      .where((offer) => offer.id.isNotEmpty)
      .toList();
}

ClientBookingOffer _bookingOfferFromMap(Map<String, dynamic> json) {
  return ClientBookingOffer.fromJson(json);
}

Map<String, dynamic>? _chatAsMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String _chatReadString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return '';
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

bool _chatReadBool(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return false;
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized.isEmpty) continue;
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

DateTime? _chatParseDateTime(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

Map<String, dynamic>? _chatThreadFromResponse(Map<String, dynamic> response) {
  final data = _chatAsMap(response['data']);
  final directThread = _chatAsMap(response['thread']);
  final thread =
      _chatAsMap(data?['thread']) ??
      _chatAsMap(data?['chatThread']) ??
      directThread ??
      data;
  return thread;
}

Map<String, dynamic>? _chatMessageFromPayload(Object? payload) {
  if (payload is Map<String, dynamic>) return payload;
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}

List<Map<String, dynamic>> _chatMessagesFromResponse(
  Map<String, dynamic> response,
) {
  final data = _chatAsMap(response['data']);
  final items =
      data?['messages'] ??
      data?['items'] ??
      data?['results'] ??
      response['messages'] ??
      response['items'] ??
      response['results'] ??
      data;

  final Iterable<dynamic> list =
      (items is Iterable
              ? items
              : data is Iterable
              ? data
              : const <dynamic>[])
          as Iterable<dynamic>;

  return list.whereType<Map<String, dynamic>>().toList();
}

class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: Icon(icon, size: 18, color: const Color(0xFF2FA56E)),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Icon(icon, size: 24, color: const Color(0xFF111111)),
      ),
    );
  }
}

class TrackingMapBackdrop extends StatelessWidget {
  const TrackingMapBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackingMapPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF3F6FB), Color(0xFFE8EEF6)],
          ),
        ),
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD8DEE9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final roadAccentPaint = Paint()
      ..color = const Color(0xFFC8D2E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = const Color(0xFFF9FBFD);
    final nodeBorderPaint = Paint()
      ..color = const Color(0xFFCFEFDB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF3F6FB),
    );

    final paths = [
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.18)
        ..quadraticBezierTo(
          size.width * 0.4,
          size.height * 0.12,
          size.width * 0.62,
          size.height * 0.24,
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.34,
          size.width * 0.95,
          size.height * 0.22,
        ),
      Path()
        ..moveTo(size.width * 0.05, size.height * 0.44)
        ..quadraticBezierTo(
          size.width * 0.32,
          size.height * 0.38,
          size.width * 0.5,
          size.height * 0.5,
        )
        ..quadraticBezierTo(
          size.width * 0.72,
          size.height * 0.62,
          size.width * 0.98,
          size.height * 0.56,
        ),
      Path()
        ..moveTo(size.width * 0.14, size.height * 0.72)
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.64,
          size.width * 0.58,
          size.height * 0.76,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          size.height * 0.86,
          size.width * 0.94,
          size.height * 0.78,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, roadAccentPaint);
    }

    final nodes = [
      Offset(size.width * 0.18, size.height * 0.24),
      Offset(size.width * 0.46, size.height * 0.33),
      Offset(size.width * 0.72, size.height * 0.27),
      Offset(size.width * 0.28, size.height * 0.58),
      Offset(size.width * 0.63, size.height * 0.66),
      Offset(size.width * 0.84, size.height * 0.82),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 11, nodePaint);
      canvas.drawCircle(node, 11, nodeBorderPaint);
      canvas.drawCircle(node, 3.5, Paint()..color = const Color(0xFF2FA56E));
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EBF3)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.12 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
