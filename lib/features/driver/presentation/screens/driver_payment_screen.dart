import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/providers/driver_location_tracker_provider.dart';

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
  double? _amountToCollect;
  String? _driverQrUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(driverLocationTrackerProvider).setActiveTripId(widget.tripId);
      unawaited(_loadTripState());
    });
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
      final trip = data is Map<String, dynamic> ? data : response;
      final paymentStatus = trip['paymentStatus']
          ?.toString()
          .trim()
          .toLowerCase();
      final amountToCollect = trip['amountToCollect'];
      final driverQrUrl = trip['driverQrUrl']?.toString();

      if (!mounted) return;
      setState(() {
        _amountToCollect = amountToCollect is num
            ? amountToCollect.toDouble()
            : double.tryParse(amountToCollect?.toString() ?? '');
        _driverQrUrl = driverQrUrl != null && driverQrUrl.isNotEmpty
            ? driverQrUrl
            : null;
        _loadingTrip = false;
      });

      if (paymentStatus == 'paid' && mounted) {
        context.go('/driver/thank-you/${widget.tripId}');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
    }
  }

  String _formatCurrency(double amount) {
    return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
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
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
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
          backgroundColor: const Color(0xFF2FA56E),
        ),
      );
      context.go('/driver/thank-you/${widget.tripId}');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
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
                    leading: const Icon(Icons.qr_code_rounded),
                    title: const Text('UPI'),
                    onTap: () => Navigator.of(sheetContext).pop('upi'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.payments_rounded),
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
    const paidToWallet = '₹40.30';
    const orderValue = '₹101.00';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF101828),
        elevation: 0,
        title: const Text(
          'Payments',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD0D5DD)),
              ),
              child: const Icon(Icons.support_agent_rounded, size: 18),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: const Text('Help'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF101828),
                side: const BorderSide(color: Color(0xFFD0D5DD)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          children: [
            if (_loadingTrip) ...[
              const LinearProgressIndicator(
                minHeight: 2,
                backgroundColor: Color(0xFFE8EDF2),
                color: Color(0xFF1F88C9),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Amount to be collected',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              amountToCollect,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: const Color(0xFF2FA56E),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FB),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _PaymentRow(
                    label: 'Collect from customer',
                    value: amountToCollect,
                  ),
                  const SizedBox(height: 10),
                  _PaymentRow(label: 'Paid to wallet', value: paidToWallet),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _PaymentRow(label: 'Order Value', value: orderValue),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF171A23),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Text(
                    'Your QR here',
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
                  _QrPlaceholder(
                    qrUrl: _driverQrUrl,
                    accessToken: ref
                        .read(authSessionProvider)
                        .valueOrNull
                        ?.tokens
                        .accessToken,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _savingQr ? null : _uploadQrCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3F73E0),
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
                    color: Color(0xFFD0D5DD),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xFFD0D5DD),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _collectingPayment ? null : _showPaymentModeSheet,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF101828),
                  side: const BorderSide(color: Color(0xFFD0D5DD)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: _collectingPayment
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Text(
                        'Collect Cash',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentRow extends StatelessWidget {
  const _PaymentRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  const _QrPlaceholder({this.qrUrl, this.accessToken});

  final String? qrUrl;
  final String? accessToken;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2230),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (qrUrl != null && accessToken != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  qrUrl!,
                  fit: BoxFit.cover,
                  headers: {'Authorization': 'Bearer $accessToken'},
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
              border: Border.all(color: const Color(0xFFF2D28B), width: 3),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Color(0xFFCA8A04),
              size: 28,
            ),
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
                  ? const Color(0xFF707784)
                  : const Color(0xFF2A2F3E),
              borderRadius: BorderRadius.circular(3),
            ),
          );
        },
      ),
    );
  }
}
