import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:developer' as developer;

import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../data/driver_dashboard_models.dart';

class DriverRiderScreen extends ConsumerStatefulWidget {
  const DriverRiderScreen({super.key});

  @override
  ConsumerState<DriverRiderScreen> createState() => _DriverRiderScreenState();
}

class _DriverRiderScreenState extends ConsumerState<DriverRiderScreen> {
  late final _LifecycleRefreshObserver _lifecycleRefreshObserver;

  @override
  void initState() {
    super.initState();
    _lifecycleRefreshObserver = _LifecycleRefreshObserver(
      onResume: () {
        if (!mounted) return;
        ref.invalidate(driverDashboardProvider);
      },
    );
    WidgetsBinding.instance.addObserver(_lifecycleRefreshObserver);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(driverDashboardProvider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(_lifecycleRefreshObserver);
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    final _ = await ref.refresh(driverDashboardProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return SafeArea(
      top: false,
      child: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => RefreshIndicator(
          onRefresh: _refreshDashboard,
          color: const Color(0xFF1F88C9),
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
                    style: const TextStyle(color: Color(0xFFE23A4B)),
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
          final history = dashboard.history;
          final currentTripStatus =
              currentTrip?.status.trim().toLowerCase() ?? '';
          final isResumableCompletionTrip = currentTripStatus == 'delivered';

          return RefreshIndicator(
            onRefresh: _refreshDashboard,
            color: const Color(0xFF1F88C9),
            backgroundColor: Colors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                if (currentTrip == null) ...[
                  const _EmptyCard(
                    icon: Icons.route_rounded,
                    title: 'No active delivery',
                    subtitle: 'Accepted deliveries will appear here live.',
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionHeader(
                  title: currentTrip != null
                      ? (isResumableCompletionTrip
                            ? 'Finish delivery'
                            : 'Ongoing delivery')
                      : 'Latest trip activity',
                  subtitle: currentTrip != null
                      ? (isResumableCompletionTrip
                            ? 'Upload proof and complete payment'
                            : 'Current trip in progress')
                      : 'Recent deliveries and settlements',
                  actionLabel: 'View all',
                  onActionTap: () {},
                ),
                const SizedBox(height: 12),
                if (currentTrip != null)
                  _ActiveTripCard(
                    shipment: currentTrip,
                    onTap: () {
                      final tripId = currentTrip.bookingId?.trim() ?? '';
                      if (tripId.isEmpty) {
                        developer.log(
                          'Active trip card tap ignored: missing trip id.',
                          name: 'driver.rider',
                        );
                        return;
                      }
                      developer.log(
                        'Opening driver delivery details from active tab. tripId=$tripId status=${currentTrip.status}',
                        name: 'driver.rider',
                      );
                      if (isResumableCompletionTrip) {
                        final requiresPayment =
                            currentTrip.paymentStatus.trim().toLowerCase() !=
                            'paid';
                        context.push(
                          '/driver/delivery-proof/$tripId?payment=${requiresPayment ? 'pending' : 'paid'}',
                        );
                        return;
                      }

                      context.push('/driver/delivery-details/$tripId');
                    },
                  ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Latest trip activity',
                  subtitle: 'Recent deliveries and settlements',
                  actionLabel: 'View all',
                  onActionTap: () {},
                ),
                const SizedBox(height: 12),
                if (history.isNotEmpty)
                  _TripSummaryCard(
                    settlement: history.first,
                    onTap: () {
                      final settlement = history.first;
                      final bookingId = settlement.bookingId.isNotEmpty
                          ? settlement.bookingId
                          : settlement.bookingNumber;
                      if (bookingId.isEmpty) {
                        return;
                      }
                      context.push(
                        '/driver/deliveries/$bookingId',
                        extra: settlement,
                      );
                    },
                  )
                else
                  const _EmptyCard(
                    icon: Icons.local_shipping_outlined,
                    title: 'No trip activity yet',
                    subtitle:
                        'Recent deliveries and settlements will appear here.',
                  ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Deliveries done',
                  subtitle: 'Recently completed deliveries',
                  actionLabel: 'View all',
                  onActionTap: () {},
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  const _EmptyCard(
                    icon: Icons.inbox_rounded,
                    title: 'No completed deliveries yet',
                    subtitle:
                        'Finished trips will be listed here once they close.',
                  )
                else
                  ...history
                      .skip(1)
                      .toList()
                      .asMap()
                      .entries
                      .expand(
                        (entry) => [
                          _TripSummaryCard(
                            settlement: entry.value,
                            onTap: () {
                              final settlement = entry.value;
                              final bookingId = settlement.bookingId.isNotEmpty
                                  ? settlement.bookingId
                                  : settlement.bookingNumber;
                              if (bookingId.isEmpty) {
                                return;
                              }
                              context.push(
                                '/driver/deliveries/$bookingId',
                                extra: settlement,
                              );
                            },
                          ),
                          if (entry.key != history.skip(1).length - 1)
                            const SizedBox(height: 12),
                        ],
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
  if (_isVisibleDriverTripStatus(activeStatus)) {
    return activeTrip;
  }

  final upcomingStatus = upcomingTrip?.status.trim().toLowerCase() ?? '';
  if (_isVisibleDriverTripStatus(upcomingStatus)) {
    return upcomingTrip;
  }

  return null;
}

bool _isVisibleDriverTripStatus(String status) {
  const visibleStatuses = {
    'accepted',
    'confirmed',
    'en_route_pickup',
    'picked_up',
    'in_transit',
    'delivered',
  };

  return visibleStatuses.contains(status.trim().toLowerCase());
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
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (actionLabel != null) ...[
          const SizedBox(width: 12),
          TextButton(
            onPressed: onActionTap,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF667085),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, size: 18),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ActiveTripCard extends StatelessWidget {
  const _ActiveTripCard({required this.shipment, required this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final route = _splitActiveRoute(shipment.fromLocation, shipment.toLocation);
    final statusLabel = _activeStatusLabel(shipment.status);
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
                        Text(
                          'Active Delivery',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 17,
                                color: const Color(0xFF12824A),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        _ActiveStatusPill(
                          label: statusLabel,
                          isDelivered: isDelivered,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          shipment.trackingId,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontSize: 17,
                                color: const Color(0xFF101828),
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
                              color: const Color(
                                0xFF2FA56E,
                              ).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 15,
                            height: 15,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF2FA56E),
                                width: 1.4,
                              ),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFF2FA56E),
                              size: 8,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 2,
                          child: Image.asset(
                            'assets/driver/active_truck_driver.png',
                            width: 70,
                            height: 44,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3ECE6)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _RouteSummaryColumn(
                        label: 'From',
                        value: route.from,
                        subtitle: route.fromSubtitle,
                        dotColor: const Color(0xFF2FA56E),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 34,
                      child: Column(
                        children: [
                          const SizedBox(height: 2),
                          Icon(
                            Icons.local_shipping_rounded,
                            size: 15,
                            color: const Color(0xFF2FA56E),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 2,
                            height: 10,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBFE7CE),
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            Icons.flag_rounded,
                            size: 14,
                            color: const Color(0xFF2FA56E),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RouteSummaryColumn(
                        label: 'To',
                        value: route.to,
                        subtitle: route.toSubtitle,
                        dotColor: const Color(0xFF2FA56E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 360;
                  final detailsButton = SizedBox(
                    width: narrow ? double.infinity : 126,
                    height: 38,
                    child: FilledButton(
                      onPressed: onTap,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1F9D57),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'View Details',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                        ],
                      ),
                    ),
                  );

                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _ExpectedDeliveryBlock(
                          label: 'Status',
                          value: isDelivered ? 'Delivered' : 'In progress',
                        ),
                        const SizedBox(height: 10),
                        detailsButton,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: _ExpectedDeliveryBlock(
                          label: 'Status',
                          value: isDelivered ? 'Delivered' : 'In progress',
                        ),
                      ),
                      const SizedBox(width: 10),
                      detailsButton,
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

class _RouteSummaryColumn extends StatelessWidget {
  const _RouteSummaryColumn({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.dotColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    final displayTitle = value.trim().isEmpty ? '$label location' : value;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: dotColor.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF98A2B3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
        ),
      ],
    );
  }
}

class _ExpectedDeliveryBlock extends StatelessWidget {
  const _ExpectedDeliveryBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FA),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFE1E6ED)),
          ),
          child: const Icon(
            Icons.access_time_rounded,
            size: 18,
            color: Color(0xFF667085),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF98A2B3),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
        ? const Color(0xFFBFE7CE)
        : const Color(0xFF96DEB0);
    final textColor = isDelivered
        ? const Color(0xFF0F7A43)
        : const Color(0xFF12824A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
        ),
      ),
    );
  }
}

class _TripSummaryCard extends StatelessWidget {
  const _TripSummaryCard({required this.settlement, required this.onTap});

  final BrokerSettlement settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final route = _splitRoute(settlement.route);
    final bookingId = settlement.bookingId.isNotEmpty
        ? settlement.bookingId
        : settlement.bookingNumber;
    final status = settlement.status.trim().toLowerCase();
    final isCompleted =
        status == 'completed' || status == 'paid' || status == 'settled';
    final statusColor = isCompleted
        ? const Color(0xFF2FA56E)
        : const Color(0xFFF59E0B);
    final leadingBg = isCompleted
        ? const Color(0xFFE7F7EC)
        : const Color(0xFFFDF1DA);
    final leadingIcon = isCompleted
        ? Icons.check_rounded
        : Icons.schedule_rounded;
    final dateLabel =
        settlement.settledAt != null && settlement.settledAt!.trim().isNotEmpty
        ? _formatDisplayDate(settlement.settledAt!)
        : 'Today';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE4E8EE)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.035),
                blurRadius: 24,
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
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: leadingBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(leadingIcon, size: 30, color: statusColor),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF101828),
                                height: 1.15,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: _StatusPill(status: settlement.status),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.visibility_rounded,
                      size: 20,
                      color: Color(0xFF1F88C9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _TripRouteRow(from: route.from, to: route.to),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFECEFF3)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TripMetric(
                      label: isCompleted ? 'Delivered on' : 'Booking time',
                      value: dateLabel,
                      icon: Icons.event_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TripMetric(
                      label: isCompleted ? 'Earnings' : 'Amount',
                      value: '₹${settlement.netEarnings.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TripMetric(
                      label: 'Status',
                      value: settlement.status,
                      icon: Icons.circle,
                      valueColor: statusColor,
                      iconColor: statusColor,
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

class _TripRouteRow extends StatelessWidget {
  const _TripRouteRow({required this.from, required this.to});

  final String from;
  final String to;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16,
          child: Column(
            children: [
              const SizedBox(height: 4),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.fiber_manual_record,
                    size: 4,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ),
              Container(
                width: 2,
                height: 22,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFD8DDE5),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.fiber_manual_record,
                    size: 4,
                    color: Color(0xFF2FA56E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                from,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1C2430),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                to,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1C2430),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final resolvedIconColor = iconColor ?? const Color(0xFF98A2B3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: resolvedIconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF98A2B3),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? const Color(0xFF101828),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

({String from, String fromSubtitle, String to, String toSubtitle})
_splitActiveRoute(String from, String to) {
  return (
    from: _splitRouteText(from).title,
    fromSubtitle: _splitRouteText(from).subtitle,
    to: _splitRouteText(to).title,
    toSubtitle: _splitRouteText(to).subtitle,
  );
}

({String title, String subtitle}) _splitRouteText(String value) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    return (title: 'Location unavailable', subtitle: '');
  }

  final separators = ['\n', ' - ', ' | ', ', '];
  for (final separator in separators) {
    final index = normalized.indexOf(separator);
    if (index > 0) {
      final title = normalized.substring(0, index).trim();
      final subtitle = normalized.substring(index + separator.length).trim();
      if (title.isNotEmpty) {
        return (title: title, subtitle: subtitle);
      }
    }
  }

  return (title: normalized, subtitle: '');
}

String _activeStatusLabel(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'In Progress';
  }
  if (normalized == 'delivered') {
    return 'Delivered';
  }
  if (normalized == 'accepted' ||
      normalized == 'confirmed' ||
      normalized == 'en_route_pickup' ||
      normalized == 'en route' ||
      normalized == 'en_route' ||
      normalized == 'in_transit' ||
      normalized == 'in transit' ||
      normalized == 'picked_up' ||
      normalized == 'picked up') {
    return 'In Progress';
  }
  return normalized
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
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
            border: Border.all(color: const Color(0xFFE8EDF2)),
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
                      color: const Color(0xFFEAF7EF),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SvgPicture.string(
                        _doneTickSvg,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF10A64A),
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
                                color: const Color(0xFF101828),
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
                      color: const Color(0xFFF7FAFD),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.visibility_rounded,
                      size: 18,
                      color: Color(0xFF1F88C9),
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
                            color: const Color(
                              0xFF2FA56E,
                            ).withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2FA56E),
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
                            color: const Color(
                              0xFF2FA56E,
                            ).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF2FA56E,
                            ).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF2FA56E),
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
                                color: const Color(0xFF1C2430),
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
                                color: const Color(0xFF1C2430),
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
              const Divider(height: 1, color: Color(0xFFECEFF3)),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA56E),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2FA56E,
                          ).withValues(alpha: 0.25),
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
                      color: const Color(0xFF1C2430),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      settlement.status,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
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
      'paid' || 'settled' => const Color(0xFF2FA56E),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF667085),
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

const String _doneTickSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 122.88 101.6">
  <title>tick-green</title>
  <path fill="#10A64A" d="M4.67,67.27c-14.45-15.53,7.77-38.7,23.81-24C34.13,48.4,42.32,55.9,48,61L93.69,5.3c15.33-15.86,39.53,7.42,24.4,23.36L61.14,96.29a17,17,0,0,1-12.31,5.31h-.2a16.24,16.24,0,0,1-11-4.26c-9.49-8.8-23.09-21.71-32.91-30v0Z"/>
</svg>
''';
