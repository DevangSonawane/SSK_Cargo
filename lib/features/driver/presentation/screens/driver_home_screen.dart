import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/driver_dashboard_models.dart';
import '../../data/driver_trip_handoff_utils.dart';
import '../../data/driver_request_models.dart';
import '../widgets/slide_to_action.dart';

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
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
          backgroundColor: accept ? AppColors.brand : AppColors.dangerIcon,
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
          backgroundColor: AppColors.dangerIcon,
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
          backgroundColor: AppColors.dangerIcon,
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
                          ? AppColors.textTertiary
                          : AppColors.dangerText,
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
                      activeThumbColor: AppColors.brand,
                      activeTrackColor: AppColors.brand.withValues(alpha: 0.35),
                      inactiveThumbColor: AppColors.surface,
                      inactiveTrackColor: AppColors.dangerIcon.withValues(
                        alpha: 0.35,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isOnline
                          ? AppColors.brand
                          : AppColors.textTertiary,
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
                  color: AppColors.brandFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Text(
                  'Active trip in progress. Online mode stays locked until the trip is completed.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: AppColors.divider),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Deliveries',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
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
                                color: AppColors.textPrimary,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.fillSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.textTertiary, size: 34),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
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
    required this.busy,
    required this.onOpenNegotiation,
    required this.onAcceptBrokerAssigned,
    required this.onDeclineBrokerAssigned,
  });

  final DriverRequestItem request;
  final bool busy;
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
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
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.displayRef,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: AppColors.divider),
          const SizedBox(height: 14),
          Column(
            children: [
              _RoutePointCard(
                label: 'Pickup',
                value: request.pickup,
                accentColor: AppColors.brand,
              ),
              const SizedBox(height: 10),
              _RoutePointCard(
                label: 'Drop',
                value: request.drop,
                accentColor: AppColors.dangerIcon,
              ),
            ],
          ),
          if (request.driverTimedOut) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Text(
                'This request timed out for the driver. Broker handoff is active.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warningText,
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
          if (brokerAssigned)
            _BrokerAssignedActions(
              busy: busy,
              onAccept: onAcceptBrokerAssigned,
              onDecline: onDeclineBrokerAssigned,
            )
          else if (canOpen)
            SlideToAction(
              label: 'Swipe to accept',
              onCompleted: onOpenNegotiation,
            )
          else
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
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
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.clientName.isNotEmpty
                          ? request.clientName
                          : 'Client request',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
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
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '₹${amount.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.brand,
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
                accentColor: AppColors.brand,
              ),
              const SizedBox(height: 10),
              _RoutePointCard(
                label: 'Drop',
                value: request.drop,
                accentColor: AppColors.dangerIcon,
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
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (request.driverTimedOut) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warningFill,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.warningBorder),
              ),
              child: Text(
                'This request timed out for the driver. Broker handoff is active.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.warningText,
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
          ] else if (canOpen) ...[
            SlideToAction(
              label: 'Swipe to accept',
              onCompleted: () => widget.onOpenNegotiation(request),
            ),
          ] else ...[
            Text(
              statusLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w600,
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
            color: AppColors.textTertiary,
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
                  foregroundColor: AppColors.dangerText,
                  side: const BorderSide(color: AppColors.dangerBorder),
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
                  backgroundColor: AppColors.brand,
                  foregroundColor: AppColors.textOnBrand,
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
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.handshake_rounded,
            size: 18,
            color: AppColors.brand,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Broker-assigned - accept or decline, no negotiation.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.brand,
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppShadows.card,
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
                  color: AppColors.textPrimary,
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
              color: AppColors.textPrimary,
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
                color: AppColors.textSecondary,
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