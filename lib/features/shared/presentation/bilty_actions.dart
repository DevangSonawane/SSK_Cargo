import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Bilty (Lorry Receipt) actions shared by the client and broker booking
/// screens. The Bilty is the transporter's goods receipt — a separate
/// document from the GST invoice — and the backend already auto-emails it to
/// the client when a trip is marked Delivered. These are the manual
/// download / resend actions (web BookingDetail parity).

const MethodChannel _shareChannel = MethodChannel('plugins.flutter.io/share');

/// Same gate as the invoice: the Bilty exists once the trip is delivered.
bool isBiltyReady(String? bookingStatus) => const {
  'delivered',
  'completed',
  'paid',
  'settled',
}.contains(bookingStatus?.trim().toLowerCase());

void _snack(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? Theme.of(context).colorScheme.error : null,
    ),
  );
}

/// The PDF endpoint streams bytes, so a JSON error body arrives as bytes too.
String? _messageFromBytesError(DioException error) {
  final data = error.response?.data;
  try {
    final decoded = data is List<int> ? jsonDecode(utf8.decode(data)) : data;
    if (decoded is Map && decoded['message'] is String) {
      final message = (decoded['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
  } catch (_) {}
  return null;
}

Future<void> downloadBookingBilty({
  required BuildContext context,
  required WidgetRef ref,
  required String bookingId,
  required String bookingRef,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final session = ref.read(authSessionProvider).valueOrNull;
  if (bookingId.isEmpty || session == null) return;

  try {
    final response = await ref
        .read(apiClientProvider)
        .getBookingBilty(
          accessToken: session.tokens.accessToken,
          id: bookingId,
        );
    final bytes = response.data ?? const <int>[];
    if (!context.mounted) return;
    if (bytes.isEmpty) {
      _snack(context, l10n.biltyFileEmpty, error: true);
      return;
    }
    final refText = bookingRef.replaceFirst('#', '');
    final fileName =
        'bilty-${refText.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')}.pdf';
    String savedPath = '';
    try {
      savedPath =
          await _shareChannel.invokeMethod<String>('downloadFile', {
            'bytes': Uint8List.fromList(bytes),
            'fileName': fileName,
            'mimeType': 'application/pdf',
          }) ??
          '';
    } catch (_) {
      savedPath = '';
    }
    var sharedFallback = false;
    if (savedPath.isEmpty) {
      try {
        sharedFallback =
            await _shareChannel.invokeMethod<bool>('shareFile', {
              'bytes': Uint8List.fromList(bytes),
              'fileName': fileName,
              'mimeType': 'application/pdf',
              'subject': l10n.biltyForBooking(refText),
            }) ??
            false;
      } catch (_) {
        sharedFallback = false;
      }
    }
    if (!context.mounted) return;
    if (savedPath.isNotEmpty) {
      _snack(context, l10n.biltyDownloadedTo(savedPath));
    } else if (sharedFallback) {
      _snack(context, l10n.biltyReadyToSaveOrShare);
    } else {
      _snack(context, l10n.biltyDownloadFailed, error: true);
    }
  } on DioException catch (error) {
    if (!context.mounted) return;
    _snack(
      context,
      _messageFromBytesError(error) ?? l10n.biltyDownloadFailed,
      error: true,
    );
  } catch (_) {
    if (!context.mounted) return;
    _snack(context, l10n.biltyDownloadFailed, error: true);
  }
}

/// Always emails the client's own address on file — there is no compose step.
Future<void> resendBookingBilty({
  required BuildContext context,
  required WidgetRef ref,
  required String bookingId,
  required String successMessage,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final session = ref.read(authSessionProvider).valueOrNull;
  if (bookingId.isEmpty || session == null) return;

  try {
    await ref
        .read(apiClientProvider)
        .sendBookingBilty(
          accessToken: session.tokens.accessToken,
          id: bookingId,
        );
    if (!context.mounted) return;
    _snack(context, successMessage);
  } on ApiException catch (error) {
    if (!context.mounted) return;
    _snack(
      context,
      error.message.isEmpty ? l10n.biltySendFailed : error.message,
      error: true,
    );
  } catch (_) {
    if (!context.mounted) return;
    _snack(context, l10n.biltySendFailed, error: true);
  }
}
