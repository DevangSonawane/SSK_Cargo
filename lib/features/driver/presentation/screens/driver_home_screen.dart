import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_dashboard_models.dart';
import '../../data/driver_trip_handoff_utils.dart';
import '../../data/driver_request_models.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  double _acceptSlide = 0;
  bool _launchingRequest = false;
  bool _launchingActiveTrip = false;
  bool _reconcilingActiveTrip = false;
  String _reconcilingTripId = '';
  final Set<String> _answeringRequestIds = <String>{};
  Timer? _activeTripReconcileTimer;
  late final WidgetsBindingObserver _lifecycleObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleObserver = _HomeLifecycleObserver(
      onResume: () {
        if (!mounted) return;
        ref.invalidate(driverRequestFeedProvider);
        _reconcileActiveTripLock();
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
  }

  @override
  void dispose() {
    _activeTripReconcileTimer?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    super.dispose();
  }

  void _clearActiveTripLock() {
    ref.read(driverActiveTripIdProvider.notifier).state = null;
    ref.read(driverTripSessionProvider.notifier).state = null;
    ref.invalidate(driverDashboardProvider);
  }

  bool _isInactiveTripStatus(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'completed' ||
        normalized == 'delivered' ||
        normalized == 'cancelled' ||
        normalized == 'canceled' ||
        normalized == 'rejected' ||
        normalized == 'declined' ||
        normalized == 'expired';
  }

  String _readStatus(Map<String, dynamic> json) {
    for (final key in const [
      'status',
      'rawStatus',
      'bookingStatus',
      'booking_status',
    ]) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  void _syncActiveTripReconciliation(String activeTripId) {
    final normalizedTripId = activeTripId.trim();
    if (normalizedTripId.isEmpty) {
      _activeTripReconcileTimer?.cancel();
      _activeTripReconcileTimer = null;
      _reconcilingTripId = '';
      return;
    }

    if (_reconcilingTripId == normalizedTripId &&
        _activeTripReconcileTimer != null) {
      return;
    }

    _activeTripReconcileTimer?.cancel();
    _reconcilingTripId = normalizedTripId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _reconcilingTripId == normalizedTripId) {
        unawaited(_reconcileActiveTripLock());
      }
    });
    _activeTripReconcileTimer = Timer.periodic(const Duration(seconds: 12), (
      _,
    ) {
      unawaited(_reconcileActiveTripLock());
    });
  }

  Future<void> _reconcileActiveTripLock() async {
    if (_reconcilingActiveTrip || !mounted) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    final localTripId =
        (ref.read(driverTripSessionProvider)?.tripId ??
                ref.read(driverActiveTripIdProvider) ??
                '')
            .trim();
    if (session == null || localTripId.isEmpty) {
      return;
    }

    _reconcilingActiveTrip = true;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getActiveTrip(accessToken: session.tokens.accessToken);
      final trip = extractTripFromResponse(response);
      if (!mounted || localTripId != _reconcilingTripId) {
        return;
      }

      if (trip == null) {
        _clearActiveTripLock();
        return;
      }

      final tripStatus = _readStatus(trip);
      if (_isInactiveTripStatus(tripStatus)) {
        _clearActiveTripLock();
        return;
      }

      final serverTripId = extractTripId(trip);
      if (serverTripId.isNotEmpty && serverTripId != localTripId) {
        ref.read(driverActiveTripIdProvider.notifier).state = serverTripId;
        final currentSession = ref.read(driverTripSessionProvider);
        ref
            .read(driverTripSessionProvider.notifier)
            .state = (currentSession ?? DriverTripSession(tripId: serverTripId))
            .copyWith(tripId: serverTripId, status: tripStatus);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      if (error.statusCode == 404) {
        _clearActiveTripLock();
      }
    } finally {
      _reconcilingActiveTrip = false;
    }
  }

  Future<void> _answerBrokerAssignedRequest(
    DriverRequestItem request, {
    required bool accept,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _answeringRequestIds.contains(request.id)) {
      return;
    }

    setState(() => _answeringRequestIds.add(request.id));
    try {
      final api = ref.read(apiClientProvider);
      if (accept) {
        await api.acceptDriverRequestAsDriver(
          accessToken: session.tokens.accessToken,
          id: request.id,
        );
      } else {
        await api.rejectDriverRequestAsDriver(
          accessToken: session.tokens.accessToken,
          id: request.id,
        );
      }
      ref.read(driverRequestFeedProvider.notifier).refresh();
      ref.invalidate(driverDashboardProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept ? 'Trip accepted.' : 'Trip declined.'),
          backgroundColor: accept
              ? const Color(0xFF2FA56E)
              : const Color(0xFFE23A4B),
        ),
      );
      if (accept) {
        unawaited(_goToActiveTrip());
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _answeringRequestIds.remove(request.id));
      }
    }
  }

  DriverRequestItem? _acceptedRequestForUser(
    List<DriverRequestItem>? requests,
    String userId,
  ) {
    if (requests == null || userId.isEmpty) {
      return null;
    }

    for (final request in requests) {
      if (request.driverId == userId &&
          request.status.trim().toLowerCase() == 'accepted') {
        return request;
      }
    }
    return null;
  }

  Future<void> _goToActiveTrip() async {
    if (_launchingActiveTrip) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) {
      return;
    }

    _launchingActiveTrip = true;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getActiveTrip(accessToken: session.tokens.accessToken);
      final trip = extractTripFromResponse(response);
      final tripId = trip == null ? '' : extractTripId(trip);

      if (!mounted) {
        return;
      }

      if (trip == null ||
          tripId.isEmpty ||
          _isInactiveTripStatus(_readStatus(trip))) {
        _clearActiveTripLock();
        return;
      }

      ref.read(driverActiveTripIdProvider.notifier).state = tripId;
      ref.read(driverTripSessionProvider.notifier).state = DriverTripSession(
        tripId: tripId,
        status: _readStatus(trip),
      );
      context.go('/driver/delivery-details/$tripId');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      _launchingActiveTrip = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(driverOnlineProvider);
    final session = ref.watch(authSessionProvider).valueOrNull;
    final tripSession = ref.watch(driverTripSessionProvider);
    final activeTripId =
        (tripSession?.tripId ?? ref.watch(driverActiveTripIdProvider) ?? '')
            .trim();
    final hasActiveTrip = activeTripId.isNotEmpty;
    final requestsAsync = ref.watch(driverRequestFeedProvider);
    _syncActiveTripReconciliation(activeTripId);

    ref.listen(driverRequestFeedProvider, (previous, next) {
      if (!mounted || _launchingActiveTrip) {
        return;
      }

      final userId = ref.read(authSessionProvider).valueOrNull?.user.id ?? '';
      final previousAccepted = _acceptedRequestForUser(
        previous?.valueOrNull,
        userId,
      );
      final nextAccepted = _acceptedRequestForUser(next.valueOrNull, userId);

      if (nextAccepted != null &&
          nextAccepted.id != previousAccepted?.id &&
          nextAccepted.driverId == userId) {
        unawaited(_goToActiveTrip());
      }
    });

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isOnline
                          ? const Color(0xFF98A2B3)
                          : const Color(0xFFE23A4B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Tooltip(
                    message: hasActiveTrip && isOnline
                        ? "Can't go offline while you have an active trip"
                        : isOnline
                        ? 'Toggle offline'
                        : 'Toggle online',
                    child: Switch(
                      value: isOnline,
                      onChanged: (isOnline && hasActiveTrip)
                          ? null
                          : (value) {
                              if (!value && hasActiveTrip) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'You cannot go offline while a trip is active.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              ref.read(driverOnlineProvider.notifier).state =
                                  value;
                            },
                      activeThumbColor: const Color(0xFF2FA56E),
                      activeTrackColor: const Color(
                        0xFF2FA56E,
                      ).withValues(alpha: 0.35),
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: const Color(
                        0xFFE23A4B,
                      ).withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isOnline
                          ? const Color(0xFF2FA56E)
                          : const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            if (hasActiveTrip) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: Text(
                  'Active trip in progress. Online mode stays locked until the trip is completed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF2)),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deliveries',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF101828),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(driverRequestFeedProvider.notifier).refresh();
                  },
                  icon: const Icon(AppIcons.refresh_rounded),
                  tooltip: 'Refresh requests',
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!isOnline)
              const _EmptyStateCard(
                icon: AppIcons.wifi_off_rounded,
                title: 'Go online to receive requests',
                subtitle:
                    'Negotiation cards will appear here once you are available.',
              )
            else if (session == null)
              const _EmptyStateCard(
                icon: AppIcons.lock_outline_rounded,
                title: 'Please sign in again',
                subtitle:
                    'We need an active session before we can load requests.',
              )
            else
              requestsAsync.when(
                loading: () => const _EmptyStateCard(
                  icon: AppIcons.hourglass_top_rounded,
                  title: 'Loading requests',
                  subtitle: 'Fetching driver requests from the server.',
                ),
                error: (error, _) => _EmptyStateCard(
                  icon: AppIcons.error_outline_rounded,
                  title: 'Could not load requests',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
                data: (requests) {
                  final newRequests = requests
                      .where((request) => request.isVisibleInNewTravel)
                      .toList();

                  if (newRequests.isEmpty) {
                    return const _EmptyStateCard(
                      icon: AppIcons.inbox_rounded,
                      title: 'No new deliveries',
                      subtitle:
                          'New client requests will appear here when they arrive.',
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _DeliveryOrderCard(
                        request: newRequests.first,
                        acceptSlide: _acceptSlide,
                        busy: _answeringRequestIds.contains(
                          newRequests.first.id,
                        ),
                        onAcceptBrokerAssigned: () =>
                            _answerBrokerAssignedRequest(
                              newRequests.first,
                              accept: true,
                            ),
                        onDeclineBrokerAssigned: () =>
                            _answerBrokerAssignedRequest(
                              newRequests.first,
                              accept: false,
                            ),
                        onSlideChanged: (value) {
                          if (_launchingRequest) return;
                          setState(() => _acceptSlide = value);
                          if (value >= 0.98) {
                            _launchingRequest = true;
                            Future.delayed(
                              const Duration(milliseconds: 350),
                              () {
                                if (!context.mounted) return;
                                context.push(
                                  '/driver/request',
                                  extra: newRequests.first.raw,
                                );
                                setState(() => _acceptSlide = 0);
                                _launchingRequest = false;
                              },
                            );
                          }
                        },
                        onOpenNegotiation: () {
                          context.push(
                            '/driver/request',
                            extra: newRequests.first.raw,
                          );
                        },
                      ),
                      if (newRequests.length > 1) ...[
                        const SizedBox(height: 18),
                        Text(
                          'More requests',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF101828),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 12),
                        for (var i = 1; i < newRequests.length; i++) ...[
                          _DriverRequestCard(
                            request: newRequests[i],
                            busy: _answeringRequestIds.contains(
                              newRequests[i].id,
                            ),
                            onAcceptBrokerAssigned: () =>
                                _answerBrokerAssignedRequest(
                                  newRequests[i],
                                  accept: true,
                                ),
                            onDeclineBrokerAssigned: () =>
                                _answerBrokerAssignedRequest(
                                  newRequests[i],
                                  accept: false,
                                ),
                            onOpenNegotiation: (request) {
                              context.push(
                                '/driver/request',
                                extra: request.raw,
                              );
                            },
                          ),
                          if (i != newRequests.length - 1)
                            const SizedBox(height: 14),
                        ],
                      ],
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeLifecycleObserver extends WidgetsBindingObserver {
  _HomeLifecycleObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF98A2B3), size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryOrderCard extends StatelessWidget {
  const _DeliveryOrderCard({
    required this.request,
    required this.acceptSlide,
    required this.busy,
    required this.onSlideChanged,
    required this.onOpenNegotiation,
    required this.onAcceptBrokerAssigned,
    required this.onDeclineBrokerAssigned,
  });

  final DriverRequestItem request;
  final double acceptSlide;
  final bool busy;
  final ValueChanged<double> onSlideChanged;
  final VoidCallback onOpenNegotiation;
  final VoidCallback onAcceptBrokerAssigned;
  final VoidCallback onDeclineBrokerAssigned;

  @override
  Widget build(BuildContext context) {
    final amount = request.amount > 0 ? request.amount : 0;
    final brokerAssigned = request.isBrokerAssigned;
    final canOpen = request.canNegotiate || brokerAssigned;
    final statusLabel = _driverRequestStatusLabel(request);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery ID',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.displayRef,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF2)),
          const SizedBox(height: 14),
          Column(
            children: [
              _RoutePointCard(
                label: 'Pickup',
                value: request.pickup,
                accentColor: const Color(0xFF2FA56E),
              ),
              const SizedBox(height: 10),
              _RoutePointCard(
                label: 'Drop',
                value: request.drop,
                accentColor: const Color(0xFFE23A4B),
              ),
            ],
          ),
          if (request.driverTimedOut) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4D3A5)),
              ),
              child: Text(
                'This request timed out for the driver. Broker handoff is active.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9A5B13),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (brokerAssigned) ...[
            const SizedBox(height: 12),
            const _BrokerAssignedNotice(),
          ],
          const SizedBox(height: 14),
          if (brokerAssigned) ...[
            _BrokerAssignedActions(
              busy: busy,
              onAccept: onAcceptBrokerAssigned,
              onDecline: onDeclineBrokerAssigned,
            ),
          ] else ...[
            Text(
              canOpen ? 'Slide to open negotiation' : statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF98A2B3),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (canOpen && !brokerAssigned)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 48,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const _RequestThumbShape(),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                activeTrackColor: const Color(0xFFE5E7EB),
                inactiveTrackColor: const Color(0xFFE5E7EB),
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: acceptSlide,
                min: 0,
                max: 1,
                divisions: 100,
                onChanged: (value) {
                  onSlideChanged(value);
                  if (value >= 0.98) {
                    Future.delayed(const Duration(milliseconds: 250), () {
                      if (context.mounted) {
                        onOpenNegotiation();
                      }
                    });
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

String _driverRequestStatusLabel(DriverRequestItem request) {
  final status = request.status.trim().toLowerCase();
  final pendingBy = request.pendingConfirmationBy.trim().toLowerCase();
  if (request.driverTimedOut) {
    return 'Broker handoff active';
  }
  if (status == 'countered') {
    return 'Waiting for the client response';
  }
  if (status == 'awaiting_confirmation') {
    if (pendingBy == 'client') {
      return 'Client accepted. Open the request to confirm.';
    }
    return 'Waiting for client confirmation';
  }
  return 'Negotiation unavailable';
}

class _DriverRequestCard extends StatefulWidget {
  const _DriverRequestCard({
    required this.request,
    required this.busy,
    required this.onOpenNegotiation,
    required this.onAcceptBrokerAssigned,
    required this.onDeclineBrokerAssigned,
  });

  final DriverRequestItem request;
  final bool busy;
  final ValueChanged<DriverRequestItem> onOpenNegotiation;
  final VoidCallback onAcceptBrokerAssigned;
  final VoidCallback onDeclineBrokerAssigned;

  @override
  State<_DriverRequestCard> createState() => _DriverRequestCardState();
}

class _DriverRequestCardState extends State<_DriverRequestCard> {
  double _slideValue = 0;
  bool _opening = false;

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final amount = request.amount > 0 ? request.amount : 0;
    final brokerAssigned = request.isBrokerAssigned;
    final canOpen = request.canNegotiate || brokerAssigned;
    final statusLabel = _driverRequestStatusLabel(request);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.displayRef,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.clientName.isNotEmpty
                          ? request.clientName
                          : 'Client request',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF2FA56E),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              _RoutePointCard(
                label: 'Pickup',
                value: request.pickup,
                accentColor: const Color(0xFF2FA56E),
              ),
              const SizedBox(height: 10),
              _RoutePointCard(
                label: 'Drop',
                value: request.drop,
                accentColor: const Color(0xFFE23A4B),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            [
              if (request.truckType.isNotEmpty) request.truckType,
              if (request.weight.isNotEmpty) request.weight,
              if (request.truckReg.isNotEmpty) request.truckReg,
            ].join(' • '),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          if (request.driverTimedOut) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF4E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF4D3A5)),
              ),
              child: Text(
                'This request timed out for the driver. Broker handoff is active.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9A5B13),
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
          ],
          if (brokerAssigned) ...[
            const SizedBox(height: 12),
            const _BrokerAssignedNotice(),
          ],
          const SizedBox(height: 14),
          if (brokerAssigned) ...[
            _BrokerAssignedActions(
              busy: widget.busy,
              onAccept: widget.onAcceptBrokerAssigned,
              onDecline: widget.onDeclineBrokerAssigned,
            ),
          ] else ...[
            Text(
              canOpen ? 'Swipe to open negotiation' : statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF98A2B3),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 48,
                trackShape: const RoundedRectSliderTrackShape(),
                thumbShape: const _RequestThumbShape(),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 0),
                activeTrackColor: const Color(0xFFE5E7EB),
                inactiveTrackColor: const Color(0xFFE5E7EB),
                thumbColor: Colors.white,
                overlayColor: Colors.transparent,
              ),
              child: Slider(
                value: canOpen ? _slideValue : 0,
                min: 0,
                max: 1,
                divisions: 100,
                onChanged: canOpen
                    ? (value) {
                        setState(() {
                          _slideValue = value;
                        });
                        if (!_opening && value >= 0.98) {
                          _opening = true;
                          Future.delayed(const Duration(milliseconds: 250), () {
                            if (!mounted) return;
                            widget.onOpenNegotiation(request);
                            setState(() => _slideValue = 0);
                            _opening = false;
                          });
                        }
                      }
                    : null,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: canOpen
                    ? () => widget.onOpenNegotiation(request)
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA56E),
                  disabledBackgroundColor: const Color(0xFFE5E7EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Open negotiation',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BrokerAssignedActions extends StatelessWidget {
  const _BrokerAssignedActions({
    required this.busy,
    required this.onAccept,
    required this.onDecline,
  });

  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Already agreed with the broker - accept or decline.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF98A2B3),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: busy ? null : onDecline,
                icon: const Icon(AppIcons.close_rounded, size: 17),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE23A4B),
                  side: const BorderSide(color: Color(0xFFF3B4B4)),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton.icon(
                onPressed: busy ? null : onAccept,
                icon: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(AppIcons.check_rounded, size: 17),
                label: Text(busy ? 'Saving...' : 'Accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA56E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BrokerAssignedNotice extends StatelessWidget {
  const _BrokerAssignedNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCDEFD9)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.handshake_rounded,
            size: 18,
            color: Color(0xFF2FA56E),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Broker-assigned - accept or decline, no negotiation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF2FA56E),
                fontWeight: FontWeight.w800,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutePointCard extends StatelessWidget {
  const _RoutePointCard({
    required this.label,
    required this.value,
    required this.accentColor,
  });

  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final hasValue = value.trim().isNotEmpty;
    final parts = _splitLocationText(value);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasValue ? parts.title : '$label location',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          if (hasValue && parts.subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              parts.subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationTextParts {
  const _LocationTextParts({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

_LocationTextParts _splitLocationText(String value) {
  final raw = value.trim();
  if (raw.isEmpty) {
    return const _LocationTextParts(title: '', subtitle: '');
  }

  final separators = ['\n', ' - ', ' | ', ', '];
  for (final separator in separators) {
    final index = raw.indexOf(separator);
    if (index > 0) {
      final title = raw.substring(0, index).trim();
      final subtitle = raw.substring(index + separator.length).trim();
      if (title.isNotEmpty) {
        return _LocationTextParts(title: title, subtitle: subtitle);
      }
    }
  }

  return _LocationTextParts(title: raw, subtitle: '');
}

class _RequestThumbShape extends SliderComponentShape {
  const _RequestThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(44, 44);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final paint = Paint()..color = Colors.white;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    final rect = Rect.fromCenter(center: center, width: 44, height: 44);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 2)),
        const Radius.circular(14),
      ),
      shadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(14)),
      paint,
    );

    final iconPainter = TextPainter(
      text: const TextSpan(
        text: '\u27A4',
        style: TextStyle(
          color: Color(0xFF2FA56E),
          fontSize: 20,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: textDirection,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2 - 1,
      ),
    );
  }
}
