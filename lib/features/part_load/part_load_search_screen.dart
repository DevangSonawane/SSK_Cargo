// Part-Load client search — NEW standalone screen, duplicated (not reusing)
// full-truck FindTruck screens. Direct port of web PartLoadSearch.jsx:
// candidates -> pending -> accepted, resume-on-return, 5s poll + socket.
//
// Styling mirrors the full-truck client flow exactly: _BookingSummaryCard
// (surface/radius-20), _EligibleBrokerTile (surface/radius-18/avatar-44),
// _BrokerLoadingCard/_BrokerEmptyCard, _BookingWaitingCard (radius-24 +
// 96 spinner circle) and _BookingSuccessCard (radius-24 + 96 check circle).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/services/app_socket_service.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'part_load_api.dart';
import 'part_load_models.dart';

enum _PartLoadPhase { candidates, pending, accepted }

class PartLoadSearchScreen extends ConsumerStatefulWidget {
  const PartLoadSearchScreen({
    super.key,
    required this.bookingId,
    required this.bookingNumber,
    required this.pickup,
    required this.pickupLat,
    required this.pickupLng,
    required this.drop,
    required this.dropLat,
    required this.dropLng,
    required this.weightTons,
  });

  final String bookingId;
  final String bookingNumber;
  final String pickup;
  final double pickupLat;
  final double pickupLng;
  final String drop;
  final double dropLat;
  final double dropLng;
  final double weightTons;

  @override
  ConsumerState<PartLoadSearchScreen> createState() =>
      _PartLoadSearchScreenState();
}

class _PartLoadSearchScreenState extends ConsumerState<PartLoadSearchScreen> {
  _PartLoadPhase _phase = _PartLoadPhase.candidates;
  List<PartLoadTruck> _candidates = const [];
  bool _loading = true;
  bool _error = false;
  String? _requestingTruckId;
  PartLoadJoinRequest? _request;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  String get _token =>
      ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';

  @override
  void initState() {
    super.initState();
    _checkExisting();
    _listenSocket();
  }

  Future<void> _listenSocket() async {
    final token = _token;
    if (token.isEmpty) return;
    await ref.read(appSocketServiceProvider).ensureConnected(accessToken: token);
    _socketSub = ref
        .read(appSocketServiceProvider)
        .tripJoinRequestStream
        .listen(_onSocketPayload);
  }

  void _onSocketPayload(Map<String, dynamic> payload) {
    // Payload may be { request: {...} } / { data: { request } } or bare.
    Map<String, dynamic> req = payload;
    final data = payload['data'];
    if (data is Map) {
      final m = data.cast<String, dynamic>();
      if (m['request'] is Map) {
        req = (m['request'] as Map).cast<String, dynamic>();
      }
    } else if (payload['request'] is Map) {
      req = (payload['request'] as Map).cast<String, dynamic>();
    }
    final bookingId = (req['bookingId'] ?? req['booking_id'] ?? '').toString();
    if (bookingId.isNotEmpty && bookingId != widget.bookingId) return;
    try {
      _applyRequestUpdate(PartLoadJoinRequest.fromJson(req));
    } catch (_) {
      // Ignore malformed pushes; poll will correct.
    }
  }

  Future<void> _checkExisting() async {
    try {
      final existing = await ref.read(partLoadApiProvider).getRequestForBooking(
            accessToken: _token,
            bookingId: widget.bookingId,
          );
      if (!mounted) return;
      if (existing != null) {
        _applyRequestUpdate(existing, silentDeclined: true);
        return;
      }
    } catch (_) {
      // Fall through to fresh search.
    }
    await _fetchCandidates();
  }

  Future<void> _fetchCandidates() async {
    setState(() {
      _loading = true;
      _error = false;
    });
    try {
      final trucks =
          await ref.read(partLoadApiProvider).searchNearbyOnTrip(
                accessToken: _token,
                pickupLat: widget.pickupLat,
                pickupLng: widget.pickupLng,
                dropLat: widget.dropLat,
                dropLng: widget.dropLng,
                weightTons: widget.weightTons,
              );
      if (!mounted) return;
      setState(() {
        _candidates = trucks;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        final req =
            await ref.read(partLoadApiProvider).getRequestForBooking(
                  accessToken: _token,
                  bookingId: widget.bookingId,
                );
        if (req != null && mounted) _applyRequestUpdate(req);
      } catch (_) {
        // Next poll retries.
      }
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  void _applyRequestUpdate(PartLoadJoinRequest req,
      {bool silentDeclined = false}) {
    if (!mounted) return;
    setState(() => _request = req);
    if (req.isAccepted) {
      _stopPolling();
      setState(() => _phase = _PartLoadPhase.accepted);
    } else if (req.isDeclined) {
      _stopPolling();
      if (!silentDeclined && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('That driver declined — pick another truck.')),
        );
      }
      setState(() {
        _request = null;
        _phase = _PartLoadPhase.candidates;
      });
      _fetchCandidates();
    } else {
      setState(() => _phase = _PartLoadPhase.pending);
      _startPolling();
    }
  }

  Future<void> _requestTruck(PartLoadTruck c) async {
    if (c.currentTripId.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'That truck is no longer on a trip — pick another.',
          ),
        ),
      );
      await _fetchCandidates();
      return;
    }
    setState(() => _requestingTruckId = c.truckId);
    try {
      final req = await ref.read(partLoadApiProvider).requestTruck(
            accessToken: _token,
            bookingId: widget.bookingId,
            targetTripId: c.currentTripId,
          );
      if (!mounted) return;
      setState(() => _phase = _PartLoadPhase.pending);
      _applyRequestUpdate(req);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
      await _fetchCandidates();
    } finally {
      if (mounted) setState(() => _requestingTruckId = null);
    }
  }

  @override
  void dispose() {
    _stopPolling();
    _socketSub?.cancel();
    super.dispose();
  }

  /// Same exit as full-truck success cards: close this pushed layer, then
  /// go to a real route (pop first so imperative booking-flow layers
  /// beneath don't linger).
  void _exitTo(String location) {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(location);
      });
      return;
    }
    router.go(location);
  }

  Set<Marker> _markers() {
    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('pickup'),
        position: LatLng(widget.pickupLat, widget.pickupLng),
        infoWindow: InfoWindow(title: widget.pickup),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
      ),
    };
    for (final c in _candidates) {
      final lat = c.currentLat;
      final lng = c.currentLng;
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId('truck-${c.truckId}'),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(title: c.registration),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (_phase) {
      _PartLoadPhase.candidates => 'Pick a truck to share',
      _PartLoadPhase.pending => 'Waiting for the driver',
      _PartLoadPhase.accepted => l10n.bookingConfirmed,
    };
    // Web parity (PartLoadSearch.jsx): the radar ping runs through both
    // actively-searching phases, same as full-truck FindTruckSearch.
    final isActivelySearching = _phase == _PartLoadPhase.candidates ||
        _phase == _PartLoadPhase.pending;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Locked map behind everything — same shell as full-truck
            // FindTruckSearch's own map panel (pickup center, zoom 13).
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(widget.pickupLat, widget.pickupLng),
                  zoom: 13,
                ),
                markers: _markers(),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
            if (isActivelySearching)
              const Positioned.fill(
                child: IgnorePointer(
                  child: Center(child: _RadarPulse()),
                ),
              ),
            Positioned(
              top: 12,
              left: 18,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                customBorder: const CircleBorder(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(AppIcons.arrow_back_rounded, size: 18),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight:
                      MediaQuery.sizeOf(context).height * 0.62,
                ),
                decoration: BoxDecoration(
                  color: context.colors.surfaceElevated,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(
                    top: BorderSide(color: context.colors.line, width: 1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B1F3A).withValues(alpha: 0.14),
                      blurRadius: 28,
                      offset: const Offset(0, -10),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(18, 10, 18, 16 + bottomInset),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: context.colors.line,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.pickup} → ${widget.drop}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 14),
                      _PartLoadSummaryCard(
                        pickup: widget.pickup,
                        drop: widget.drop,
                        weightTons: widget.weightTons,
                        bookingNumber: widget.bookingNumber,
                      ),
                      const SizedBox(height: 14),
                      switch (_phase) {
                        _PartLoadPhase.candidates => _candidatesBody(),
                        _PartLoadPhase.pending => _pendingBody(),
                        _PartLoadPhase.accepted => _acceptedBody(),
                      },
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _candidatesBody() {
    if (_loading) {
      return const _PartLoadLoadingCard(
        message: 'Looking for trucks already heading your way...',
      );
    }
    if (_error) {
      return _PartLoadEmptyCard(
        icon: AppIcons.wifi_off_rounded,
        title: "Couldn't load nearby trucks.",
        message: 'Check your connection and try again.',
        actionLabel: 'Retry',
        onRetry: _fetchCandidates,
      );
    }
    if (_candidates.isEmpty) {
      return _PartLoadEmptyCard(
        icon: AppIcons.local_shipping_rounded,
        title: 'No trucks available to share right now',
        message:
            'Try again in a few minutes, or go back and book a dedicated truck instead.',
        actionLabel: 'Search Again',
        onRetry: _fetchCandidates,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: context.colors.brandFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.brandBorder),
          ),
          child: Row(
            children: [
              const Icon(
                AppIcons.verified_user_rounded,
                color: Color(0xFF2FA56E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_candidates.length} verified truck${_candidates.length == 1 ? '' : 's'} with spare capacity',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        for (var i = 0; i < _candidates.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          PartLoadCandidateTile(
            truck: _candidates[i],
            requesting: _requestingTruckId == _candidates[i].truckId,
            onRequest: () => _requestTruck(_candidates[i]),
          ),
        ],
      ],
    );
  }

  Widget _pendingBody() {
    final r = _request;
    final driverLine = (r?.truckReg.isNotEmpty ?? false)
        ? 'Waiting for ${(r!.driverName.isEmpty ? 'the driver' : r.driverName)} (${r.truckReg})'
        : 'Waiting for the driver to respond';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.brandBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colors.brandFill,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFF2FA56E),
                  ),
                ),
                Icon(
                  AppIcons.local_shipping_rounded,
                  color: Color(0xFF2FA56E),
                  size: 34,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            driverLine,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: context.colors.textPrimary,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'This screen updates automatically once they accept or decline.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
          ),
          if (r?.amount.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              'Price: ₹${r!.amount}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
          if (r?.driverTimedOut ?? false) ...[
            const SizedBox(height: 8),
            Text(
              'Driver timed out — waiting on their broker…',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _acceptedBody() {
    final l10n = AppLocalizations.of(context)!;
    final r = _request;
    final message =
        '${(r?.driverName.isEmpty ?? true) ? 'Your driver' : r!.driverName} will carry your load${(r?.truckReg.isNotEmpty ?? false) ? ' — truck ${r!.truckReg}' : ''}.';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: context.colors.canvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colors.brandFill,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              AppIcons.check_rounded,
              color: Color(0xFF2FA56E),
              size: 58,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Load Confirmed!',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: context.colors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            widget.bookingNumber.isEmpty
                ? 'Booking number pending'
                : widget.bookingNumber,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => context.go('/client/tracking'),
                  child: const Text('Track'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _exitTo('/client/home'),
                  child: Text(l10n.goToHome),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Route summary — same sizing as full-truck _BookingSummaryCard:
/// surface, radius 20, line border, dot timeline, fillSubtle inner boxes.
class _PartLoadSummaryCard extends StatelessWidget {
  const _PartLoadSummaryCard({
    required this.pickup,
    required this.drop,
    required this.weightTons,
    required this.bookingNumber,
  });

  final String pickup;
  final String drop;
  final double weightTons;
  final String bookingNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2FA56E),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE23A4B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickup,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$weightTons tons · Part Truck (shared)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    drop,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textPrimary,
                        ),
                  ),
                ),
                if (bookingNumber.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Booking: $bookingNumber',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.textSecondary,
                          fontSize: 11,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Candidate row — same sizing as _EligibleBrokerTile: radius 18,
/// padding 12/11, 44 avatar, meta pills, check-style action.
class PartLoadCandidateTile extends StatelessWidget {
  const PartLoadCandidateTile({
    super.key,
    required this.truck,
    required this.requesting,
    required this.onRequest,
  });

  final PartLoadTruck truck;
  final bool requesting;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final initials = truck.registration.trim().isEmpty
        ? 'T'
        : truck.registration.trim().split(RegExp(r'\s+')).take(2).map((p) {
            final chars = p.characters;
            return chars.isEmpty ? '' : chars.first.toUpperCase();
          }).join();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.045),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.colors.brandFill,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials.isEmpty ? 'T' : initials,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: context.colors.brandEmphasis,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${truck.registration} · ${truck.driverName.isEmpty ? 'Driver' : truck.driverName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: context.colors.textPrimary,
                      ),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (truck.distanceKm != null)
                      PartLoadMetaPill(
                        icon: AppIcons.location_on_rounded,
                        label:
                            '${truck.distanceKm!.toStringAsFixed(1)} km',
                      ),
                    if (truck.etaMinutes != null)
                      PartLoadMetaPill(
                        icon: AppIcons.schedule_rounded,
                        label: '~${truck.etaMinutes} min',
                      ),
                    PartLoadMetaPill(
                      icon: AppIcons.scale_rounded,
                      label: '${truck.spareTons} ton spare',
                      highlighted: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${truck.estimatedTotal.toStringAsFixed(truck.estimatedTotal % 1 == 0 ? 0 : 2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
              ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: requesting ? null : onRequest,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA56E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(requesting ? 'Requesting…' : 'Request'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PartLoadMetaPill extends StatelessWidget {
  const PartLoadMetaPill({
    super.key,
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color:
            highlighted ? context.colors.brandFill : context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlighted
                ? const Color(0xFF2FA56E)
                : context.colors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: highlighted
                      ? context.colors.brandEmphasis
                      : context.colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

/// Soft sonar ping while actively searching — exact duplicate of web
/// PartLoadSearch.jsx's RadarPulse (3 rings, 0.7s stagger, green dot with
/// white halo), same as full-truck FindTruckSearch.
class _RadarPulse extends StatefulWidget {
  const _RadarPulse();

  @override
  State<_RadarPulse> createState() => _RadarPulseState();
}

class _RadarPulseState extends State<_RadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < 3; i++)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, _) {
                final progress =
                    ((_controller.value * 2.1) - (i * 0.7)) % 1.0;
                final size = 16 + progress * 104;
                return Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2FA56E).withValues(
                      alpha: 0.4 * (1 - progress),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF2FA56E),
              boxShadow: [
                BoxShadow(color: Colors.white, spreadRadius: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Same sizing as _BrokerLoadingCard: brandFill, radius 18, brandBorder.
class _PartLoadLoadingCard extends StatelessWidget {
  const _PartLoadLoadingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.brandFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.brandBorder),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Same sizing as _BrokerEmptyCard: fillSubtle, radius 18, 42px icon box.
class _PartLoadEmptyCard extends StatelessWidget {
  const _PartLoadEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: context.colors.fillSubtle,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: context.colors.textSecondary, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
