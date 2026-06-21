import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../client/presentation/widgets/client_flow_widgets.dart';

final brokerPendingRequestsProvider = StateProvider<int>((ref) {
  return mockBrokerRequests.length;
});

final brokerHistoryProvider = StateProvider<List<TrackingDemoShipment>>((ref) {
  return [...mockBrokerHistoryShipments];
});

final brokerVehiclesProvider = StateProvider<List<BrokerVehicle>>((ref) {
  return [...mockBrokerVehicles];
});

final brokerDriversProvider = StateProvider<List<BrokerDriver>>((ref) {
  return [...mockBrokerDrivers];
});

enum BrokerVehicleStatus { idle, onTrip, maintenance }

enum BrokerDriverStatus { onTrip, idle, offline }

class BookingRequest {
  const BookingRequest({
    required this.id,
    required this.clientName,
    required this.clientInitials,
    required this.productName,
    required this.from,
    required this.to,
    required this.weight,
    required this.vehicleType,
    required this.value,
    required this.distance,
    required this.etaText,
    required this.requestedAt,
  });

  final String id;
  final String clientName;
  final String clientInitials;
  final String productName;
  final String from;
  final String to;
  final String weight;
  final String vehicleType;
  final String value;
  final String distance;
  final String etaText;
  final String requestedAt;
}

class BrokerVehicle {
  const BrokerVehicle({
    required this.id,
    required this.label,
    required this.plateNumber,
    required this.capacity,
    required this.status,
    required this.assignedDriverName,
    required this.assetPath,
  });

  final String id;
  final String label;
  final String plateNumber;
  final String capacity;
  final BrokerVehicleStatus status;
  final String assignedDriverName;
  final String assetPath;
}

class BrokerDriver {
  const BrokerDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.licenseNo,
    required this.vehicleType,
    required this.status,
    required this.currentLocation,
    required this.assignedVehicle,
    required this.onTripSince,
    required this.currentBookingRef,
  });

  final String id;
  final String name;
  final String phone;
  final String licenseNo;
  final String vehicleType;
  final BrokerDriverStatus status;
  final String currentLocation;
  final String assignedVehicle;
  final String onTripSince;
  final String currentBookingRef;
}

const mockBrokerRequests = <BookingRequest>[
  BookingRequest(
    id: 'req-1001',
    clientName: 'Neha Kapoor',
    clientInitials: 'NK',
    productName: 'Office Chair Set',
    from: 'Delhi DC-3',
    to: 'Jaipur Office',
    weight: '8.6 KG',
    vehicleType: 'Medium truck',
    value: '₹2,950',
    distance: '276 km',
    etaText: '4h 20m',
    requestedAt: '12 min ago',
  ),
  BookingRequest(
    id: 'req-1002',
    clientName: 'Aarav Mehta',
    clientInitials: 'AM',
    productName: '4-Seater Sofa',
    from: 'Mumbai Warehouse',
    to: 'Pune Kothrud',
    weight: '22 KG',
    vehicleType: 'Big truck',
    value: '₹4,800',
    distance: '148 km',
    etaText: '3h 10m',
    requestedAt: '25 min ago',
  ),
  BookingRequest(
    id: 'req-1003',
    clientName: 'Rohit Sharma',
    clientInitials: 'RS',
    productName: 'Printer Cartridge Box',
    from: 'Pune Cargo Yard',
    to: 'Hyderabad Retail Store',
    weight: '4.1 KG',
    vehicleType: 'Truck pooling',
    value: '₹1,150',
    distance: '560 km',
    etaText: '8h 50m',
    requestedAt: '41 min ago',
  ),
];

const mockBrokerVehicles = <BrokerVehicle>[
  BrokerVehicle(
    id: 'veh-1',
    label: 'Medium truck',
    plateNumber: 'MH 12 AB 2456',
    capacity: '1.5 ton',
    status: BrokerVehicleStatus.idle,
    assignedDriverName: 'Vikram Patil',
    assetPath: 'assets/trucks/medium truck.png',
  ),
  BrokerVehicle(
    id: 'veh-2',
    label: 'Big truck',
    plateNumber: 'MH 14 XY 8104',
    capacity: '3 ton',
    status: BrokerVehicleStatus.onTrip,
    assignedDriverName: 'Rahul Jadhav',
    assetPath: 'assets/trucks/big truck.png',
  ),
  BrokerVehicle(
    id: 'veh-3',
    label: 'Small truck',
    plateNumber: 'MH 10 CZ 1198',
    capacity: '500 kg',
    status: BrokerVehicleStatus.maintenance,
    assignedDriverName: 'Unassigned',
    assetPath: 'assets/trucks/small truck.png',
  ),
];

const mockBrokerDrivers = <BrokerDriver>[
  BrokerDriver(
    id: 'drv-1',
    name: 'Vikram Patil',
    phone: '+91 98220 11234',
    licenseNo: 'DL-1823-PL',
    vehicleType: 'Medium truck',
    status: BrokerDriverStatus.idle,
    currentLocation: 'Near Pune Gateway Hub',
    assignedVehicle: 'MH 12 AB 2456',
    onTripSince: '',
    currentBookingRef: '',
  ),
  BrokerDriver(
    id: 'drv-2',
    name: 'Rahul Jadhav',
    phone: '+91 98710 32455',
    licenseNo: 'DL-9172-RJ',
    vehicleType: 'Big truck',
    status: BrokerDriverStatus.onTrip,
    currentLocation: 'Ahmedabad Bypass',
    assignedVehicle: 'MH 14 XY 8104',
    onTripSince: '2h 12m',
    currentBookingRef: 'BK-20489',
  ),
  BrokerDriver(
    id: 'drv-3',
    name: 'Sahil Verma',
    phone: '+91 99203 88091',
    licenseNo: 'DL-4471-SK',
    vehicleType: 'Truck pooling',
    status: BrokerDriverStatus.offline,
    currentLocation: 'Offline for login',
    assignedVehicle: 'Unassigned',
    onTripSince: '',
    currentBookingRef: '',
  ),
];

const mockBrokerHistoryShipments = <TrackingDemoShipment>[
  TrackingDemoShipment(
    packageName: 'Server Rack',
    trackingId: 'TRK-BR-1009',
    fromLocation: 'Mumbai Warehouse',
    toLocation: 'Bengaluru Tech Park',
    status: 'Completed',
    customerName: 'Aarav Mehta',
    weight: '32.5 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Booking accepted',
        subtitle: 'Broker assigned vehicle',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In transit',
        subtitle: 'Vehicle left depot',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Received by client',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Closed',
        subtitle: 'Payment settled',
        completed: true,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Office Chair Set',
    trackingId: 'TRK-BR-1014',
    fromLocation: 'Delhi DC-3',
    toLocation: 'Jaipur Office',
    status: 'Accepted',
    customerName: 'Neha Kapoor',
    weight: '8.6 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Request received',
        subtitle: 'Waiting for assignment',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Broker accepted',
        subtitle: 'Vehicle to be assigned',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Pickup scheduled',
        subtitle: 'Pending',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Pending',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Industrial Printer',
    trackingId: 'TRK-BR-1021',
    fromLocation: 'Pune Cargo Yard',
    toLocation: 'Hyderabad Retail Store',
    status: 'Cancelled',
    customerName: 'Rohit Sharma',
    weight: '48 KG',
    timeline: [
      TrackingTimelineStep(
        title: 'Request received',
        subtitle: 'Awaiting action',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Cancelled',
        subtitle: 'Rejected by client',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In transit',
        subtitle: 'Not started',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Not started',
        completed: false,
      ),
    ],
  ),
];

TrackingDemoShipment bookingRequestToShipment(
  BookingRequest request, {
  String status = 'Accepted',
}) {
  return TrackingDemoShipment(
    packageName: request.productName,
    trackingId: 'TRK-${request.id.toUpperCase()}',
    fromLocation: request.from,
    toLocation: request.to,
    status: status,
    customerName: request.clientName,
    weight: request.weight,
    timeline: [
      const TrackingTimelineStep(
        title: 'Request received',
        subtitle: 'Broker inbox',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Broker $status',
        subtitle: 'Assignment pending',
        completed: true,
      ),
      const TrackingTimelineStep(
        title: 'In transit',
        subtitle: 'Vehicle assignment pending',
        completed: false,
      ),
      const TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Awaiting pickup',
        completed: false,
      ),
    ],
  );
}

class BrokerHeader extends StatelessWidget {
  const BrokerHeader({
    super.key,
    required this.highlighted,
    required this.title,
    this.subtitle,
    required this.pendingRequestsCount,
    required this.onAvatarTap,
  });

  final bool highlighted;
  final String title;
  final String? subtitle;
  final int pendingRequestsCount;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = highlighted ? const Color(0xFF1F88C9) : Colors.white;
    final titleColor = highlighted ? Colors.white : const Color(0xFF101828);
    final iconAccent = highlighted ? Colors.white : const Color(0xFF1F88C9);
    return Container(
      width: double.infinity,
      margin: EdgeInsets.zero,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        16,
        12,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: highlighted ? 0.10 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: highlighted
                              ? Colors.white.withValues(alpha: 0.84)
                              : const Color(0xFF667085),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            hasBadge: pendingRequestsCount > 0,
            iconColor: iconAccent,
            size: 30,
            badgeOffset: const Offset(5, 2),
            onTap: () {},
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: highlighted ? Colors.white.withValues(alpha: 0.16) : const Color(0xFFF1F4F8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: highlighted
                      ? Colors.white.withValues(alpha: 0.35)
                      : const Color(0xFFE5EAF0),
                  width: 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                'assets/user.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    required this.icon,
    required this.hasBadge,
    required this.iconColor,
    required this.size,
    required this.badgeOffset,
    required this.onTap,
  });

  final IconData icon;
  final bool hasBadge;
  final Color iconColor;
  final double size;
  final Offset badgeOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          if (hasBadge)
            Positioned(
              right: badgeOffset.dx,
              top: badgeOffset.dy,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE23A4B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE23A4B).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BrokerBottomBar extends StatelessWidget {
  const BrokerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.pendingRequestsCount,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingRequestsCount;

  @override
  Widget build(BuildContext context) {
    final items = <_BrokerNavItem>[
      _BrokerNavItem(
        icon: Icons.inbox_rounded,
        label: 'New Booking',
        showDot: pendingRequestsCount > 0,
      ),
      const _BrokerNavItem(
        icon: Icons.local_shipping_rounded,
        label: 'Vehicles',
      ),
      const _BrokerNavItem(
        icon: Icons.gps_fixed_rounded,
        label: 'Tracking',
      ),
      const _BrokerNavItem(
        icon: Icons.history_rounded,
        label: 'History',
      ),
    ];

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
            for (var index = 0; index < items.length; index++) ...[
              Expanded(
                child: _BrokerBottomBarItem(
                  item: items[index],
                  selected: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              ),
              if (index != items.length - 1) const SizedBox(width: 12),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrokerNavItem {
  const _BrokerNavItem({
    required this.icon,
    required this.label,
    this.showDot = false,
  });

  final IconData icon;
  final String label;
  final bool showDot;
}

class _BrokerBottomBarItem extends StatelessWidget {
  const _BrokerBottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _BrokerNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF1F88C9);
    final iconColor = selected ? selectedColor : const Color(0xFF98A2B3);

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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Center(child: Icon(item.icon, color: iconColor, size: 20)),
                  if (item.showDot)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE23A4B),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE23A4B).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: selected ? selectedColor : const Color(0xFF667085),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

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
          if (icon != null) ...[
            Icon(icon, size: 15, color: textColor),
            const SizedBox(width: 6),
          ],
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

class BrokerRequestCard extends StatelessWidget {
  const BrokerRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  final BookingRequest request;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1A365D).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Load ID: #${request.id.toUpperCase()}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                            fontSize: 11,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      request.clientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF1A365D),
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  request.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF002045),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(
                width: 28,
                child: _RouteLine(),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LoadPoint(
                      label: 'Pickup',
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF1A365D),
                      place: request.from,
                      timeText: request.requestedAt,
                    ),
                    const SizedBox(height: 14),
                    _LoadPoint(
                      label: 'Drop-off',
                      icon: Icons.near_me_rounded,
                      iconColor: const Color(0xFF875200),
                      place: request.to,
                      timeText: '',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF667085)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${request.productName} • ${request.weight} • ${request.vehicleType}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF0B1C30),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    foregroundColor: const Color(0xFFBA1A1A),
                    side: const BorderSide(color: Color(0xFFBA1A1A)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFFFB55C),
                    foregroundColor: const Color(0xFF744600),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF1A365D).withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF1A365D),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        Container(
          width: 2,
          height: 54,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF74777F).withValues(alpha: 0.30),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB55C).withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Color(0xFF875200),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LoadPoint extends StatelessWidget {
  const _LoadPoint({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.place,
    required this.timeText,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final String place;
  final String timeText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                place,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF0B1C30),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (timeText.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  timeText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontSize: 11,
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

class VehicleCard extends StatelessWidget {
  const VehicleCard({
    super.key,
    required this.vehicle,
    required this.onTap,
  });

  final BrokerVehicle vehicle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Image.asset(
                      vehicle.assetPath,
                      width: 44,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                _VehicleStatusBadge(
                  label: vehicleStatusLabel(vehicle.status),
                  backgroundColor: vehicleStatusBackground(vehicle.status),
                  textColor: vehicleStatusColor(vehicle.status),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 17,
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    vehicle.plateNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.capacity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          color: const Color(0xFF98A2B3),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Assigned to ${vehicle.assignedDriverName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 13,
                          color: const Color(0xFF98A2B3),
                          fontWeight: FontWeight.w500,
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

class _VehicleStatusBadge extends StatelessWidget {
  const _VehicleStatusBadge({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class DriverListTile extends StatelessWidget {
  const DriverListTile({
    super.key,
    required this.driver,
    required this.onTap,
    required this.onRemove,
  });

  final BrokerDriver driver;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final meta = _driverCardMeta(driver);
    final statusColor = driverStatusColor(driver.status);
    final avatarBg = driverAvatarColor(driver.status);
    final avatarText = driverAvatarTextColor(driver.status);

    return InkWell(
      onTap: onTap,
      onLongPress: onRemove,
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
              blurRadius: 14,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DriverAvatar(
                  initials: _initials(driver.name),
                  backgroundColor: avatarBg,
                  textColor: avatarText,
                  statusColor: statusColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            driver.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontSize: 15,
                                  color: const Color(0xFF101828),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          _DriverCardMetaChip(label: 'ID: ${driver.id}'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meta.statusLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 12,
                              color: statusColor,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 13,
                            color: Color(0xFF98A2B3),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              driver.currentLocation,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: const Color(0xFF667085),
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _DriverFooterBlock(
                    label: 'Phone',
                    value: driver.phone,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DriverFooterBlock(
                    label: 'Last seen',
                    value: meta.lastSeen,
                    alignRight: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _DriverActionIconButton(
                  icon: Icons.edit_rounded,
                  backgroundColor: const Color(0xFFEAF4FD),
                  iconColor: const Color(0xFF1F88C9),
                  onPressed: onTap,
                  tooltip: 'Edit driver',
                ),
                const SizedBox(width: 8),
                _DriverActionIconButton(
                  icon: Icons.delete_rounded,
                  backgroundColor: const Color(0xFFFEE4E2),
                  iconColor: const Color(0xFFD92D20),
                  onPressed: onRemove,
                  tooltip: 'Remove driver',
                ),
                const Spacer(),
                Flexible(
                  child: FilledButton.icon(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      minimumSize: const Size(0, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: Icon(meta.ctaIcon, size: 18),
                    label: Text(
                      meta.ctaLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({
    required this.initials,
    required this.backgroundColor,
    required this.textColor,
    required this.statusColor,
  });

  final String initials;
  final Color backgroundColor;
  final Color textColor;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 13,
                    color: textColor,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverFooterBlock extends StatelessWidget {
  const _DriverFooterBlock({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final crossAxisAlignment = alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
                color: const Color(0xFF98A2B3),
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: textAlign,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _DriverActionIconButton extends StatelessWidget {
  const _DriverActionIconButton({
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 18, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _DriverCardMetaChip extends StatelessWidget {
  const _DriverCardMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: const Color(0xFF344054),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DriverCardMeta {
  const _DriverCardMeta({
    required this.statusLine,
    required this.lastSeen,
    required this.ctaLabel,
    required this.ctaIcon,
  });

  final String statusLine;
  final String lastSeen;
  final String ctaLabel;
  final IconData ctaIcon;
}

_DriverCardMeta _driverCardMeta(BrokerDriver driver) {
  switch (driver.status) {
    case BrokerDriverStatus.onTrip:
      return _DriverCardMeta(
        statusLine: 'Active on booking ${driver.currentBookingRef}',
        lastSeen: driver.onTripSince.isEmpty ? 'Just now' : '${driver.onTripSince} ago',
        ctaLabel: 'View Map',
        ctaIcon: Icons.map_outlined,
      );
    case BrokerDriverStatus.idle:
      return _DriverCardMeta(
        statusLine: 'Idle and ready for assignment',
        lastSeen: '14 mins ago',
        ctaLabel: 'Assign Load',
        ctaIcon: Icons.add_task_rounded,
      );
    case BrokerDriverStatus.offline:
      return _DriverCardMeta(
        statusLine: 'Offline',
        lastSeen: 'Not available',
        ctaLabel: 'View Details',
        ctaIcon: Icons.info_outline_rounded,
      );
  }
}

class BrokerProfileActionCard extends StatelessWidget {
  const BrokerProfileActionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 86,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: iconColor),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class BrokerMenuTile extends StatelessWidget {
  const BrokerMenuTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.titleColor = const Color(0xFF101828),
    this.iconColor = const Color(0xFF1C2430),
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Color titleColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF98A2B3)),
          ],
        ),
      ),
    );
  }
}

class SheetContainer extends StatelessWidget {
  const SheetContainer({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: child,
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF1F88C9);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? selectedColor.withValues(alpha: 0.28) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: selected ? selectedColor.withValues(alpha: 0.12) : Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: selected ? selectedColor : const Color(0xFF94A3B8)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF101828),
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
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

class VehicleSelectionTile extends StatelessWidget {
  const VehicleSelectionTile({
    super.key,
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = selected ? vehicle.accentColor : const Color(0xFF98A2B3);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? vehicle.accentColor.withValues(alpha: 0.08) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? vehicle.accentColor.withValues(alpha: 0.24) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.local_shipping_rounded, color: accent, size: 20),
                ),
                const Spacer(),
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? vehicle.accentColor : const Color(0xFFCBD5E1),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              vehicle.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              vehicle.capacity,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

Color vehicleStatusBackground(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return const Color(0xFFF5F7FB);
    case BrokerVehicleStatus.onTrip:
      return const Color(0xFFE0F4E8);
    case BrokerVehicleStatus.maintenance:
      return const Color(0xFFFFF3D9);
  }
}

Color vehicleStatusColor(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return const Color(0xFF667085);
    case BrokerVehicleStatus.onTrip:
      return const Color(0xFF2FA56E);
    case BrokerVehicleStatus.maintenance:
      return const Color(0xFFF59E0B);
  }
}

String vehicleStatusLabel(BrokerVehicleStatus status) {
  switch (status) {
    case BrokerVehicleStatus.idle:
      return 'Idle';
    case BrokerVehicleStatus.onTrip:
      return 'On Trip';
    case BrokerVehicleStatus.maintenance:
      return 'Maintenance';
  }
}

Color driverStatusBackground(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFFE0F4E8);
    case BrokerDriverStatus.idle:
      return const Color(0xFFF5F7FB);
    case BrokerDriverStatus.offline:
      return const Color(0xFFF3F4F6);
  }
}

Color driverStatusColor(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFF2FA56E);
    case BrokerDriverStatus.idle:
      return const Color(0xFF667085);
    case BrokerDriverStatus.offline:
      return const Color(0xFF98A2B3);
  }
}

String driverStatusLabel(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return 'On Trip';
    case BrokerDriverStatus.idle:
      return 'Idle';
    case BrokerDriverStatus.offline:
      return 'Offline';
  }
}

Color driverAvatarColor(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFFE0F4E8);
    case BrokerDriverStatus.idle:
      return const Color(0xFFEFF6FF);
    case BrokerDriverStatus.offline:
      return const Color(0xFFF3F4F6);
  }
}

Color driverAvatarTextColor(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return const Color(0xFF2FA56E);
    case BrokerDriverStatus.idle:
      return const Color(0xFF1F88C9);
    case BrokerDriverStatus.offline:
      return const Color(0xFF98A2B3);
  }
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
}

String maskPersonName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
  return parts.map(_maskWord).join(' ');
}

String _maskWord(String word) {
  final normalized = word.toLowerCase();
  if (normalized.length <= 2) {
    return '${normalized.substring(0, 1)}*';
  }
  if (normalized.length == 3) {
    return '${normalized[0]}*${normalized[2]}';
  }

  final middleLength = normalized.length - 2;
  final maskedMiddle = middleLength <= 3
      ? '*' * middleLength
      : '${'*' * (middleLength - 2)}${normalized[normalized.length - 2]}*';

  return '${normalized[0]}$maskedMiddle${normalized[normalized.length - 1]}';
}
