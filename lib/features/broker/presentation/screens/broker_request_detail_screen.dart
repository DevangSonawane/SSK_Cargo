import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../widgets/broker_flow_widgets.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';

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

  BookingRequest get _request => widget.initialRequest is BookingRequest
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

  BrokerDriverRequest? get _driverRequest =>
      widget.initialRequest is BrokerDriverRequest
      ? widget.initialRequest as BrokerDriverRequest
      : null;

  bool get _isDriverNegotiation => _driverRequest != null;

  String get _counterSeedText {
    final driverRequest = _driverRequest;
    if (driverRequest != null) {
      return driverRequest.amount.toStringAsFixed(0);
    }
    return _readAmount(_request.value).toStringAsFixed(0);
  }

  String get _titleText => _isDriverNegotiation
      ? (_driverRequest!.bookingNumber.isNotEmpty
            ? _driverRequest!.bookingNumber
            : _driverRequest!.bookingId)
      : _request.productName;

  String get _requestNumberText => _isDriverNegotiation
      ? 'Driver request #${_driverRequest!.id}'
      : 'Request #${_request.id}';

  String get _pickupText => _isDriverNegotiation
      ? (_driverRequest!.pickup.isNotEmpty
            ? _driverRequest!.pickup
            : 'Pickup location not provided')
      : _request.from;

  String get _dropText => _isDriverNegotiation
      ? (_driverRequest!.drop.isNotEmpty
            ? _driverRequest!.drop
            : 'Drop-off location not provided')
      : _request.to;

  String get _vehicleText => _isDriverNegotiation
      ? (_driverRequest!.truckType.isNotEmpty
            ? _driverRequest!.truckType
            : 'Truck')
      : _request.vehicleType;

  String get _weightText => _isDriverNegotiation
      ? (_driverRequest!.weight.isNotEmpty ? _driverRequest!.weight : 'N/A')
      : _request.weight;

  String get _valueText => _isDriverNegotiation
      ? '₹${_driverRequest!.amount.toStringAsFixed(0)}'
      : _request.value;

  String get _statusText => _isDriverNegotiation
      ? (_driverRequest!.driverTimedOut
            ? 'Driver timed out. Broker handoff active.'
            : _driverRequest!.status)
      : _request.status;

  @override
  void initState() {
    super.initState();
    _counterController = TextEditingController(text: _counterSeedText);
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _counterController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double _readAmount(String value) {
    final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), ''));
    return parsed == null || parsed.isNaN ? 0 : parsed;
  }

  String? _defaultDriverId(List<BrokerDriver> drivers) {
    for (final driver in drivers) {
      if (driver.vehicleType.toLowerCase() ==
          _request.vehicleType.toLowerCase()) {
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
      if (_isDriverNegotiation) {
        await ref
            .read(apiClientProvider)
            .rejectDriverRequest(
              accessToken: session.tokens.accessToken,
              id: _driverRequest!.id,
            );
        ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      } else {
        await ref
            .read(apiClientProvider)
            .declineJobRequest(
              accessToken: session.tokens.accessToken,
              id: _request.id,
            );
        ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      }
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
      if (_isDriverNegotiation) {
        await ref
            .read(apiClientProvider)
            .counterDriverRequest(
              accessToken: session.tokens.accessToken,
              id: _driverRequest!.id,
              amount: amount,
            );
        ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      } else {
        await ref
            .read(apiClientProvider)
            .counterJobRequest(
              accessToken: session.tokens.accessToken,
              id: _request.id,
              amount: amount,
              note: _noteController.text.trim(),
            );
        ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));
      }
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
    final selectedDriver =
        drivers.where((driver) => driver.id == driverId).isNotEmpty
        ? drivers.firstWhere((driver) => driver.id == driverId)
        : null;
    final selectedTruck =
        trucks.where((truck) => truck.id == truckId).isNotEmpty
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
      final assignResponse = await ref
          .read(apiClientProvider)
          .assignDriverToJob(
            accessToken: session.tokens.accessToken,
            id: _request.id,
            driverId: selectedDriver.id,
            truckId: selectedTruck.id,
          );
      ref.invalidate(brokerJobRequestsProvider((page: 1, limit: 100)));

      final bookingShipment = _bookingShipmentFromAssignResponse(
        assignResponse,
        fallbackDriver: selectedDriver,
        fallbackTruck: selectedTruck,
      );
      final shipment =
          bookingShipment ??
          bookingRequestToShipment(
            _request,
            status: 'Assigned',
            assignedDriverName: selectedDriver.name,
            assignedTruckName:
                '${selectedTruck.label} • ${selectedTruck.plateNumber}',
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

  Future<void> _acceptTimedOutDriverRequest() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final request = _driverRequest;
    if (session == null || request == null) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .acceptDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
      ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      if (!mounted) return;
      final shipment = brokerDriverRequestToShipment(request);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Negotiation accepted.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
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
                          _titleText,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
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
                          color: _isDriverNegotiation
                              ? const Color(0xFFFFF4E5)
                              : const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _valueText,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: _isDriverNegotiation
                                    ? const Color(0xFFB54708)
                                    : const Color(0xFF1F88C9),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _requestNumberText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (_isDriverNegotiation) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _driverRequest!.driverTimedOut
                            ? const Color(0xFFFFF7ED)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _driverRequest!.driverTimedOut
                              ? const Color(0xFFFECF9E)
                              : const Color(0xFFE8EDF2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _statusText,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: _driverRequest!.driverTimedOut
                                      ? const Color(0xFFB54708)
                                      : const Color(0xFF101828),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Driver: ${_driverRequest!.driverName.isEmpty ? 'Unavailable' : _driverRequest!.driverName}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF344054)),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Truck: ${_driverRequest!.truckType.isEmpty ? 'Truck' : _driverRequest!.truckType}${_driverRequest!.truckReg.isEmpty ? '' : ' • ${_driverRequest!.truckReg}'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: const Color(0xFF344054)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _SummaryRow(label: 'Pickup', value: _pickupText),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Drop-off', value: _dropText),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Vehicle', value: _vehicleText),
                  const SizedBox(height: 10),
                  _SummaryRow(label: 'Weight', value: _weightText),
                  if (_isDriverNegotiation) ...[
                    const SizedBox(height: 10),
                    _SummaryRow(
                      label: 'Broker',
                      value: _driverRequest!.brokerName.isNotEmpty
                          ? _driverRequest!.brokerName
                          : 'Broker handoff active',
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (_isDriverNegotiation)
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
                      'Broker negotiation',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Counter or reject the timed-out driver request, then accept to assign this truck.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
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
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : _reject,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFE23A4B),
                              side: const BorderSide(color: Color(0xFFF5B7BF)),
                            ),
                            child: const Text('Reject'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting ? null : _counter,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF1F88C9),
                              side: const BorderSide(color: Color(0xFF1F88C9)),
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
                            : _acceptTimedOutDriverRequest,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F88C9),
                        ),
                        child: Text(
                          _submitting ? 'Saving...' : 'Accept & assign',
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
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
                                        onPressed: _submitting ? null : _reject,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFFE23A4B,
                                          ),
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
                                        onPressed: _submitting
                                            ? null
                                            : _counter,
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(
                                            0xFF1F88C9,
                                          ),
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

TrackingDemoShipment? _bookingShipmentFromAssignResponse(
  Map<String, dynamic> response, {
  required BrokerDriver fallbackDriver,
  required BrokerVehicle fallbackTruck,
}) {
  final data = response['data'];
  final payload = data is Map<String, dynamic> ? data : response;
  final booking = payload['booking'];
  if (booking is! Map<String, dynamic>) {
    return null;
  }

  final bookingModel = ClientBooking.fromJson(booking);
  final base = trackingShipmentFromBooking(bookingModel);
  return base.copyWith(
    status: _shipmentStatusFromBooking(bookingModel.status),
    assignedDriverName: fallbackDriver.name,
    assignedTruckName: '${fallbackTruck.label} • ${fallbackTruck.plateNumber}',
  );
}

String _shipmentStatusFromBooking(String status) {
  final normalized = status.trim().toLowerCase();
  return switch (normalized) {
    'confirmed' => 'Confirmed',
    'assigned' => 'Assigned',
    'en_route_pickup' => 'En Route',
    'picked_up' => 'Picked Up',
    'in_transit' => 'In Transit',
    'delivered' => 'Delivered',
    'completed' => 'Completed',
    'cancelled' => 'Cancelled',
    _ => status.isEmpty ? 'Assigned' : status,
  };
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
