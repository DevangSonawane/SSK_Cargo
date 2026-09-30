import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_tokens.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_trip_handoff_utils.dart';

String _readTripString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

/// After POD upload + payment, the driver waits here until the client
/// approves the proof of delivery. Mirrors the web driver's `CompleteStep`
/// (`pending_verification` -> waiting screen, `rejected` -> re-upload,
/// `verified` -> auto `PATCH status=completed`).
class DriverPodWaitingScreen extends ConsumerStatefulWidget {
  const DriverPodWaitingScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<DriverPodWaitingScreen> createState() =>
      _DriverPodWaitingScreenState();
}

class _DriverPodWaitingScreenState
    extends ConsumerState<DriverPodWaitingScreen> {
  String _podStatus = '';
  String _rejectionReason = '';
  bool _loading = true;
  bool _completing = false;
  String? _completeError;
  bool _autoCompleted = false;
  StreamSubscription<Map<String, dynamic>>? _tripSubscription;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_startLiveUpdates());
      unawaited(_refreshTrip());
      _pollTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        if (mounted) unawaited(_refreshTrip(silent: true));
      });
    });
  }

  @override
  void dispose() {
    _tripSubscription?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) return;
    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );
    if (!mounted) return;
    await _tripSubscription?.cancel();
    _tripSubscription = socketService.tripStatusStream.listen((payload) {
      if (!mounted) return;
      final trip = _asTripMap(payload);
      if (trip != null && tripMatchesContext(trip, tripId: widget.tripId)) {
        _applyTrip(trip);
      } else if (_payloadMatchesTrip(payload)) {
        unawaited(_refreshTrip(silent: true));
      }
    });
  }

  Map<String, dynamic>? _asTripMap(Map<String, dynamic> payload) {
    for (final key in const ['trip', 'data']) {
      final nested = payload[key];
      if (nested is Map<String, dynamic>) {
        if (key == 'data' && nested['trip'] is Map) {
          return (nested['trip'] as Map).cast<String, dynamic>();
        }
        if (key == 'trip') return nested;
      }
      if (nested is Map) return nested.cast<String, dynamic>();
    }
    if (payload.containsKey('podStatus') ||
        payload.containsKey('pod_status') ||
        payload.containsKey('id')) {
      return payload;
    }
    return null;
  }

  bool _payloadMatchesTrip(Map<String, dynamic> payload) {
    final ids = <String>{
      _readTripString(payload, const ['id', 'tripId', 'trip_id']),
      _readTripString(payload, const ['bookingId', 'booking_id']),
      _readTripString(payload, const ['bookingNumber', 'booking_number']),
    }..removeWhere((v) => v.isEmpty);
    return ids.contains(widget.tripId);
  }

  Future<void> _refreshTrip({bool silent = false}) async {
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
      setState(() => _loading = false);
      _applyTrip(trip);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _applyTrip(Map<String, dynamic> trip) {
    final status = _readTripString(trip, const [
      'podStatus',
      'pod_status',
    ]).toLowerCase();
    final reason = _readTripString(trip, const [
      'podRejectionReason',
      'pod_rejection_reason',
      'podRejectReason',
    ]);
    final tripStatus = _readTripString(trip, const ['status']).toLowerCase();
    if (!mounted) return;
    // Trip already closed server-side (e.g. verified + auto-completed
    // elsewhere) — go straight to the thank-you screen.
    if (tripStatus == 'completed') {
      context.go('/driver/thank-you/${widget.tripId}');
      return;
    }
    setState(() {
      if (status.isNotEmpty) _podStatus = status;
      _rejectionReason = reason;
      _loading = false;
    });
    if (_podStatus == 'verified') {
      unawaited(_runCompletion());
    }
  }

  Future<void> _runCompletion() async {
    if (_completing || _autoCompleted) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    _autoCompleted = true;
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
      context.go('/driver/thank-you/${widget.tripId}');
    } on ApiException catch (error) {
      if (!mounted) return;
      // Backend still wants changes (e.g. re-upload after a race) — surface
      // the message with a retry instead of spinning forever.
      _autoCompleted = false;
      setState(() {
        _completing = false;
        _completeError = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      _autoCompleted = false;
      setState(() {
        _completing = false;
        _completeError = error.toString();
      });
    }
  }

  void _goReupload() {
    context.go('/driver/delivery-proof/${widget.tripId}');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isRejected = _podStatus == 'rejected';
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
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
                  child: Text(
                    l10n.podWaitingTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: CircularProgressIndicator(),
                    )
                  else if (isRejected) ...[
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
                      l10n.podWaitingRejectedTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _rejectionReason.isNotEmpty
                          ? _rejectionReason
                          : l10n.podWaitingNewPhotosFallback,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _goReupload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.podWaitingUploadNew,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ] else if (_completeError != null) ...[
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
                      l10n.podWaitingCouldNotComplete,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                          _autoCompleted = false;
                          unawaited(_runCompletion());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.podWaitingTryAgain,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
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
                          ? l10n.podWaitingFinishing
                          : l10n.podWaitingWaitingReview,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.podWaitingPhotosUp,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
