import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';
import 'tracking_details_screen.dart';
import '../widgets/client_flow_widgets.dart';

class ClientDeliveryScreen extends ConsumerStatefulWidget {
  const ClientDeliveryScreen({super.key});

  @override
  ConsumerState<ClientDeliveryScreen> createState() => _ClientDeliveryScreenState();
}

class _ClientDeliveryScreenState extends ConsumerState<ClientDeliveryScreen> {
  static const int _pageSize = 20;

  Future<void> _refreshBookings() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final query = (status: null, page: 1, limit: _pageSize);
    final refreshed = ref.refresh(clientBookingsProvider(query).future);
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final query = (status: null, page: 1, limit: _pageSize);
    final bookingsAsync = session == null
        ? null
        : ref.watch(clientBookingsProvider(query));

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF2FA56E),
        onRefresh: _refreshBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
          children: [
            const _TrackingHeroCard(),
            const SizedBox(height: 14),
            if (session == null)
              const _EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to view bookings',
                subtitle: 'We need an active client session before we can load your activity feed.',
              )
            else if (bookingsAsync == null)
              const SizedBox.shrink()
            else
              bookingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load bookings',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                  actionLabel: 'Try again',
                  onAction: _refreshBookings,
                ),
                data: (page) {
                  final bookings = page.bookings;
                  if (bookings.isEmpty) {
                    return _EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No bookings found',
                      subtitle: 'Once a booking is created, it will show up here.',
                      actionLabel: 'Refresh',
                      onAction: _refreshBookings,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${bookings.length} booking${bookings.length == 1 ? '' : 's'} loaded',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF667085),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ...bookings.asMap().entries.expand(
                            (entry) => [
                              ClientBookingCard(
                                booking: entry.value,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => TrackingDetailsScreen(
                                        shipment: trackingShipmentFromBooking(entry.value),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              if (entry.key != bookings.length - 1) const SizedBox(height: 12),
                            ],
                          ),
                      if (page.totalPages > 1) ...[
                        const SizedBox(height: 14),
                        Center(
                          child: Text(
                            'Page ${page.page} of ${page.totalPages}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF98A2B3),
                                ),
                          ),
                        ),
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

class _TrackingHeroCard extends StatelessWidget {
  const _TrackingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF2FA56E),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2FA56E).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track your package',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please enter tracking number',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search_rounded, color: Colors.black45, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tracking number',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF101828),
                          fontSize: 15,
                        ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8B84D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 20,
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

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF667085), size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
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
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class ClientBookingCard extends StatelessWidget {
  const ClientBookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  final ClientBooking booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F3F7)),
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
                  color: const Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset(
                  'assets/package.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF121826),
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.displaySubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black45,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: booking.displayStatusLabel, color: statusColor),
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
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
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
                      height: 28,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking.pickupLocation.isEmpty ? 'Pickup location not provided' : booking.pickupLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF1C2430),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Shipping to:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black38,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking.dropoffLocation.isEmpty ? 'Drop-off location not provided' : booking.dropoffLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          if (booking.packageName.isNotEmpty ||
              booking.weight.isNotEmpty ||
              booking.vehicleType.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_rounded, color: Color(0xFF667085), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if (booking.packageName.isNotEmpty) booking.packageName,
                        if (booking.weight.isNotEmpty) booking.weight,
                        if (booking.vehicleType.isNotEmpty) booking.vehicleType,
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF1C2430),
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  if (booking.amountText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.amountText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF1F88C9),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (booking.id.isNotEmpty)
                Text(
                  booking.id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'delivered':
      return const Color(0xFF2FA56E);
    case 'cancelled':
      return const Color(0xFFE23A4B);
    case 'confirmed':
    case 'assigned':
    case 'in_transit':
    case 'en_route_pickup':
    case 'picked_up':
      return const Color(0xFF1F88C9);
    case 'pending':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF667085);
  }
}
