import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:receipt_printer/receipt_printer.dart';
import 'package:ssk/l10n/app_localizations.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/client_flow_widgets.dart';

int _toMinor(double rupees) {
  if (!rupees.isFinite || rupees <= 0) return 0;
  return (rupees * 100).round();
}

/// Invoice preview page: Classic Thermal receipt.
/// Pull the receipt down to download the PDF instead of tearing it.
class ClientInvoicePreviewScreen extends ConsumerStatefulWidget {
  const ClientInvoicePreviewScreen({super.key, required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  ConsumerState<ClientInvoicePreviewScreen> createState() =>
      _ClientInvoicePreviewScreenState();
}

class _ClientInvoicePreviewScreenState
    extends ConsumerState<ClientInvoicePreviewScreen> {
  static const MethodChannel _shareChannel = MethodChannel(
    'plugins.flutter.io/share',
  );

  late final ReceiptPrinterController _printerController;
  ReceiptPrinterStage _stage = ReceiptPrinterStage.processing;
  bool _isDownloading = false;
  Timer? _feedTimer;

  static const _preset = ReceiptPrinterPreset.classicThermal;

  @override
  void initState() {
    super.initState();
    _printerController = ReceiptPrinterController();
    // Start the feed only after the first frame (fonts/layout settled),
    // then flip to complete only after the full feed duration — flipping
    // mid-feed is what caused the visible jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _stage = ReceiptPrinterStage.printing);
      _feedTimer = Timer(
        _preset.shell.duration + const Duration(milliseconds: 350),
        () {
          if (mounted) {
            setState(() => _stage = ReceiptPrinterStage.complete);
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _feedTimer?.cancel();
    _printerController.dispose();
    super.dispose();
  }

  TrackingDemoShipment get _shipment => widget.shipment;

  Receipt _buildReceipt() {
    final s = _shipment;
    final totalMinor = _toMinor(s.amount);

    final packageName = s.packageName.trim().isEmpty
        ? 'Freight charges'
        : s.packageName.trim();

    return Receipt(
      title: 'SSK LOGISTICS',
      subtitle: s.trackingId.isEmpty
          ? (s.bookingId ?? 'Invoice')
          : 'Invoice • ${s.trackingId}',
      items: [
        ReceiptItem(
          title: packageName,
          unitPrice: totalMinor,
          quantityMillis: 1000,
          description:
              '${s.fromLocation} → ${s.toLocation}\nWeight: ${s.weight}',
        ),
      ],
      totals: [
        ReceiptTotal(label: 'Sub total', amount: totalMinor, emphasized: true),
      ],
      metadata: [
        ReceiptMetadata(
          label: 'Status',
          value: (s.bookingStatus ?? s.status).trim().isEmpty
              ? s.status
              : (s.bookingStatus ?? s.status),
        ),
        ReceiptMetadata(label: 'Payment', value: s.paymentStatus),
        if (s.customerName.trim().isNotEmpty)
          ReceiptMetadata(label: 'Customer', value: s.customerName.trim()),
      ],
      footer: 'Thank you for shipping with SSK.',
    );
  }

  Future<void> _handlePullToDownload() async {
    if (_isDownloading) return;
    // Let the tear/detach animation settle before the rebuild + network
    // call, otherwise the pull looks choppy.
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _isDownloading) return;
    await _downloadPdf();
  }

  Future<void> _downloadPdf() async {
    final l10n = AppLocalizations.of(context)!;
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _isDownloading = true);
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
        ).showSnackBar(SnackBar(content: Text(l10n.invoiceFileEmpty)));
        return;
      }
      final fileName =
          'invoice-${_shipment.trackingId.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')}.pdf';
      String? savedPath;
      try {
        savedPath =
            await _shareChannel.invokeMethod<String>('downloadFile', {
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
                ? l10n.invoiceDownloadedTo(savedPath)
                : sharedFallback
                    ? l10n.invoiceReadyToSaveOrShare
                    : l10n.invoiceDownloadFailed,
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
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  Future<void> _emailInvoice() async {
    final bookingId = _shipment.bookingId;
    if (bookingId == null || bookingId.isEmpty) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    final l10n = AppLocalizations.of(context)!;

    final toController = TextEditingController(text: session.user.email);
    final subjectController = TextEditingController(
      text: l10n.invoiceForBooking(_shipment.trackingId),
    );
    final messageController = TextEditingController(
      text: l10n.invoiceEmailMessage(_shipment.trackingId),
    );
    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(l10n.emailInvoice),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: toController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(labelText: l10n.to),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(labelText: l10n.subject),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(labelText: l10n.message),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.send),
            ),
          ],
        ),
      );
      if (shouldSend != true) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.invoiceEmailedSuccessfully)));
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

  @override
  Widget build(BuildContext context) {
    const preset = _preset;
    final receipt = _buildReceipt();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppIcons.arrow_back_rounded),
        ),
        title: Text(
          _shipment.trackingId.isEmpty
              ? 'Invoice'
              : 'Invoice • ${_shipment.trackingId}',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RepaintBoundary(
                child: Center(
                  child: ReceiptPrinter(
                    preset: preset,
                    controller: _printerController,
                    stage: _stage,
                    receiptTheme: preset.theme.copyWith(
                      titleStyle: preset.theme.titleStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                      totalStyle: preset.theme.totalStyle.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    interaction: ReceiptRipConfig(
                      enabled: _stage == ReceiptPrinterStage.complete,
                      grabArea: const ReceiptGrabArea.handle(),
                      physics: const ReceiptRipPhysics(
                        threshold: 72,
                        maxPull: 110,
                        spring: 300,
                        damping: 30,
                        detachDistance: 40,
                        duration: Duration(milliseconds: 260),
                      ),
                      showHint: false,
                      lineStyle: ReceiptRipLineStyle.hidden,
                      autoReset: true,
                      resetDelay: const Duration(seconds: 3),
                    ),
                    ripCallbacks: ReceiptRipCallbacks(
                      onRipped: _handlePullToDownload,
                    ),
                child: ReceiptView(
                  receipt: receipt,
                  formatter: ReceiptFormatter(
                    currency: '₹',
                    currencyPosition: ReceiptCurrencyPosition.prefix,
                    decimalDigits: 2,
                  ),
                  builders: ReceiptBuilders(
                    // Kill only the dotted rule above the total — emphasized
                    // totals keep their strong black rule regardless.
                    separatorBuilder: (_) => const SizedBox.shrink(),
                    // Keep the header's own dotted rule under the title.
                    headerBuilder: (context, receipt) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ReceiptHeader(receipt: receipt),
                        const ReceiptSeparator(),
                      ],
                    ),
                  ),
                ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton.icon(
                  onPressed: _isDownloading ? null : _downloadPdf,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.download_rounded, size: 18),
                  label: Text(
                    _isDownloading ? 'Downloading…' : 'Download PDF',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _emailInvoice,
                  icon: const Icon(AppIcons.mail_outline_rounded, size: 18),
                  label: const Text(
                    'Email invoice',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
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
