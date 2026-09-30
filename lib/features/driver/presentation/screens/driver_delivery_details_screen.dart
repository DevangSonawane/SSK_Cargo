import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_location_tracker_provider.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/services/driver_external_navigation_service.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../../../shared/data/trip_route_stop.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../../../shared/presentation/widgets/halting_timer_card.dart';
import '../../data/driver_dashboard_models.dart';
import '../../data/driver_trip_handoff_utils.dart';
import '../../../chat/presentation/widgets/booking_chat_view.dart';
import '../widgets/slide_to_confirm.dart';

class _TripStop {
  const _TripStop({
    required this.index,
    required this.type,
    required this.location,
    required this.status,
  });

  final int index;
  final String type;
  final String location;
  final String status;

  bool get done => status == 'done' || status == 'completed';
  bool get loading => type == 'loading';
  String label(AppLocalizations l10n) =>
      loading ? l10n.deliveryDetailsLoadingPoint : l10n.deliveryDetailsUnloadingPoint;
  String actionLabel(AppLocalizations l10n) =>
      loading ? l10n.markLoaded : l10n.markUnloaded;

  factory _TripStop.fromJson({
    required int index,
    required Map<String, dynamic> json,
  }) {
    String read(List<String> keys) {
      for (final key in keys) {
        final value = json[key]?.toString().trim();
        if (value != null &&
            value.isNotEmpty &&
            value.toLowerCase() != 'null') {
          return value;
        }
      }
      return '';
    }

    return _TripStop(
      index: index,
      type: read(const ['type']).toLowerCase(),
      location: read(const ['location', 'address']),
      status: read(const ['status']).toLowerCase(),
    );
  }
}

class _TripStopTile extends StatelessWidget {
  const _TripStopTile({
    required this.stop,
    required this.actionableIndex,
    required this.completing,
    required this.onComplete,
  });

  final _TripStop stop;
  final int actionableIndex;
  final bool completing;
  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context) {
    final actionable = stop.index == actionableIndex;
    final color = stop.loading ? AppColors.warningText : AppColors.dangerIcon;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stop.done ? AppColors.brandTint : AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: stop.done ? AppColors.brandBorder : AppColors.fillSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            stop.done
                ? AppIcons.check_circle_rounded
                : stop.loading
                ? AppIcons.inventory_2_outlined
                : AppIcons.inventory_2_rounded,
            color: stop.done ? AppColors.brand : color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stop.label(AppLocalizations.of(context)!),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stop.location.isEmpty ? '—' : stop.location,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          if (!stop.done) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: actionable && !completing ? onComplete : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                disabledBackgroundColor: AppColors.line,
                minimumSize: const Size(0, 38),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: completing
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      stop.actionLabel(AppLocalizations.of(context)!),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}

class DriverDeliveryDetailsScreen extends ConsumerStatefulWidget {
  const DriverDeliveryDetailsScreen({
    super.key,
    this.tripId = '',
    this.bookingId,
  });

  final String tripId;
  final String? bookingId;

  @override
  ConsumerState<DriverDeliveryDetailsScreen> createState() =>
      _DriverDeliveryDetailsScreenState();
}

class _DriverDeliveryDetailsScreenState
    extends ConsumerState<DriverDeliveryDetailsScreen>
    with WidgetsBindingObserver {
  bool _showArrivalSwipe = false;
  bool _arrivalFlowActive = false;
  bool _detailsPanelExpanded = true;
  bool _loadingTrip = true;
  bool _confirmingArrival = false;
  bool _decliningTrip = false;
  int? _completingStopIndex;
  String _tripStatus = 'confirmed';
  String _customerName = 'Customer';
  String _customerPhone = '';
  String _dropLocation = 'Drop location not provided';
  TrackingDemoShipment? _shipment;
  Map<String, dynamic> _tripRaw = const <String, dynamic>{};
  String? _resolvedBookingId;
  Timer? _tripRefreshTimer;
  StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;
  bool _loadingTripInFlight = false;
  String? _resolvedTripId;
  bool _awaitingOverlayPermission = false;

  String get _tripId => _resolvedTripId?.trim().isNotEmpty == true
      ? _resolvedTripId!.trim()
      : widget.tripId.trim();

  String get _bookingId => _resolvedBookingId?.trim().isNotEmpty == true
      ? _resolvedBookingId!.trim()
      : widget.bookingId?.trim() ?? '';

  void _setTripSession({
    required String tripId,
    String? bookingId,
    String? bookingNumber,
    String? status,
    String? paymentStatus,
  }) {
    final resolvedTripId = tripId.trim();
    if (resolvedTripId.isEmpty) {
      return;
    }

    ref.read(driverActiveTripIdProvider.notifier).state = resolvedTripId;
    ref.read(driverTripSessionProvider.notifier).state = DriverTripSession(
      tripId: resolvedTripId,
      bookingId: bookingId?.trim().isNotEmpty == true
          ? bookingId!.trim()
          : null,
      bookingNumber: bookingNumber?.trim().isNotEmpty == true
          ? bookingNumber!.trim()
          : null,
      status: status?.trim().isNotEmpty == true ? status!.trim() : null,
      paymentStatus: paymentStatus?.trim().isNotEmpty == true
          ? paymentStatus!.trim()
          : null,
    );
  }

  void _clearTripSession() {
    ref.read(driverActiveTripIdProvider.notifier).state = null;
    ref.read(driverTripSessionProvider.notifier).state = null;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final initialTripId = widget.tripId.trim();
    if (initialTripId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _setTripSession(tripId: initialTripId);
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadTrip());
      unawaited(_startLiveUpdates());
      _tripRefreshTimer?.cancel();
      _tripRefreshTimer = Timer.periodic(const Duration(seconds: 12), (_) {
        if (mounted) {
          unawaited(_loadTrip());
        }
      });
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tripRefreshTimer?.cancel();
    _tripStatusSubscription?.cancel();
    unawaited(DriverExternalNavigationService.hideBubble());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // User is back from system Settings after the overlay permission prompt:
    // continue automatically instead of making them tap the menu again.
    if (state == AppLifecycleState.resumed && _awaitingOverlayPermission) {
      _awaitingOverlayPermission = false;
      unawaited(_continueAfterOverlaySettings());
    }
  }

  Future<void> _continueAfterOverlaySettings() async {
    if (!mounted) return;
    final granted = await DriverExternalNavigationService.hasBubblePermission();
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Floating button is still off. Opening Maps without it — '
            'you can enable it later from the menu.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
    }
    await _openMapsDirect();
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

    await _tripStatusSubscription?.cancel();
    _tripStatusSubscription = socketService.tripStatusStream.listen((payload) {
      if (!mounted || !_matchesTripStatusPayload(payload)) {
        return;
      }
      unawaited(_loadTrip());
    });
  }

  bool _matchesTripStatusPayload(Map<String, dynamic> payload) {
    final currentTripId = _tripId;
    final bookingId = _bookingId;
    if (currentTripId.isEmpty && bookingId.isEmpty) {
      return false;
    }

    return tripMatchesContext(
      payload,
      bookingId: bookingId,
      tripId: currentTripId,
    );
  }

  Future<void> _loadTrip() async {
    if (_loadingTripInFlight) {
      return;
    }

    _loadingTripInFlight = true;
    try {
      final session = ref.read(authSessionProvider).valueOrNull;
      if (session == null) {
        if (!mounted) return;
        setState(() => _loadingTrip = false);
        return;
      }

      final api = ref.read(apiClientProvider);
      var tripId = _tripId;
      if (tripId.isEmpty && _bookingId.isNotEmpty) {
        final bookingResponse = await api.getBookingById(
          accessToken: session.tokens.accessToken,
          id: _bookingId,
        );
        final bookingData = bookingResponse['data'];
        final booking = bookingData is Map<String, dynamic>
            ? (bookingData['booking'] is Map<String, dynamic>
                  ? bookingData['booking'] as Map<String, dynamic>
                  : bookingData)
            : bookingResponse;
        tripId = _readString(booking, const ['tripId', 'trip_id']);
        if (tripId.isEmpty) {
          final requestResponse = await api.getDriverRequestByBooking(
            accessToken: session.tokens.accessToken,
            bookingId: _bookingId,
          );
          final requestData = requestResponse['data'];
          final request = requestData is Map<String, dynamic>
              ? (requestData['request'] is Map<String, dynamic>
                    ? requestData['request'] as Map<String, dynamic>
                    : requestData)
              : requestResponse;
          tripId = _readString(request, const ['tripId', 'trip_id']);
        }

        if (tripId.isEmpty) {
          final activeResponse = await api.getActiveTrip(
            accessToken: session.tokens.accessToken,
          );
          final activeTrip = extractTripFromResponse(activeResponse);
          if (activeTrip != null &&
              tripMatchesContext(
                activeTrip,
                bookingId: _bookingId,
                bookingNumber: _readString(booking, const [
                  'bookingNumber',
                  'booking_number',
                ]),
              )) {
            tripId = extractTripId(activeTrip);
          }
        }

        if (tripId.isEmpty) {
          if (!mounted) return;
          setState(() => _loadingTrip = true);
          return;
        }

        if (mounted) {
          _resolvedTripId = tripId;
          _setTripSession(
            tripId: tripId,
            bookingId: _bookingId,
            bookingNumber: _readString(booking, const [
              'bookingNumber',
              'booking_number',
            ]),
          );
        }
      }

      final response = await api.getTrip(
        accessToken: session.tokens.accessToken,
        tripId: tripId,
      );
      final data = response['data'];
      final trip = data is Map<String, dynamic>
          ? (data['trip'] is Map<String, dynamic>
                ? data['trip'] as Map<String, dynamic>
                : data)
          : response;
      if (!mounted) return;
      final resolvedTripId = _readString(trip, const [
        'id',
        'tripId',
        'trip_id',
      ]);
      final tripBooking = _readMap(trip, const ['booking']);
      final resolvedBookingId =
          _readString(trip, const ['bookingId', 'booking_id']).isNotEmpty
          ? _readString(trip, const ['bookingId', 'booking_id'])
          : _readString(tripBooking, const ['id', 'bookingId', 'booking_id']);
      if (resolvedBookingId.isNotEmpty) {
        _resolvedBookingId = resolvedBookingId;
      }
      if (resolvedTripId.isNotEmpty) {
        _resolvedTripId = resolvedTripId;
        _setTripSession(
          tripId: resolvedTripId,
          bookingId: _bookingId,
          bookingNumber: _readString(trip, const [
            'bookingNumber',
            'booking_number',
          ]),
          status: _readString(trip, const ['status', 'rawStatus']),
          paymentStatus: _readString(trip, const [
            'paymentStatus',
            'payment_status',
          ]),
        );
      }

      setState(() {
        _shipment = _shipmentFromTrip(AppLocalizations.of(context)!, trip);
        _tripRaw = trip;
        final incomingStatus = _normalizeTripStatus(
          _readString(trip, const ['status', 'rawStatus']),
        );
        if (_mayApplyTripStatus(_tripStatus, incomingStatus)) {
          _tripStatus = incomingStatus;
        } else {
          developer.log(
            'Ignoring stale trip snapshot status=$incomingStatus current=$_tripStatus.',
            name: 'driver.deliveryDetails',
          );
        }
        final loadedCustomerName = _readString(trip, const [
          'clientName',
          'customerName',
          'customer_name',
        ]);
        if (loadedCustomerName.isNotEmpty) {
          _customerName = loadedCustomerName;
        }
        final loadedCustomerPhone = _readString(trip, const [
          'clientPhone',
          'customerPhone',
          'customer_phone',
        ]);
        if (loadedCustomerPhone.isNotEmpty) {
          _customerPhone = loadedCustomerPhone;
        }
        final loadedDrop = _readLocation(trip, const [
          'drop',
          'dropLocation',
          'dropoffLocation',
          'destination',
        ]);
        if (loadedDrop.isNotEmpty) {
          _dropLocation = loadedDrop;
        }
        _loadingTrip = false;
      });

      if (_tripStatus == 'completed' || _tripStatus == 'cancelled') {
        _clearTripSession();
        unawaited(DriverExternalNavigationService.hideBubble());
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
    } finally {
      _loadingTripInFlight = false;
    }
  }

  /// Publishes a fresh tracking point without ever blocking a trip action.
  /// The live 3s stream already covers tracking; this is best-effort with a
  /// deadline so a satellite hunt can never stall the driver's tap.
  void _publishLocationInBackground() {
    unawaited(
      ref
          .read(driverLocationTrackerProvider)
          .refreshCurrentLocation()
          .timeout(const Duration(seconds: 8))
          .then((String? error) {
            if (error != null) {
              developer.log(
                'Background location publish skipped: $error',
                name: 'driver.deliveryDetails',
              );
            }
          })
          .catchError((Object error) {
            developer.log(
              'Background location publish failed: $error',
              name: 'driver.deliveryDetails',
            );
          }),
    );
  }

  Future<void> _advanceTripStatus() async {
    final l10n = AppLocalizations.of(context)!;
    final nextStatus = _nextStatusForCurrentTrip();
    if (nextStatus == null) return;
    if (nextStatus == 'picked_up') {
      await _showPickupOtpPrompt();
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final stopwatch = Stopwatch()..start();
    developer.log(
      'Primary trip action started. tripId=$_tripId nextStatus=$nextStatus loadingTrip=$_loadingTrip confirmingArrival=$_confirmingArrival',
      name: 'driver.deliveryDetails',
    );
    if (_tripId.isEmpty) {
      developer.log(
        'Trip id missing before status update, reloading trip first.',
        name: 'driver.deliveryDetails',
      );
      await _loadTrip();
      if (!mounted || _tripId.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.tripStillSyncing)));
        return;
      }
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signInAgainToContinue)));
      return;
    }

    if (!mounted) return;
    setState(() => _loadingTrip = true);

    // Fire-and-forget: the status update must not wait on a satellite fix.
    _publishLocationInBackground();

    try {
      developer.log(
        'Sending trip status update to backend. tripId=$_tripId status=$nextStatus',
        name: 'driver.deliveryDetails',
      );
      final apiStopwatch = Stopwatch()..start();
      final response = await ref
          .read(apiClientProvider)
          .updateTripStatus(
            accessToken: session.tokens.accessToken,
            tripId: _tripId,
            status: nextStatus,
          );
      apiStopwatch.stop();
      developer.log(
        'Backend returned trip status update in ${apiStopwatch.elapsedMilliseconds}ms for tripId=$_tripId status=$nextStatus',
        name: 'driver.deliveryDetails',
      );
      final data = response['data'];
      final trip = data is Map<String, dynamic>
          ? (data['trip'] is Map<String, dynamic>
                ? data['trip'] as Map<String, dynamic>
                : data)
          : response;
      if (!mounted) return;

      final updatedStatus = _normalizeTripStatus(
        _readString(trip, const ['status', 'rawStatus']),
      );
      final resolvedStatus = updatedStatus.isNotEmpty
          ? updatedStatus
          : nextStatus;

      _resolvedTripId = _readString(trip, const ['id', 'tripId', 'trip_id']);
      if (_resolvedTripId?.trim().isNotEmpty == true) {
        _setTripSession(
          tripId: _resolvedTripId!,
          bookingId: _bookingId,
          bookingNumber: _readString(trip, const [
            'bookingNumber',
            'booking_number',
          ]),
          status: resolvedStatus,
          paymentStatus: _readString(trip, const [
            'paymentStatus',
            'payment_status',
          ]),
        );
      }

      setState(() {
        _tripRaw = trip;
        _shipment = _shipmentFromTrip(AppLocalizations.of(context)!, trip);
        _tripStatus = resolvedStatus;
        _loadingTrip = false;
        if (resolvedStatus == 'en_route_pickup') {
          _arrivalFlowActive = false;
          _showArrivalSwipe = false;
          _detailsPanelExpanded = true;
        }
      });
      ref.invalidate(driverDashboardProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_statusChangeMessageFor(AppLocalizations.of(context)!, resolvedStatus)),
          backgroundColor: AppColors.brand,
          duration: const Duration(seconds: 2),
        ),
      );
      developer.log(
        'Primary trip action completed. tripId=$_tripId resolvedStatus=$resolvedStatus totalElapsedMs=${stopwatch.elapsedMilliseconds}',
        name: 'driver.deliveryDetails',
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      developer.log(
        'Primary trip action failed with ApiException after ${stopwatch.elapsedMilliseconds}ms: ${error.message}',
        name: 'driver.deliveryDetails',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingTrip = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      developer.log(
        'Primary trip action failed after ${stopwatch.elapsedMilliseconds}ms: $error',
        name: 'driver.deliveryDetails',
      );
    }
  }

  Future<void> _completeStop(int index) async {
    final l10n = AppLocalizations.of(context)!;
    if (_completingStopIndex != null) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.signInAgainToContinue)),
      );
      return;
    }
    if (_tripId.isEmpty) {
      await _loadTrip();
      if (!mounted || _tripId.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.tripStillSyncing)));
        return;
      }
    }

    setState(() => _completingStopIndex = index);
    // Fire-and-forget: completing a stop must not wait on a satellite fix.
    _publishLocationInBackground();
    try {
      final response = await ref
          .read(apiClientProvider)
          .completeTripStop(
            accessToken: session.tokens.accessToken,
            tripId: _tripId,
            index: index,
          );
      final data = response['data'];
      final trip = data is Map<String, dynamic>
          ? (data['trip'] is Map<String, dynamic>
                ? data['trip'] as Map<String, dynamic>
                : data)
          : response;
      if (!mounted) return;
      setState(() {
        _tripRaw = trip;
        _shipment = _shipmentFromTrip(AppLocalizations.of(context)!, trip);
        final updatedStatus = _normalizeTripStatus(
          _readString(trip, const ['status', 'rawStatus']),
        );
        if (updatedStatus.isNotEmpty) {
          _tripStatus = updatedStatus;
        }
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.stopMarkedComplete),
          backgroundColor: AppColors.brand,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _completingStopIndex = null);
      }
    }
  }

  Future<void> _showPickupOtpPrompt() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PickupOtpDialog(onSubmit: _submitPickupOtp),
    );
  }

  Future<String?> _submitPickupOtp(String pickupOtp) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final stopwatch = Stopwatch()..start();
    developer.log(
      'Pickup OTP confirmation started. tripId=$_tripId',
      name: 'driver.deliveryDetails',
    );
    if (_tripId.isEmpty) {
      await _loadTrip();
      if (_tripId.isEmpty) {
        return l10n.tripStillSyncing;
      }
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return l10n.deliveryDetailsSignInToContinue;
    }

    setState(() => _loadingTrip = true);

    // Fire-and-forget: OTP verification must not wait on a satellite fix.
    _publishLocationInBackground();

    try {
      developer.log(
        'Sending pickup OTP status update to backend. tripId=$_tripId',
        name: 'driver.deliveryDetails',
      );
      final apiStopwatch = Stopwatch()..start();
      final response = await ref
          .read(apiClientProvider)
          .updateTripStatus(
            accessToken: session.tokens.accessToken,
            tripId: _tripId,
            status: 'picked_up',
            pickupOtp: pickupOtp,
          );
      apiStopwatch.stop();
      developer.log(
        'Backend returned pickup OTP status update in ${apiStopwatch.elapsedMilliseconds}ms for tripId=$_tripId',
        name: 'driver.deliveryDetails',
      );
      final data = response['data'];
      final trip = data is Map<String, dynamic>
          ? (data['trip'] is Map<String, dynamic>
                ? data['trip'] as Map<String, dynamic>
                : data)
          : response;
      if (!mounted) return null;

      final updatedStatus = _normalizeTripStatus(
        _readString(trip, const ['status', 'rawStatus']),
      );
      final resolvedStatus = updatedStatus.isNotEmpty
          ? updatedStatus
          : 'picked_up';

      _resolvedTripId = _readString(trip, const ['id', 'tripId', 'trip_id']);
      if (_resolvedTripId?.trim().isNotEmpty == true) {
        _setTripSession(
          tripId: _resolvedTripId!,
          bookingId: _bookingId,
          bookingNumber: _readString(trip, const [
            'bookingNumber',
            'booking_number',
          ]),
          status: resolvedStatus,
          paymentStatus: _readString(trip, const [
            'paymentStatus',
            'payment_status',
          ]),
        );
      }

      setState(() {
        _tripRaw = trip;
        _shipment = _shipmentFromTrip(AppLocalizations.of(context)!, trip);
        _tripStatus = resolvedStatus;
        _loadingTrip = false;
        _detailsPanelExpanded = true;
      });
      ref.invalidate(driverDashboardProvider);

      messenger.showSnackBar(
        SnackBar(
          content: Text(_statusChangeMessageFor(AppLocalizations.of(context)!, resolvedStatus)),
          backgroundColor: AppColors.brand,
          duration: const Duration(seconds: 2),
        ),
      );
      developer.log(
        'Pickup OTP confirmation completed. tripId=$_tripId resolvedStatus=$resolvedStatus totalElapsedMs=${stopwatch.elapsedMilliseconds}',
        name: 'driver.deliveryDetails',
      );
      return null;
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _loadingTrip = false);
      }
      developer.log(
        'Pickup OTP confirmation failed with ApiException after ${stopwatch.elapsedMilliseconds}ms: ${error.message}',
        name: 'driver.deliveryDetails',
      );
      return error.message;
    } catch (error) {
      if (mounted) {
        setState(() => _loadingTrip = false);
      }
      developer.log(
        'Pickup OTP confirmation failed after ${stopwatch.elapsedMilliseconds}ms: $error',
        name: 'driver.deliveryDetails',
      );
      return error.toString();
    }
  }

  String? _nextStatusForCurrentTrip() {
    switch (_tripStatus) {
      case 'confirmed':
      case 'assigned':
      case 'accepted':
      case 'active':
      case 'live':
      case 'ongoing':
      case 'started':
      case 'on_route':
      case 'en_route':
      case 'route_to_pickup':
      case 'to_pickup':
        return 'en_route_pickup';
      case 'en_route_pickup':
        return 'picked_up';
      case 'picked_up':
        return 'in_transit';
      case 'in_transit':
        return 'delivered';
      case 'delivered':
      case 'completed':
      case 'paid':
      case 'settled':
      case 'cancelled':
      case 'canceled':
      case 'rejected':
      case 'declined':
        return null;
      default:
        return 'en_route_pickup';
    }
  }

  String _actionLabelForCurrentTrip(AppLocalizations l10n) {
    switch (_tripStatus) {
      case 'confirmed':
      case 'assigned':
      case 'accepted':
      case 'active':
      case 'live':
      case 'ongoing':
      case 'started':
      case 'on_route':
      case 'en_route':
      case 'route_to_pickup':
      case 'to_pickup':
        return l10n.deliveryDetailsStartTripToPickup;
      case 'en_route_pickup':
        return l10n.deliveryDetailsReachedPickup;
      case 'picked_up':
        return l10n.deliveryDetailsStartDelivery;
      case 'in_transit':
        return l10n.deliveryDetailsMarkAsDelivered;
      default:
        return l10n.deliveryDetailsStartTripToPickup;
    }
  }

  String _statusChangeMessageFor(AppLocalizations l10n, String status) {
    switch (status) {
      case 'en_route_pickup':
        return l10n.deliveryDetailsTripStartedHeadingToPickup;
      case 'picked_up':
        return l10n.deliveryDetailsPickupMarkedStartDelivery;
      case 'in_transit':
        return l10n.deliveryDetailsNowInTransit;
      case 'delivered':
        return l10n.deliveryDetailsMarkedAsDelivered;
      default:
        return l10n.tripStatusUpdated;
    }
  }

  List<_TripStop> get _extraStops {
    final rawStops = _tripRaw['stops'];
    if (rawStops is! List) {
      return const [];
    }
    return [
          for (var index = 0; index < rawStops.length; index++)
            if (rawStops[index] is Map)
              _TripStop.fromJson(
                index: index,
                json: (rawStops[index] as Map).cast<String, dynamic>(),
              ),
        ]
        .where((stop) => stop.type == 'loading' || stop.type == 'unloading')
        .toList(growable: false);
  }

  int _pendingStopCount(String type) =>
      _extraStops.where((stop) => stop.type == type && !stop.done).length;

  int _nextActionableStopIndex(String type) {
    final rawStops = _tripRaw['stops'];
    if (rawStops is! List) {
      return -1;
    }
    for (var index = 0; index < rawStops.length; index++) {
      final item = rawStops[index];
      if (item is! Map) continue;
      final stop = _TripStop.fromJson(
        index: index,
        json: item.cast<String, dynamic>(),
      );
      if (stop.type == type && !stop.done) {
        return index;
      }
    }
    return -1;
  }

  String? _statusBlockedByStopsReason(AppLocalizations l10n) {
    if (_tripStatus == 'picked_up') {
      final count = _pendingStopCount('loading');
      if (count > 0) {
        return l10n.deliveryDetailsCompleteLoadingStopsFirst(count);
      }
    }
    if (_tripStatus == 'in_transit') {
      final count = _pendingStopCount('unloading');
      if (count > 0) {
        return l10n.deliveryDetailsCompleteUnloadingStopsFirst(count);
      }
    }
    return null;
  }

  Widget _buildStopsChecklist(BuildContext context) {
    final stops = _extraStops;
    if (stops.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 14),
        const Divider(height: 1, thickness: 1, color: AppColors.divider),
        const SizedBox(height: 14),
        Text(
          AppLocalizations.of(context)!.loadingUnloadingStopsTitle,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        for (final stop in stops) ...[
          _TripStopTile(
            stop: stop,
            actionableIndex: _nextActionableStopIndex(stop.type),
            completing: _completingStopIndex == stop.index,
            onComplete: () => unawaited(_completeStop(stop.index)),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  bool get _navHeadingToPickup {
    // Before pickup -> navigate to pickup; after pickup -> navigate to drop.
    return const {
      'confirmed',
      'assigned',
      'accepted',
      'active',
      'live',
      'ongoing',
      'started',
      'on_route',
      'en_route',
      'route_to_pickup',
      'to_pickup',
      'en_route_pickup',
    }.contains(_tripStatus);
  }

  String get _navPickupAddress {
    final fromShipment = _shipment?.fromLocation.trim() ?? '';
    if (fromShipment.isNotEmpty &&
        fromShipment.toLowerCase() != 'pickup location not provided') {
      return fromShipment;
    }
    return _readLocation(_tripRaw, const ['pickup', 'pickupLocation']);
  }

  Widget _buildTripPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isArrivalFlow = _arrivalFlowActive || _showArrivalSwipe;
    final panelTitle = isArrivalFlow
        ? l10n.arrivedTitle
        : l10n.deliveryDetailsOnRoute;
    final panelBadge = isArrivalFlow
        ? l10n.arrivedStatusReady
        : l10n.deliveryDetailsActiveBadge;
    final stopBlockReason = _statusBlockedByStopsReason(l10n);
    final panelSubtitle = isArrivalFlow
        ? l10n.deliveryDetailsConfirmDropReached
        : stopBlockReason ?? l10n.deliveryDetailsUseActionToAdvance;

    return AnimatedSize(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubicEmphasized,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppShadows.float,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.deliveryDetailsCurrentStatus,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        panelTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (_shipment?.isExpress == true) ...[
                        const SizedBox(height: 8),
                        const ExpressBadge(),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    panelBadge,
                    style: const TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () {
                    setState(() {
                      _detailsPanelExpanded = !_detailsPanelExpanded;
                    });
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: AnimatedRotation(
                      turns: _detailsPanelExpanded ? 0.0 : 0.5,
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeInOutCubicEmphasized,
                      child: const Icon(
                        AppIcons.keyboard_arrow_down_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              reverseDuration: const Duration(milliseconds: 220),
              curve: Curves.easeInOutCubicEmphasized,
              alignment: Alignment.topCenter,
              child: _detailsPanelExpanded
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 14),
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.divider,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          panelSubtitle,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                        ),
                        if (isArrivalFlow) ...[
                          const SizedBox(height: 16),
                          SlideToConfirm(
                            enabled: !_loadingTrip && !_confirmingArrival,
                            label: _confirmingArrival
                                ? AppLocalizations.of(context)!.confirming
                                : AppLocalizations.of(context)!.slideToDeliver,
                            onConfirmed: () => unawaited(_confirmArrival()),
                          ),
                        ] else ...[
                          const SizedBox(height: 12),
                          _DetailRow(
                            label: AppLocalizations.of(context)!.customer,
                            value: _customerName,
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            label: AppLocalizations.of(context)!.phone,
                            value: _customerPhone.isNotEmpty
                                ? _customerPhone
                                : '—',
                          ),
                          const SizedBox(height: 10),
                          _DetailRow(
                            label: AppLocalizations.of(context)!.address,
                            value: _dropLocation,
                          ),
                          if (_readDouble(_tripRaw, const [
                                'haltingGraceHours',
                                'halting_grace_hours',
                              ]) !=
                              null) ...[
                            const SizedBox(height: 14),
                            _buildHaltingTimer(),
                          ],
                          if (_readDouble(_tripRaw, const [
                                    'expectedDeliveryHours',
                                    'expected_delivery_hours',
                                  ]) !=
                                  null ||
                              (_readDouble(_tripRaw, const [
                                        'slaOverageCharge',
                                        'sla_overage_charge',
                                      ]) ??
                                      0) >
                                  0) ...[
                            const SizedBox(height: 10),
                            _DeliverySlaCard(
                              expectedHours: _readDouble(_tripRaw, const [
                                'expectedDeliveryHours',
                                'expected_delivery_hours',
                              ]),
                              overageHours:
                                  _readDouble(_tripRaw, const [
                                    'slaOverageHours',
                                    'sla_overage_hours',
                                  ]) ??
                                  0,
                              overageCharge:
                                  _readDouble(_tripRaw, const [
                                    'slaOverageCharge',
                                    'sla_overage_charge',
                                  ]) ??
                                  0,
                            ),
                          ],
                          _buildStopsChecklist(context),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: FilledButton(
                              onPressed:
                                  _loadingTrip ||
                                      _confirmingArrival ||
                                      _tripId.isEmpty ||
                                      stopBlockReason != null
                                  ? null
                                  : () {
                                      developer.log(
                                        'Primary trip button pressed. tripId=$_tripId tripStatus=$_tripStatus',
                                        name: 'driver.deliveryDetails',
                                      );
                                      if (_tripStatus == 'in_transit') {
                                        setState(() {
                                          _arrivalFlowActive = true;
                                          _showArrivalSwipe = true;
                                          _detailsPanelExpanded = true;
                                        });
                                        return;
                                      }
                                      unawaited(_advanceTripStatus());
                                    },
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.brand,
                                disabledBackgroundColor: AppColors.fillSubtle,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                _loadingTrip
                                    ? l10n.deliveryDetailsLoadingEllipsis
                                    : _tripId.isEmpty
                                    ? l10n.deliveryDetailsSyncingTrip
                                    : _actionLabelForCurrentTrip(l10n),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                          // Web `MyTrip.jsx` parity: back out before starting
                          // (only while still `confirmed`). Frees the trip
                          // for broker reassignment.
                          if (_tripStatus == 'confirmed' &&
                              !_loadingTrip &&
                              _tripId.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                onPressed: _decliningTrip
                                    ? null
                                    : _confirmDeclineTrip,
                                child: Text(
                                  _decliningTrip
                                      ? l10n.deliveryDetailsDecliningEllipsis
                                      : l10n.declineTrip,
                                  style: const TextStyle(
                                    color: AppColors.dangerText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeclineTrip() async {
    if (_decliningTrip || _tripId.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.declineThisTrip),
        content: Text(AppLocalizations.of(context)!.declineTripDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.keepTrip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerText,
            ),
            child: Text(AppLocalizations.of(context)!.declineTrip),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.signInAgainToContinue),
        ),
      );
      return;
    }
    setState(() => _decliningTrip = true);
    try {
      developer.log(
        'Declining trip. tripId=$_tripId status=$_tripStatus',
        name: 'driver.deliveryDetails',
      );
      await ref
          .read(apiClientProvider)
          .declineTrip(
            accessToken: session.tokens.accessToken,
            tripId: _tripId,
          );
      if (!mounted) return;
      ref.invalidate(driverDashboardProvider);
      ref.read(driverActiveTripIdProvider.notifier).state = null;
      ref.read(driverTripSessionProvider.notifier).state = null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.tripDeclined)),
      );
      context.go('/driver/home');
    } on ApiException catch (error) {
      if (!mounted) return;
      developer.log(
        'Decline trip failed. tripId=$_tripId message=${error.message}',
        name: 'driver.deliveryDetails',
      );
      // The button only shows while locally `confirmed` — a 409 means the
      // local snapshot was stale (trip already started). Reload so the UI
      // reflects the real status instead of a dead button.
      if ((error.statusCode == 409 ||
              error.message.toLowerCase().contains('already')) &&
          mounted) {
        unawaited(_loadTrip());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _decliningTrip = false);
    }
  }

  Future<void> _confirmArrival() async {
    final l10n = AppLocalizations.of(context)!;
    if (_confirmingArrival) return;
    final messenger = ScaffoldMessenger.of(context);
    final stopwatch = Stopwatch()..start();
    developer.log(
      'Confirm arrival started. tripId=$_tripId loadingTrip=$_loadingTrip',
      name: 'driver.deliveryDetails',
    );
    if (_tripId.isEmpty) {
      developer.log(
        'Trip id missing before confirm arrival, reloading trip first.',
        name: 'driver.deliveryDetails',
      );
      await _loadTrip();
      if (!mounted || _tripId.isEmpty) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.tripStillSyncing)));
        return;
      }
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.signInAgainToContinue)));
      return;
    }

    if (!mounted) return;
    setState(() => _confirmingArrival = true);

    // Fire-and-forget: confirming arrival must not wait on a satellite fix.
    _publishLocationInBackground();

    try {
      developer.log(
        'Sending delivered status update to backend. tripId=$_tripId',
        name: 'driver.deliveryDetails',
      );
      final apiStopwatch = Stopwatch()..start();
      await ref
          .read(apiClientProvider)
          .updateTripStatus(
            accessToken: session.tokens.accessToken,
            tripId: _tripId,
            status: 'delivered',
          );
      apiStopwatch.stop();
      developer.log(
        'Backend returned delivered status update in ${apiStopwatch.elapsedMilliseconds}ms for tripId=$_tripId',
        name: 'driver.deliveryDetails',
      );
      if (!mounted) return;
      ref.invalidate(driverDashboardProvider);
      developer.log(
        'Navigating to delivery completion flow. tripId=$_tripId totalElapsedMs=${stopwatch.elapsedMilliseconds}',
        name: 'driver.deliveryDetails',
      );
      // Single-screen wizard (web `DeliveryCompletionFlow` parity): arrival,
      // POD upload, payment and client-approval waiting all stay on one
      // screen derived from server state — no route-hopping.
      context.go('/driver/complete/$_tripId');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      developer.log(
        'Confirm arrival failed with ApiException after ${stopwatch.elapsedMilliseconds}ms: ${error.message}',
        name: 'driver.deliveryDetails',
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      developer.log(
        'Confirm arrival failed after ${stopwatch.elapsedMilliseconds}ms: $error',
        name: 'driver.deliveryDetails',
      );
    } finally {
      if (mounted) {
        setState(() => _confirmingArrival = false);
      }
    }
  }

  String _readString(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return '';
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  String _readLocation(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return '';
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        final nested = _readString(value, const [
          'location',
          'address',
          'name',
        ]);
        if (nested.isNotEmpty) return nested;
      }
      final text = value?.toString().trim();
      if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
        return text;
      }
    }
    return '';
  }

  double? _readDouble(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      final parsed = double.tryParse(value?.toString().trim() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  int? _readInt(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.round();
      }
      final parsed = int.tryParse(value?.toString().trim() ?? '');
      if (parsed != null) {
        return parsed;
      }
    }
    return null;
  }

  bool _readBool(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return false;
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      if (value is bool) return value;
      if (value is num) return value != 0;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized.isEmpty || normalized == 'null') continue;
      return normalized == 'true' || normalized == '1' || normalized == 'yes';
    }
    return false;
  }

  DateTime? _readDateTime(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;
    for (final key in keys) {
      final value = json[key];
      if (value is DateTime) {
        return value.toLocal();
      }
      final text = value?.toString().trim();
      if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
        continue;
      }
      final parsed = DateTime.tryParse(text);
      if (parsed != null) {
        return parsed.toLocal();
      }
    }
    return null;
  }

  Map<String, dynamic> _readMap(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return const <String, dynamic>{};
    for (final key in keys) {
      final value = json[key];
      if (value is Map<String, dynamic>) {
        return value;
      }
      if (value is Map) {
        return value.cast<String, dynamic>();
      }
    }
    return const <String, dynamic>{};
  }

  TrackingDemoShipment? _shipmentFromTrip(
    AppLocalizations l10n,
    Map<String, dynamic> trip,
  ) {
    final pickup = _readMap(trip, const ['pickup', 'pickupLocation']);
    final drop = _readMap(trip, const ['drop', 'dropoffLocation']);
    final currentLocation = _readMap(trip, const [
      'currentLocation',
      'liveLocation',
      'truckLocation',
    ]);
    final bookingNumber = _readString(trip, const [
      'bookingNumber',
      'booking_number',
    ]);
    final id = _readString(trip, const ['id', 'tripId', 'trip_id']);
    final booking = _readMap(trip, const ['booking']);
    final bookingId =
        _readString(trip, const ['bookingId', 'booking_id']).isNotEmpty
        ? _readString(trip, const ['bookingId', 'booking_id'])
        : _readString(booking, const ['id', 'bookingId', 'booking_id']);
    final status = _readString(trip, const [
      'status',
      'rawStatus',
    ]).trim().toLowerCase();
    final pickupLocation = _readLocation(trip, const [
      'pickup',
      'pickupLocation',
    ]);
    final dropLocation = _readLocation(trip, const ['drop', 'dropoffLocation']);

    if (pickup.isEmpty &&
        drop.isEmpty &&
        currentLocation.isEmpty &&
        bookingNumber.isEmpty &&
        id.isEmpty) {
      return null;
    }

    return TrackingDemoShipment(
      packageName: bookingNumber.isNotEmpty
          ? bookingNumber
          : l10n.deliveryDetailsTripFallbackLabel,
      trackingId: bookingNumber.isNotEmpty ? bookingNumber : id,
      fromLocation: pickupLocation.isNotEmpty
          ? pickupLocation
          : 'Pickup location not provided',
      toLocation: dropLocation.isNotEmpty
          ? dropLocation
          : 'Drop location not provided',
      status: status.isEmpty ? 'Confirmed' : _titleCase(status),
      customerName: _readString(trip, const ['clientName', 'customerName']),
      weight:
          _readString(trip, const [
            'weight',
            'cargoWeight',
            'cargo_weight',
          ]).isNotEmpty
          ? _readString(trip, const ['weight', 'cargoWeight', 'cargo_weight'])
          : 'N/A',
      timeline: const [],
      amount: _readDouble(trip, const ['earnings', 'amount', 'price']) ?? 0,
      paymentStatus:
          _readString(trip, const [
            'paymentStatus',
            'payment_status',
          ]).isNotEmpty
          ? _readString(trip, const ['paymentStatus', 'payment_status'])
          : 'pending',
      pickupLat:
          _readDouble(pickup, const ['lat', 'latitude']) ??
          _readDouble(trip, const ['pickupLat', 'pickup_lat']),
      pickupLng:
          _readDouble(pickup, const ['lng', 'longitude']) ??
          _readDouble(trip, const ['pickupLng', 'pickup_lng']),
      dropLat:
          _readDouble(drop, const ['lat', 'latitude']) ??
          _readDouble(trip, const ['dropLat', 'drop_lat']),
      dropLng:
          _readDouble(drop, const ['lng', 'longitude']) ??
          _readDouble(trip, const ['dropLng', 'drop_lng']),
      liveLat:
          _readDouble(currentLocation, const ['lat', 'latitude']) ??
          _readDouble(trip, const ['currentLat', 'current_lat']),
      liveLng:
          _readDouble(currentLocation, const ['lng', 'longitude']) ??
          _readDouble(trip, const ['currentLng', 'current_lng']),
      isExpress: _readBool(trip, const ['isExpress', 'is_express']),
      expectedDeliveryHours: _readDouble(trip, const [
        'expectedDeliveryHours',
        'expected_delivery_hours',
      ]),
      estimatedDeliveryDate: _readDateTime(trip, const [
        'estimatedDeliveryDate',
        'estimated_delivery_date',
      ]),
      estimatedDeliveryDays: _readInt(trip, const [
        'estimatedDeliveryDays',
        'estimated_delivery_days',
      ]),
      slaOverageHours:
          _readDouble(trip, const ['slaOverageHours', 'sla_overage_hours']) ??
          0,
      slaOverageCharge:
          _readDouble(trip, const ['slaOverageCharge', 'sla_overage_charge']) ??
          0,
      tripId: id.isNotEmpty ? id : null,
      bookingId: bookingId.isNotEmpty ? bookingId : null,
      bookingStatus: status,
      stops: tripRouteStopsFromSource(trip),
    );
  }

  String _normalizeTripStatus(String status) {
    final normalized = status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return '';
    }
    return normalized.replaceAll(RegExp(r'[\s-]+'), '_');
  }

  /// Forward-only rank of the trip lifecycle. Used to ignore stale snapshots
  /// (socket echo / lagging refetch) that would otherwise drag a confirmed
  /// status backwards — e.g. back to pre-pickup, re-popping the OTP dialog
  /// after a successful verify.
  static int _tripStatusRank(String status) {
    switch (status) {
      case 'confirmed':
      case 'assigned':
        return 0;
      case 'en_route_pickup':
      case 'en_route':
        return 1;
      case 'picked_up':
        return 2;
      case 'in_transit':
        return 3;
      case 'delivered':
        return 4;
      case 'completed':
      case 'paid':
      case 'settled':
        return 5;
      default:
        return 0;
    }
  }

  static bool _isDeadEndTripStatus(String status) {
    return const {
      'cancelled',
      'canceled',
      'rejected',
      'declined',
    }.contains(status);
  }

  /// Whether an incoming status snapshot may overwrite the current one.
  /// Empty snapshots never win; cancel/reject always applies; a dead-end
  /// state is never left; everything else must move forward (or stay).
  static bool _mayApplyTripStatus(String current, String incoming) {
    if (incoming.isEmpty) return false;
    if (current.isEmpty || incoming == current) return true;
    if (_isDeadEndTripStatus(incoming)) return true;
    if (_isDeadEndTripStatus(current)) return false;
    return _tripStatusRank(incoming) >= _tripStatusRank(current);
  }

  Widget _buildHaltingTimer() {
    return HaltingTimerCard(
      status: _tripStatus,
      startedAt: _readDateTime(_tripRaw, const [
        'startedAt',
        'started_at',
        'tripStartedAt',
        'trip_started_at',
      ]),
      haltingGraceHours: _readDouble(_tripRaw, const [
        'haltingGraceHours',
        'halting_grace_hours',
      ]),
      haltingRatePerHour: _readDouble(_tripRaw, const [
        'haltingRatePerHour',
        'halting_rate_per_hour',
      ]),
      haltingHours:
          _readDouble(_tripRaw, const ['haltingHours', 'halting_hours']) ?? 0,
      haltingCharge:
          _readDouble(_tripRaw, const ['haltingCharge', 'halting_charge']) ?? 0,
      showNotStarted: true,
      showLiveChargeEstimate: true,
    );
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  Future<void> _openMapsFromMenu() async {
    final messenger = ScaffoldMessenger.of(context);
    final granted = await DriverExternalNavigationService.hasBubblePermission();
    if (!mounted) return;

    if (granted) {
      await _openMapsDirect();
      return;
    }

    final proceed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.allowDisplayOverApps),
        content: Text(AppLocalizations.of(context)!.allowDisplayOverAppsText),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(context)!.skip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(AppLocalizations.of(context)!.openSettings),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (proceed != true) {
      // Skip -> open Maps without the bubble.
      await _openMapsDirect();
      return;
    }
    _awaitingOverlayPermission = true;
    final opened =
        await DriverExternalNavigationService.requestBubblePermission();
    if (!mounted) return;
    if (!opened) {
      _awaitingOverlayPermission = false;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotOpenSettings),
          duration: const Duration(seconds: 4),
        ),
      );
    }
    // Return from Settings -> didChangeAppLifecycleState continues.
  }

  /// Shows the bubble (when permitted) and launches Google Maps. The bubble
  /// is shown BEFORE leaving the app because some devices block overlays
  /// that are added while the app is already in the background.
  Future<void> _openMapsDirect() async {
    final messenger = ScaffoldMessenger.of(context);
    var bubbleShown = false;
    if (await DriverExternalNavigationService.hasBubblePermission()) {
      bubbleShown = await DriverExternalNavigationService.showBubble();
      if (!mounted) return;
      if (!bubbleShown) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.couldNotShowFloatingButton,
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    final error = await DriverExternalNavigationService.openDriverNavigation(
      pickupLat: _shipment?.pickupLat,
      pickupLng: _shipment?.pickupLng,
      pickupAddress: _navPickupAddress,
      dropLat: _shipment?.dropLat,
      dropLng: _shipment?.dropLng,
      dropAddress: _dropLocation,
      liveLat: _shipment?.liveLat,
      liveLng: _shipment?.liveLng,
      headingToPickup: _navHeadingToPickup,
    );
    if (!mounted) return;
    if (error != null) {
      await DriverExternalNavigationService.hideBubble();
      messenger.showSnackBar(SnackBar(content: Text(error)));
    } else if (bubbleShown) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.tapBubbleToReturn),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEmergencyAssistance(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.dangerFill,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          AppIcons.shield_outlined,
                          color: AppColors.dangerIcon,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(sheetContext)!
                              .deliveryDetailsEmergencyAssistance,
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        icon: const Icon(AppIcons.close_rounded),
                        color: AppColors.textTertiary,
                        tooltip:
                            AppLocalizations.of(sheetContext)!.close,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _EmergencyAssistanceTile(
                    backgroundColor: AppColors.brandTint,
                    iconColor: AppColors.brand,
                    icon: AppIcons.navigation_rounded,
                    title: _navHeadingToPickup
                        ? AppLocalizations.of(sheetContext)!
                              .deliveryDetailsOpenPickupInMaps
                        : AppLocalizations.of(sheetContext)!
                              .deliveryDetailsOpenDropInMaps,
                    subtitle: _navHeadingToPickup
                        ? (_navPickupAddress.isEmpty
                              ? AppLocalizations.of(sheetContext)!
                                    .deliveryDetailsNavigateToPickup
                              : _navPickupAddress)
                        : (_dropLocation.isEmpty
                              ? AppLocalizations.of(context)!.navigateToDrop
                              : _dropLocation),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      unawaited(_openMapsFromMenu());
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: AppColors.dangerFill,
                    iconColor: AppColors.dangerIcon,
                    icon: AppIcons.local_police_rounded,
                    title: AppLocalizations.of(context)!.callPolice,
                    subtitle: AppLocalizations.of(context)!.emergency112,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.callingPoliceSoon,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: AppColors.dangerFill,
                    iconColor: AppColors.dangerIcon,
                    icon: AppIcons.local_hospital_rounded,
                    title: AppLocalizations.of(context)!.callAmbulance,
                    subtitle: AppLocalizations.of(context)!.emergency108,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.callingAmbulanceSoon,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: AppColors.brandTint,
                    iconColor: AppColors.brand,
                    icon: AppIcons.call_rounded,
                    title: AppLocalizations.of(context)!.callBroker,
                    subtitle: '9000000003',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)!.callingBrokerSoon,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: AppColors.warningFill,
                    iconColor: AppColors.warningText,
                    icon: AppIcons.report_outlined,
                    title: AppLocalizations.of(
                      context,
                    )!.reportIncidentToSupport,
                    subtitle: AppLocalizations.of(
                      context,
                    )!.notifySupportImmediately,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showIncidentReport(context, _tripId);
                    },
                  ),
                  const SizedBox(height: 10),
                  _EmergencyAssistanceTile(
                    backgroundColor: AppColors.brandTint,
                    iconColor: AppColors.brand,
                    icon: AppIcons.build_circle_outlined,
                    title: AppLocalizations.of(context)!.viewMechanicStatus,
                    subtitle: AppLocalizations.of(context)!.seeRepairProgress,
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      _showMechanicStatus(context, _tripId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showIncidentReport(BuildContext context, String tripId) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return _IncidentReportDialog(parentContext: context, tripId: tripId);
      },
    );
  }

  Future<void> _showMechanicStatus(BuildContext context, String tripId) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.signInAgainToViewMechanicStatus,
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return _MechanicStatusDialog(
          tripId: tripId,
          accessToken: session.tokens.accessToken,
        );
      },
    );
  }

  Future<void> _openChat() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _bookingId.isNotEmpty
        ? _bookingId
        : (_shipment?.bookingId ?? '').trim();
    if (session == null || bookingId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.chatUnavailableForTrip),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DriverBookingChatSheet(
        bookingId: bookingId,
        accessToken: session.tokens.accessToken,
        currentUserId: session.user.id,
      ),
    );
  }

  Future<void> _callCustomer() async {
    final number = _customerPhone.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.customerPhoneUnavailable),
        ),
      );
      return;
    }
    final launched = await launchUrl(
      Uri.parse('tel:$number'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.couldNotOpenPhoneApp),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _shipment == null
              ? const _DriverDeliveryMapBackdrop()
              : TrackingRouteMapView(shipment: _shipment!, liveMode: true),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.20),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.66),
                  ],
                  stops: const [0.0, 0.40, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FloatingRoundButton(
                    icon: AppIcons.arrow_back_rounded,
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                        return;
                      }
                      context.go('/driver/active');
                    },
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            AppIcons.receipt_long_rounded,
                            size: 14,
                            color: AppColors.brand,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _tripId.isNotEmpty ? _tripId : _bookingId,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _FloatingRoundButton(
                    icon: AppIcons.call_rounded,
                    onTap: _callCustomer,
                    highlight: true,
                  ),
                  const SizedBox(width: 8),
                  _FloatingRoundButton(
                    icon: AppIcons.chat_bubble_outline_rounded,
                    onTap: _openChat,
                    highlight: true,
                  ),
                  const SizedBox(width: 8),
                  _FloatingRoundButton(
                    icon: AppIcons.more_vert_rounded,
                    onTap: () => _showEmergencyAssistance(context),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14 + bottomInset,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _buildTripPanel(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingRoundButton extends StatelessWidget {
  const _FloatingRoundButton({
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: highlight ? AppColors.brand : AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _PickupOtpDialog extends StatefulWidget {
  const _PickupOtpDialog({required this.onSubmit});

  final Future<String?> Function(String pickupOtp) onSubmit;

  @override
  State<_PickupOtpDialog> createState() => _PickupOtpDialogState();
}

class _PickupOtpDialogState extends State<_PickupOtpDialog> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;
  bool _submitting = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  bool get _isComplete => _code.length == 4;

  void _onDigitChanged(int index, String value) {
    if (_errorText.isNotEmpty) {
      setState(() => _errorText = '');
    }
    if (value.isEmpty) {
      return;
    }
    if (index < 3) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      unawaited(_submit());
    }
  }

  void _onBackspaceEmpty(int index) {
    final prev = index - 1;
    _controllers[prev].clear();
    _focusNodes[prev].requestFocus();
  }

  Future<void> _submit() async {
    final code = _code;
    if (code.length != 4 || _submitting) return;
    setState(() => _submitting = true);
    final error = await widget.onSubmit(code);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _errorText = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 344),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.brandBright, AppColors.brand],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.brandBright, AppColors.brand],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.30),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          AppIcons.lock_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)!
                                  .deliveryDetailsEnterPickupCode,
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              AppLocalizations.of(context)!
                                  .deliveryDetailsAskCustomerForCode,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.fillSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.close_rounded,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < 4; index++) ...[
                        if (index > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _OtpField(
                            controller: _controllers[index],
                            focusNode: _focusNodes[index],
                            autoFocus: index == 0,
                            error: _errorText.isNotEmpty,
                            onChanged: (value) => _onDigitChanged(index, value),
                            onBackspaceEmpty: () => _onBackspaceEmpty(index),
                          ),
                        ),
                      ],
                    ],
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: _errorText.isEmpty
                        ? const SizedBox(height: 10)
                        : Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  AppIcons.error_outline_rounded,
                                  size: 16,
                                  color: AppColors.dangerText,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    _errorText,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.dangerText,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: _isComplete && !_submitting ? _submit : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        disabledBackgroundColor: AppColors.brand.withValues(
                          alpha: 0.35,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        shadowColor: AppColors.brand,
                        elevation: 3,
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!
                                  .deliveryDetailsConfirmPickup,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
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
    );
  }
}

class _OtpField extends StatefulWidget {
  const _OtpField({
    required this.controller,
    required this.focusNode,
    required this.autoFocus,
    required this.error,
    required this.onChanged,
    required this.onBackspaceEmpty,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool autoFocus;
  final bool error;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspaceEmpty;

  @override
  State<_OtpField> createState() => _OtpFieldState();
}

class _OtpFieldState extends State<_OtpField> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.onKeyEvent = _handleKeyEvent;
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        widget.controller.text.isEmpty) {
      widget.onBackspaceEmpty();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final hasText = widget.controller.text.isNotEmpty;
    final fill = widget.error
        ? const Color(0xFFFFF4F4)
        : hasText
        ? AppColors.brandTint
        : Colors.white;
    final borderColor = widget.error
        ? AppColors.dangerBorder
        : widget.focusNode.hasFocus
        ? AppColors.brand
        : AppColors.line;
    final borderWidth = widget.focusNode.hasFocus ? 2.0 : 1.2;

    return SizedBox(
      height: 62,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        autofocus: widget.autoFocus,
        autofillHints: widget.autoFocus
            ? const [AutofillHints.oneTimeCode]
            : null,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        showCursor: true,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(1),
        ],
        style: const TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w900,
          color: AppColors.brandDark,
          height: 1,
        ),
        cursorColor: AppColors.brand,
        cursorWidth: 2,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: fill,
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: borderColor, width: borderWidth),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.brand, width: 2),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide(color: borderColor, width: borderWidth),
          ),
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DeliverySlaCard extends StatelessWidget {
  const _DeliverySlaCard({
    required this.expectedHours,
    required this.overageHours,
    required this.overageCharge,
  });

  final double? expectedHours;
  final double overageHours;
  final double overageCharge;

  @override
  Widget build(BuildContext context) {
    final hasCharge = overageCharge > 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasCharge ? AppColors.warningFill : AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCharge ? AppColors.warningBorder : AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasCharge
                ? AppIcons.warning_amber_rounded
                : AppIcons.schedule_rounded,
            color: hasCharge ? AppColors.warningText : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasCharge
                      ? AppLocalizations.of(context)!
                            .deliveryDetailsDelayCharge
                      : AppLocalizations.of(context)!.deliveryDetailsSla,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasCharge
                      ? AppLocalizations.of(context)!
                            .deliveryDetailsDelayChargeBody(
                              '₹${overageCharge.toStringAsFixed(overageCharge % 1 == 0 ? 0 : 2)}',
                              overageHours.toStringAsFixed(
                                overageHours % 1 == 0 ? 0 : 1,
                              ),
                            )
                      : AppLocalizations.of(context)!
                            .deliveryDetailsExpectedWithin(
                              expectedHours!.toStringAsFixed(
                                expectedHours! % 1 == 0 ? 0 : 1,
                              ),
                            ),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: hasCharge
                        ? AppColors.warningText
                        : AppColors.textSecondary,
                    height: 1.35,
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

class _IncidentReportDialog extends ConsumerStatefulWidget {
  const _IncidentReportDialog({
    required this.parentContext,
    required this.tripId,
  });

  final BuildContext parentContext;
  final String tripId;

  @override
  ConsumerState<_IncidentReportDialog> createState() =>
      _IncidentReportDialogState();
}

class _IncidentReportDialogState extends ConsumerState<_IncidentReportDialog> {
  static const _incidentTypes = <_IncidentTypeOption>[
    _IncidentTypeOption(
      label: 'accident',
      icon: AppIcons.warning_amber_rounded,
      accent: AppColors.warningText,
      background: AppColors.warningFill,
    ),
    _IncidentTypeOption(
      label: 'breakdown',
      icon: AppIcons.build_rounded,
      accent: AppColors.textTertiary,
      background: AppColors.fillSubtle,
    ),
    _IncidentTypeOption(
      label: 'traffic_block',
      icon: AppIcons.traffic_rounded,
      accent: AppColors.brand,
      background: AppColors.brandTint,
    ),
    _IncidentTypeOption(
      label: 'medical',
      icon: AppIcons.favorite_border_rounded,
      accent: AppColors.dangerIcon,
      background: AppColors.dangerFill,
    ),
    _IncidentTypeOption(
      label: 'other',
      icon: AppIcons.chat_bubble_outline_rounded,
      accent: AppColors.textTertiary,
      background: AppColors.fillSubtle,
    ),
  ];

  late String _selectedType;
  late final TextEditingController _detailsController;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _selectedType = _incidentTypes.first.label;
    _detailsController = TextEditingController();
  }

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(widget.parentContext).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.signInAgainToReportIssue),
        ),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(widget.parentContext);
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .reportTripIssue(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
            reason: _incidentReasonFor(_selectedType),
            notes: _detailsController.text.trim(),
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.incidentReportSubmitted(
              _incidentDisplayLabel(context, _selectedType),
            ),
          ),
          backgroundColor: AppColors.brand,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.warningFill,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        AppIcons.report_gmailerrorred_outlined,
                        color: AppColors.warningText,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.reportIncident,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.close_rounded),
                      color: AppColors.textTertiary,
                      tooltip: AppLocalizations.of(context)!.close,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.incidentDialogSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: _incidentTypes.map((option) {
                    return _IncidentTypeChip(
                      option: option,
                      selected: _selectedType == option.label,
                      onTap: () => setState(() => _selectedType = option.label),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _detailsController,
                  maxLines: 4,
                  minLines: 4,
                  cursorColor: AppColors.brand,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.addDetailsOptional,
                    hintStyle: const TextStyle(
                      color: AppColors.textTertiary,
                      fontWeight: FontWeight.w600,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(color: AppColors.line),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: const BorderSide(
                        color: AppColors.warningText,
                        width: 1.4,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitReport,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warningText,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: _isSubmitting
                          ? const SizedBox(
                              key: ValueKey('submit-loading'),
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppLocalizations.of(context)!.submitReport,
                              key: const ValueKey('submit-label'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
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

class _DriverBookingChatSheet extends StatelessWidget {
  const _DriverBookingChatSheet({
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
          padding: EdgeInsets.fromLTRB(18, 12, 18, 18 + bottomInset),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.fillSubtle,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!.deliveryDetailsBookingChat,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
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
                  allowBotActions: false,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MechanicStatusDialog extends ConsumerStatefulWidget {
  const _MechanicStatusDialog({
    required this.tripId,
    required this.accessToken,
  });

  final String tripId;
  final String accessToken;

  @override
  ConsumerState<_MechanicStatusDialog> createState() =>
      _MechanicStatusDialogState();
}

class _MechanicStatusDialogState extends ConsumerState<_MechanicStatusDialog> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _incidents = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadIncidents());
    });
  }

  Future<void> _loadIncidents() async {
    try {
      final response = await ref
          .read(apiClientProvider)
          .getTripIncidents(
            accessToken: widget.accessToken,
            tripId: widget.tripId,
          );
      final data = response['data'];
      final items = data is Map<String, dynamic>
          ? (data['incidents'] ??
                data['items'] ??
                data['results'] ??
                data['rows'])
          : response['incidents'] ?? response['items'] ?? response['results'];

      final list = items is List ? items : const <dynamic>[];

      if (!mounted) return;
      setState(() {
        _incidents = list.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
        _loading = false;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.fromLTRB(18, 24, 18, 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      AppIcons.build_circle_outlined,
                      color: AppColors.brand,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context)!
                          .deliveryDetailsMechanicStatus,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(AppIcons.close_rounded),
                    color: AppColors.textTertiary,
                    tooltip: AppLocalizations.of(context)!.close,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!
                    .deliveryDetailsLiveIncidentUpdates,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                Text(
                  _error!,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.dangerText),
                )
              else if (_incidents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    AppLocalizations.of(context)!.noIncidentsReported,
                  ),
                )
              else
                Column(
                  children: [
                    for (var index = 0; index < _incidents.length; index++) ...[
                      _MechanicIncidentCard(incident: _incidents[index]),
                      if (index != _incidents.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ],
                ),
              const SizedBox(height: 14),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: _loading ? null : _loadIncidents,
                  child: Text(AppLocalizations.of(context)!.refresh),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MechanicIncidentCard extends StatelessWidget {
  const _MechanicIncidentCard({required this.incident});

  final Map<String, dynamic> incident;

  @override
  Widget build(BuildContext context) {
    final reason = _readIncidentString(incident, const ['reason', 'type']);
    final notes = _readIncidentString(incident, const ['notes', 'description']);
    final mechanic = _asMap(incident['mechanicRequest']);
    final mechanicStatus = _readIncidentString(mechanic, const ['status']);
    final mechanicName = _readIncidentString(mechanic, const [
      'mechanicName',
      'mechanic_name',
    ]);
    final mechanicPhone = _readIncidentString(mechanic, const [
      'mechanicPhone',
      'mechanic_phone',
    ]);
    final mechanicNotes = _readIncidentString(mechanic, const ['notes']);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reason.isEmpty
                ? AppLocalizations.of(context)!.deliveryDetailsIncident
                : reason,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (notes.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              notes,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          if (mechanic.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.deliveryDetailsMechanicLine(
                mechanicName.isEmpty
                    ? AppLocalizations.of(context)!
                          .deliveryDetailsPendingAssignment
                    : mechanicName,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (mechanicPhone.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                AppLocalizations.of(context)!
                    .deliveryDetailsPhoneLine(mechanicPhone),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!
                  .deliveryDetailsStatusLine(
                    mechanicStatus.isEmpty
                        ? AppLocalizations.of(context)!
                              .deliveryDetailsRequestedLabel
                        : mechanicStatus,
                  ),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            if (mechanicNotes.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                mechanicNotes,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _IncidentTypeOption {
  const _IncidentTypeOption({
    required this.label,
    required this.icon,
    required this.accent,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final Color background;
}

String _incidentReasonFor(String label) {
  return switch (label) {
    'accident' => 'accident',
    'breakdown' => 'breakdown',
    'traffic_block' => 'traffic_block',
    'medical' => 'medical',
    _ => 'other',
  };
}

String _incidentDisplayLabel(BuildContext context, String label) {
  final l10n = AppLocalizations.of(context)!;
  return switch (label) {
    'accident' => l10n.accident,
    'breakdown' => l10n.breakdown,
    'traffic_block' => l10n.trafficBlock,
    'medical' => l10n.medical,
    _ => l10n.other,
  };
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}

String _readIncidentString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

class _IncidentTypeChip extends StatelessWidget {
  const _IncidentTypeChip({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _IncidentTypeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? option.background : AppColors.fillSubtle,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 125,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? option.accent : AppColors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(option.icon, color: option.accent, size: 22),
              const SizedBox(height: 6),
              Text(
                _incidentDisplayLabel(context, option.label),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyAssistanceTile extends StatelessWidget {
  const _EmergencyAssistanceTile({
    required this.backgroundColor,
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color backgroundColor;
  final Color iconColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
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

class _DriverDeliveryMapBackdrop extends StatelessWidget {
  const _DriverDeliveryMapBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DriverDeliveryMapPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.fillSubtle, AppColors.line],
          ),
        ),
      ),
    );
  }
}

class _DriverDeliveryMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final accentPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = AppColors.surface;
    final nodeBorderPaint = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = AppColors.fillSubtle,
    );

    final paths = [
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.18)
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.10,
          size.width * 0.63,
          size.height * 0.24,
        )
        ..quadraticBezierTo(
          size.width * 0.82,
          size.height * 0.34,
          size.width * 0.95,
          size.height * 0.21,
        ),
      Path()
        ..moveTo(size.width * 0.06, size.height * 0.44)
        ..quadraticBezierTo(
          size.width * 0.30,
          size.height * 0.38,
          size.width * 0.50,
          size.height * 0.50,
        )
        ..quadraticBezierTo(
          size.width * 0.74,
          size.height * 0.62,
          size.width * 0.98,
          size.height * 0.56,
        ),
      Path()
        ..moveTo(size.width * 0.14, size.height * 0.75)
        ..quadraticBezierTo(
          size.width * 0.38,
          size.height * 0.65,
          size.width * 0.59,
          size.height * 0.77,
        )
        ..quadraticBezierTo(
          size.width * 0.78,
          size.height * 0.86,
          size.width * 0.94,
          size.height * 0.79,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, accentPaint);
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
      canvas.drawCircle(node, 3.5, Paint()..color = AppColors.brand);
    }

    final gridPaint = Paint()
      ..color = AppColors.line
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.12 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
