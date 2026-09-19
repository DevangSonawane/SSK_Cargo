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
  String? _bookingId;
  String _paymentStatus = 'pending';
  StreamSubscription<Map<String, dynamic>>? _paymentSubscription;

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
        if (_driverUpiId == null && _companyUpiId != null) {
          _qrSource = 'company';
        }
        _loadingTrip = false;
      });
      _setTripSession(
        tripId: widget.tripId,
        bookingId: _bookingId,
        paymentStatus: paymentStatus,
      );

      if (_paymentStatus == 'paid' && mounted) {
        unawaited(_finalizeTripAfterPayment());
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

  Future<void> _showPaymentModeSheet() async {
    if (_collectingPayment) return;

    final selectedMode = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(AppIcons.qr_code_rounded),
                    title: const Text('UPI'),
                    onTap: () => Navigator.of(sheetContext).pop('upi'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(AppIcons.payments_rounded),
                    title: const Text('Cash'),
                    onTap: () => Navigator.of(sheetContext).pop('cash'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selectedMode == null || !mounted) return;
    await _collectPayment(selectedMode);
  }

  @override
  Widget build(BuildContext context) {
    final amountToCollect = _amountToCollect == null
        ? '₹0'
        : _formatCurrency(_amountToCollect!);
    final hasPersonalUpi = _driverUpiId?.trim().isNotEmpty == true;
    final hasCompanyUpi = _companyUpiId?.trim().isNotEmpty == true;
    final activeQrSource = hasPersonalUpi && hasCompanyUpi
        ? _qrSource
        : hasCompanyUpi
        ? 'company'
        : 'personal';
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _PaymentRow(
                      label: 'Due from customer',
                      value: amountToCollect,
                      light: true,
                    ),
                  ),
                  const SizedBox(height: 6),
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
                    activeQrSource == 'company' ? 'Company QR' : 'Your QR here',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '100% money in your bank',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (hasPersonalUpi && hasCompanyUpi) ...[
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: 'personal',
                          icon: Icon(AppIcons.person_rounded),
                          label: Text('Personal'),
                        ),
                        ButtonSegment<String>(
                          value: 'company',
                          icon: Icon(AppIcons.apartment_rounded),
                          label: Text('Company'),
                        ),
                      ],
                      selected: {_qrSource},
                      style: SegmentedButton.styleFrom(
                        foregroundColor: Colors.white,
                        selectedForegroundColor: AppColors.textPrimary,
                        selectedBackgroundColor: Colors.white,
                      ),
                      onSelectionChanged: (selection) {
                        setState(() => _qrSource = selection.first);
                      },
                    ),
                    const SizedBox(height: 14),
                  ],
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
            Row(
              children: [
                const Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.line,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.line,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _collectingPayment ? null : _showPaymentModeSheet,
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
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({
    required this.label,
    required this.value,
    this.light = false,
  });

  final String label;
  final String value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final baseColor = light ? Colors.white : AppColors.textPrimary;
    final dimColor = light
        ? Colors.white.withValues(alpha: 0.82)
        : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: dimColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: baseColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
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
