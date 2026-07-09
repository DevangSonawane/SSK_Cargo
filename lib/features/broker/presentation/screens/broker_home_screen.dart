import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/broker_flow_widgets.dart';

class BrokerHomeScreen extends ConsumerStatefulWidget {
  const BrokerHomeScreen({super.key});

  @override
  ConsumerState<BrokerHomeScreen> createState() => _BrokerHomeScreenState();
}

class _BrokerHomeScreenState extends ConsumerState<BrokerHomeScreen> {
  late List<BookingRequest> _requests;

  @override
  void initState() {
    super.initState();
    _requests = [...mockBrokerRequests];
  }

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      _requests = [...mockBrokerRequests];
    });
    ref.read(brokerPendingRequestsProvider.notifier).state = _requests.length;
  }

  Future<void> _acceptRequest(BookingRequest request) async {
    final assignment = await _pickAssignment(request);
    if (assignment == null || !mounted) {
      return;
    }

    final shipment = bookingRequestToShipment(
      request,
      status: 'Accepted',
      assignedDriverName: assignment.driver.name,
      assignedTruckName: '${assignment.truck.label} • ${assignment.truck.plateNumber}',
    );

    setState(() {
      _requests.removeWhere((item) => item.id == request.id);
    });

    ref.read(brokerPendingRequestsProvider.notifier).state = _requests.length;
    final history = ref.read(brokerHistoryProvider.notifier);
    history.state = [
      shipment,
      ...history.state,
    ];

    if (!mounted) return;

    await context.push('/broker/tracking/details', extra: shipment);
  }

  Future<_AssignmentSelection?> _pickAssignment(BookingRequest request) {
    final defaultDriver = mockBrokerDrivers.firstWhere(
      (driver) => driver.vehicleType.toLowerCase() == request.vehicleType.toLowerCase(),
      orElse: () => mockBrokerDrivers.first,
    );
    final defaultTruck = mockBrokerVehicles.firstWhere(
      (truck) => truck.label.toLowerCase() == request.vehicleType.toLowerCase(),
      orElse: () => mockBrokerVehicles.first,
    );

    return showDialog<_AssignmentSelection>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        var selectedDriver = defaultDriver;
        var selectedTruck = defaultTruck;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Assign driver and truck',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose who will handle ${request.productName} before opening live tracking.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF667085),
                            ),
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<BrokerDriver>(
                        initialValue: selectedDriver,
                        isExpanded: true,
                        decoration: _popupFieldDecoration(
                          labelText: 'Driver',
                          prefixIcon: Icons.person_rounded,
                        ),
                        items: mockBrokerDrivers
                            .map(
                              (driver) => DropdownMenuItem<BrokerDriver>(
                                value: driver,
                                child: Text(
                                  driver.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedDriver = value);
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<BrokerVehicle>(
                        initialValue: selectedTruck,
                        isExpanded: true,
                        decoration: _popupFieldDecoration(
                          labelText: 'Truck',
                          prefixIcon: Icons.local_shipping_rounded,
                        ),
                        items: mockBrokerVehicles
                            .map(
                              (truck) => DropdownMenuItem<BrokerVehicle>(
                                value: truck,
                                child: Text(
                                  '${truck.label} • ${truck.plateNumber}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setModalState(() => selectedTruck = value);
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop(
                              _AssignmentSelection(
                                driver: selectedDriver,
                                truck: selectedTruck,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF1F88C9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Confirm assignment',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _rejectRequest(BookingRequest request) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject request?'),
          content: Text('Reject the booking request for ${request.productName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFFE23A4B)),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (shouldRemove != true || !mounted) return;

    setState(() {
      _requests.removeWhere((item) => item.id == request.id);
    });
    ref.read(brokerPendingRequestsProvider.notifier).state = _requests.length;
    final history = ref.read(brokerHistoryProvider.notifier);
    history.state = [
      bookingRequestToShipment(request, status: 'Cancelled'),
      ...history.state,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = _requests.isEmpty;

    return RefreshIndicator(
      onRefresh: _refresh,
      color: const Color(0xFF1F88C9),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          Row(
            children: [
              Text(
                'New booking requests',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF101828),
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const Spacer(),
              StatusPill(
                label: '${_requests.length} pending',
                backgroundColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1F88C9),
                icon: Icons.inbox_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isEmpty)
            Container(
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
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inbox_rounded,
                      color: Color(0xFF1F88C9),
                      size: 34,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'No new requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF101828),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fresh bookings will appear here as soon as clients send them.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                  ),
                ],
              ),
            )
          else
            ..._requests.asMap().entries.expand(
                  (entry) => [
                    BrokerRequestCard(
                      request: entry.value,
                      onAccept: () => _acceptRequest(entry.value),
                      onReject: () => _rejectRequest(entry.value),
                    ),
                    if (entry.key != _requests.length - 1) const SizedBox(height: 12),
                  ],
                ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload demo data'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssignmentSelection {
  const _AssignmentSelection({
    required this.driver,
    required this.truck,
  });

  final BrokerDriver driver;
  final BrokerVehicle truck;
}

InputDecoration _popupFieldDecoration({
  required String labelText,
  required IconData prefixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF1F88C9), width: 1.4),
    ),
  );
}
