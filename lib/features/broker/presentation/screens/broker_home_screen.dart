import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerHomeScreen extends ConsumerStatefulWidget {
  const BrokerHomeScreen({super.key});

  @override
  ConsumerState<BrokerHomeScreen> createState() => _BrokerHomeScreenState();
}

class _BrokerHomeScreenState extends ConsumerState<BrokerHomeScreen> {
  static const _requestsQuery = (page: 1, limit: 100);

  Future<void> _refresh() async {
    ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
    await ref.read(brokerJobRequestsProvider(_requestsQuery).future);
  }

  Future<void> _acceptRequest(BookingRequest request) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to accept requests.')),
      );
      return;
    }

    try {
      await ref.read(apiClientProvider).acceptJobRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
      return;
    }

    if (!mounted) return;

    ref.invalidate(brokerJobRequestsProvider(_requestsQuery));

    final assignment = await _pickAssignment(request);
    if (assignment == null || !mounted) {
      return;
    }

    try {
      await ref.read(apiClientProvider).assignDriverToJob(
            accessToken: session.tokens.accessToken,
            id: request.id,
            driverId: assignment.driver!.id,
            truckId: assignment.truck!.id,
          );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
      return;
    }

    final shipment = bookingRequestToShipment(
      request,
      status: 'Assigned',
      assignedDriverName: assignment.driver!.name,
      assignedTruckName: '${assignment.truck!.label} • ${assignment.truck!.plateNumber}',
    );

    ref.invalidate(brokerJobRequestsProvider(_requestsQuery));

    if (!mounted) return;

    await context.push('/broker/tracking/details', extra: shipment);
  }

  Future<_AssignmentSelection?> _pickAssignment(BookingRequest request) async {
    final result = await _loadAssignmentOptions();
    final drivers = result.drivers;
    final trucks = result.trucks;

    if (!mounted) {
      return null;
    }

    if (drivers.isEmpty || trucks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No available drivers or trucks found for assignment.'),
          backgroundColor: Color(0xFFE23A4B),
        ),
      );
      return null;
    }

    final defaultDriver = _defaultDriverForRequest(request, drivers);
    final defaultTruck = _defaultTruckForRequest(request, trucks);

    return showDialog<_AssignmentSelection>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (dialogContext) {
        BrokerDriver? selectedDriver = defaultDriver;
        BrokerVehicle? selectedTruck = defaultTruck;

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
                      _SelectionSection<BrokerDriver>(
                        label: 'Driver',
                        icon: Icons.person_rounded,
                        emptyLabel: 'None',
                        value: selectedDriver,
                        items: drivers,
                        itemLabel: (driver) => driver.name,
                        onSelected: (driver) => setModalState(() => selectedDriver = driver),
                      ),
                      const SizedBox(height: 12),
                      _SelectionSection<BrokerVehicle>(
                        label: 'Truck',
                        icon: Icons.local_shipping_rounded,
                        emptyLabel: 'None',
                        value: selectedTruck,
                        items: trucks,
                        itemLabel: (truck) => '${truck.label} • ${truck.plateNumber}',
                        onSelected: (truck) => setModalState(() => selectedTruck = truck),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          onPressed: () {
                            if (selectedDriver == null || selectedTruck == null) {
                              return;
                            }
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Skip for now'),
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

  Future<({List<BrokerDriver> drivers, List<BrokerVehicle> trucks})> _loadAssignmentOptions() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return (drivers: const <BrokerDriver>[], trucks: const <BrokerVehicle>[]);
    }

    final results = await Future.wait([
      ref.read(
        brokerDriversApiProvider((status: 'available', page: 1, limit: 100)).future,
      ),
      ref.read(
        brokerTrucksProvider((status: 'available', page: 1, limit: 100)).future,
      ),
    ]);

    return (
      drivers: results[0] as List<BrokerDriver>,
      trucks: results[1] as List<BrokerVehicle>,
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

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to reject requests.')),
      );
      return;
    }

    try {
      await ref.read(apiClientProvider).declineJobRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );

      if (!mounted) return;
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request declined.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(brokerJobRequestsProvider(_requestsQuery));
    final requests = requestsAsync.valueOrNull ?? const <BookingRequest>[];
    final pendingRequests = requests.where(isPendingBookingRequest).toList();

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
                label: '${pendingRequests.length} pending',
                backgroundColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1F88C9),
                icon: Icons.inbox_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),
          requestsAsync.when(
            data: (_) {
              if (pendingRequests.isEmpty) {
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
                );
              }

              return Column(
                children: [
                  for (var index = 0; index < pendingRequests.length; index++) ...[
                    BrokerRequestCard(
                      request: pendingRequests[index],
                      onAccept: () => _acceptRequest(pendingRequests[index]),
                      onReject: () => _rejectRequest(pendingRequests[index]),
                    ),
                    if (index != pendingRequests.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.only(top: 36),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Text(
                error.toString().replaceFirst('Exception: ', ''),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFFB42318),
                    ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reload requests'),
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

  final BrokerDriver? driver;
  final BrokerVehicle? truck;
}

BrokerDriver? _defaultDriverForRequest(BookingRequest request, List<BrokerDriver> drivers) {
  if (drivers.isEmpty) return null;
  for (final driver in drivers) {
    if (driver.vehicleType.toLowerCase() == request.vehicleType.toLowerCase()) {
      return driver;
    }
  }
  return drivers.first;
}

BrokerVehicle? _defaultTruckForRequest(BookingRequest request, List<BrokerVehicle> trucks) {
  if (trucks.isEmpty) return null;
  for (final truck in trucks) {
    if (truck.label.toLowerCase() == request.vehicleType.toLowerCase()) {
      return truck;
    }
  }
  return trucks.first;
}

class _SelectionSection<T> extends StatelessWidget {
  const _SelectionSection({
    required this.label,
    required this.icon,
    required this.emptyLabel,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final String emptyLabel;
  final T? value;
  final List<T> items;
  final String Function(T item) itemLabel;
  final ValueChanged<T?> onSelected;

  @override
  Widget build(BuildContext context) {
    final hasItems = items.isNotEmpty;
    final displayValue = value == null ? emptyLabel : itemLabel(value as T);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE3E8EF)),
          ),
          child: Column(
            children: [
              _SelectableOptionCard(
                label: emptyLabel,
                icon: icon,
                selected: value == null,
                onTap: () => onSelected(null),
              ),
              if (hasItems) ...[
                const SizedBox(height: 10),
                ...items.asMap().entries.map(
                      (entry) => Padding(
                        padding: EdgeInsets.only(top: entry.key == 0 ? 0 : 10),
                        child: _SelectableOptionCard(
                          label: itemLabel(entry.value),
                          icon: icon,
                          selected: value == entry.value,
                          onTap: () => onSelected(entry.value),
                        ),
                      ),
                    ),
              ] else ...[
                const SizedBox(height: 10),
                Text(
                  'No $label available right now.',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: $displayValue',
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  const _SelectableOptionCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF1F88C9) : const Color(0xFFE3E8EF),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF1F88C9) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF667085),
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF101828),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
