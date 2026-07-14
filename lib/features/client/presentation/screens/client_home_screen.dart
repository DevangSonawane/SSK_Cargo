import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';
import 'tracking_details_screen.dart';
import '../widgets/client_flow_widgets.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  double _refreshTurns = 0;
  TripType _selectedTripType = TripType.interCity;
  final TextEditingController _whereToController = TextEditingController();
  static const int _recentBookingsLimit = 3;

  @override
  void dispose() {
    _whereToController.dispose();
    super.dispose();
  }

  Future<void> _openBookingLocation({required int vehicleIndex}) async {
    HapticFeedback.lightImpact();
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BookingLocationScreen(
            tripType: _selectedTripType,
            initialVehicleIndex: vehicleIndex,
          ),
        ),
      );
    } finally {
      if (mounted) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      }
    }
  }

  Future<void> _refreshRecentBookings() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final query = (status: null, page: 1, limit: _recentBookingsLimit);
    final refreshed = ref.refresh(clientBookingsProvider(query).future);
    await refreshed;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final recentBookingsQuery = (
      status: null,
      page: 1,
      limit: _recentBookingsLimit,
    );
    final recentBookingsAsync = session == null
        ? null
        : ref.watch(clientBookingsProvider(recentBookingsQuery));
    final pricingState = ref.watch(clientPricingProvider);
    final vehicles = resolveVehicleOptions(
      tripType: _selectedTripType,
      pricing: pricingState.valueOrNull,
      isLoading: pricingState.isLoading,
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TripHeader(
              selectedTripType: _selectedTripType,
              onTripTypeChanged: (value) {
                if (_selectedTripType != value) {
                  HapticFeedback.lightImpact();
                }
                setState(() {
                  _selectedTripType = value;
                });
              },
            ),
            const SizedBox(height: 14),
            _WhereToPill(controller: _whereToController),
            const SizedBox(height: 12),
            const _RecentAddressCard(),
            const SizedBox(height: 16),
            Text(
              'Vehicles we provide',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: vehicles.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 8,
                childAspectRatio: 1.45,
              ),
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return _VehiclePreviewTile(
                  vehicle: vehicle,
                  onTap: () {
                    _openBookingLocation(vehicleIndex: index);
                  },
                );
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'View all',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.black45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _refreshTurns += 1;
                    });
                    await _refreshRecentBookings();
                  },
                  icon: AnimatedRotation(
                    turns: _refreshTurns,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeInOut,
                    child: const Icon(Icons.refresh_rounded),
                  ),
                  color: Colors.black54,
                  tooltip: 'Refresh',
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (session == null)
              const _HomeEmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to view bookings',
                subtitle:
                    'Recent bookings will appear here once you are signed in.',
              )
            else if (recentBookingsAsync == null)
              const SizedBox.shrink()
            else
              recentBookingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _HomeEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load bookings',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                  actionLabel: 'Try again',
                  onAction: _refreshRecentBookings,
                ),
                data: (page) {
                  final bookings = page.bookings;
                  if (bookings.isEmpty) {
                    return const _HomeEmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No bookings yet',
                      subtitle:
                          'Once you create a booking, it will appear here.',
                    );
                  }

                  return Column(
                    children: [
                      ...bookings.asMap().entries.expand(
                        (entry) => [
                          _RecentBookingCard(
                            booking: entry.value,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => TrackingDetailsScreen(
                                    shipment: trackingShipmentFromBooking(
                                      entry.value,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          if (entry.key != bookings.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ),
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

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState({
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF667085), size: 30),
          ),
          const SizedBox(height: 14),
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
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _BookingStatusPill extends StatelessWidget {
  const _BookingStatusPill({required this.label, required this.color});

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

class _RecentBookingCard extends StatelessWidget {
  const _RecentBookingCard({required this.booking, this.onTap});

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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset('assets/package.png', fit: BoxFit.contain),
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
              _BookingStatusPill(
                label: booking.displayStatusLabel,
                color: statusColor,
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
                      booking.pickupLocation.isEmpty
                          ? 'Pickup location not provided'
                          : booking.pickupLocation,
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
                      booking.dropoffLocation.isEmpty
                          ? 'Drop-off location not provided'
                          : booking.dropoffLocation,
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
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF667085),
                    size: 18,
                  ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
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
    default:
      return const Color(0xFFF59E0B);
  }
}

class _VehiclePreviewTile extends StatelessWidget {
  const _VehiclePreviewTile({required this.vehicle, required this.onTap});

  final VehicleOption vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            height: 84,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Image.asset(
                vehicle.assetPath,
                width: 58,
                height: 58,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            vehicle.label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF101828),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({
    required this.selectedTripType,
    required this.onTripTypeChanged,
  });

  final TripType selectedTripType;
  final ValueChanged<TripType> onTripTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: _TripModeLabel(
                    label: 'Inter city',
                    imagePath: 'assets/trucks/inter-city.png',
                    selected: selectedTripType == TripType.interCity,
                    onTap: () => onTripTypeChanged(TripType.interCity),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFE3E8EF)),
                Expanded(
                  child: _TripModeLabel(
                    label: 'Intra city',
                    imagePath: 'assets/trucks/intra-city.png',
                    selected: selectedTripType == TripType.intraCity,
                    onTap: () => onTripTypeChanged(TripType.intraCity),
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

class _TripModeLabel extends StatelessWidget {
  const _TripModeLabel({
    required this.label,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  imagePath,
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? const Color(0xFF101828)
                        : const Color(0xFF9AA4B2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: 2,
              width: selected ? 30 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WhereToPill extends StatelessWidget {
  const _WhereToPill({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF101828),
              ),
              decoration: const InputDecoration(
                hintText: 'Where to?',
                hintStyle: TextStyle(
                  color: Color(0xFF9AA4B2),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFF9AA4B2),
          ),
        ],
      ),
    );
  }
}

class _RecentAddressCard extends StatelessWidget {
  const _RecentAddressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8EF)),
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
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF2D6EF2),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ghanshyam Enclave, 1303/1304, Nagpur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Home',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF98A2B3),
                    fontWeight: FontWeight.w600,
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
