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
    name: 'Sahil Khan',
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
    required this.pendingRequestsCount,
    required this.onAvatarTap,
  });

  final int pendingRequestsCount;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning, Aman',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SSK Freight & Logistics',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _HeaderIconButton(
            icon: Icons.notifications_none_rounded,
            hasBadge: pendingRequestsCount > 0,
            onTap: () {},
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onAvatarTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5EAF0), width: 1.2),
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
    required this.onTap,
  });

  final IconData icon;
  final bool hasBadge;
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Icon(icon, color: const Color(0xFF1F88C9)),
          ),
          if (hasBadge)
            Positioned(
              right: 4,
              top: 4,
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFE8EDF2))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
                if (index != items.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor.withValues(alpha: 0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(item.icon, color: iconColor, size: 24),
                if (item.showDot)
                  Positioned(
                    right: -3,
                    top: -2,
                    child: Container(
                      width: 7,
                      height: 7,
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
            const SizedBox(height: 5),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
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
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  request.clientInitials,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1F88C9),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.clientName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.requestedAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF98A2B3),
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            request.productName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusPill(
                label: request.weight,
                backgroundColor: const Color(0xFFF5F7FB),
                textColor: const Color(0xFF667085),
                icon: Icons.scale_rounded,
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: request.vehicleType,
                backgroundColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1F88C9),
                icon: Icons.local_shipping_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _RouteRow(
            from: request.from,
            to: request.to,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${request.distance} • ${request.etaText}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  request.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF1F88C9),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFECEFF3)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE23A4B),
                    side: const BorderSide(color: Color(0xFFE23A4B)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Reject',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F88C9),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.w700),
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

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.from,
    required this.to,
  });

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
                height: 26,
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4E8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EDF2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: Color(0xFF98A2B3),
                      shape: BoxShape.circle,
                    ),
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
                'From',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                from,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF101828),
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'To',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                to,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Image.asset(
                  vehicle.assetPath,
                  width: 56,
                  height: 56,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plateNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vehicle.capacity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF98A2B3),
                        ),
                  ),
                  const SizedBox(height: 10),
                  StatusPill(
                    label: vehicleStatusLabel(vehicle.status),
                    backgroundColor: vehicleStatusBackground(vehicle.status),
                    textColor: vehicleStatusColor(vehicle.status),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Assigned to ${vehicle.assignedDriverName}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    return InkWell(
      onTap: onTap,
      onLongPress: onRemove,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EDF2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: driverAvatarColor(driver.status),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(driver.name),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: driverAvatarTextColor(driver.status),
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    driver.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    driver.phone,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      StatusPill(
                        label: driverStatusLabel(driver.status),
                        backgroundColor: driverStatusBackground(driver.status),
                        textColor: driverStatusColor(driver.status),
                      ),
                      if (driver.currentBookingRef.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            driver.currentBookingRef,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF98A2B3),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF98A2B3)),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          driver.currentLocation,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: const Color(0xFF98A2B3),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              children: [
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: const Color(0xFF98A2B3),
                  tooltip: 'Open driver details',
                ),
                IconButton(
                  onPressed: onRemove,
                  icon: const Icon(Icons.more_horiz_rounded),
                  color: const Color(0xFF98A2B3),
                  tooltip: 'Remove driver',
                ),
              ],
            ),
          ],
        ),
      ),
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
