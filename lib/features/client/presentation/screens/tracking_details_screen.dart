import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

// ignore_for_file: unused_element

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/services/booking_payment_gateway.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../widgets/client_flow_widgets.dart';
import '../widgets/tracking_route_map_view.dart';
import '../../../chat/presentation/widgets/booking_chat_view.dart';
import '../../../shared/data/trip_route_stop.dart';
import '../../../shared/presentation/widgets/halting_timer_card.dart';
import '../../../../core/theme/app_tokens.dart';

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

String _readText(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

String _formatTrackingHours(double hours) {
  return '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h';
}

String _formatTrackingDate(DateTime value) {
  return '${value.day}/${value.month}/${value.year}';
}

String _formatTrackingMoney(double value) {
  if (value <= 0) return '-';
  return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
}

String _formatTrackingStatusLabel(String value) {
  final cleaned = value.trim().replaceAll(RegExp(r'[_-]+'), ' ');
  if (cleaned.isEmpty) return 'In transit';
  return cleaned
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

bool _isCancelledTrackingStatus(String value) {
  final normalized = value.trim().toLowerCase().replaceAll('-', '_');
  return normalized.contains('cancel');
}

Uri? _proofOfDeliveryUri(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  final parsed = Uri.tryParse(trimmed);
  if (parsed != null && parsed.hasScheme) return parsed;
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return Uri.parse('https://apigadidosti.asynk.in$path');
}

String _cleanTrackingLocation(String value, String fallback) {
  final cleaned = value.trim();
  final normalized = cleaned.toLowerCase().replaceAll('-', ' ');
  if (cleaned.isEmpty ||
      normalized == 'pickup location not provided' ||
      normalized == 'drop off location not provided' ||
      normalized == 'dropoff location not provided' ||
      normalized == 'pickup pending' ||
      normalized == 'drop pending') {
    return fallback;
  }
  return cleaned;
}

class TrackingDetailsScreen extends ConsumerStatefulWidget {
  const TrackingDetailsScreen({super.key, required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  ConsumerState<TrackingDetailsScreen> createState() =>
      _TrackingDetailsScreenState();
}

class _TrackingDetailsScreenState extends ConsumerState<TrackingDetailsScreen> {
  static const Duration _refreshInterval = Duration(seconds: 6);
  static const MethodChannel _shareChannel = MethodChannel(
    'plugins.flutter.io/share',
  );

  TrackingDemoShipment? _resolvedShipment;
  bool _isLiveTracking = false;
  bool _isCancelling = false;
  bool _isSharingTracking = false;
  bool _isBookingCancelled = false;
  bool _autoCancellingDriverDecline = false;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;
  List<_ReassignmentHistoryEntry> _reassignmentHistory = const [];

  void _setBottomNavVisible(bool visible) {
    ref.read(bottomNavVisibleProvider.notifier).state = visible;
  }

  void _openLiveTracking() {
    _setBottomNavVisible(false);
    setState(() => _isLiveTracking = true);
  }

  void _closeLiveTracking() {
    setState(() => _isLiveTracking = false);
  }

  Future<void> _callDriver(String? phone) async {
    final number = phone?.trim() ?? '';
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver phone number is not available.')),
      );
      return;
    }
    final launched = await launchUrl(
      Uri.parse('tel:$number'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone app.')),
      );
    }
  }

  TrackingDemoShipment get _shipment => _resolvedShipment ?? widget.shipment;

  @override
  void initState() {
    super.initState();
    _resolvedShipment = widget.shipment;
    _refreshShipment();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _setBottomNavVisible(false);
        _startLiveShipmentUpdates();
        unawaited(_loadReassignmentHistory());
      }
    });
  }

  Future<void> _loadReassignmentHistory() async {
    final bookingId = _shipment.bookingId?.trim() ?? '';
    final session = ref.read(authSessionProvider).valueOrNull;
    if (bookingId.isEmpty || session == null) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingReassignmentHistory(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );
      final data = _asMap(response['data']);
      final rawHistory = data['history'] ?? response['history'];
      final history = rawHistory is Iterable
          ? rawHistory
                .map(
                  (item) => item is Map ? item.cast<String, dynamic>() : null,
                )
                .whereType<Map<String, dynamic>>()
                .map(_ReassignmentHistoryEntry.fromJson)
                .toList(growable: false)
          : const <_ReassignmentHistoryEntry>[];
      if (!mounted) return;
      setState(() {
        _reassignmentHistory = history;
      });
    } catch (_) {
      // Optional parity data: tracking should still load without it.
    }
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
          ? (bookingData['booking'] is Map<String, dynamic>
                ? bookingData['booking']
                : bookingData)
          : null;
      if (bookingJson is! Map<String, dynamic>) {
        return;
      }

      final booking = ClientBooking.fromJson(bookingJson);
      var nextShipment = trackingShipmentFromBooking(booking);
      nextShipment = _shipmentWithResolvedLocations(nextShipment, bookingJson);

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
          nextShipment = _shipmentWithResolvedLocations(
            nextShipment,
            trackData,
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

  TrackingDemoShipment _shipmentWithResolvedLocations(
    TrackingDemoShipment shipment,
    Map<String, dynamic> data,
  ) {
    final pickup = _readPayloadString(data, const [
      'pickup',
      'pickupLocation',
      'pickup_location',
      'pickupAddress',
      'pickup_address',
      'from',
      'origin',
      'source',
      'sourceLocation',
      'source_location',
    ]);
    final drop = _readPayloadString(data, const [
      'drop',
      'dropLocation',
      'drop_location',
      'dropoff',
      'dropoffLocation',
      'dropoff_location',
      'dropOffLocation',
      'drop_off_location',
      'dropAddress',
      'drop_address',
      'dropoffAddress',
      'dropoff_address',
      'to',
      'destination',
      'destinationLocation',
      'destination_location',
      'targetLocation',
      'target_location',
    ]);

    final fromLocation =
        pickup.isNotEmpty &&
            _cleanTrackingLocation(shipment.fromLocation, '').isEmpty
        ? pickup
        : shipment.fromLocation;
    final toLocation =
        drop.isNotEmpty &&
            _cleanTrackingLocation(shipment.toLocation, '').isEmpty
        ? drop
        : shipment.toLocation;

    if (fromLocation == shipment.fromLocation &&
        toLocation == shipment.toLocation) {
      return shipment;
    }
    return shipment.copyWith(
      fromLocation: fromLocation,
      toLocation: toLocation,
    );
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

  String _readPayloadBookingId(Map<String, dynamic> payload) {
    final direct = _readPayloadString(payload, const [
      'bookingId',
      'booking_id',
    ]);
    if (direct.isNotEmpty) return direct;

    for (final key in const ['booking', 'data', 'request', 'driverRequest']) {
      final nested = _asMap(payload[key]);
      if (nested.isEmpty) continue;
      final value = _readPayloadString(nested, const [
        'bookingId',
        'booking_id',
        'id',
      ]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  String _readPayloadStatus(Map<String, dynamic> payload) {
    final direct = _readPayloadString(payload, const [
      'status',
      'job_status',
      'requestStatus',
      'request_status',
    ]);
    if (direct.isNotEmpty) return direct;

    for (final key in const [
      'data',
      'request',
      'driverRequest',
      'jobRequest',
    ]) {
      final nested = _asMap(payload[key]);
      if (nested.isEmpty) continue;
      final value = _readPayloadString(nested, const [
        'status',
        'job_status',
        'requestStatus',
        'request_status',
      ]);
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  bool _isDriverDeclinedStatus(String status) {
    final normalized = status.trim().toLowerCase().replaceAll('-', '_');
    return normalized == 'declined' ||
        normalized == 'rejected' ||
        normalized == 'driver_declined' ||
        normalized == 'driver_rejected' ||
        normalized == 'rejected_by_driver' ||
        normalized == 'declined_by_driver';
  }

  Future<void> _cancelAfterDriverDecline() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null ||
        bookingId.isEmpty ||
        _autoCancellingDriverDecline ||
        _isBookingCancelled) {
      return;
    }

    setState(() {
      _autoCancellingDriverDecline = true;
      _isBookingCancelled = true;
      _resolvedShipment = _shipment.copyWith(
        status: 'Cancelled',
        bookingStatus: 'cancelled',
      );
    });

    try {
      final session = ref.read(authSessionProvider).valueOrNull;
      if (session != null) {
        await ref
            .read(apiClientProvider)
            .cancelBooking(
              accessToken: session.tokens.accessToken,
              id: bookingId,
              reason: 'Driver declined trip',
            );
      }
    } catch (_) {
      // Best effort: the backend may already have cancelled it.
    } finally {
      if (mounted) {
        setState(() => _autoCancellingDriverDecline = false);
        unawaited(_refreshShipment());
      }
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _driverRequestSubscription?.cancel();
    _tripStatusSubscription?.cancel();
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
      final bookingId = _readPayloadBookingId(payload);
      if (bookingId.isNotEmpty && bookingId == _shipment.bookingId) {
        final status = _readPayloadStatus(payload);
        if (_isDriverDeclinedStatus(status)) {
          unawaited(_cancelAfterDriverDecline());
        }
        _refreshShipment();
      }
    });

    await _tripStatusSubscription?.cancel();
    _tripStatusSubscription = socketService.tripStatusStream.listen((payload) {
      final bookingId = _readPayloadBookingId(payload);
      if (bookingId.isNotEmpty && bookingId == _shipment.bookingId) {
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

  bool get _isPayable {
    final status = _shipment.bookingStatus?.toLowerCase();
    final paymentStatus = _shipment.paymentStatus.toLowerCase();
    return _shipment.bookingId != null &&
        status != 'cancelled' &&
        (paymentStatus == 'pending' || paymentStatus == 'partial');
  }

  bool get _isRatable {
    final status = _shipment.bookingStatus?.toLowerCase();
    return _shipment.bookingId != null &&
        (status == 'delivered' || status == 'completed') &&
        _shipment.ratingStars == null;
  }

  bool get _isInvoiceReady {
    final status = _shipment.bookingStatus?.toLowerCase();
    return _shipment.bookingId != null &&
        const {'delivered', 'completed', 'paid', 'settled'}.contains(status);
  }

  double get _remainingAmount =>
      (_shipment.amount - _shipment.amountPaid).clamp(0, double.infinity);

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
      final cancellationReason = reason.trim().isEmpty
          ? 'Cancelled by client'
          : reason.trim();
      await ref
          .read(apiClientProvider)
          .cancelBooking(
            accessToken: session.tokens.accessToken,
            id: bookingId,
            reason: cancellationReason,
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
    return showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _CancellationReasonDialog(),
    );
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

    final amount = _remainingAmount;
    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment amount is unavailable.')),
      );
      return;
    }

    final shouldPay = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Continue to payment?'),
        content: Text(
          'This will open secure checkout for ₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}.',
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
    if (!mounted) return;

    try {
      final paymentGateway = BookingPaymentGateway(
        apiClient: ref.read(apiClientProvider),
      );
      await paymentGateway.payBooking(
        accessToken: session.tokens.accessToken,
        bookingId: bookingId,
        payType: 'full',
        contact: session.user.phone,
        email: session.user.email,
        description: 'Booking payment',
        context: context,
      );
      if (!mounted) return;
      unawaited(_refreshShipment());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment completed successfully.')),
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

  Future<void> _shareTracking() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty || _isSharingTracking) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to share tracking.'),
        ),
      );
      return;
    }

    setState(() => _isSharingTracking = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .createBookingTrackingShareLink(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      final data = _asMap(response['data']);
      final shareUrl = _readText(data, const ['shareUrl', 'share_url', 'url']);
      if (shareUrl.isEmpty) {
        throw const ApiException('Tracking link is unavailable.');
      }

      final text =
          'Track ${_shipment.trackingId} (${_shipment.fromLocation} to ${_shipment.toLocation})\n$shareUrl';
      var shared = false;
      try {
        await _shareChannel.invokeMethod<void>('share', <String, dynamic>{
          'text': text,
          'subject': 'Track your shipment',
        });
        shared = true;
      } catch (_) {
        shared = false;
      }

      if (!shared) {
        await Clipboard.setData(ClipboardData(text: shareUrl));
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shared
                ? 'Tracking link is ready to share.'
                : 'Tracking link copied to clipboard.',
          ),
          backgroundColor: const Color(0xFF2FA56E),
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
    } finally {
      if (mounted) {
        setState(() => _isSharingTracking = false);
      }
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
      if (bytes.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invoice file is empty.')));
        return;
      }
      final fileName =
          'invoice-${_shipment.trackingId.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')}.pdf';
      String? savedPath;
      try {
        savedPath =
            await _shareChannel
                .invokeMethod<String>('downloadFile', <String, dynamic>{
                  'bytes': Uint8List.fromList(bytes),
                  'fileName': fileName,
                  'mimeType': 'application/pdf',
                }) ??
            '';
      } catch (_) {
        savedPath = null;
      }
      var sharedFallback = false;
      if (savedPath == null || savedPath.isEmpty) {
        try {
          sharedFallback =
              await _shareChannel.invokeMethod<bool>('shareFile', {
                'bytes': Uint8List.fromList(bytes),
                'fileName': fileName,
                'mimeType': 'application/pdf',
                'subject': 'Invoice ${_shipment.trackingId}',
              }) ??
              false;
        } catch (_) {
          sharedFallback = false;
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            savedPath != null && savedPath.isNotEmpty
                ? 'Invoice downloaded to $savedPath.'
                : sharedFallback
                ? 'Invoice ready to save or share.'
                : 'Failed to download invoice. Please restart the app and try again.',
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
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        final rating = index + 1;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: InkResponse(
                            onTap: () => setState(() => stars = rating),
                            radius: 20,
                            child: SizedBox(
                              width: 34,
                              height: 38,
                              child: Icon(
                                rating <= stars
                                    ? AppIcons.star_rounded
                                    : AppIcons.star_border_rounded,
                                color: const Color(0xFFF5B301),
                                size: 28,
                              ),
                            ),
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
    final accessToken =
        ref.watch(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
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
                onCallTap: () => _callDriver(shipment.assignedDriverPhone),
              )
            : SafeArea(
                key: const ValueKey('details'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () =>
                                  Navigator.of(context).maybePop(),
                              icon: const Icon(AppIcons.arrow_back_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    context.colors.surfaceElevated,
                                foregroundColor: context.colors.textPrimary,
                                shadowColor: const Color(
                                  0xFF101828,
                                ).withValues(alpha: 0.10),
                                elevation: 2,
                              ),
                            ),
                            const Spacer(),
                            _PremiumStatusPill(
                              label: (shipment.bookingStatus ?? shipment.status)
                                  .trim(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _GoogleMapsTrackingCard(
                          shipment: shipment,
                          onTap: _openLiveTracking,
                        ),
                        const SizedBox(height: 14),
                        if ((shipment.pickupOtp ?? '').isNotEmpty) ...[
                          _ReactStylePickupOtpBanner(
                            pickupOtp: shipment.pickupOtp,
                            pickupOtpVerified: shipment.pickupOtpVerified,
                          ),
                          const SizedBox(height: 14),
                        ],
                        _CompactSummaryCard(
                          shipment: shipment,
                          reassignmentHistory: _reassignmentHistory,
                          isSharingTracking: _isSharingTracking,
                          onShareTracking: shipment.bookingId == null
                              ? null
                              : _shareTracking,
                          onCallDriver: () =>
                              _callDriver(shipment.assignedDriverPhone),
                        ),
                        const SizedBox(height: 14),
                        _ShipmentTimelineCard(shipment: shipment),
                        const SizedBox(height: 14),
                        _QuickStatsRow(shipment: shipment),
                        const SizedBox(height: 14),
                        if (shipment.podMedia.isNotEmpty) ...[
                          _ProofOfDeliveryCard(
                            media: shipment.podMedia,
                            accessToken: accessToken,
                          ),
                          const SizedBox(height: 14),
                        ],
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).padding.bottom,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isPayable)
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 48,
                                        child: FilledButton.icon(
                                          onPressed: _payBooking,
                                          icon: const Icon(
                                            AppIcons.payments_outlined,
                                            size: 18,
                                          ),
                                          label: Text(
                                            shipment.paymentStatus
                                                        .toLowerCase() ==
                                                    'partial'
                                                ? 'Pay remaining'
                                                : 'Pay now',
                                          ),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF1976D2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (shipment.bookingId != null &&
                                        _canCancelBooking) ...[
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: OutlinedButton(
                                            onPressed: _isCancelling
                                                ? null
                                                : _confirmCancelBooking,
                                            style: OutlinedButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFFE23A4B),
                                              ),
                                              foregroundColor: const Color(
                                                0xFFE23A4B,
                                              ),
                                              backgroundColor:
                                                  context.colors.surface,
                                            ),
                                            child: Text(
                                              _isCancelling
                                                  ? 'Cancelling...'
                                                  : 'Cancel',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              if (_isPayable && (_isRatable || _isInvoiceReady))
                                const SizedBox(height: 10),
                              if (_isRatable || _isInvoiceReady)
                                Row(
                                  children: [
                                    if (_isRatable)
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: OutlinedButton.icon(
                                            onPressed: _rateBooking,
                                            icon: const Icon(
                                              AppIcons.star_outline_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Rate delivery'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(
                                                0xFFB88900,
                                              ),
                                              side: const BorderSide(
                                                color: Color(0xFFF3DC8C),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (_isRatable && _isInvoiceReady)
                                      const SizedBox(width: 10),
                                    if (_isInvoiceReady)
                                      Expanded(
                                        child: SizedBox(
                                          height: 48,
                                          child: OutlinedButton.icon(
                                            onPressed: _downloadInvoice,
                                            icon: const Icon(
                                              AppIcons.download_rounded,
                                              size: 18,
                                            ),
                                            label: const Text('Invoice'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor:
                                                  context.colors.textPrimary,
                                              side: BorderSide(
                                                color: context.colors.line,
                                              ),
                                              backgroundColor:
                                                  context.colors.surface,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              if (_isRatable &&
                                  !_isPayable &&
                                  shipment.bookingId != null &&
                                  _canCancelBooking)
                                const SizedBox(height: 10),
                              if (shipment.bookingId != null &&
                                  !_isPayable &&
                                  _canCancelBooking)
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed: _isCancelling
                                        ? null
                                        : _confirmCancelBooking,
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFFE23A4B),
                                      ),
                                      foregroundColor: const Color(0xFFE23A4B),
                                      backgroundColor: context.colors.surface,
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
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
    required this.onCallTap,
  });

  final TrackingDemoShipment shipment;
  final VoidCallback onBack;
  final VoidCallback onChatTap;
  final VoidCallback onCallTap;

  @override
  State<_LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<_LiveTrackingView> {
  static const MethodChannel _mapsLauncherChannel = MethodChannel(
    'ssk/google_maps_launcher',
  );

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

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[LiveTracking] build bookingId=${widget.shipment.bookingId} '
      'pickup=${widget.shipment.pickupLat},${widget.shipment.pickupLng} '
      'drop=${widget.shipment.dropLat},${widget.shipment.dropLng} '
      'live=${widget.shipment.liveLat},${widget.shipment.liveLng}',
    );
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
          bottom: false,
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
                      color: context.colors.surfaceElevated.withValues(
                        alpha: 0.92,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(AppIcons.arrow_back_rounded, size: 20),
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
                      color: context.colors.textPrimary,
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
                  icon: const Icon(AppIcons.map_outlined, size: 16),
                  label: const Text('Maps'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    foregroundColor: context.colors.infoEmphasis,
                    backgroundColor: context.colors.surfaceElevated.withValues(
                      alpha: 0.92,
                    ),
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
              if ((widget.shipment.pickupOtp ?? '').trim().isNotEmpty)
                Positioned(
                  right: 14,
                  top: 62,
                  child: _LivePickupOtpCard(shipment: widget.shipment),
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _LiveInfoCard(
            shipment: widget.shipment,
            bottomInset: MediaQuery.of(context).viewPadding.bottom,
            onChatTap: widget.onChatTap,
            onCallTap: widget.onCallTap,
          ),
        ),
      ],
    );
  }
}

class _LivePickupOtpCard extends StatelessWidget {
  const _LivePickupOtpCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    final verified = shipment.pickupOtpVerified;
    final otp = (shipment.pickupOtp ?? '').trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: verified ? context.colors.brandFill : const Color(0xFFFFF6DB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: verified
              ? context.colors.brandBorder
              : const Color(0xFFF3DC8C),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            verified ? AppIcons.verified_rounded : AppIcons.key_rounded,
            size: 16,
            color: verified ? const Color(0xFF2FA56E) : const Color(0xFFB88900),
          ),
          const SizedBox(width: 6),
          Text(
            verified ? 'OTP $otp ✓' : 'OTP $otp',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveInfoCard extends StatefulWidget {
  const _LiveInfoCard({
    required this.shipment,
    required this.bottomInset,
    required this.onChatTap,
    required this.onCallTap,
  });

  final TrackingDemoShipment shipment;
  final double bottomInset;
  final VoidCallback onChatTap;
  final VoidCallback onCallTap;

  @override
  State<_LiveInfoCard> createState() => _LiveInfoCardState();
}

class _LiveInfoCardState extends State<_LiveInfoCard> {
  bool _expanded = true;

  TrackingDemoShipment get shipment => widget.shipment;
  double get bottomInset => widget.bottomInset;
  VoidCallback get onChatTap => widget.onChatTap;
  VoidCallback get onCallTap => widget.onCallTap;

  void _handleSheetSwipe(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond.dy;
    if (velocity > 180 && _expanded) {
      setState(() => _expanded = false);
    } else if (velocity < -180 && !_expanded) {
      setState(() => _expanded = true);
    }
  }

  Widget _buildCollapsedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(AppIcons.local_shipping_rounded, color: Color(0xFF2FA56E)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.packageName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  shipment.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          _ContactIconButton(
            icon: AppIcons.chat_bubble_outline_rounded,
            onTap: onChatTap,
          ),
          const SizedBox(width: 8),
          Icon(
            AppIcons.keyboard_arrow_up_rounded,
            color: context.colors.textSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildSheetHandle(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: _handleSheetSwipe,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 28,
        child: Center(
          child: Container(
            width: 56,
            height: 5,
            decoration: BoxDecoration(
              color: context.colors.line,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.34;
    final driverName = shipment.assignedDriverName?.trim() ?? '';
    final truckName = shipment.assignedTruckName?.trim() ?? '';
    final crewTitle = truckName.isNotEmpty ? truckName : 'Assigned driver';
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(18, 10, 18, 12 + bottomInset),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated.withValues(alpha: 0.97),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSheetHandle(context),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: _expanded
                ? ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxHeight),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            'Package information',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  color: context.colors.textPrimary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: context.colors.fillSubtle,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Delivery Type:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .colors
                                                      .textSecondary,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            widget.shipment.isExpress
                                                ? 'Express delivery'
                                                : 'Standard delivery',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Package weight:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: context
                                                      .colors
                                                      .textSecondary,
                                                  fontSize: 11,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            shipment.weight,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w500,
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
                                    color: context.colors.fillSubtle,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    AppIcons.person_rounded,
                                    color: Color(0xFF2FA56E),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        driverName.isEmpty
                                            ? 'Driver not assigned'
                                            : driverName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        crewTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Colors.white70,
                                              fontSize: 11,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Row(
                                  children: [
                                    _ContactIconButton(
                                      icon:
                                          AppIcons.chat_bubble_outline_rounded,
                                      onTap: onChatTap,
                                    ),
                                    const SizedBox(width: 10),
                                    _ContactIconButton(
                                      icon: AppIcons.call_rounded,
                                      onTap: onCallTap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildCollapsedContent(context),
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({
    required this.shipment,
    required this.reassignmentHistory,
    required this.isSharingTracking,
    required this.onShareTracking,
    required this.onCallDriver,
  });

  final TrackingDemoShipment shipment;
  final List<_ReassignmentHistoryEntry> reassignmentHistory;
  final bool isSharingTracking;
  final VoidCallback? onShareTracking;
  final VoidCallback onCallDriver;

  @override
  Widget build(BuildContext context) {
    final driverName = shipment.assignedDriverName?.trim() ?? '';
    final truckName = shipment.assignedTruckName?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumDetailBlockDecoration(context, radius: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  shipment.trackingId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textTertiary,
                  ),
                ),
              ),
              if (shipment.isExpress) ...[
                const SizedBox(width: 8),
                const _ExpressIconChip(),
              ],
              if (onShareTracking != null) ...[
                const SizedBox(width: 8),
                _CircleIconButton(
                  icon: isSharingTracking
                      ? AppIcons.more_horiz_rounded
                      : AppIcons.share_rounded,
                  onTap: isSharingTracking ? null : onShareTracking,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _ReactRouteRail(
            fromLocation: shipment.fromLocation,
            toLocation: shipment.toLocation,
            stops: shipment.stops,
          ),
          if (truckName.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReactInfoRow(
              leading: const _ReactSquareIcon(
                icon: AppIcons.local_shipping_outlined,
              ),
              title: truckName,
              trailing: shipment.weight.isEmpty
                  ? null
                  : _SoftTextPill(label: shipment.weight),
            ),
          ],
          if (driverName.isNotEmpty) ...[
            const SizedBox(height: 14),
            _ReactInfoRow(
              leading: _DriverInitialsAvatar(name: driverName),
              title: driverName,
              subtitle: shipment.assignedDriverPhone,
              trailing: _CallDriverButton(onTap: onCallDriver),
            ),
          ],
          if (shipment.haltingGraceHours != null &&
              (shipment.tripStartedAt != null ||
                  shipment.haltingCharge > 0)) ...[
            const SizedBox(height: 14),
            HaltingTimerCard(
              status: shipment.bookingStatus ?? shipment.status,
              startedAt: shipment.tripStartedAt,
              haltingGraceHours: shipment.haltingGraceHours,
              haltingHours: shipment.haltingHours,
              haltingCharge: shipment.haltingCharge,
              showNotStarted: false,
              tickInterval: const Duration(seconds: 60),
            ),
          ],
          if (reassignmentHistory.isNotEmpty) ...[
            const SizedBox(height: 8),
            _ReassignmentHistoryPanel(history: reassignmentHistory),
          ],
        ],
      ),
    );
  }
}

BoxDecoration _premiumDetailBlockDecoration(
  BuildContext context, {
  double radius = 18,
  Color? color,
}) {
  final colors = context.colors;
  return BoxDecoration(
    color: color ?? colors.surface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: colors.line),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF101828).withValues(alpha: 0.055),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _PremiumStatusPill extends StatelessWidget {
  const _PremiumStatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final displayLabel = _formatTrackingStatusLabel(label);
    final isCancelled = _isCancelledTrackingStatus(label);
    final backgroundColor = isCancelled
        ? const Color(0xFFFFEBEE)
        : context.colors.brandFill;
    final borderColor = isCancelled
        ? const Color(0xFFFFCDD2)
        : context.colors.brandBorder;
    final dotColor = isCancelled
        ? const Color(0xFFE23A4B)
        : const Color(0xFF2FA56E);
    final textColor = isCancelled
        ? const Color(0xFFC62828)
        : context.colors.textPrimary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactStylePickupOtpBanner extends StatelessWidget {
  const _ReactStylePickupOtpBanner({
    required this.pickupOtp,
    required this.pickupOtpVerified,
  });

  final String? pickupOtp;
  final bool pickupOtpVerified;

  @override
  Widget build(BuildContext context) {
    final otp = pickupOtp?.trim() ?? '';
    if (otp.isEmpty) return const SizedBox.shrink();

    if (pickupOtpVerified) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.brandFill,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.brandBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Pickup Code',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: context.colors.brandEmphasis,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2FA56E),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              AppIcons.check_rounded,
                              size: 11,
                              color: Colors.white,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pickup confirmed with your code.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                      height: 1.25,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              otp,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF2FA56E),
                fontSize: 30,
                fontWeight: FontWeight.w500,
                letterSpacing: 5,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.brandBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup Code',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.brandEmphasis,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share this with your driver when they arrive to confirm pickup.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                    height: 1.25,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            otp,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: const Color(0xFF2FA56E),
              fontSize: 30,
              fontWeight: FontWeight.w500,
              letterSpacing: 5,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: context.colors.fillSubtle,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: context.colors.textSecondary),
      ),
    );
  }
}

class _ExpressIconChip extends StatelessWidget {
  const _ExpressIconChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        AppIcons.bolt_rounded,
        size: 16,
        color: Color(0xFF2FA56E),
      ),
    );
  }
}

class _ReactRouteRail extends StatelessWidget {
  const _ReactRouteRail({
    required this.fromLocation,
    required this.toLocation,
    this.stops = const [],
  });

  final String fromLocation;
  final String toLocation;
  final List<TripRouteStop> stops;

  @override
  Widget build(BuildContext context) {
    final pickup = _cleanTrackingLocation(fromLocation, 'Pickup pending');
    final drop = _cleanTrackingLocation(toLocation, 'Drop pending');
    final extraStops = stops.where((stop) => stop.isExtraStop).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _premiumDetailBlockDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteRailStop(marker: _routeRailPickupMarker, value: pickup),
          const _RouteRailConnector(),
          for (final stop in extraStops) ...[
            _RouteRailStop(
              marker: _RouteStopMarker(stop: stop),
              value: _cleanTrackingLocation(stop.location, stop.label),
              trailing: stop.isDone
                  ? const Icon(
                      AppIcons.check_circle_rounded,
                      size: 15,
                      color: Color(0xFF12B76A),
                    )
                  : null,
            ),
            const _RouteRailConnector(),
          ],
          _RouteRailStop(marker: _routeRailDropMarker, value: drop),
        ],
      ),
    );
  }
}

/// Pickup marker matching the rest of the app: green circle-dot
/// (same as [_PremiumRouteLine]).
const Widget _routeRailPickupMarker = Icon(
  AppIcons.radio_button_checked_rounded,
  color: Color(0xFF2FA56E),
  size: 20,
);

/// Drop marker matching the rest of the app: red pin
/// (same as [_PremiumRouteLine]).
const Widget _routeRailDropMarker = Icon(
  AppIcons.location_on_rounded,
  color: Color(0xFFE23A4B),
  size: 20,
);

class _RouteRailStop extends StatelessWidget {
  const _RouteRailStop({
    required this.marker,
    required this.value,
    this.trailing,
  });

  final Widget marker;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Align(alignment: Alignment.center, child: marker),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontSize: 14,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteStopMarker extends StatelessWidget {
  const _RouteStopMarker({required this.stop});

  final TripRouteStop stop;

  @override
  Widget build(BuildContext context) {
    return Icon(
      stop.isLoading
          ? AppIcons.inventory_2_outlined
          : AppIcons.inventory_2_rounded,
      color: const Color(0xFFF59E0B),
      size: 16,
    );
  }
}

class _RouteRailConnector extends StatelessWidget {
  const _RouteRailConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 10),
      child: Container(
        width: 2,
        height: 30,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: context.colors.line,
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _ReactInfoRow extends StatelessWidget {
  const _ReactInfoRow({
    required this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        leading,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if ((subtitle ?? '').isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 10), trailing!],
      ],
    );
  }
}

class _ReactSquareIcon extends StatelessWidget {
  const _ReactSquareIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 18, color: const Color(0xFF2FA56E)),
    );
  }
}

class _SoftTextPill extends StatelessWidget {
  const _SoftTextPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF2FA56E),
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DriverInitialsAvatar extends StatelessWidget {
  const _DriverInitialsAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'D' : initials,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(0xFF2FA56E),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _CallDriverButton extends StatelessWidget {
  const _CallDriverButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Color(0xFF2FA56E),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          AppIcons.phone_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

class _GoogleMapsTrackingCard extends StatelessWidget {
  const _GoogleMapsTrackingCard({required this.shipment, required this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          height: 190,
          decoration: _premiumDetailBlockDecoration(context, radius: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Preview only: the platform map view swallows gestures, so
                // ignore them here and let the card InkWell open live view.
                IgnorePointer(
                  child: TrackingRouteMapView(
                    shipment: shipment,
                    liveMode: true,
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.02),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IgnorePointer(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.open_in_full_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Live',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
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

class _ShipmentTimelineCard extends StatelessWidget {
  const _ShipmentTimelineCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    var currentIndex = shipment.timeline.indexWhere((step) => !step.completed);
    if (currentIndex == -1) currentIndex = shipment.timeline.length - 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _premiumDetailBlockDecoration(context, radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipment Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < shipment.timeline.length; i++)
                    _HorizontalTimelineStep(
                      step: shipment.timeline[i],
                      isCurrent: i == currentIndex,
                      showConnector: i != shipment.timeline.length - 1,
                    ),
                ],
              ),
            ),
          ),
          if (shipment.timeline.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Current Status: ${shipment.timeline[currentIndex].title}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textTertiary,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HorizontalTimelineStep extends StatelessWidget {
  const _HorizontalTimelineStep({
    required this.step,
    required this.isCurrent,
    required this.showConnector,
  });

  final TrackingTimelineStep step;
  final bool isCurrent;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final isCompleted = step.completed && !isCurrent;
    final dotColor = isCompleted || isCurrent
        ? const Color(0xFF2FA56E)
        : Colors.white;
    final borderColor = isCompleted || isCurrent
        ? const Color(0xFF2FA56E)
        : context.colors.line;
    final textColor = isCompleted
        ? const Color(0xFF2FA56E)
        : isCurrent
        ? const Color(0xFF2FA56E)
        : context.colors.textTertiary;

    return SizedBox(
      width: showConnector ? 96 : 70,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 2),
                  boxShadow: isCurrent
                      ? [
                          BoxShadow(
                            color: const Color(
                              0xFF2FA56E,
                            ).withValues(alpha: 0.16),
                            spreadRadius: 4,
                          ),
                        ]
                      : null,
                ),
                child: isCompleted
                    ? const Icon(
                        AppIcons.check_rounded,
                        size: 15,
                        color: Colors.white,
                      )
                    : isCurrent
                    ? Center(
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(height: 7),
              SizedBox(
                width: 64,
                child: Text(
                  step.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: textColor,
                    fontSize: 10,
                    height: 1.15,
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          if (showConnector)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(top: 12, left: 4, right: 4),
                color: isCompleted
                    ? const Color(0xFF2FA56E)
                    : context.colors.fillSubtle,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProofOfDeliveryCard extends StatelessWidget {
  const _ProofOfDeliveryCard({required this.media, required this.accessToken});

  final List<PodDeliveryMedia> media;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    final count = media.length;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: _premiumDetailBlockDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: context.colors.brandFill,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  AppIcons.camera_alt_outlined,
                  color: Color(0xFF2FA56E),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Proof of delivery',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$count ${count == 1 ? 'file' : 'files'} posted by driver',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                AppIcons.open_in_full_rounded,
                color: context.colors.textTertiary,
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: media.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemBuilder: (context, index) {
              return _PodMediaTile(
                media: media[index],
                accessToken: accessToken,
                onTap: () =>
                    _openPodLightbox(context, media, accessToken, index),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openPodLightbox(
    BuildContext context,
    List<PodDeliveryMedia> media,
    String accessToken,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PodMediaLightbox(
          media: media,
          accessToken: accessToken,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _PodMediaTile extends StatelessWidget {
  const _PodMediaTile({
    required this.media,
    required this.accessToken,
    required this.onTap,
  });

  final PodDeliveryMedia media;
  final String accessToken;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final uri = _proofOfDeliveryUri(media.url);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: uri == null ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            color: context.colors.fillSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: context.colors.divider),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (uri == null)
                  ColoredBox(color: context.colors.fillSubtle)
                else if (media.isVideo)
                  const ColoredBox(color: Color(0xFF111827))
                else
                  Image.network(
                    uri.toString(),
                    fit: BoxFit.cover,
                    headers: _podMediaHeaders(accessToken),
                    errorBuilder: (context, error, stackTrace) => ColoredBox(
                      color: context.colors.fillSubtle,
                      child: Icon(
                        AppIcons.error_outline_rounded,
                        color: context.colors.textTertiary,
                      ),
                    ),
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return ColoredBox(
                        color: context.colors.fillSubtle,
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    },
                  ),
                if (media.isVideo)
                  Center(
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.play_arrow_rounded,
                        color: Colors.white,
                        size: 24,
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

class _PodMediaLightbox extends StatefulWidget {
  const _PodMediaLightbox({
    required this.media,
    required this.accessToken,
    required this.initialIndex,
  });

  final List<PodDeliveryMedia> media;
  final String accessToken;
  final int initialIndex;

  @override
  State<_PodMediaLightbox> createState() => _PodMediaLightboxState();
}

class _PodMediaLightboxState extends State<_PodMediaLightbox> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.media.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    if (widget.media.length < 2) return;
    final next = (_index + delta) % widget.media.length;
    final resolved = next < 0 ? widget.media.length - 1 : next;
    _pageController.animateToPage(
      resolved,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.media.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return _PodMediaPage(
                  media: widget.media[index],
                  accessToken: widget.accessToken,
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(AppIcons.close_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                ),
              ),
            ),
            if (widget.media.length > 1) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => _go(-1),
                  icon: const Icon(AppIcons.chevron_left_rounded),
                  color: Colors.white,
                  iconSize: 34,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => _go(1),
                  icon: const Icon(AppIcons.chevron_right_rounded),
                  color: Colors.white,
                  iconSize: 34,
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 16,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${_index + 1} / ${widget.media.length}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PodMediaPage extends StatelessWidget {
  const _PodMediaPage({required this.media, required this.accessToken});

  final PodDeliveryMedia media;
  final String accessToken;

  @override
  Widget build(BuildContext context) {
    final uri = _proofOfDeliveryUri(media.url);
    if (uri == null) {
      return const Center(
        child: Text(
          'Could not load delivery proof.',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    if (media.isVideo) {
      return _PodVideoPlayer(uri: uri, accessToken: accessToken);
    }
    return Center(
      child: InteractiveViewer(
        minScale: 0.8,
        maxScale: 4,
        child: Image.network(
          uri.toString(),
          fit: BoxFit.contain,
          headers: _podMediaHeaders(accessToken),
          errorBuilder: (context, error, stackTrace) => const Text(
            'Could not load delivery proof.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

class _PodVideoPlayer extends StatefulWidget {
  const _PodVideoPlayer({required this.uri, required this.accessToken});

  final Uri uri;
  final String accessToken;

  @override
  State<_PodVideoPlayer> createState() => _PodVideoPlayerState();
}

class _PodVideoPlayerState extends State<_PodVideoPlayer> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialize;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      widget.uri,
      httpHeaders: _podMediaHeaders(widget.accessToken),
    );
    _initialize = _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() {});
      _controller.play();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initialize,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              'Could not play delivery video.',
              style: TextStyle(color: Colors.white),
            ),
          );
        }
        return Center(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _controller.value.isPlaying
                    ? _controller.pause()
                    : _controller.play();
              });
            },
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio == 0
                  ? 16 / 9
                  : _controller.value.aspectRatio,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VideoPlayer(_controller),
                  if (!_controller.value.isPlaying)
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Map<String, String> _podMediaHeaders(String accessToken) {
  final token = accessToken.trim();
  if (token.isEmpty) return const {};
  return {'Authorization': 'Bearer $token'};
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _QuickStatCard(label: 'Weight', value: shipment.weight),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickStatCard(
            label: 'Amount',
            value: _formatTrackingMoney(shipment.amount),
            highlight: true,
          ),
        ),
      ],
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _premiumDetailBlockDecoration(context, radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: highlight
                  ? const Color(0xFF2FA56E)
                  : context.colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumRouteLine extends StatelessWidget {
  const _PremiumRouteLine({
    required this.fromLocation,
    required this.toLocation,
  });

  final String fromLocation;
  final String toLocation;

  @override
  Widget build(BuildContext context) {
    final pickup = _cleanTrackingLocation(fromLocation, 'Pickup pending');
    final drop = _cleanTrackingLocation(toLocation, 'Drop pending');

    return Column(
      children: [
        _RouteStop(
          icon: AppIcons.radio_button_checked_rounded,
          iconColor: const Color(0xFF2FA56E),
          label: 'Pickup',
          value: pickup,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 11),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 2,
              height: 18,
              decoration: BoxDecoration(
                color: context.colors.line,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        _RouteStop(
          icon: AppIcons.location_on_rounded,
          iconColor: const Color(0xFFE23A4B),
          label: 'Drop',
          value: drop,
        ),
      ],
    );
  }
}

class _CompactPickupOtpChip extends StatelessWidget {
  const _CompactPickupOtpChip({
    required this.pickupOtp,
    required this.pickupOtpVerified,
  });

  final String? pickupOtp;
  final bool pickupOtpVerified;

  @override
  Widget build(BuildContext context) {
    final otp = pickupOtp?.trim() ?? '';
    if (otp.isEmpty) return const SizedBox.shrink();

    final accentColor = pickupOtpVerified
        ? const Color(0xFF2FA56E)
        : const Color(0xFFB88900);
    final backgroundColor = pickupOtpVerified
        ? context.colors.brandFill
        : const Color(0xFFFFF8E6);
    final borderColor = pickupOtpVerified
        ? context.colors.brandBorder
        : const Color(0xFFF3DC8C);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pickupOtpVerified
                  ? AppIcons.verified_rounded
                  : AppIcons.key_rounded,
              size: 15,
              color: accentColor,
            ),
            const SizedBox(width: 7),
            Text(
              otp,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontSize: 13,
                  height: 1.25,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PremiumFactTile extends StatelessWidget {
  const _PremiumFactTile({
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
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: context.colors.textSecondary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumCrewCard extends StatelessWidget {
  const _PremiumCrewCard({required this.driverName, required this.truckName});

  final String driverName;
  final String truckName;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.colors.brandFill,
              shape: BoxShape.circle,
            ),
            child: Icon(
              AppIcons.local_shipping_outlined,
              size: 19,
              color: context.colors.brandEmphasis,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driverName.isEmpty ? 'Driver pending' : driverName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  truckName.isEmpty ? 'Truck not assigned' : truckName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: context.colors.textSecondary,
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

class _ExpressBadge extends StatelessWidget {
  const _ExpressBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.bolt_rounded, size: 13, color: Color(0xFFEA580C)),
          const SizedBox(width: 3),
          Text(
            'Express',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFC2410C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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
      fromDriverName: _readText(json, const [
        'fromDriverName',
        'from_driver_name',
      ]),
      toDriverName: _readText(json, const ['toDriverName', 'to_driver_name']),
      reason: _readText(json, const ['reason']),
      reassignedByName: _readText(json, const [
        'reassignedByName',
        'reassigned_by_name',
      ]),
      createdAt: DateTime.tryParse(
        _readText(json, const ['createdAt', 'created_at']),
      ),
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
        final left = a.createdAt;
        final right = b.createdAt;
        if (left == null && right == null) return 0;
        if (left == null) return 1;
        if (right == null) return -1;
        return right.compareTo(left);
      });
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        leading: Icon(
          AppIcons.sync_alt_rounded,
          color: context.colors.infoEmphasis,
          size: 18,
        ),
        title: Text(
          'Driver changed (${history.length})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        children: [
          for (final entry in sorted)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.fillSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.fromDriverName.isEmpty ? 'Unassigned' : entry.fromDriverName} -> ${entry.toDriverName.isEmpty ? 'Unknown' : entry.toDriverName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (entry.reason.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (entry.reassignedByName.isNotEmpty)
                          'By ${entry.reassignedByName}',
                        if (entry.createdAt != null)
                          _formatTrackingDate(entry.createdAt!),
                      ].join(' - '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textTertiary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
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
                  color: context.colors.textSecondary,
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
                  color: context.colors.textPrimary,
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
                  color: context.colors.textSecondary,
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
                  color: context.colors.textPrimary,
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

class _CancellationReasonDialog extends StatefulWidget {
  const _CancellationReasonDialog();

  @override
  State<_CancellationReasonDialog> createState() =>
      _CancellationReasonDialogState();
}

class _CancellationReasonDialogState extends State<_CancellationReasonDialog> {
  late final TextEditingController _controller;

  static const _quickReasons = [
    'Driver is delayed',
    'Booked by mistake',
    'Found another truck',
    'Price changed',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reason = _controller.text.trim();
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colors.surfaceElevated,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDECEC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF7B4B4)),
                  ),
                  child: const Icon(
                    AppIcons.warning_amber_rounded,
                    color: Color(0xFFE23A4B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cancel this booking?',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: colors.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Tell us why — it helps us do better.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final quick in _quickReasons)
                  GestureDetector(
                    onTap: () {
                      _controller.text = quick;
                      _controller.selection = TextSelection.collapsed(
                        offset: _controller.text.length,
                      );
                      setState(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: reason == quick
                            ? const Color(0xFFFDECEC)
                            : colors.fillSubtle,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: reason == quick
                              ? const Color(0xFFE23A4B)
                              : colors.line,
                        ),
                      ),
                      child: Text(
                        quick,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: reason == quick
                              ? const Color(0xFFB42318)
                              : colors.textSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 13),
            TextField(
              controller: _controller,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: colors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Add more detail (optional)',
                hintStyle: TextStyle(color: colors.textTertiary, fontSize: 13),
                filled: true,
                fillColor: colors.fillSubtle,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: colors.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE23A4B),
                    width: 1.4,
                  ),
                ),
              ),
              onChanged: (_) {
                if (mounted) {
                  setState(() {});
                }
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.textPrimary,
                      side: BorderSide(color: colors.line),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Keep booking',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF05252), Color(0xFFC81E3A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x40E23A4B),
                          blurRadius: 14,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(reason),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Yes, cancel',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        : context.colors.line;

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
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  step.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
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
            color: context.colors.surfaceElevated,
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
                    color: context.colors.line,
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
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Use the live APIs for chat, invoice, rating, payment, and disputes.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              _ActionSheetTile(
                icon: AppIcons.chat_bubble_outline_rounded,
                title: 'Open chat',
                subtitle: 'Message the booking thread over Socket.IO',
                onTap: () => onChat(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: AppIcons.handshake_outlined,
                title: 'Negotiation & offers',
                subtitle: 'Review driver requests and broker offers',
                onTap: () => onNegotiation(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: AppIcons.receipt_long_rounded,
                title: 'Download invoice',
                subtitle: 'Fetch the PDF invoice stream',
                onTap: () => onDownloadInvoice(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: AppIcons.mail_outline_rounded,
                title: 'Email invoice',
                subtitle: 'Send the invoice PDF by email',
                onTap: () => onEmailInvoice(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: AppIcons.payments_outlined,
                title: 'Pay booking',
                subtitle: 'Open secure checkout',
                onTap: () => onPay(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: AppIcons.star_outline_rounded,
                title: 'Rate booking',
                subtitle: 'Submit delivery feedback',
                onTap: () => onRate(),
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: AppIcons.report_gmailerrorred_outlined,
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
          color: destructive ? const Color(0xFFFFF5F6) : context.colors.canvas,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.colors.line),
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
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              AppIcons.chevron_right_rounded,
              color: context.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientBookingChatSheet extends StatelessWidget {
  const _ClientBookingChatSheet({
    required this.bookingId,
    required this.accessToken,
    required this.currentUserId,
  });

  final String bookingId;
  final String accessToken;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return FractionallySizedBox(
      heightFactor: 0.88,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomInset),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking chat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(AppIcons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: BookingChatView(
                  bookingId: bookingId,
                  accessToken: accessToken,
                  currentUserId: currentUserId,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegacyClientBookingChatSheet extends ConsumerStatefulWidget {
  const _LegacyClientBookingChatSheet({
    required this.bookingId,
    required this.accessToken,
    required this.currentUserId,
  });

  final String bookingId;
  final String accessToken;
  final String currentUserId;

  @override
  ConsumerState<_LegacyClientBookingChatSheet> createState() =>
      _LegacyClientBookingChatSheetState();
}

class _LegacyClientBookingChatSheetState
    extends ConsumerState<_LegacyClientBookingChatSheet> {
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
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomInset),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: context.colors.line,
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
                                color: context.colors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Thread updates over REST + Socket.IO',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(AppIcons.close_rounded),
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
                              ?.copyWith(color: context.colors.textSecondary),
                        ),
                      )
                    : _messages.isEmpty
                    ? Center(
                        child: Text(
                          'No messages yet.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: context.colors.textSecondary),
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
                                        : context.colors.canvas,
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
                                                color: context
                                                    .colors
                                                    .textSecondary,
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
                                                  : context.colors.textPrimary,
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
                                                  : context.colors.textTertiary,
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
                      color: context.colors.textSecondary,
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
                        fillColor: context.colors.canvas,
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
                          : const Icon(AppIcons.send_rounded, size: 18),
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
        final requestResponse = await api.getDriverRequestsForBooking(
          accessToken: widget.accessToken,
          bookingId: widget.bookingId,
        );
        driverRequest = _bestDriverRequestFromResponse(requestResponse);
      } catch (_) {
        try {
          final requestResponse = await api.getDriverRequestByBooking(
            accessToken: widget.accessToken,
            bookingId: widget.bookingId,
          );
          driverRequest = _firstRequestFromResponse(requestResponse);
        } catch (_) {
          driverRequest = null;
        }
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
      final response = await ref
          .read(apiClientProvider)
          .acceptDriverRequest(accessToken: widget.accessToken, id: request.id);
      final responseData = _chatAsMap(response['data']);
      final updatedRequest =
          _chatAsMap(responseData?['request']) ?? responseData;
      final booking = _chatAsMap(responseData?['booking']);
      if (!mounted) return;
      if (booking != null ||
          _chatReadString(updatedRequest, const ['status']) == 'accepted') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver request accepted.')),
        );
        if (mounted) Navigator.of(context).maybePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accepted - waiting for the driver to confirm.'),
          ),
        );
        await _loadNegotiation();
      }
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(132, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Send', maxLines: 1, softWrap: false),
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
      final response = await ref
          .read(apiClientProvider)
          .clientAcceptCounterOffer(
            accessToken: widget.accessToken,
            id: offer.id,
          );
      final responseData = _chatAsMap(response['data']);
      final booking = _chatAsMap(responseData?['booking']);
      final updatedRequest =
          _chatAsMap(responseData?['request']) ?? responseData;
      if (!mounted) return;
      if (booking != null ||
          _chatReadString(updatedRequest, const ['status']) == 'accepted') {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Offer accepted.')));
        if (mounted) Navigator.of(context).maybePop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accepted - waiting for the broker to confirm.'),
          ),
        );
        await _loadNegotiation();
      }
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
              style: FilledButton.styleFrom(
                minimumSize: const Size(132, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: const Text('Send', maxLines: 1, softWrap: false),
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
            color: context.colors.surfaceElevated,
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
                    color: context.colors.line,
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
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Driver requests and broker offers from the client flow.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
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
                              ?.copyWith(color: context.colors.textSecondary),
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
                                    statusText: _offerStatusText(offer),
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
    return request.isActionableByClient;
  }

  bool _isOfferActionable(ClientBookingOffer offer) {
    return offer.isActionableByClient;
  }

  String _offerStatusText(ClientBookingOffer offer) {
    if (offer.isClientTurnToConfirm) {
      return 'Your turn';
    }
    if (offer.isWaitingForCounterpartyConfirmation) {
      return 'Waiting for broker confirmation';
    }
    if (offer.isCountered) {
      return 'Your turn';
    }
    if (offer.normalizedStatus == 'accepted') {
      return 'Confirmed';
    }
    if (offer.normalizedStatus == 'declined') {
      return 'No longer available';
    }
    return 'Waiting for broker response';
  }

  String _driverRequestStatusText(ClientBookingOffer request) {
    if (request.isClientTurnToConfirm) {
      return 'Your turn';
    }
    if (request.isWaitingForCounterpartyConfirmation) {
      return 'Waiting for driver confirmation';
    }
    if (request.isCountered) {
      return 'Your turn';
    }
    if (request.normalizedStatus == 'accepted') {
      return 'Confirmed';
    }
    if (request.normalizedStatus == 'declined') {
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

    if (request.isClientTurnToConfirm) {
      return [
        FilledButton(
          onPressed: _busy ? null : _acceptDriverRequest,
          child: const Text('Confirm'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : _rejectDriverRequest,
          child: const Text('Decline'),
        ),
      ];
    }

    return [
      FilledButton(
        onPressed: _busy ? null : _acceptDriverRequest,
        child: const Text('Accept'),
      ),
      TextButton(
        onPressed: _busy ? null : _rejectDriverRequest,
        child: const Text('Reject'),
      ),
    ];
  }

  List<Widget> _clientActionButtonsForOffer(ClientBookingOffer offer) {
    if (offer.isWaitingForCounterpartyConfirmation) {
      return const [];
    }

    if (offer.isClientTurnToConfirm) {
      return [
        FilledButton(
          onPressed: _busy ? null : () => _acceptOffer(offer),
          child: const Text('Confirm'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _rejectOffer(offer),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE23A4B),
            side: const BorderSide(color: Color(0xFFF3B4B4)),
          ),
          child: const Text('Decline'),
        ),
      ];
    }

    if (offer.isCountered) {
      return [
        FilledButton(
          onPressed: _busy ? null : () => _acceptOffer(offer),
          child: const Text('Accept'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _rejectOffer(offer),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFE23A4B),
            side: const BorderSide(color: Color(0xFFF3B4B4)),
          ),
          child: const Text('Reject'),
        ),
        OutlinedButton(
          onPressed: _busy ? null : () => _counterOffer(offer),
          child: const Text('Counter'),
        ),
      ];
    }

    return const [];
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
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
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
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2FA56E), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2FA56E).withValues(alpha: 0.08),
            blurRadius: 16,
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
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.local_shipping_rounded,
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
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
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
                      color: context.colors.textPrimary,
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 14),
            _NegotiationActionLayout(actions: actions),
          ],
        ],
      ),
    );
  }
}

class _NegotiationActionLayout extends StatelessWidget {
  const _NegotiationActionLayout({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.length == 3) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: actions[0]),
              const SizedBox(width: 10),
              Expanded(child: actions[1]),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(width: double.infinity, child: actions[2]),
        ],
      );
    }

    if (actions.length == 2) {
      return Row(
        children: [
          Expanded(child: actions[0]),
          const SizedBox(width: 10),
          Expanded(child: actions[1]),
        ],
      );
    }

    if (actions.length == 1) {
      return SizedBox(width: double.infinity, child: actions.single);
    }

    return const SizedBox.shrink();
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
        color: context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        children: [
          Icon(
            AppIcons.inbox_outlined,
            color: context.colors.textTertiary,
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
            ),
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

ClientBookingOffer? _bestDriverRequestFromResponse(
  Map<String, dynamic> response,
) {
  final data = _chatAsMap(response['data']) ?? response;
  final dynamic items =
      data['requests'] ??
      data['driverRequests'] ??
      data['items'] ??
      data['results'] ??
      data['rows'] ??
      data['data'];
  if (items is! List) {
    return _firstRequestFromResponse(response);
  }
  final requests = items
      .whereType<Map<String, dynamic>>()
      .map(_bookingOfferFromMap)
      .where((request) => request.id.isNotEmpty)
      .toList(growable: false);
  if (requests.isEmpty) {
    return null;
  }
  for (final request in requests) {
    if (request.isActionableByClient) {
      return request;
    }
  }
  for (final request in requests) {
    if (request.normalizedStatus == 'accepted' ||
        request.normalizedStatus == 'countered') {
      return request;
    }
  }
  return requests.first;
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
        decoration: BoxDecoration(
          color: context.colors.surfaceElevated,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF2FA56E)),
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
