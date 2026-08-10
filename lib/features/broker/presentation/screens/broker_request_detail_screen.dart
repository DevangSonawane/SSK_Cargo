import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerRequestDetailScreen extends ConsumerStatefulWidget {
  const BrokerRequestDetailScreen({super.key, this.initialRequest});

  final Object? initialRequest;

  @override
  ConsumerState<BrokerRequestDetailScreen> createState() =>
      _BrokerRequestDetailScreenState();
}

class _BrokerRequestDetailScreenState
    extends ConsumerState<BrokerRequestDetailScreen> {
  late final TextEditingController _counterController;
  late final TextEditingController _noteController;
  bool _submitting = false;
  String? _selectedDriverId;
  String? _selectedTruckId;

  BookingRequest get _request =>
      widget.initialRequest is BookingRequest
          ? widget.initialRequest as BookingRequest
          : const BookingRequest(
              id: '',
              status: 'pending',
              clientName: 'Customer',
              clientInitials: 'C',
              productName: 'Booking request',
              from: 'Pickup location not provided',
              to: 'Drop-off location not provided',
              weight: 'N/A',
              vehicleType: 'Truck',
              value: '₹0',
              distance: '',
              etaText: '',
              requestedAt: '',
            );

  @override
  void initState() {
    super.initState();
    _counterController = TextEditingController(
      text: _readAmount(_request.value).toStringAsFixed(0),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _counterController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _readAmount(String value) {
    final parsed = double.tryParse(
      value.replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    return parsed == null || parsed.isNaN ? 0 : parsed;
  }

  String? _defaultDriverId(List<BrokerDriver> drivers) {
    for (final driver in drivers) {
      if (driver.vehicleType.toLowerCase() == _request.vehicleType.toLowerCase()) {
        return driver.id;
      }
    }
    return drivers.isNotEmpty ? drivers.first.id : null;
  }

  String? _defaultTruckId(List<BrokerVehicle> trucks) {
    for (final truck in trucks) {
      if (truck.label.toLowerCase() == _request.vehicleType.toLowerCase()) {
        return truck.id;
      }
    }
    return trucks.isNotEmpty ? trucks.first.id : null;
  }

  Future<void> _reject() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .declineJobRequest(
            accessToken: session.tokens.accessToken,
            id: _request.id,
          );
      ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request rejected.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
      if (context.canPop()) context.pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _counter() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final amount = _readAmount(_counterController.text);
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid counter amount.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .counterJobRequest(
            accessToken: session.tokens.accessToken,
            id: _request.id,
            amount: amount,
            note: _noteController.text.trim(),
          );
      ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Counter sent.'),
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
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _acceptAndAssign({
    required List<BrokerDriver> drivers,
    required List<BrokerVehicle> trucks,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    final driverId = _selectedDriverId ?? _defaultDriverId(drivers);
    final truckId = _selectedTruckId ?? _defaultTruckId(trucks);
    final selectedDriver = drivers.where((driver) => driver.id == driverId).isNotEmpty
        ? drivers.firstWhere((driver) => driver.id == driverId)
        : null;
    final selectedTruck = trucks.where((truck) => truck.id == truckId).isNotEmpty
        ? trucks.firstWhere((truck) => truck.id == truckId)
        : null;

    if (selectedDriver == null || selectedTruck == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose both a driver and a truck to continue.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .acceptJobRequest(
            accessToken: session.tokens.accessToken,
            id: _request.id,
          );
      await ref
          .read(apiClientProvider)
          .assignDriverToJob(
            accessToken: session.tokens.accessToken,
            id: _request.id,
            driverId: selectedDriver.id,
            truckId: selectedTruck.id,
          );
      ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));

      final shipment = bookingRequestToShipment(
        _request,
        status: 'Assigned',
        assignedDriverName: selectedDriver.name,
        assignedTruckName: '${selectedTruck.label} • ${selectedTruck.plateNumber}',
      );

      if (!mounted) return;
      context.go('/broker/tracking/details', extra: shipment);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final driversAsync = ref.watch(
      brokerDriversApiProvider((status: null, page: 1, limit: 100)),
    );
    final trucksAsync = ref.watch(brokerVehiclesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Request review'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.productName,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF101828),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          request.value,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF1F88C9),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Request #${request.id}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(label: 'Pickup', value: request.from),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Drop-off', value: request.to),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Vehicle', value: request.vehicleType),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Weight', value: request.weight),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assignment',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose the driver and truck before accepting the request.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 14),
                  driversAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 18),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Color(0xFFE23A4B)),
                    ),
                    data: (drivers) {
                      final defaultDriverId = _defaultDriverId(drivers);
                      final selectedDriverId =
                          _selectedDriverId ?? defaultDriverId;
                      return trucksAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (error, _) => Text(
                          error.toString().replaceFirst('Exception: ', ''),
                          style: const TextStyle(color: Color(0xFFE23A4B)),
                        ),
                        data: (trucks) {
                          final defaultTruckId = _defaultTruckId(trucks);
                          final selectedTruckId =
                              _selectedTruckId ?? defaultTruckId;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: selectedDriverId,
                                decoration: const InputDecoration(
                                  labelText: 'Driver',
                                ),
                                items: drivers
                                    .map(
                                      (driver) => DropdownMenuItem(
                                        value: driver.id,
                                        child: Text(
                                          driver.name.isEmpty
                                              ? driver.id
                                              : driver.name,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _submitting
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedDriverId = value;
                                        });
                                      },
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: selectedTruckId,
                                decoration: const InputDecoration(
                                  labelText: 'Truck',
                                ),
                                items: trucks
                                    .map(
                                      (truck) => DropdownMenuItem(
                                        value: truck.id,
                                        child: Text(
                                          truck.plateNumber.isEmpty
                                              ? truck.label
                                              : '${truck.label} • ${truck.plateNumber}',
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _submitting
                                    ? null
                                    : (value) {
                                        setState(() {
                                          _selectedTruckId = value;
                                        });
                                      },
                              ),
                              const SizedBox(height: 14),
                              TextField(
                                controller: _counterController,
                                enabled: !_submitting,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Counter amount',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _noteController,
                                enabled: !_submitting,
                                minLines: 2,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  labelText: 'Note',
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _submitting ? null : _reject,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFFE23A4B),
                                        side: const BorderSide(
                                          color: Color(0xFFF5B7BF),
                                        ),
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed:
                                          _submitting ? null : _counter,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor:
                                            const Color(0xFF1F88C9),
                                        side: const BorderSide(
                                          color: Color(0xFF1F88C9),
                                        ),
                                      ),
                                      child: const Text('Counter'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: FilledButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => _acceptAndAssign(
                                          drivers: drivers,
                                          trucks: trucks,
                                        ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1F88C9),
                                  ),
                                  child: Text(
                                    _submitting
                                        ? 'Saving...'
                                        : 'Accept & assign',
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
