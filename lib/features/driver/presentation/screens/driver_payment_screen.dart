import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class DriverPaymentScreen extends ConsumerStatefulWidget {
  const DriverPaymentScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<DriverPaymentScreen> createState() =>
      _DriverPaymentScreenState();
}

class _DriverPaymentScreenState extends ConsumerState<DriverPaymentScreen> {
  final _picker = ImagePicker();
  bool _loadingTrip = true;
  bool _savingQr = false;
  bool _collectingPayment = false;
  bool _finalizingTrip = false;
  double? _amountToCollect;
  String? _driverQrUrl;
  String? _driverUpiId;
  String? _driverName;
  String? _companyUpiId;
  String? _companyUpiName;
  String _qrSource = 'personal';
  bool _razorpayQrAvailable = false;
  String? _razorpayQrImageUrl;
  bool _creatingRazorpayQr = false;
  bool _razorpayQrError = false;
  bool _razorpayPaid = false;
  String? _bookingId;
  String _paymentStatus = 'pending';
  StreamSubscription<Map<String, dynamic>>? _paymentSubscription;
  Timer? _razorpayQrPollTimer;

  void _setTripSession({
    required String tripId,
    String? bookingId,
    String? paymentStatus,
  }) {
    final resolvedTripId = tripId.trim();
    if (resolvedTripId.isEmpty) {
      return;
    }

    final currentSession = ref.read(driverTripSessionProvider);
    ref.read(driverActiveTripIdProvider.notifier).state = resolvedTripId;
    ref.read(driverTripSessionProvider.notifier).state = DriverTripSession(
      tripId: resolvedTripId,
      bookingId: bookingId?.trim().isNotEmpty == true
          ? bookingId!.trim()
          : currentSession?.bookingId,
      bookingNumber: currentSession?.bookingNumber,
      status: currentSession?.status,
      paymentStatus: paymentStatus?.trim().isNotEmpty == true
          ? paymentStatus!.trim()
          : currentSession?.paymentStatus,
      updatedAt: DateTime.now(),
    );
  }

  void _clearTripSession() {
    ref.read(driverActiveTripIdProvider.notifier).state = null;
    ref.read(driverTripSessionProvider.notifier).state = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startLiveUpdates());
      unawaited(_loadTripState());
    });
  }

  @override
  void dispose() {
    _paymentSubscription?.cancel();
    _stopRazorpayPolling();
    super.dispose();
  }

  Future<void> _loadTripState() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final data = response['data'];
      final trip = data is Map<String, dynamic>
          ? (data['trip'] is Map<String, dynamic>
                ? data['trip'] as Map<String, dynamic>
                : data)
          : response;
      final paymentStatus = _readString(trip, const [
        'paymentStatus',
        'payment_status',
      ]).toLowerCase();
      final amountToCollect = trip['amountToCollect'];
      final driverQrUrl = _readString(trip, const [
        'driverQrUrl',
        'driver_qr_url',
      ]);
      final driverUpiId = _readString(trip, const [
        'driverUpiId',
        'driver_upi_id',
        'upiId',
        'upi_id',
      ]);
      final companyUpiId = _readString(trip, const [
        'companyUpiId',
        'company_upi_id',
      ]);
      final companyUpiName = _readString(trip, const [
        'companyUpiName',
        'company_upi_name',
      ]);
      final razorpayQrAvailable = _readBool(trip, const [
        'razorpayQrAvailable',
        'razorpay_qr_available',
      ]);
      final razorpayQrImageUrl = _readString(trip, const [
        'razorpayQrImageUrl',
        'razorpay_qr_image_url',
      ]);
      final razorpayQrStatus = _readString(trip, const [
        'razorpayQrStatus',
        'razorpay_qr_status',
      ]).toLowerCase();
      final hasPersonalUpi = driverUpiId.isNotEmpty;
      final hasCompanyUpi = companyUpiId.isNotEmpty;
      final defaultQrSource = hasPersonalUpi
          ? 'personal'
          : hasCompanyUpi
          ? 'company'
          : razorpayQrAvailable
          ? 'razorpay'
          : 'personal';

      if (!mounted) return;
      setState(() {
        _bookingId = _readString(trip, const [
          'bookingId',
          'booking_id',
          'id',
          'tripId',
          'trip_id',
        ]);
        _paymentStatus = paymentStatus.isNotEmpty
            ? paymentStatus
            : _paymentStatus;
        _amountToCollect = amountToCollect is num
            ? amountToCollect.toDouble()
            : double.tryParse(amountToCollect?.toString() ?? '');
        _driverQrUrl = driverQrUrl.isNotEmpty ? driverQrUrl : null;
        _driverUpiId = driverUpiId.isNotEmpty ? driverUpiId : null;
        _driverName = _readString(trip, const ['driverName', 'driver_name']);
        _companyUpiId = companyUpiId.isNotEmpty ? companyUpiId : null;
        _companyUpiName = companyUpiName.isNotEmpty ? companyUpiName : null;
        _razorpayQrAvailable = razorpayQrAvailable;
        _razorpayQrImageUrl =
            razorpayQrStatus == 'active' && razorpayQrImageUrl.isNotEmpty
            ? razorpayQrImageUrl
            : null;
        _razorpayQrError = false;
        _razorpayPaid = _paymentStatus == 'paid';
        _qrSource = defaultQrSource;
        _loadingTrip = false;
      });
      _setTripSession(
        tripId: widget.tripId,
        bookingId: _bookingId,
        paymentStatus: paymentStatus,
      );

      if (_paymentStatus == 'paid' && mounted) {
        unawaited(_finalizeTripAfterPayment());
      } else {
        unawaited(_syncRazorpayQrFlow());
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
    }
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );
    if (!mounted) {
      return;
    }

    await _paymentSubscription?.cancel();
    _paymentSubscription = socketService.bookingPaymentStream.listen((payload) {
      if (!mounted || !_matchesPaymentEvent(payload)) {
        return;
      }

      final status = _readPayloadString(payload, const [
        'paymentStatus',
        'payment_status',
        'status',
      ]).toLowerCase();
      final paymentMode = _readPayloadString(payload, const [
        'paymentMode',
        'payment_mode',
      ]);

      setState(() {
        if (status.isNotEmpty) {
          _paymentStatus = status;
        }
      });

      if (_paymentStatus == 'paid' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              paymentMode.isNotEmpty
                  ? 'Payment marked as ${paymentMode.toUpperCase()}.'
                  : 'Payment marked as paid.',
            ),
            backgroundColor: AppColors.brand,
          ),
        );
        unawaited(_finalizeTripAfterPayment());
      }
    });
  }

  Future<void> _finalizeTripAfterPayment() async {
    if (_finalizingTrip) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    setState(() => _finalizingTrip = true);
    try {
      await ref
          .read(apiClientProvider)
          .completeTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      if (!mounted) return;
      _clearTripSession();
      context.go('/driver/thank-you/${widget.tripId}');
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
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _finalizingTrip = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
  }

  String _buildUpiIntent({
    required String upiId,
    required String payeeName,
    required double amount,
    required String note,
  }) {
    final query =
        <String, String>{
              'pa': upiId,
              'pn': payeeName,
              'am': amount.toStringAsFixed(2),
              'cu': 'INR',
              'tn': note,
            }.entries
            .map((entry) {
              return '${entry.key}=${Uri.encodeQueryComponent(entry.value)}';
            })
            .join('&');
    return 'upi://pay?$query';
  }

  String _buildQrImageUrl(String value) {
    return Uri.https('chart.googleapis.com', '/chart', {
      'cht': 'qr',
      'chs': '220x220',
      'chl': value,
    }).toString();
  }

  Future<void> _uploadQrCode() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to upload your QR code.'),
        ),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    setState(() => _savingQr = true);
    try {
      await ref
          .read(apiClientProvider)
          .uploadDriverPaymentQr(
            accessToken: session.tokens.accessToken,
            filePath: picked.path,
          );
      if (!mounted) return;
      await _loadTripState();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment QR uploaded successfully.'),
          backgroundColor: AppColors.brand,
        ),
      );
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
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _savingQr = false);
      }
    }
  }

  Future<void> _syncRazorpayQrFlow() async {
    if (!mounted ||
        _qrSource != 'razorpay' ||
        !_razorpayQrAvailable ||
        _razorpayPaid ||
        _paymentStatus == 'paid') {
      _stopRazorpayPolling();
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    if (_razorpayQrImageUrl == null && !_creatingRazorpayQr) {
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
        final data = _responseData(response);
        final imageUrl = _readString(data, const ['imageUrl', 'image_url']);
        if (!mounted || _qrSource != 'razorpay') return;
        setState(() {
          _razorpayQrImageUrl = imageUrl.isNotEmpty ? imageUrl : null;
          _razorpayQrError = imageUrl.isEmpty;
        });
      } on ApiException catch (_) {
        if (!mounted) return;
        setState(() => _razorpayQrError = true);
        return;
      } catch (_) {
        if (!mounted) return;
        setState(() => _razorpayQrError = true);
        return;
      } finally {
        if (mounted) {
          setState(() => _creatingRazorpayQr = false);
        }
      }
    }

    if (_razorpayQrImageUrl != null) {
      _startRazorpayPolling();
    }
  }

  void _startRazorpayPolling() {
    if (_razorpayQrPollTimer != null) {
      return;
    }
    unawaited(_pollRazorpayQrStatus());
    _razorpayQrPollTimer = Timer.periodic(const Duration(milliseconds: 3500), (
      _,
    ) {
      unawaited(_pollRazorpayQrStatus());
    });
  }

  void _stopRazorpayPolling() {
    _razorpayQrPollTimer?.cancel();
    _razorpayQrPollTimer = null;
  }

  Future<void> _pollRazorpayQrStatus() async {
    if (!mounted ||
        _qrSource != 'razorpay' ||
        !_razorpayQrAvailable ||
        _razorpayPaid ||
        _paymentStatus == 'paid') {
      _stopRazorpayPolling();
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getTripPaymentQrStatus(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final data = _responseData(response);
      if (!_readBool(data, const ['paid']) || !mounted) {
        return;
      }
      _stopRazorpayPolling();
      setState(() {
        _razorpayPaid = true;
        _paymentStatus = 'paid';
      });
      _setTripSession(
        tripId: widget.tripId,
        bookingId: _bookingId,
        paymentStatus: 'paid',
      );
      unawaited(_finalizeTripAfterPayment());
    } catch (_) {
      // Polling failures are treated as transient; the next tick can recover.
    }
  }

  Future<void> _collectPayment(String mode) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to record payment.'),
        ),
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
      if (mounted) {
        setState(() {
          _paymentStatus = 'paid';
        });
      }
      await ref
          .read(apiClientProvider)
          .completeTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment recorded as ${mode.toUpperCase()}.'),
          backgroundColor: AppColors.brand,
        ),
      );
      context.go('/driver/thank-you/${widget.tripId}');
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
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _collectingPayment = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountToCollect = _amountToCollect == null
        ? '₹0'
        : _formatCurrency(_amountToCollect!);
    final hasPersonalUpi = _driverUpiId?.trim().isNotEmpty == true;
    final hasCompanyUpi = _companyUpiId?.trim().isNotEmpty == true;
    final hasRazorpayQr = _razorpayQrAvailable;
    final availableQrSources = <String>[
      if (hasPersonalUpi) 'personal',
      if (hasCompanyUpi) 'company',
      if (hasRazorpayQr) 'razorpay',
    ];
    final activeQrSource = availableQrSources.contains(_qrSource)
        ? _qrSource
        : (availableQrSources.isNotEmpty
              ? availableQrSources.first
              : 'personal');
    final activeUpiId = activeQrSource == 'company'
        ? _companyUpiId
        : _driverUpiId;
    final activePayeeName = activeQrSource == 'company'
        ? (_companyUpiName?.trim().isNotEmpty == true
              ? _companyUpiName!.trim()
              : 'GadiDost Logistics')
        : (_driverName?.trim().isNotEmpty == true
              ? _driverName!.trim()
              : 'Driver');
    final generatedQrUrl =
        activeUpiId?.trim().isNotEmpty == true && (_amountToCollect ?? 0) > 0
        ? _buildQrImageUrl(
            _buildUpiIntent(
              upiId: activeUpiId!.trim(),
              payeeName: activePayeeName,
              amount: _amountToCollect!,
              note: 'Payment for ${_bookingId ?? widget.tripId}',
            ),
          )
        : null;
    final razorpayTabActiveUnpaid =
        activeQrSource == 'razorpay' && !_razorpayPaid;
    final canSelfReportUpi =
        !razorpayTabActiveUnpaid &&
        activeQrSource != 'razorpay' &&
        (activeUpiId?.trim().isNotEmpty == true ||
            _driverQrUrl?.trim().isNotEmpty == true);
    final hasAdvance = _paymentStatus == 'partial';
    final paymentStatusLabel = _paymentStatus == 'paid'
        ? 'Paid'
        : hasAdvance
        ? 'Advance paid - balance due'
        : 'Payment pending';
    final paymentStatusBackground = _paymentStatus == 'paid'
        ? Colors.white.withValues(alpha: 0.18)
        : Colors.black.withValues(alpha: 0.16);
    final paymentStatusForeground = Colors.white;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      AppIcons.arrow_back_rounded,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Collect payment',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _bookingId ?? widget.tripId,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_loadingTrip) ...[
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: AppColors.divider,
                color: AppColors.brand,
              ),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.brandDark, AppColors.brand],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brand.withValues(alpha: 0.28),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          hasAdvance
                              ? 'Remaining balance to collect'
                              : 'Amount to collect from the customer',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.85),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: paymentStatusBackground,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Text(
                          paymentStatusLabel,
                          style: TextStyle(
                            color: paymentStatusForeground,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    amountToCollect,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    hasAdvance
                        ? 'An advance has already been paid for this delivery.'
                        : 'Share your QR or collect cash to complete the payment.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.brandDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    switch (activeQrSource) {
                      'company' => 'Company QR',
                      'razorpay' => 'Verified QR',
                      _ => 'Your QR here',
                    },
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeQrSource == 'razorpay'
                        ? 'Auto-confirmed by Razorpay'
                        : '100% money in your bank',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (availableQrSources.length > 1) ...[
                    SegmentedButton<String>(
                      segments: [
                        if (hasPersonalUpi)
                          const ButtonSegment<String>(
                            value: 'personal',
                            icon: Icon(AppIcons.person_rounded),
                            label: Text('Personal'),
                          ),
                        if (hasCompanyUpi)
                          const ButtonSegment<String>(
                            value: 'company',
                            icon: Icon(AppIcons.apartment_rounded),
                            label: Text('Company'),
                          ),
                        if (hasRazorpayQr)
                          const ButtonSegment<String>(
                            value: 'razorpay',
                            icon: Icon(AppIcons.shield_rounded),
                            label: Text('Verified'),
                          ),
                      ],
                      selected: {activeQrSource},
                      style: SegmentedButton.styleFrom(
                        foregroundColor: Colors.white,
                        selectedForegroundColor: AppColors.textPrimary,
                        selectedBackgroundColor: Colors.white,
                      ),
                      onSelectionChanged: (selection) {
                        final source = selection.first;
                        setState(() => _qrSource = source);
                        if (source == 'razorpay') {
                          unawaited(_syncRazorpayQrFlow());
                        } else {
                          _stopRazorpayPolling();
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
                  if (activeQrSource == 'razorpay')
                    _RazorpayQrView(
                      imageUrl: _razorpayQrImageUrl,
                      loading: _creatingRazorpayQr,
                      error: _razorpayQrError,
                      paid: _razorpayPaid,
                      amount: amountToCollect,
                    )
                  else
                    _QrPlaceholder(
                      qrUrl: generatedQrUrl ?? _driverQrUrl,
                      accessToken: ref
                          .read(authSessionProvider)
                          .valueOrNull
                          ?.tokens
                          .accessToken,
                      requiresAuth: generatedQrUrl == null,
                      centerIcon: activeQrSource == 'company'
                          ? AppIcons.apartment_rounded
                          : AppIcons.person_rounded,
                    ),
                  const SizedBox(height: 16),
                  if (activeQrSource != 'razorpay')
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _savingQr ? null : _uploadQrCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _savingQr
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '+ Add your QR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (canSelfReportUpi) ...[
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _collectingPayment
                      ? null
                      : () => _collectPayment('upi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.brand.withValues(
                      alpha: 0.55,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: _collectingPayment
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(AppIcons.qr_code_rounded, size: 20),
                  label: Text(
                    _collectingPayment
                        ? 'Confirming...'
                        : 'Payment Received via UPI',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _collectingPayment
                    ? null
                    : () => _collectPayment('cash'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.textPrimary,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.7),
                  side: const BorderSide(color: AppColors.line),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                icon: _collectingPayment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(AppIcons.payments_rounded, size: 20),
                label: Text(
                  _collectingPayment ? 'Recording…' : 'Collect Cash',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _matchesPaymentEvent(Map<String, dynamic> payload) {
    final bookingIds = <String>{
      _bookingId ?? '',
      widget.tripId,
      _readPayloadString(payload, const ['bookingId', 'booking_id']),
      _readPayloadString(payload, const ['bookingNumber', 'booking_number']),
    }..removeWhere((value) => value.trim().isEmpty);

    final eventBookingId = _readPayloadString(payload, const [
      'bookingId',
      'booking_id',
    ]);
    final eventBookingNumber = _readPayloadString(payload, const [
      'bookingNumber',
      'booking_number',
    ]);
    final eventTripId = _readPayloadString(payload, const [
      'tripId',
      'trip_id',
    ]);

    return bookingIds.contains(eventBookingId) ||
        bookingIds.contains(eventBookingNumber) ||
        bookingIds.contains(eventTripId);
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

  String _readPayloadString(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  bool _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') {
        return true;
      }
      if (text == 'false' || text == '0' || text == 'no') {
        return false;
      }
    }
    return false;
  }

  Map<String, dynamic> _responseData(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return response;
  }
}

class _RazorpayQrView extends StatelessWidget {
  const _RazorpayQrView({
    required this.imageUrl,
    required this.loading,
    required this.error,
    required this.paid,
    required this.amount,
  });

  final String? imageUrl;
  final bool loading;
  final bool error;
  final bool paid;
  final String amount;

  @override
  Widget build(BuildContext context) {
    if (paid) {
      return Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.check_circle_rounded,
              color: AppColors.successText,
              size: 42,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Payment verified by Razorpay',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    }

    if (error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Text(
          'Could not generate the verified QR code. Collect via UPI ID or cash instead.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.white,
            height: 1.4,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Column(
      children: [
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final frameSize = (constraints.maxWidth - 36).clamp(240.0, 300.0);
            return GestureDetector(
              onTap: imageUrl == null || loading
                  ? null
                  : () => _showQrZoom(context, imageUrl!),
              child: Stack(
                children: [
                  Container(
                    width: frameSize,
                    height: frameSize,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: imageUrl == null || loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: AppColors.brand,
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              imageUrl!,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    AppIcons.qr_code_rounded,
                                    color: AppColors.textSecondary,
                                    size: 56,
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                  if (imageUrl != null && !loading)
                    Positioned(
                      right: 10,
                      bottom: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.zoom_in_rounded,
                              size: 13,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Tap to enlarge',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.warningFill,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: AppColors.warningText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              const Text(
                'Waiting for payment...',
                style: TextStyle(
                  color: AppColors.warningText,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Fullscreen QR viewer so the code is unmissable at scan time.
void _showQrZoom(BuildContext context, String imageUrl) {
  final side = MediaQuery.of(context).size.width * 0.86;
  showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.78),
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: side,
            height: side,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, _, _) => const Center(
                  child: Icon(
                    AppIcons.qr_code_rounded,
                    color: AppColors.textSecondary,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text(
              'Close',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    ),
  );
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({
    this.qrUrl,
    this.accessToken,
    this.requiresAuth = true,
    this.centerIcon = AppIcons.person_rounded,
  });

  final String? qrUrl;
  final String? accessToken;
  final bool requiresAuth;
  final IconData centerIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.brandDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (qrUrl != null && (!requiresAuth || accessToken != null))
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  qrUrl!,
                  fit: BoxFit.cover,
                  headers: requiresAuth
                      ? {'Authorization': 'Bearer $accessToken'}
                      : null,
                  errorBuilder: (context, error, stackTrace) {
                    return const _QrPattern();
                  },
                ),
              ),
            )
          else
            const Positioned.fill(child: _QrPattern()),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.warningBorder, width: 3),
            ),
            child: Icon(centerIcon, color: AppColors.warningText, size: 28),
          ),
        ],
      ),
    );
  }
}

class _QrPattern extends StatelessWidget {
  const _QrPattern();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final isDark = (index % 2 == 0) ^ ((index ~/ 8) % 2 == 0);
          final accent = (index % 7 == 0) || (index % 11 == 0);
          return Container(
            decoration: BoxDecoration(
              color: accent
                  ? Colors.white
                  : isDark
                  ? AppColors.textTertiary
                  : AppColors.brandDark,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}
