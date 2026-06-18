import 'package:flutter/material.dart';

enum TripType { interCity, intraCity }

class BookingData {
  const BookingData({
    required this.from,
    required this.to,
    required this.tripType,
  });

  final String from;
  final String to;
  final TripType tripType;
}

class TruckSize {
  const TruckSize({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class VehicleOption {
  const VehicleOption({
    required this.label,
    required this.capacity,
    required this.price,
    required this.accentColor,
    required this.assetPath,
  });

  final String label;
  final String capacity;
  final String price;
  final Color accentColor;
  final String assetPath;
}

const vehicleOptions = <VehicleOption>[
  VehicleOption(
    label: 'Small truck',
    capacity: 'Up to 500 kg',
    price: '₹899',
    accentColor: Color(0xFF2FA56E),
    assetPath: 'assets/trucks/small truck.png',
  ),
  VehicleOption(
    label: 'Medium truck',
    capacity: 'Up to 1.5 ton',
    price: '₹1,499',
    accentColor: Color(0xFF1F88C9),
    assetPath: 'assets/trucks/medium truck.png',
  ),
  VehicleOption(
    label: 'Big truck',
    capacity: 'Up to 3 ton',
    price: '₹2,299',
    accentColor: Color(0xFF7A5AF8),
    assetPath: 'assets/trucks/big truck.png',
  ),
  VehicleOption(
    label: 'Truck pooling',
    capacity: 'Shared capacity',
    price: '₹499',
    accentColor: Color(0xFFF59E0B),
    assetPath: 'assets/trucks/truck pooling.png',
  ),
];

class TrackingDemoShipment {
  const TrackingDemoShipment({
    required this.packageName,
    required this.trackingId,
    required this.fromLocation,
    required this.toLocation,
    required this.status,
    required this.customerName,
    required this.weight,
    required this.timeline,
  });

  final String packageName;
  final String trackingId;
  final String fromLocation;
  final String toLocation;
  final String status;
  final String customerName;
  final String weight;
  final List<TrackingTimelineStep> timeline;
}

class TrackingTimelineStep {
  const TrackingTimelineStep({
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  final String title;
  final String subtitle;
  final bool completed;
}

const trackingDemoShipments = <TrackingDemoShipment>[
  TrackingDemoShipment(
    packageName: 'MacBook Air M3',
    trackingId: 'TRK-SSK-20489',
    fromLocation: 'Mumbai Warehouse',
    toLocation: 'Pune Distribution Center',
    status: 'Your package is in transit',
    customerName: 'Aarav Mehta',
    weight: '2.40 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Mumbai Warehouse',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Pune Gateway Hub',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Pune Distribution Center',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Awaiting final handoff',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Apple iPhone 15 Pro',
    trackingId: 'TRK-SSK-20841',
    fromLocation: 'Navi Mumbai Hub',
    toLocation: 'Bangalore Tech Park',
    status: 'Arriving at next checkpoint',
    customerName: 'Karan Shah',
    weight: '1.15 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Navi Mumbai Hub',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Kolhapur Sorting Center',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Bangalore Tech Park',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Final confirmation pending',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Office Chair Set',
    trackingId: 'TRK-SSK-21077',
    fromLocation: 'Delhi DC-3',
    toLocation: 'Jaipur Office',
    status: 'Awaiting dispatch',
    customerName: 'Neha Kapoor',
    weight: '8.60 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Delhi DC-3',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Load assigned',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Queue for pickup',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Not started yet',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Printer Cartridge Box',
    trackingId: 'TRK-SSK-21330',
    fromLocation: 'Pune Cargo Yard',
    toLocation: 'Hyderabad Retail Store',
    status: 'Out for pickup',
    customerName: 'Rohan Kulkarni',
    weight: '4.05 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Pune Cargo Yard',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Pickup scheduled',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Not started',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Pending',
        completed: false,
      ),
    ],
  ),
];

class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationArc extends StatelessWidget {
  const LocationArc({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EDF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              color: scheme.primary,
              size: 17,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick up from',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mumbai, Maharashtra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF17324D),
                          fontWeight: FontWeight.w400,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: const AspectRatio(
        aspectRatio: 2,
        child: Image(
          image: AssetImage('assets/client/test.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

Future<void> showTripTypeSheet(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  onOpen?.call();
  try {
    final tripType = initialTripType ??
        await showModalBottomSheet<TripType>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TripTypeSheet(),
        );
    if (tripType == null || !context.mounted) return;

    final bookingData = await Navigator.of(context).push<BookingData>(
      MaterialPageRoute(
        builder: (context) => BookingLocationScreen(tripType: tripType),
      ),
    );
    if (bookingData == null || !context.mounted) return;

    final vehicle = await Navigator.of(context).push<VehicleOption>(
      MaterialPageRoute(
        builder: (context) => SelectVehicleScreen(
          bookingData: bookingData,
          initialIndex: initialVehicleIndex ?? 0,
        ),
      ),
    );
    if (vehicle == null || !context.mounted) return;

  } finally {
    onClose?.call();
  }
}

Future<void> showBookingFlow(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  await showTripTypeSheet(
    context,
    initialTripType: initialTripType,
    initialVehicleIndex: initialVehicleIndex,
    onOpen: onOpen,
    onClose: onClose,
  );
}

class TrackingMockCard extends StatelessWidget {
  const TrackingMockCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.black54,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEAF2F8),
                    valueColor: AlwaysStoppedAnimation(accent),
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

class PackageTrackingCard extends StatelessWidget {
  const PackageTrackingCard({
    super.key,
    required this.shipment,
    this.onTap,
  });

  final TrackingDemoShipment shipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
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
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/package.png',
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
                      shipment.packageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF121826),
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#Tracking ID: ${shipment.trackingId}',
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
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(width: 28, height: 28),
                icon: const Icon(Icons.more_horiz_rounded, size: 22),
                color: Colors.black45,
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
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF6C63FF),
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
                        color: const Color(0xFFE7E6FF),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDEBFF),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB8B3FF),
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
                      shipment.fromLocation,
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
                      shipment.toLocation,
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
          const Divider(height: 1, color: Color(0xFFECEFF3)),
          const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withValues(alpha: 0.25),
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

class TruckIllustration extends StatelessWidget {
  const TruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            left: 4,
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
          Positioned(
            right: 6,
            top: 16,
            child: Container(
              width: 20,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1F88C9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: Colors.white, size: 13),
            ),
          ),
          const Positioned(
            bottom: 10,
            left: 10,
            child: Wheel(),
          ),
          const Positioned(
            bottom: 10,
            right: 10,
            child: Wheel(),
          ),
        ],
      ),
    );
  }
}

class Wheel extends StatelessWidget {
  const Wheel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF17324D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7EEF5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF2FA56E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class SheetContainer extends StatelessWidget {
  const SheetContainer({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.46,
        minChildSize: 0.36,
        maxChildSize: 0.86,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE7EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TripTypeSheet extends StatelessWidget {
  const TripTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose trip type',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 12),
            _TripTypeRow(
              imagePath: 'assets/trucks/intra-city.png',
              label: 'Inter city',
              helperText: 'Move between cities',
              onTap: () => Navigator.of(context).pop(TripType.interCity),
            ),
            const SizedBox(height: 10),
            _TripTypeRow(
              imagePath: 'assets/trucks/inter-city.png',
              label: 'Intra city',
              helperText: 'Deliver within the city',
              onTap: () => Navigator.of(context).pop(TripType.intraCity),
            ),
          ],
        ),
      ),
    );
  }
}

double _sheetBottomInset(BuildContext context) {
  final viewPadding = MediaQuery.of(context).viewPadding.bottom;
  return viewPadding > 0 ? viewPadding + 28 : 28;
}

class _TripTypeRow extends StatelessWidget {
  const _TripTypeRow({
    required this.imagePath,
    required this.label,
    required this.helperText,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Image.asset(
              imagePath,
              width: 54,
              height: 54,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
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

class BookingLocationScreen extends StatefulWidget {
  const BookingLocationScreen({
    super.key,
    required this.tripType,
  });

  final TripType tripType;

  @override
  State<BookingLocationScreen> createState() => _BookingLocationScreenState();
}

class _BookingLocationScreenState extends State<BookingLocationScreen> {
  final _toController = TextEditingController();

  @override
  void dispose() {
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInterCity = widget.tripType == TripType.interCity;
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final bookBottomPadding = bottomInset > 0 ? bottomInset + 36.0 : 44.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.centerLeft,
                            child: const Icon(Icons.arrow_back_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _BookingSummaryCard(
                      pickupTitle: isInterCity ? 'Aarav Mehta · 9823419076' : 'Current location',
                      pickupSubtitle: isInterCity
                          ? 'Ghanshyam Enclave, 1303/1304, N...'
                          : 'Current location will appear here',
                      dropController: _toController,
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionShortcutTile(
                            assetPath: 'assets/gps.png',
                            title: 'Select on map',
                            onTap: () {},
                            compact: true,
                            iconSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                          child: VerticalDivider(
                            width: 10,
                            thickness: 1,
                            color: Color(0xFFEAEFF4),
                          ),
                        ),
                        Expanded(
                          child: _ActionShortcutTile(
                            assetPath: 'assets/heart.png',
                            title: 'Saved addresses',
                            onTap: () {},
                            compact: true,
                            iconSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Recent addresses',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 10),
                    ..._recentAddresses.asMap().entries.expand(
                          (entry) => [
                            _RecentAddressTile(
                              title: entry.value.$1,
                              subtitle: entry.value.$2,
                              onTap: () {
                                _toController.text = entry.value.$2;
                              },
                            ),
                            if (entry.key != _recentAddresses.length - 1)
                              const SizedBox(height: 8),
                          ],
                        ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, bookBottomPadding),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(
                      BookingData(
                        from: isInterCity ? 'Ghanshyam Enclave' : 'Current location',
                        to: _toController.text.trim().isEmpty
                            ? 'Dummy location'
                            : _toController.text.trim(),
                        tripType: widget.tripType,
                      ),
                    );
                  },
                  child: const Text('Book'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.pickupTitle,
    required this.pickupSubtitle,
    this.dropController,
    this.dropValue,
  });

  final String pickupTitle;
  final String pickupSubtitle;
  final TextEditingController? dropController;
  final String? dropValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEFF4)),
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
              children: [
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
                  height: 56,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
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
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C2430),
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        pickupSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2D6EF2), width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: dropController == null
                            ? Text(
                                dropValue ?? 'Where is your Drop ?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF1C2430),
                                      fontSize: 13,
                                    ),
                              )
                            : TextField(
                                controller: dropController,
                                decoration: InputDecoration(
                                  hintText: 'Where is your Drop ?',
                                  border: InputBorder.none,
                                  isDense: true,
                                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        color: Colors.black38,
                                        fontSize: 13,
                                      ),
                                ),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: const Color(0xFF1C2430),
                                      fontSize: 13,
                                    ),
                              ),
                      ),
                      if (dropController != null)
                        IconButton(
                          onPressed: () {},
                          visualDensity: VisualDensity.compact,
                          constraints: const BoxConstraints.tightFor(width: 24, height: 24),
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.mic_none_rounded,
                            color: Color(0xFF2D6EF2),
                            size: 16,
                          ),
                        ),
                    ],
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

const List<(String, String)> _recentAddresses = [
    ('Home', 'Ghanshyam Enclave, 1303/1304, Nagpur'),
    ('Office', 'Orbit Plaza, IT Park Road, Nagpur'),
    ('Warehouse', 'MIDC Cargo Yard, Phase 2'),
    ('Client Site', 'Laxmi Nagar, Near Metro Station'),
  ];

class _ActionShortcutTile extends StatelessWidget {
  const _ActionShortcutTile({
    required this.assetPath,
    required this.title,
    required this.onTap,
    this.compact = false,
    this.iconSize,
  });

  final String assetPath;
  final String title;
  final VoidCallback onTap;
  final bool compact;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12,
          vertical: compact ? 8 : 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                assetPath,
                width: iconSize ?? (compact ? 16 : 22),
                height: iconSize ?? (compact ? 16 : 22),
              ),
              SizedBox(width: compact ? 6 : 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 11 : null,
                      color: const Color(0xFF1C2430),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentAddressTile extends StatelessWidget {
  const _RecentAddressTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFF2FA56E), size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                          fontSize: 11,
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

class SelectVehicleScreen extends StatefulWidget {
  const SelectVehicleScreen({
    super.key,
    required this.bookingData,
    this.initialIndex = 0,
  });

  final BookingData bookingData;
  final int initialIndex;

  @override
  State<SelectVehicleScreen> createState() => _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends State<SelectVehicleScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, vehicleOptions.length - 1).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final selected = vehicleOptions[_selectedIndex];
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                18,
                12,
                18,
                132 + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(Icons.arrow_back_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookingSummaryCard(
                    pickupTitle: widget.bookingData.from,
                    pickupSubtitle: widget.bookingData.to,
                    dropValue: widget.bookingData.to,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your vehicle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828),
                          letterSpacing: 0.1,
                        ),
                  ),
                  const SizedBox(height: 10),
                  ...vehicleOptions.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _VehicleOptionTile(
                            option: entry.value,
                            selected: _selectedIndex == entry.key,
                            onTap: () => setState(() => _selectedIndex = entry.key),
                          ),
                        ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: bottomInset + 44,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(selected);
                  },
                  child: Text('Proceed with ${selected.label}'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleOptionTile extends StatelessWidget {
  const _VehicleOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? option.accentColor : const Color(0xFFE7EEF5),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.045 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1.14 : 1.0,
              curve: Curves.easeOutBack,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(option.assetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828),
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.capacity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  option.price,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? 'Selected' : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: selected ? option.accentColor : Colors.transparent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClientBottomBar extends StatelessWidget {
  const ClientBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: NavItem(
                label: 'Home',
                assetPath: 'assets/home.png',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NavItem(
                label: 'Delivery',
                assetPath: 'assets/delivery-truck.png',
                assetSize: 22,
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NavItem(
                label: 'Tracking',
                assetPath: 'assets/tracking.png',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NavItem(
                label: 'Profile',
                assetPath: 'assets/user.png',
                selected: currentIndex == 3,
                onTap: () => onTap(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.assetPath,
    this.assetSize = 18,
  });

  final String label;
  final IconData? icon;
  final String? assetPath;
  final double assetSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : Colors.black45;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        width: assetSize,
                        height: assetSize,
                        fit: BoxFit.contain,
                        color: color,
                        colorBlendMode: BlendMode.srcIn,
                      )
                    : Icon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
