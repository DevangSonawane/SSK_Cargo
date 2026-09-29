import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_trip_handoff_utils.dart';
import '../widgets/slide_to_confirm.dart';

/// Single-screen delivery-completion wizard, mirroring the React web app's
/// `DeliveryCompletionFlow.jsx` (Arrived -> Upload -> Payments? -> Complete).
///
/// Unlike the old route-hopping flow (delivery-proof -> payment ->
/// pod-waiting -> thank-you, where each screen fetched its own possibly
/// stale snapshot), everything here lives on one screen: the step is
/// derived from server state, the trip reloads live over the trip-status
/// socket, and the driver never leaves until the trip is closed.
class DriverDeliveryCompletionFlowScreen extends ConsumerStatefulWidget {
  const DriverDeliveryCompletionFlowScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<DriverDeliveryCompletionFlowScreen> createState() =>
      _DriverDeliveryCompletionFlowScreenState();
}

class _DriverDeliveryCompletionFlowScreenState
    extends ConsumerState<DriverDeliveryCompletionFlowScreen> {
  static const int _minMedia = 2;
  static const int _maxMedia = 6;
  static const Set<String> _paymentDue = {'pending', 'partial'};

  final _picker = ImagePicker();

  bool _loading = true;
  Map<String, dynamic> _trip = const {};
  String _step = 'arrived';
  bool _stepInitialized = false;
  bool _includePayments = false;

  // Upload step state.
  final List<_FlowMedia> _newMedia = [];
  bool _uploading = false;

  // Arrived step state.
  bool _confirmingArrival = false;

  // Payments step state.
  bool _collectingPayment = false;
  String _qrSource = 'personal';
  bool _creatingRazorpayQr = false;
  bool _razorpayQrError = false;
  bool _razorpayPaid = false;
  String? _razorpayQrImageUrl;
  Timer? _razorpayPollTimer;

  // Complete step state.
  bool _completing = false;
  String? _completeError;
  bool _completed = false;
  bool _autoRunDone = false;

  StreamSubscription<Map<String, dynamic>>? _tripSubscription;
  StreamSubscription<Map<String, dynamic>>? _paymentSubscription;
  Timer? _pollTimer;

  // ---- derived trip fields (web `adaptTrip` equivalents) ----

  String _str(List<String> keys) {
    for (final key in keys) {
      final value = _trip[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  String get _rawStatus => _str(const ['status']).toLowerCase();
  String get _paymentStatus => _str(const [
    'paymentStatus',
    'payment_status',
  ]).toLowerCase();
  String get _podStatus => _str(const [
    'podStatus',
    'pod_status',
  ]).toLowerCase();
  String get _podRejectionReason => _str(const [
    'podRejectionReason',
    'pod_rejection_reason',
    'podRejectReason',
  ]);

  int get _podMinRequired {
    final raw =
        _trip['podMinRequired']?.toString() ??
        _trip['pod_min_required']?.toString() ??
        '';
    final parsed = int.tryParse(raw) ?? _minMedia;
    return parsed >= _minMedia ? parsed : _minMedia;
  }

  List<_RemotePod> get _remoteMedia {
    final out = <_RemotePod>[];
    final candidates = <Object?>[
      _trip['podMedia'],
      _trip['pod_media'],
      _trip['podPhotos'],
      _trip['pod_photos'],
    ];
    for (final candidate in candidates) {
      if (candidate is! Iterable) continue;
      for (final item in candidate) {
        if (item is Map) {
          final json = item.cast<String, dynamic>();
          final url = _mapStr(json, const ['url', 'src', 'path']);
          if (url.isEmpty) continue;
          final type = _mapStr(json, const ['type', 'mediaType']);
          out.add(
            _RemotePod(
              url: url,
              isVideo: type.toLowerCase() == 'video',
            ),
          );
        } else {
          final url = item.toString().trim();
          if (url.isEmpty || url.toLowerCase() == 'null') continue;
          out.add(_RemotePod(url: url, isVideo: false));
        }
      }
      if (out.isNotEmpty) return out;
    }
    return out;
  }

  /// A rejected batch no longer counts (web parity).
  int get _effectiveRemoteCount =>
      _podStatus == 'rejected' ? 0 : _remoteMedia.length;
  int get _totalMediaCount => _effectiveRemoteCount + _newMedia.length;

  double? get _amountToCollect {
    final value = _trip['amountToCollect'] ?? _trip['amount_to_collect'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  String get _bookingRef {
    final ref = _str(const [
      'bookingNumber',
      'booking_number',
      'bookingRef',
      'booking_ref',
    ]);
    return ref.isNotEmpty ? ref : widget.tripId;
  }

  String get _dropLocation {
    final drop = _trip['drop'];
    if (drop is Map) {
      final label = _mapStr(
        drop.cast<String, dynamic>(),
        const ['location', 'address', 'name'],
      );
      if (label.isNotEmpty) return label;
    }
    return _str(const ['dropLocation', 'drop_location', 'dropAddress']);
  }

  String get _contactPhone {
    final drop = _trip['drop'];
    if (drop is Map) {
      final phone = _mapStr(
        drop.cast<String, dynamic>(),
        const ['contactPhone', 'contact_phone', 'phone'],
      );
      if (phone.isNotEmpty) return phone;
    }
    return _str(const ['clientPhone', 'client_phone', 'customerPhone']);
  }

  String get _contactName {
    final drop = _trip['drop'];
    if (drop is Map) {
      final name = _mapStr(
        drop.cast<String, dynamic>(),
        const ['contactPerson', 'contact_person', 'name'],
      );
      if (name.isNotEmpty) return name;
    }
    return _str(const ['clientName', 'client_name', 'customerName']);
  }

  String _mapStr(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  bool _readBool(List<String> keys) {
    for (final key in keys) {
      final value = _trip[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
    }
    return false;
  }

  // ---- lifecycle ----

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(driverActiveTripIdProvider.notifier).state = widget.tripId;
      unawaited(_startLiveUpdates());
      unawaited(_loadTrip());
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) unawaited(_loadTrip(silent: true));
      });
    });
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _paymentSubscription?.cancel();
    _pollTimer?.cancel();
    _razorpayPollTimer?.cancel();
    super.dispose();
  }

  /// Web `resolveInitialStep`: derive the step purely from server state so a
  /// fresh load (or app reopen) always lands in the right place. Only used
  /// for the first load — afterwards steps advance explicitly (web parity).
  String _resolveStepFrom(Map<String, dynamic> trip) {
    final status = _mapStr(trip, const ['status']).toLowerCase();
    if (status == 'completed') return 'complete';
    if (status != 'delivered') return 'arrived';
    final podStatus = _mapStr(trip, const [
      'podStatus',
      'pod_status',
    ]).toLowerCase();
    final count = _countRemote(trip);
    final minRequired =
        int.tryParse(
          trip['podMinRequired']?.toString() ??
              trip['pod_min_required']?.toString() ??
              '',
        ) ??
        _minMedia;
    if (podStatus == 'rejected' || count < minRequired) return 'upload';
    final payment = _mapStr(trip, const [
      'paymentStatus',
      'payment_status',
    ]).toLowerCase();
    if (_paymentDue.contains(payment)) return 'payments';
    return 'complete';
  }

  Future<void> _loadTrip({bool silent = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .getTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final trip = extractTripFromResponse(response) ?? response;
      if (!mounted) return;
      setState(() {
        _trip = trip;
        _loading = false;
        if (!_stepInitialized) {
          _stepInitialized = true;
          _includePayments = _paymentDue.contains(
            _mapStr(trip, const [
              'paymentStatus',
              'payment_status',
            ]).toLowerCase(),
          );
          _step = _resolveStepFrom(trip);
        }
        _razorpayPaid = _paymentStatus == 'paid' ? true : _razorpayPaid;
      });
      _afterTripUpdate();
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  int _countRemote(Map<String, dynamic> trip) {
    final podStatus = _mapStr(trip, const [
      'podStatus',
      'pod_status',
    ]).toLowerCase();
    if (podStatus == 'rejected') return 0;
    for (final key in const [
      'podMedia',
      'pod_media',
      'podPhotos',
      'pod_photos',
    ]) {
      final value = trip[key];
      if (value is Iterable) return value.length;
    }
    return 0;
  }

  /// Runs after every trip update: auto-complete once verified (web's
  /// `useEffect` on `[step, trip.podStatus]`), bounce a rejection back to
  /// upload, and advance past payments once paid.
  void _afterTripUpdate() {
    if (!mounted || !_stepInitialized) return;
    if (_rawStatus == 'completed' && !_completed) {
      setState(() => _completed = true);
      return;
    }
    if (_podStatus == 'rejected' && (_step == 'complete')) {
      setState(() => _step = 'upload');
      return;
    }
    if (_step == 'payments' &&
        !_paymentDue.contains(_paymentStatus) &&
        _paymentStatus.isNotEmpty) {
      setState(() => _step = 'complete');
    }
    if (_step == 'complete' &&
        _podStatus == 'verified' &&
        !_completed &&
        !_autoRunDone) {
      _autoRunDone = true;
      unawaited(_runCompletion());
    }
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) return;
    final sockets = ref.read(appSocketServiceProvider);
    await sockets.ensureConnected(accessToken: session.tokens.accessToken);
    if (!mounted) return;
    await _tripSubscription?.cancel();
    _tripSubscription = sockets.tripStatusStream.listen((payload) {
      if (!mounted) return;
      if (tripMatchesContext(payload, tripId: widget.tripId)) {
        unawaited(_loadTrip(silent: true));
        return;
      }
      final trip = _nestedTrip(payload);
      if (trip != null && tripMatchesContext(trip, tripId: widget.tripId)) {
        unawaited(_loadTrip(silent: true));
      }
    });
    await _paymentSubscription?.cancel();
    _paymentSubscription = sockets.bookingPaymentStream.listen((payload) {
      if (!mounted) return;
      if (tripMatchesContext(payload, tripId: widget.tripId)) {
        unawaited(_loadTrip(silent: true));
      }
    });
  }

  Map<String, dynamic>? _nestedTrip(Map<String, dynamic> payload) {
    for (final key in const ['trip', 'data']) {
      final nested = payload[key];
      if (nested is Map<String, dynamic> && key == 'trip') return nested;
      if (nested is Map) {
        final casted = nested.cast<String, dynamic>();
        if (casted['trip'] is Map) {
          return (casted['trip'] as Map).cast<String, dynamic>();
        }
      }
    }
    return null;
  }

  // ---- arrived ----

  Future<void> _confirmArrival() async {
    if (_confirmingArrival) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }
    setState(() => _confirmingArrival = true);
    try {
      await ref
          .read(apiClientProvider)
          .updateTripStatus(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
            status: 'delivered',
          );
      if (!mounted) return;
      await _loadTrip(silent: true);
      if (!mounted) return;
      setState(() => _step = 'upload');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _confirmingArrival = false);
    }
  }

  Future<void> _callContact() async {
    final number = _contactPhone.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contact phone number is not available.')),
      );
      return;
    }
    await launchUrl(
      Uri.parse('tel:$number'),
      mode: LaunchMode.externalApplication,
    );
  }

  // ---- upload ----

  Future<void> _pickImage(ImageSource source) async {
    if (_totalMediaCount >= _maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 6 proof-of-delivery items.'),
        ),
      );
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newMedia.add(
          _FlowMedia(bytes: bytes, fileName: picked.name, isVideo: false),
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open image picker: $error'),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    }
  }

  Future<void> _pickVideo() async {
    if (_totalMediaCount >= _maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can add up to 6 proof-of-delivery items.'),
        ),
      );
      return;
    }
    try {
      final picked = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 2),
      );
      if (picked == null || !mounted) return;
      final bytes = await picked.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newMedia.add(
          _FlowMedia(bytes: bytes, fileName: picked.name, isVideo: true),
        );
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video camera: $error'),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    }
  }

  Future<void> _submitPhotos() async {
    if (_totalMediaCount < _podMinRequired) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Add at least ${_podMinRequired - _totalMediaCount} more proof-of-delivery item(s).',
          ),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to upload delivery photos.'),
        ),
      );
      return;
    }
    // Nothing new picked but the server already holds enough (e.g. resume
    // after reopen) — move on without re-uploading.
    if (_newMedia.isEmpty) {
      setState(
        () => _step = _paymentDue.contains(_paymentStatus)
            ? 'payments'
            : 'complete',
      );
      _afterTripUpdate();
      return;
    }
    setState(() => _uploading = true);
    try {
      final files = _newMedia
          .map(
            (item) =>
                MultipartFile.fromBytes(item.bytes, filename: item.fileName),
          )
          .toList(growable: false);
      final response = await ref
          .read(apiClientProvider)
          .uploadTripPod(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
            files: files,
          );
      if (!mounted) return;
      final uploaded = extractTripFromResponse(response);
      if (uploaded != null) {
        setState(() {
          _trip = {..._trip, ...uploaded};
          _newMedia.clear();
        });
      } else {
        _newMedia.clear();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photos/videos uploaded.'),
          backgroundColor: AppColors.brand,
        ),
      );
      await _loadTrip(silent: true);
      if (!mounted) return;
      // A rejected batch never counted — stay put for a fresh batch.
      if (_podStatus == 'rejected') return;
      setState(
        () => _step = _paymentDue.contains(_paymentStatus)
            ? 'payments'
            : 'complete',
      );
      _afterTripUpdate();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  // ---- payments ----

  String get _driverUpiId => _str(const [
    'driverUpiId',
    'driver_upi_id',
    'upiId',
    'upi_id',
  ]);
  String get _driverName =>
      _str(const ['driverName', 'driver_name']).isNotEmpty
      ? _str(const ['driverName', 'driver_name'])
      : 'Driver';
  String get _companyUpiId =>
      _str(const ['companyUpiId', 'company_upi_id']);
  String get _companyUpiName {
    final name = _str(const ['companyUpiName', 'company_upi_name']);
    return name.isNotEmpty ? name : 'GadiDost Logistics';
  }

  String get _myQrUrl => _str(const [
    'driverQrCodeUrl',
    'driver_qr_code_url',
    'driverQrUrl',
    'driver_qr_url',
  ]);
  bool get _razorpayAvailable => _readBool(const [
    'razorpayQrAvailable',
    'razorpay_qr_available',
  ]);

  List<String> get _qrSources => [
    if (_driverUpiId.isNotEmpty) 'personal',
    if (_companyUpiId.isNotEmpty) 'company',
    if (_myQrUrl.isNotEmpty) 'mine',
    if (_razorpayAvailable) 'razorpay',
  ];

  String get _activeQrSource {
    final sources = _qrSources;
    if (sources.contains(_qrSource)) return _qrSource;
    return sources.isNotEmpty ? sources.first : 'personal';
  }

  String _upiIntent({required String upiId, required String payee}) {
    final amount = (_amountToCollect ?? 0).toStringAsFixed(2);
    final query = <String, String>{
      'pa': upiId,
      'pn': payee,
      'am': amount,
      'cu': 'INR',
      'tn': 'Payment for $_bookingRefSafe',
    }.entries
        .map((e) => '${e.key}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
    return 'upi://pay?$query';
  }

  String get _bookingRefSafe => _bookingRef;

  String _qrImageForIntent(String intent) {
    return Uri.https('chart.googleapis.com', '/chart', {
      'cht': 'qr',
      'chs': '220x220',
      'chl': intent,
    }).toString();
  }

  Future<void> _syncRazorpayQr() async {
    if (_activeQrSource != 'razorpay' ||
        !_razorpayAvailable ||
        _razorpayPaid ||
        _razorpayQrImageUrl != null ||
        _creatingRazorpayQr) {
      if (_razorpayQrImageUrl != null) _startRazorpayPolling();
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() {
      _creatingRazorpayQr = true;
      _razorpayQrError = false;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .createTripPaymentQr(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final data = response['data'];
      final map = data is Map<String, dynamic> ? data : response;
      final imageUrl = _mapStr(map, const ['imageUrl', 'image_url']);
      if (!mounted) return;
      setState(() {
        _razorpayQrImageUrl = imageUrl.isNotEmpty ? imageUrl : null;
        _razorpayQrError = imageUrl.isEmpty;
      });
      if (imageUrl.isNotEmpty) _startRazorpayPolling();
    } catch (_) {
      if (!mounted) return;
      setState(() => _razorpayQrError = true);
    } finally {
      if (mounted) setState(() => _creatingRazorpayQr = false);
    }
  }

  void _startRazorpayPolling() {
    if (_razorpayPollTimer != null) return;
    unawaited(_pollRazorpayQrStatus());
    _razorpayPollTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      _,
    ) {
      unawaited(_pollRazorpayQrStatus());
    });
  }

  void _stopRazorpayPolling() {
    _razorpayPollTimer?.cancel();
    _razorpayPollTimer = null;
  }

  Future<void> _pollRazorpayQrStatus() async {
    if (!mounted ||
        _activeQrSource != 'razorpay' ||
        _razorpayPaid ||
        _paymentDue.contains(_paymentStatus) == false) {
      _stopRazorpayPolling();
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getTripPaymentQrStatus(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final data = response['data'];
      final map = data is Map<String, dynamic> ? data : response;
      final paid = map['paid'] == true;
      if (!paid || !mounted) return;
      _stopRazorpayPolling();
      setState(() {
        _razorpayPaid = true;
        _trip = {..._trip, 'paymentStatus': 'paid'};
        _step = 'complete';
      });
      _afterTripUpdate();
    } catch (_) {
      // Transient poll failure — next tick recovers.
    }
  }

  Future<void> _collectPayment(String mode) async {
    if (_collectingPayment) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }
    setState(() => _collectingPayment = true);
    try {
      await ref
          .read(apiClientProvider)
          .collectTripPayment(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
            mode: mode,
          );
      if (!mounted) return;
      setState(() {
        _trip = {..._trip, 'paymentStatus': 'paid'};
        _step = 'complete';
      });
      _afterTripUpdate();
    } on ApiException catch (error) {
      if (!mounted) return;
      // Client paid online a moment ago (409) — nothing left to collect.
      if (error.message.toLowerCase().contains('already')) {
        setState(() {
          _trip = {..._trip, 'paymentStatus': 'paid'};
          _step = 'complete';
        });
        _afterTripUpdate();
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _collectingPayment = false);
    }
  }

  // ---- complete ----

  Future<void> _runCompletion() async {
    if (_completing || _completed) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() {
      _completing = true;
      _completeError = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .completeTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      if (!mounted) return;
      setState(() {
        _completing = false;
        _completed = true;
        _trip = {..._trip, 'status': 'completed'};
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      _autoRunDone = false;
      setState(() {
        _completing = false;
        _completeError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      _autoRunDone = false;
      setState(() {
        _completing = false;
        _completeError = error.toString();
      });
    }
  }

  void _exitToTrips() {
    ref.read(driverActiveTripIdProvider.notifier).state = null;
    ref.read(driverTripSessionProvider.notifier).state = null;
    context.go('/driver/home');
  }

  String _money(double amount) =>
      '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppIcons.arrow_back_rounded),
        ),
        title: Text(
          _bookingRef,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.divider),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _StepProgress(
                          current: _step,
                          includePayments: _includePayments,
                        ),
                        const SizedBox(height: 8),
                        if (_step == 'arrived') _buildArrived(),
                        if (_step == 'upload') _buildUpload(),
                        if (_step == 'payments') _buildPayments(),
                        if (_step == 'complete') _buildComplete(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildArrived() {
    final contactPhone = _contactPhone;
    final contactName = _contactName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (contactPhone.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _callContact,
              icon: const Icon(AppIcons.call_rounded, size: 16),
              label: Text(
                contactName.isNotEmpty
                    ? 'Call ${contactName.split(' ').first}'
                    : 'Call',
              ),
            ),
          ),
        const SizedBox(height: 8),
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.brandTint,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            AppIcons.location_on_rounded,
            color: AppColors.brand,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Reached the drop location?',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        if (_dropLocation.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            _dropLocation,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 24),
        SlideToConfirm(
          enabled: !_confirmingArrival,
          label: _confirmingArrival
              ? 'Confirming...'
              : 'Swipe to confirm arrival',
          onConfirmed: _confirmArrival,
        ),
      ],
    );
  }

  Widget _buildUpload() {
    final canSubmit = _totalMediaCount >= _podMinRequired && !_uploading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Upload Proof of Delivery',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Add photos or videos of the delivered cargo (at least $_podMinRequired)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        if (_podStatus == 'rejected') ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.dangerFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.dangerBorder),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  AppIcons.warning_amber_rounded,
                  color: AppColors.dangerIcon,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'The customer rejected your last upload',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.dangerText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _podRejectionReason.isNotEmpty
                            ? _podRejectionReason
                            : 'Please upload fresh photos of the delivered cargo.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.dangerText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in _remoteMedia)
              _ExistingTile(
                isVideo: item.isVideo,
                imageUrl: item.isVideo ? null : item.url,
                accessToken: ref
                    .read(authSessionProvider)
                    .valueOrNull
                    ?.tokens
                    .accessToken,
              ),
            for (var i = 0; i < _newMedia.length; i++)
              _NewTile(
                media: _newMedia[i],
                onRemove: _uploading
                    ? null
                    : () => setState(() => _newMedia.removeAt(i)),
              ),
            if (_totalMediaCount < _maxMedia)
              _AddTile(
                enabled: !_uploading,
                onPhotoCamera: () => _pickImage(ImageSource.camera),
                onPhotoGallery: () => _pickImage(ImageSource.gallery),
                onVideo: _pickVideo,
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _totalMediaCount < _podMinRequired
              ? 'Add at least ${_podMinRequired - _totalMediaCount} more to continue.'
              : '$_totalMediaCount of $_maxMedia added — ready to submit',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _totalMediaCount < _podMinRequired
                ? AppColors.warningText
                : AppColors.brand,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: canSubmit ? _submitPhotos : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brand,
              disabledBackgroundColor: AppColors.brand.withValues(alpha: 0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Submit Photos/Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPayments() {
    final amount = _amountToCollect ?? 0;
    final sources = _qrSources;
    final active = _activeQrSource;
    final upiId = active == 'company' ? _companyUpiId : _driverUpiId;
    final payee = active == 'company' ? _companyUpiName : _driverName;
    final intentQr = upiId.isNotEmpty && amount > 0
        ? _qrImageForIntent(_upiIntent(upiId: upiId, payee: payee))
        : null;
    final isPartial = _paymentStatus == 'partial';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Collect Payment',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isPartial
              ? 'The client already paid a 20% advance online — collect the remaining balance below.'
              : 'Payment for this delivery is still pending',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.fillSubtle,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              Text(
                isPartial
                    ? 'Remaining Balance to Collect'
                    : 'Amount to Collect',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _money(amount),
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        if (sources.length > 1) ...[
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              if (_driverUpiId.isNotEmpty)
                const ButtonSegment(value: 'personal', label: Text('Personal')),
              if (_companyUpiId.isNotEmpty)
                const ButtonSegment(value: 'company', label: Text('Company')),
              if (_myQrUrl.isNotEmpty)
                const ButtonSegment(value: 'mine', label: Text('My QR')),
              if (_razorpayAvailable)
                const ButtonSegment(value: 'razorpay', label: Text('Verified')),
            ],
            selected: {active},
            onSelectionChanged: (selection) {
              setState(() => _qrSource = selection.first);
              if (selection.first == 'razorpay') {
                unawaited(_syncRazorpayQr());
              } else {
                _stopRazorpayPolling();
              }
            },
          ),
        ],
        const SizedBox(height: 12),
        if (active == 'razorpay')
          _buildRazorpayQr()
        else if (active == 'mine')
          _QrImage(
            url: _myQrUrl,
            accessToken: ref
                .read(authSessionProvider)
                .valueOrNull
                ?.tokens
                .accessToken,
            label: 'Show this to collect ${_money(amount)}',
          )
        else if (intentQr != null)
          _QrImage(
            url: intentQr,
            accessToken: null,
            label: 'Scan to pay ${_money(amount)} via any UPI app',
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warningFill,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.warningBorder),
            ),
            child: const Text(
              'Add your UPI ID in Profile to show a scannable payment QR here next time.',
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 14),
        if (active != 'razorpay' || _razorpayPaid)
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _collectingPayment ? null : () => _collectPayment('upi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                _collectingPayment ? 'Confirming...' : 'Payment Received via UPI',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        if (active != 'razorpay' || _razorpayPaid) const SizedBox(height: 10),
        SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _collectingPayment ? null : () => _collectPayment('cash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _collectingPayment ? 'Recording…' : 'Collect Cash',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRazorpayQr() {
    if (_razorpayPaid) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.brandTint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.check_circle_rounded, color: AppColors.brand),
            SizedBox(width: 8),
            Text(
              'Payment verified by Razorpay',
              style: TextStyle(
                color: AppColors.brand,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }
    if (_razorpayQrError) {
      return const Text(
        'Couldn\'t generate the verified QR code — collect via UPI ID or cash instead.',
        textAlign: TextAlign.center,
      );
    }
    final url = _razorpayQrImageUrl;
    if (url == null || _creatingRazorpayQr) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }
    return _QrImage(
      url: url,
      accessToken: null,
      label: 'Auto-confirms the moment Razorpay verifies the payment',
    );
  }

  Widget _buildComplete() {
    if (_completed || _rawStatus == 'completed') {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.brandTint,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              AppIcons.check_circle_rounded,
              color: AppColors.brand,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Trip $_bookingRef has been completed successfully',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Payment and delivery marked complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _exitToTrips,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Back to Trips',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_podStatus == 'rejected') {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.dangerFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              AppIcons.warning_amber_rounded,
              color: AppColors.dangerIcon,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Proof of delivery rejected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _podRejectionReason.isNotEmpty
                ? _podRejectionReason
                : 'The customer asked for new photos.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 'upload'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Upload New Photos',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }
    if (_completeError != null) {
      return Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.dangerFill,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              AppIcons.warning_amber_rounded,
              color: AppColors.dangerIcon,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Couldn\'t complete the trip',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _completeError!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() => _completeError = null);
                _autoRunDone = false;
                unawaited(_runCompletion());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }
    // pending_verification (or no status yet) — wait for the client.
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.warningFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(
            AppIcons.schedule_rounded,
            color: AppColors.warningText,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _completing
              ? 'Finishing up...'
              : 'Waiting for the customer to review',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Your proof-of-delivery photos are up — this screen updates automatically the moment they respond.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        if (_completing) ...[
          const SizedBox(height: 20),
          const CircularProgressIndicator(),
        ],
      ],
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress({required this.current, required this.includePayments});

  final String current;
  final bool includePayments;

  @override
  Widget build(BuildContext context) {
    final steps = [
      _FlowStep('arrived', 'Arrived', AppIcons.location_on_rounded),
      _FlowStep('upload', 'Upload', AppIcons.photo_camera_rounded),
      if (includePayments)
        _FlowStep('payments', 'Payment', AppIcons.payments_rounded),
      _FlowStep('complete', 'Complete', AppIcons.check_circle_rounded),
    ];
    final currentIndex = steps.indexWhere((s) => s.key == current);
    // Fixed-width nodes + flexible connectors (web parity: node is
    // `flex-shrink-0`, line is `flex-1`). The old code gave nodes AND
    // connectors equal `Expanded` weight, so on narrow phones each label
    // got ~40px and "Arrived / Upload / Payment / Complete" overlapped.
    return LayoutBuilder(
      builder: (context, constraints) {
        const minLineWidth = 12.0;
        double nodeWidth =
            (constraints.maxWidth - (steps.length - 1) * minLineWidth) /
            steps.length;
        nodeWidth = nodeWidth.clamp(48.0, 68.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < steps.length; i++) ...[
              SizedBox(
                width: nodeWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: i < currentIndex
                            ? AppColors.brand
                            : i == currentIndex
                            ? AppColors.brand
                            : AppColors.fillSubtle,
                        shape: BoxShape.circle,
                        border: i == currentIndex
                            ? Border.all(
                                color: AppColors.brand.withValues(alpha: 0.25),
                                width: 4,
                              )
                            : null,
                      ),
                      child: Icon(
                        i < currentIndex
                            ? AppIcons.check_rounded
                            : steps[i].icon,
                        color: i <= currentIndex
                            ? Colors.white
                            : AppColors.textTertiary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: nodeWidth,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          steps[i].label,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: i == currentIndex
                                ? AppColors.textPrimary
                                : i < currentIndex
                                ? AppColors.brand
                                : AppColors.textTertiary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(
                      top: 17,
                      left: 4,
                      right: 4,
                    ),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i < currentIndex
                          ? AppColors.brand
                          : AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
            ],
          ],
        );
      },
    );
  }
}

class _FlowStep {
  const _FlowStep(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}

class _RemotePod {
  const _RemotePod({required this.url, required this.isVideo});

  final String url;
  final bool isVideo;
}

class _FlowMedia {
  const _FlowMedia({
    required this.bytes,
    required this.fileName,
    required this.isVideo,
  });

  final Uint8List bytes;
  final String fileName;
  final bool isVideo;
}

class _ExistingTile extends StatelessWidget {
  const _ExistingTile({
    required this.isVideo,
    required this.imageUrl,
    required this.accessToken,
  });

  final bool isVideo;
  final String? imageUrl;
  final String? accessToken;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!isVideo && imageUrl != null && accessToken != null)
              Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                headers: {'Authorization': 'Bearer $accessToken'},
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.brandTint,
                  child: const Icon(
                    AppIcons.check_circle_rounded,
                    color: AppColors.brand,
                    size: 34,
                  ),
                ),
              )
            else if (isVideo)
              Container(
                color: AppColors.textPrimary,
                child: const Center(
                  child: Icon(
                    AppIcons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              )
            else
              Container(
                color: AppColors.brandTint,
                child: const Center(
                  child: Icon(
                    AppIcons.check_circle_rounded,
                    color: AppColors.brand,
                    size: 34,
                  ),
                ),
              ),
            const Positioned(
              right: 6,
              bottom: 6,
              child: Icon(
                AppIcons.check_circle_rounded,
                color: AppColors.brand,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewTile extends StatelessWidget {
  const _NewTile({required this.media, required this.onRemove});

  final _FlowMedia media;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (media.isVideo)
              Container(
                color: AppColors.textPrimary,
                child: const Center(
                  child: Icon(
                    AppIcons.play_circle_fill_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              )
            else
              Image.memory(media.bytes, fit: BoxFit.cover),
            Positioned(
              top: 4,
              right: 4,
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.close_rounded,
                    color: Colors.white,
                    size: 14,
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

class _AddTile extends StatelessWidget {
  const _AddTile({
    required this.enabled,
    required this.onPhotoCamera,
    required this.onPhotoGallery,
    required this.onVideo,
  });

  final bool enabled;
  final VoidCallback onPhotoCamera;
  final VoidCallback onPhotoGallery;
  final VoidCallback onVideo;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 104,
      height: 104,
      child: InkWell(
        onTap: enabled
            ? () => showModalBottomSheet<void>(
                  context: context,
                  showDragHandle: true,
                  builder: (sheetContext) => SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              AppIcons.photo_camera_rounded,
                            ),
                            title: const Text('Take photo'),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onPhotoCamera();
                            },
                          ),
                          ListTile(
                            leading: const Icon(AppIcons.videocam_rounded),
                            title: const Text('Record video'),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onVideo();
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              AppIcons.photo_library_rounded,
                            ),
                            title: const Text('Choose photo'),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              onPhotoGallery();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.fillSubtle,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.brandBorder),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.add_rounded, color: AppColors.brand, size: 28),
              SizedBox(height: 4),
              Text(
                'More',
                style: TextStyle(
                  color: AppColors.brand,
                  fontSize: 11,
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

class _QrImage extends StatelessWidget {
  const _QrImage({
    required this.url,
    required this.accessToken,
    required this.label,
  });

  final String url;
  final String? accessToken;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 220,
          height: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
          ),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            headers: accessToken != null
                ? {'Authorization': 'Bearer $accessToken'}
                : null,
            errorBuilder: (_, _, _) => const Center(
              child: Icon(
                AppIcons.qr_code_rounded,
                color: AppColors.textSecondary,
                size: 56,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
