import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFFE23A4B)),
            ),
          ),
        ),
        data: (dashboard) {
          final activeTrip = dashboard.activeTrip;
          final history = dashboard.history;

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
                if (activeTrip == null) ...[
                  const _EmptyCard(
                    icon: Icons.route_rounded,
                    title: 'No active delivery',
                    subtitle: 'Accepted deliveries will appear here live.',
                  ),
                  const SizedBox(height: 18),
                ],
                _SectionHeader(
                  title: activeTrip != null
                      ? 'Ongoing delivery'
                      : 'Latest trip activity',
                  subtitle: activeTrip != null
                      ? 'Current trip in progress'
                      : 'Recent deliveries and settlements',
                ),
                const SizedBox(height: 12),
                if (activeTrip != null)
                  _ActiveTripCard(
                    shipment: activeTrip,
                    onTap: () {
                      final tripId = activeTrip.bookingId?.trim() ?? '';
                      if (tripId.isEmpty) {
                        return;
                      }
                      context.push('/driver/delivery-details/$tripId');
                    },
                  )
                else if (history.isNotEmpty)
                  _TripHistoryCard(
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
                    title: 'No delivery history yet',
                    subtitle:
                        'Completed trips will appear here once available.',
                  ),
                const SizedBox(height: 18),
                _SectionHeader(
                  title: 'Deliveries done',
                  subtitle: 'Recently completed deliveries',
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
                  ...history.asMap().entries.expand(
                    (entry) => [
                      _TripHistoryCard(
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
                      if (entry.key != history.length - 1)
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
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFFAF4),
                      shape: BoxShape.circle,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(
                        'assets/trucks/speed.png',
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
                          'Current delivery',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF121826),
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          shipment.trackingId,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Colors.black45,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF7EF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      shipment.status,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF2FA56E),
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
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
                          shipment.fromLocation,
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
                          shipment.toLocation,
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
                      shipment.status,
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
