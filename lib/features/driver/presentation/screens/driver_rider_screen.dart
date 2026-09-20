import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssk/core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart'
    show TrackingDemoShipment;
import '../../../shared/presentation/widgets/express_badge.dart';
import '../../data/driver_trip_handoff_utils.dart';
import '../../data/driver_dashboard_models.dart';
import '../widgets/history_segment_bar.dart';
import '../widgets/trip_summary_card.dart';

class DriverRiderScreen extends ConsumerStatefulWidget {
  const DriverRiderScreen({super.key});

  @override
  ConsumerState<DriverRiderScreen> createState() => _DriverRiderScreenState();
}

class DriverAllTripsScreen extends ConsumerWidget {
  const DriverAllTripsScreen({super.key});

  Future<void> _refresh(WidgetRef ref) {
    ref.invalidate(driverDashboardProvider);
    return ref.refresh(driverDashboardProvider.future);
  }

  void _openTrip(BuildContext context, DriverTripSummary trip) {
    final bookingId = trip.bookingId.isNotEmpty
        ? trip.bookingId
        : trip.bookingNumber;
    if (bookingId.isEmpty) {
      return;
    }
    context.push('/driver/deliveries/$bookingId', extra: trip.toSettlement());
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => RefreshIndicator(
            onRefresh: () => _refresh(ref),
            color: AppColors.brand,
            backgroundColor: Colors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              children: [
                _AllTripsHeader(onBack: () => context.pop()),
                const SizedBox(height: 120),
                Text(
                  error.toString().replaceFirst('Exception: ', ''),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.dangerText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          data: (dashboard) {
            final trips = dashboard.tripFeed;
            final grouped = _groupTripsByDay(trips);

            return RefreshIndicator(
              onRefresh: () => _refresh(ref),
              color: AppColors.brand,
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                children: [
                  _AllTripsHeader(onBack: () => context.pop()),
                  const SizedBox(height: 14),
                  if (trips.isEmpty)
                    const _EmptyCard(
                      icon: AppIcons.route_rounded,
                      title: 'No trips yet',
                      subtitle: 'Your full trip history will appear here.',
                    )
                  else ...[
                    _TripsStatsStrip(trips: trips),
                    const SizedBox(height: 24),
                    ...grouped.asMap().entries.expand((groupEntry) {
                      final group = groupEntry.value;
                      return [
                        _DayGroupHeader(
                          label: _tripDayLabel(group.key),
                          count: group.value.length,
                        ),
                        const SizedBox(height: 10),
                        ...group.value.asMap().entries.expand(
                          (entry) => [
                            TripSummaryCard(
                              trip: entry.value,
                              onTap: () => _openTrip(context, entry.value),
                            ),
                            if (entry.key != group.value.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ),
                        if (groupEntry.key != grouped.length - 1)
                          const SizedBox(height: 22),
                      ];
                    }),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _AllTripsHeader extends StatelessWidget {
  const _AllTripsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.fillSubtle,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                AppIcons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'All Trips',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Latest activity and completed deliveries',
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
    );
  }
}

class _DriverRiderScreenState extends ConsumerState<DriverRiderScreen> {
  late final _LifecycleRefreshObserver _lifecycleRefreshObserver;
  Timer? _refreshTimer;
  StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;
  int _historyTab = 0;

  @override
  void initState() {
    super.initState();
    _lifecycleRefreshObserver = _LifecycleRefreshObserver(
      onResume: () {
        _invalidateDashboard();
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleRefreshObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _invalidateDashboard();
      unawaited(_startLiveUpdates());
      _refreshTimer?.cancel();
      _refreshTimer = Timer.periodic(const Duration(seconds: 8), (_) {
        _invalidateDashboard();
      });
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tripStatusSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleRefreshObserver);
    super.dispose();
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
      if (!mounted) {
        return;
      }

      final dashboard = ref.read(driverDashboardProvider).valueOrNull;
      final currentTrip = _selectCurrentTrip(
        dashboard?.activeTrip,
        dashboard?.upcomingTrip,
      );
      if (currentTrip == null) {
        return;
      }

      if (!responseMatchesAnyReference(payload, [
        currentTrip.tripId ?? '',
        currentTrip.bookingId ?? '',
      ])) {
        return;
      }

      _invalidateDashboard();
    });
  }

  void _invalidateDashboard() {
    if (!mounted) return;
    ref.invalidate(driverDashboardProvider);
  }

  Future<void> _refreshDashboard() {
    if (!mounted) return Future.value();
    return ref.refresh(driverDashboardProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return SafeArea(
      top: false,
      child: dashboardAsync.when(
        loading: () => RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppColors.brand,
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: const [
              _EmptyCard(
                icon: AppIcons.route_rounded,
                title: 'No active delivery',
                subtitle: 'Accepted deliveries will appear here live.',
              ),
              SizedBox(height: 18),
              _SegmentBarPlaceholder(),
              SizedBox(height: 12),
              _InlineEmptyMessage(message: 'Loading trips...'),
            ],
          ),
        ),
        error: (error, _) => RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: AppColors.brand,
          backgroundColor: Colors.white,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.55,
                child: Center(
                  child: Text(
                    error.toString().replaceFirst('Exception: ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.dangerText),
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (dashboard) {
          final currentTrip = _selectCurrentTrip(
            dashboard.activeTrip,
            dashboard.upcomingTrip,
          );
          final tripFeed = dashboard.tripFeed;
          final pendingHistory = tripFeed.where(_isPendingTrip).toList();
          final completedHistory = tripFeed.where(_isCompletedTrip).toList();

          final showCompleted = _historyTab == 1;
          final visibleTrips = showCompleted
              ? completedHistory
              : pendingHistory;

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: AppColors.brand,
            backgroundColor: Colors.white,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionHeader(
                          title: 'Active delivery',
                          subtitle: 'Your live trip appears here first',
                        ),
                        const SizedBox(height: 12),
                        if (currentTrip == null)
                          const _EmptyCard(
                            icon: AppIcons.route_rounded,
                            title: 'No active delivery',
                            subtitle:
                                'Accepted deliveries will appear here live.',
                          )
                        else
                          _ActiveTripCard(
                            shipment: currentTrip,
                            onTap: () {
                              final tripId =
                                  currentTrip.tripId?.trim() ?? '';
                              final bookingId =
                                  currentTrip.bookingId?.trim() ?? '';
                              final effectiveTripId = tripId.isNotEmpty
                                  ? tripId
                                  : bookingId;
                              if (effectiveTripId.isEmpty) {
                                return;
                              }
                              context.go(
                                '/driver/delivery-details/$effectiveTripId',
                              );
                            },
                          ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: HistorySegmentHeaderDelegate(
                    upcomingCount: pendingHistory.length,
                    completedCount: completedHistory.length,
                    selectedIndex: _historyTab,
                    onChanged: (index) {
                      HapticFeedback.selectionClick();
                      setState(() => _historyTab = index);
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                showCompleted
                                    ? 'Recently completed deliveries'
                                    : 'Pending deliveries and settlements',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () =>
                                  context.push('/driver/all-trips'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.textSecondary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 4,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'View all',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Icon(
                                    AppIcons.chevron_right_rounded,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final offset =
                                Tween<Offset>(
                                  begin: Offset(
                                    showCompleted ? 0.05 : -0.05,
                                    0,
                                  ),
                                  end: Offset.zero,
                                ).animate(animation);
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: offset,
                                child: child,
                              ),
                            );
                          },
                          child: visibleTrips.isEmpty
                              ? Column(
                                  key: ValueKey(
                                    showCompleted ? 'empty-done' : 'empty-upcoming',
                                  ),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _InlineEmptyMessage(
                                      message: showCompleted
                                          ? 'No deliveries done yet, start working'
                                          : 'No latest trip yet',
                                    ),
                                  ],
                                )
                              : Column(
                                  key: ValueKey(
                                    showCompleted ? 'list-done' : 'list-upcoming',
                                  ),
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    ...visibleTrips.asMap().entries.expand(
                                      (entry) => [
                                        TripSummaryCard(
                                          trip: entry.value,
                                          onTap: () {
                                            final trip = entry.value;
                                            final bookingId = trip
                                                    .bookingId
                                                    .isNotEmpty
                                                ? trip.bookingId
                                                : trip.bookingNumber;
                                            if (bookingId.isEmpty) {
                                              return;
                                            }
                                            context.push(
                                              '/driver/deliveries/$bookingId',
                                              extra: trip.toSettlement(),
                                            );
                                          },
                                        ),
                                        if (entry.key !=
                                            visibleTrips.length - 1)
                                          const SizedBox(height: 12),
                                      ],
                                    ),
                                  ],
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
    );
  }
}

TrackingDemoShipment? _selectCurrentTrip(
  TrackingDemoShipment? activeTrip,
  TrackingDemoShipment? upcomingTrip,
) {
  final activeStatus = activeTrip?.status.trim().toLowerCase() ?? '';
  return _isVisibleDriverTripStatus(activeStatus) ? activeTrip : null;
}

bool _isVisibleDriverTripStatus(String status) {
  const visibleStatuses = {
    'accepted',
    'confirmed',
    'en_route_pickup',
    'picked_up',
    'in_transit',
  };

  return visibleStatuses.contains(status.trim().toLowerCase());
}

bool _isCompletedTrip(DriverTripSummary trip) {
  final status = trip.status.trim().toLowerCase();
  return status == 'completed' ||
      status == 'delivered' ||
      status == 'paid' ||
      status == 'settled';
}

bool _isCancelledTrip(DriverTripSummary trip) {
  final status = trip.status.trim().toLowerCase();
  return status == 'cancelled' ||
      status == 'canceled' ||
      status == 'rejected' ||
      status == 'declined' ||
      status == 'expired';
}

bool _isPendingTrip(DriverTripSummary trip) {
  return !_isCompletedTrip(trip) && !_isCancelledTrip(trip);
}

class _LifecycleRefreshObserver extends WidgetsBindingObserver {
  _LifecycleRefreshObserver({required this.onResume});

  final VoidCallback onResume;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    );
  }
}

/// Sticky Upcoming / Completed switcher (Rapido "My Rides" style) with count
/// badges. Selecting a segment swaps the trip list below it.
/// Loading-state placeholder mirroring the segment bar shape.
class _SegmentBarPlaceholder extends StatelessWidget {
  const _SegmentBarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDisplayDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '${months[parsed.month - 1]} ${parsed.day}, $hour:$minute $period';
}

String _tripDayKey(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '${local.year}-$month-$day';
}

String _tripDayLabel(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }
  final local = parsed.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) {
    return 'Today';
  }
  if (diff == 1) {
    return 'Yesterday';
  }
  return _formatDisplayDate(local.toIso8601String()).split(',').first;
}

List<MapEntry<String, List<DriverTripSummary>>> _groupTripsByDay(
  List<DriverTripSummary> trips,
) {
  final grouped = <String, List<DriverTripSummary>>{};
  for (final trip in trips) {
    final key = _tripDayKey(trip.bookingTime);
    grouped.putIfAbsent(key, () => []).add(trip);
  }
  final keys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  return [for (final key in keys) MapEntry(key, grouped[key]!)];
}

class _TripsStatsStrip extends StatelessWidget {
  const _TripsStatsStrip({required this.trips});

  final List<DriverTripSummary> trips;

  @override
  Widget build(BuildContext context) {
    final totalEarned = trips
        .where((trip) => trip.amount > 0)
        .fold<double>(0, (sum, trip) => sum + trip.amount);
    final completed = trips.where(_isCompletedTrip).length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF2FA56E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(value: '${trips.length}', label: 'Total trips'),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 34, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCell(
              value: '₹${totalEarned.round()}',
              label: 'Total earned',
            ),
          ),
          const SizedBox(width: 16),
          Container(width: 1, height: 34, color: Colors.white24),
          const SizedBox(width: 16),
          Expanded(
            child: _StatCell(value: '$completed', label: 'Completed'),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DayGroupHeader extends StatelessWidget {
  const _DayGroupHeader({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.brand,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.fillSubtle,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count ${count == 1 ? 'trip' : 'trips'}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

// ignore: unused_element
class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.settlement, required this.onTap});

  final BrokerSettlement settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final route = _splitRoute(settlement.route);
    final bookingId = settlement.bookingId.isNotEmpty
        ? settlement.bookingId
        : settlement.bookingNumber;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.brandTint,
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.string(
                        _doneTickSvg,
                        colorFilter: const ColorFilter.mode(
                          AppColors.brandBright,
                          BlendMode.srcIn,
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bookingId.isEmpty
                              ? settlement.bookingNumber
                              : bookingId,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(status: settlement.status),
                  const SizedBox(width: 8),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      AppIcons.visibility_rounded,
                      size: 18,
                      color: AppColors.brand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 14,
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black38,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          route.from,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textHeading,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'To:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black38,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          route.to,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textHeading,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.fillSubtle),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppColors.brand,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brand.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Status:',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textHeading,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      settlement.status,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textHeading,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'paid' || 'settled' => AppColors.brand,
      'pending' => AppColors.warningText,
      _ => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

({String from, String to}) _splitRoute(String route) {
  final normalized = route.trim();
  if (normalized.isEmpty) {
    return (from: 'From location unavailable', to: 'To location unavailable');
  }

  const separators = [' → ', ' -> ', ' to ', ' - '];
  for (final separator in separators) {
    final parts = normalized.split(separator);
    if (parts.length >= 2) {
      return (
        from: parts.first.trim(),
        to: parts.sublist(1).join(separator).trim(),
      );
    }
  }

  return (from: normalized, to: 'To location unavailable');
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
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
        border: Border.all(color: AppColors.divider),
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

class _InlineEmptyMessage extends StatelessWidget {
  const _InlineEmptyMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.shipment, required this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusLabel = tripStatusLabel(shipment.status);
    final isDelivered = shipment.status.trim().toLowerCase() == 'delivered';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF4FBF7), Color(0xFFEAF8EF), Colors.white],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFD7EEDF)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2FA56E).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ActiveStatusPill(
                          label: statusLabel,
                          isDelivered: isDelivered,
                        ),
                        if (shipment.isExpress) ...[
                          const SizedBox(height: 8),
                          const ExpressBadge(compact: true),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          shipment.trackingId,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 17,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                                height: 1.02,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 92,
                    height: 72,
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          right: 0,
                          top: 2,
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.brand.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Image.asset(
                            'assets/driver/active_truck_driver.png',
                            width: 94,
                            height: 58,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 14,
                    child: Column(
                      children: [
                        const SizedBox(height: 3),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          margin: const EdgeInsets.symmetric(vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.brand.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: AppColors.brand,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'From:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black38,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 1),
                        _ResolvedLocation(
                          label: shipment.fromLocation,
                          latitude: shipment.pickupLat,
                          longitude: shipment.pickupLng,
                          resolvingText: 'Locating pickup…',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'To:',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black38,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 1),
                        _ResolvedLocation(
                          label: shipment.toLocation,
                          latitude: shipment.dropLat,
                          longitude: shipment.dropLng,
                          resolvingText: 'Locating drop-off…',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: AppColors.fillSubtle),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 370;
                  final buttonWidth = compact
                      ? 104.0
                      : (constraints.maxWidth * 0.34).clamp(112.0, 126.0);
                  final statusFontSize = compact ? 11.0 : 12.0;
                  final detailsFontSize = compact ? 11.0 : 12.0;
                  final iconSize = compact ? 13.0 : 14.0;

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 1),
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.brand.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isDelivered ? 'Delivered' : 'In progress',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: AppColors.textHeading,
                                fontWeight: FontWeight.w600,
                                fontSize: statusFontSize,
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: buttonWidth,
                        height: 38,
                        child: FilledButton(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 8 : 10,
                            ),
                            backgroundColor: AppColors.brandDark,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: detailsFontSize,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  AppIcons.arrow_forward_rounded,
                                  size: iconSize,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResolvedLocation extends ConsumerStatefulWidget {
  const _ResolvedLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.resolvingText,
  });

  final String label;
  final double? latitude;
  final double? longitude;
  final String resolvingText;

  @override
  ConsumerState<_ResolvedLocation> createState() => _ResolvedLocationState();
}

class _ResolvedLocationState extends ConsumerState<_ResolvedLocation> {
  bool _resolving = false;
  String _resolved = '';

  @override
  void initState() {
    super.initState();
    final lat = widget.latitude ?? 0;
    final lng = widget.longitude ?? 0;
    if (_isPlaceholder(widget.label) && (lat != 0 || lng != 0)) {
      _resolving = true;
      _resolve(lat, lng);
    }
  }

  bool _isPlaceholder(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ||
        trimmed == 'Pickup location not provided' ||
        trimmed == 'Drop-off location not provided';
  }

  Future<void> _resolve(double lat, double lng) async {
    String address = '';
    try {
      address = await ref
          .read(googlePlacesServiceProvider)
          .reverseGeocode(latitude: lat, longitude: lng);
    } catch (_) {
      address = '';
    }
    if (!mounted) return;
    setState(() {
      _resolved = address.trim();
      _resolving = false;
    });
  }

  String get _display => _resolving
      ? widget.resolvingText
      : (_resolved.isNotEmpty ? _resolved : widget.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      _display,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        color: AppColors.textHeading,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
    );
  }
}

class _ActiveStatusPill extends StatelessWidget {
  const _ActiveStatusPill({required this.label, required this.isDelivered});

  final String label;
  final bool isDelivered;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDelivered
        ? AppColors.brandBorder
        : AppColors.brandBorder;
    final textColor = isDelivered ? AppColors.brandDark : AppColors.brandDark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

const String _doneTickSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 122.88 101.6">
  <title>tick-green</title>
  <path fill="#10A64A" d="M4.67,67.27c-14.45-15.53,7.77-38.7,23.81-24C34.13,48.4,42.32,55.9,48,61L93.69,5.3c15.33-15.86,39.53,7.42,24.4,23.36L61.14,96.29a17,17,0,0,1-12.31,5.31h-.2a16.24,16.24,0,0,1-11-4.26c-9.49-8.8-23.09-21.71-32.91-30v0Z"/>
</svg>
''';
