import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerTrackingScreen extends ConsumerWidget {
  const BrokerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(
      brokerDriversApiProvider((status: null, page: 1, limit: 10)),
    );
    final List<BrokerDriver> availableDrivers =
        driversAsync.valueOrNull ?? const <BrokerDriver>[];

    Future<void> openDriverSheet(BrokerDriver driver) async {
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _BrokerDriverTripSheet(driver: driver),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          children: [
            Text(
              'Driver tracking',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            _HeaderActionButton(
              icon: Icons.assignment_rounded,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const _DriverRequestsSheet(),
              ),
            ),
            const SizedBox(width: 10),
            _HeaderActionButton(
              icon: Icons.warning_amber_rounded,
              onTap: () {
                final preferredDriver = availableDrivers
                    .where(
                      (driver) => driver.status == BrokerDriverStatus.onTrip,
                    )
                    .toList();
                if (preferredDriver.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No active trip found for incident handling.',
                      ),
                    ),
                  );
                  return;
                }
                openDriverSheet(preferredDriver.first);
              },
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => context.push('/broker/drivers/add'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                fixedSize: const Size(40, 40),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        driversAsync.when(
          data: (drivers) {
            if (drivers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No drivers yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a driver from the + button to start tracking.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              );
            }

            final liveDriver = _preferredLiveDriver(drivers);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DriverLocationOverviewCard(
                  driver: liveDriver,
                  title: 'Live driver position',
                  subtitle: liveDriver.currentLocation.isEmpty
                      ? 'Awaiting driver location'
                      : liveDriver.currentLocation,
                ),
                const SizedBox(height: 14),

                for (var index = 0; index < drivers.length; index++) ...[
                  DriverListTile(
                    driver: drivers[index],
                    onTap: () => openDriverSheet(drivers[index]),
                    onEdit: () {
                      context.push(
                        '/broker/drivers/add',
                        extra: drivers[index],
                      );
                    },
                    onRemove: () =>
                        _confirmDeleteDriver(context, ref, drivers[index]),
                  ),
                  if (index != drivers.length - 1) const SizedBox(height: 10),
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
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB42318)),
            ),
          ),
        ),
      ],
    );
  }
}

Future<void> _confirmDeleteDriver(
  BuildContext context,
  WidgetRef ref,
  BrokerDriver driver,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Remove driver?'),
        content: Text('This will delete ${driver.name} from the broker fleet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE23A4B),
            ),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );

  if (confirmed != true || !context.mounted) return;

  final session = ref.read(authSessionProvider).valueOrNull;
  if (session == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in again to delete a driver.')),
    );
    return;
  }

  try {
    await ref
        .read(apiClientProvider)
        .deleteDriver(accessToken: session.tokens.accessToken, id: driver.id);
    if (!context.mounted) return;
    ref.invalidate(
      brokerDriversApiProvider((status: null, page: 1, limit: 10)),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver removed from fleet.')),
    );
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.toString().replaceFirst('ApiException: ', '')),
      ),
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Icon(icon, color: const Color(0xFF1F88C9), size: 20),
      ),
    );
  }
}

class _DriverRequestsSheet extends ConsumerStatefulWidget {
  const _DriverRequestsSheet();

  @override
  ConsumerState<_DriverRequestsSheet> createState() =>
      _DriverRequestsSheetState();
}

class _DriverRequestsSheetState extends ConsumerState<_DriverRequestsSheet> {
  static const _query = (page: 1, limit: 50);
  bool _countering = false;
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      ref.invalidate(brokerDriverRequestsProvider(_query));
      await ref.read(brokerDriverRequestsProvider(_query).future);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _runAction({
    required BrokerDriverRequest request,
    required Future<void> Function(SskApiClient api, String token) action,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    try {
      await action(ref.read(apiClientProvider), session.tokens.accessToken);
      ref.invalidate(brokerDriverRequestsProvider(_query));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request updated.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(brokerDriverRequestsProvider(_query));
    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 54,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFE1E5EB),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Driver requests',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _refreshing ? null : _refresh,
                  icon: _refreshing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh_rounded),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.62,
              child: requestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(error.toString().replaceFirst('Exception: ', '')),
                ),
                data: (requests) {
                  if (requests.isEmpty) {
                    return const Center(child: Text('No driver requests yet.'));
                  }

                  return ListView.separated(
                    itemCount: requests.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    request.bookingNumber.isEmpty
                                        ? request.bookingId
                                        : request.bookingNumber,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF101828),
                                        ),
                                  ),
                                ),
                                Text(
                                  request.status,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: const Color(0xFF1F88C9),
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${request.clientName} • ${request.pickup} → ${request.drop}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: const Color(0xFF667085)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${request.amount.toStringAsFixed(0)} • ${request.truckType}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _runAction(
                                      request: request,
                                      action: (api, token) =>
                                          api.acceptDriverRequest(
                                            accessToken: token,
                                            id: request.id,
                                          ),
                                    ),
                                    child: const Text('Accept'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _runAction(
                                      request: request,
                                      action: (api, token) =>
                                          api.rejectDriverRequest(
                                            accessToken: token,
                                            id: request.id,
                                          ),
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton(
                                    onPressed: _countering
                                        ? null
                                        : () async {
                                            final controller =
                                                TextEditingController(
                                                  text: request.amount
                                                      .toStringAsFixed(0),
                                                );
                                            final noteController =
                                                TextEditingController();
                                            final counter = await showDialog<double?>(
                                              context: context,
                                              builder: (dialogContext) {
                                                return AlertDialog(
                                                  title: const Text(
                                                    'Counter request',
                                                  ),
                                                  content: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      TextField(
                                                        controller: controller,
                                                        keyboardType:
                                                            TextInputType
                                                                .number,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText:
                                                                  'Amount',
                                                            ),
                                                      ),
                                                      const SizedBox(
                                                        height: 10,
                                                      ),
                                                      TextField(
                                                        controller:
                                                            noteController,
                                                        decoration:
                                                            const InputDecoration(
                                                              labelText: 'Note',
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(
                                                            dialogContext,
                                                          ).pop(),
                                                      child: const Text(
                                                        'Cancel',
                                                      ),
                                                    ),
                                                    FilledButton(
                                                      onPressed: () {
                                                        final amount =
                                                            double.tryParse(
                                                              controller.text
                                                                  .trim(),
                                                            );
                                                        Navigator.of(
                                                          dialogContext,
                                                        ).pop(amount);
                                                      },
                                                      child: const Text('Send'),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                            if (counter == null) return;
                                            setState(() => _countering = true);
                                            try {
                                              await _runAction(
                                                request: request,
                                                action: (api, token) =>
                                                    api.counterDriverRequest(
                                                      accessToken: token,
                                                      id: request.id,
                                                      amount: counter,
                                                    ),
                                              );
                                            } finally {
                                              if (mounted) {
                                                setState(
                                                  () => _countering = false,
                                                );
                                              }
                                            }
                                          },
                                    child: const Text('Counter'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BrokerDriver _preferredLiveDriver(List<BrokerDriver> drivers) {
  for (final driver in drivers) {
    if (driver.status == BrokerDriverStatus.onTrip &&
        driver.hasLiveCoordinates) {
      return driver;
    }
  }

  for (final driver in drivers) {
    if (driver.hasLiveCoordinates) {
      return driver;
    }
  }

  return drivers.first;
}

class _BrokerDriverTripSheet extends ConsumerStatefulWidget {
  const _BrokerDriverTripSheet({required this.driver});

  final BrokerDriver driver;

  @override
  ConsumerState<_BrokerDriverTripSheet> createState() =>
      _BrokerDriverTripSheetState();
}

class _BrokerDriverTripSheetState
    extends ConsumerState<_BrokerDriverTripSheet> {
  late Future<_BrokerDriverTripSnapshot> _snapshotFuture;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _snapshotFuture = _loadSnapshot();
  }

  String _resolveTripId() {
    if (widget.driver.activeTripId.isNotEmpty) {
      return widget.driver.activeTripId;
    }
    if (widget.driver.currentBookingRef.isNotEmpty) {
      return widget.driver.currentBookingRef;
    }
    return '';
  }

  Future<_BrokerDriverTripSnapshot> _loadSnapshot() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tripId = _resolveTripId();
    if (session == null) {
      return _BrokerDriverTripSnapshot.fromDriver(
        driver: widget.driver,
        tripId: tripId,
        statusLabel: 'Sign in to load trip progress',
      );
    }

    if (tripId.isEmpty) {
      return _BrokerDriverTripSnapshot.fromDriver(
        driver: widget.driver,
        tripId: tripId,
        statusLabel: widget.driver.hasCompletedTrip
            ? 'Trip completed'
            : 'Driver location only',
      );
    }

    try {
      final api = ref.read(apiClientProvider);
      final tripResponse = await api.getTrip(
        accessToken: session.tokens.accessToken,
        tripId: tripId,
      );
      final incidentsResponse = await api.getTripIncidents(
        accessToken: session.tokens.accessToken,
        tripId: tripId,
      );

      final tripData = _tripMapOf(
        tripResponse['data'] ?? tripResponse['trip'] ?? tripResponse,
      );
      final tripPayload = _tripMapOf(
        tripData['trip'] ??
            tripData['booking'] ??
            tripData['shipment'] ??
            tripData,
      );
      final incidents = _tripListOfMaps(
        incidentsResponse['data'] ??
            incidentsResponse['incidents'] ??
            incidentsResponse,
      ).map(_BrokerTripIncident.fromJson).toList();

      return _BrokerDriverTripSnapshot(
        driver: widget.driver,
        tripId: tripId,
        shipment: _shipmentFromTripData(
          driver: widget.driver,
          tripId: tripId,
          tripData: tripPayload,
        ),
        incidents: incidents,
        statusLabel: _tripString(tripPayload, const [
          'status',
          'trip_status',
          'tripStatus',
          'delivery_status',
          'shipment_status',
        ]),
        tripAmount:
            _tripDouble(tripPayload, const [
              'amount',
              'total_amount',
              'total',
              'fare',
              'price',
              'value',
            ]) ??
            0,
        paymentStatus: _tripString(tripPayload, const [
          'payment_status',
          'paymentStatus',
        ]),
      );
    } catch (_) {
      return _BrokerDriverTripSnapshot.fromDriver(
        driver: widget.driver,
        tripId: tripId,
        statusLabel: widget.driver.tripStatus.isNotEmpty
            ? widget.driver.tripStatus
            : 'Live details unavailable',
      );
    }
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      ref.invalidate(
        brokerDriversApiProvider((status: null, page: 1, limit: 10)),
      );
      setState(() {
        _snapshotFuture = _loadSnapshot();
      });
      await _snapshotFuture;
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _reportIncident(_BrokerDriverTripSnapshot snapshot) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tripId = snapshot.tripId;
    if (session == null || tripId.isEmpty) {
      return;
    }

    final reasonController = TextEditingController();
    final notesController = TextEditingController();
    final details = await showDialog<_IncidentReportPayload>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Report incident'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(labelText: 'Reason'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(
                  _IncidentReportPayload(
                    reason: reasonController.text.trim(),
                    notes: notesController.text.trim(),
                  ),
                );
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (details == null || details.reason.isEmpty) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .reportTripIssue(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            reason: details.reason,
            notes: details.notes,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incident reported successfully.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _collectSettlement(_BrokerDriverTripSnapshot snapshot) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tripId = snapshot.tripId;
    if (session == null || tripId.isEmpty) {
      return;
    }

    final mode = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Collect settlement'),
          content: const Text('Choose the settlement mode for this trip.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop('cash'),
              child: const Text('Cash'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(dialogContext).pop('online'),
              child: const Text('Online'),
            ),
          ],
        );
      },
    );

    if (mode == null || mode.isEmpty) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .collectTripPayment(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            mode: mode,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Settlement updated.')));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _completeTrip(_BrokerDriverTripSnapshot snapshot) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tripId = snapshot.tripId;
    if (session == null || tripId.isEmpty) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .completeTrip(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip marked as completed.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _updateIncidentMechanic(
    _BrokerTripIncident incident,
    _BrokerDriverTripSnapshot snapshot,
  ) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tripId = snapshot.tripId;
    if (session == null || tripId.isEmpty || incident.id.isEmpty) {
      return;
    }

    final mechanicNameController = TextEditingController();
    final mechanicPhoneController = TextEditingController();
    final notesController = TextEditingController();

    final details = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Update mechanic'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: mechanicNameController,
                decoration: const InputDecoration(labelText: 'Mechanic name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: mechanicPhoneController,
                decoration: const InputDecoration(labelText: 'Mechanic phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (details != true) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .updateTripIncidentMechanic(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            incidentId: incident.id,
            status: 'assigned',
            mechanicName: mechanicNameController.text.trim(),
            mechanicPhone: mechanicPhoneController.text.trim(),
            notes: notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mechanic details updated.')),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _resolveIncident(
    _BrokerTripIncident incident,
    _BrokerDriverTripSnapshot snapshot,
  ) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tripId = snapshot.tripId;
    if (session == null || tripId.isEmpty || incident.id.isEmpty) {
      return;
    }

    try {
      await ref
          .read(apiClientProvider)
          .resolveTripIncident(
            accessToken: session.tokens.accessToken,
            tripId: tripId,
            incidentId: incident.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Incident resolved.')));
      await _refresh();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Container(
        constraints: BoxConstraints(maxHeight: height * 0.9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: FutureBuilder<_BrokerDriverTripSnapshot>(
          future: _snapshotFuture,
          builder: (context, snapshot) {
            final data =
                snapshot.data ??
                _BrokerDriverTripSnapshot.fromDriver(
                  driver: widget.driver,
                  tripId: _resolveTripId(),
                  statusLabel: 'Loading...',
                );

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 54,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE1E5EB),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.driver.name,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101828),
                                ),
                          ),
                        ),
                        IconButton(
                          onPressed: _refreshing ? null : _refresh,
                          icon: _refreshing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh_rounded),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            this.context.push('/broker/settings/settlements');
                          },
                          child: const Text('Settlements'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      data.tripId.isEmpty
                          ? 'Driver location and activity overview'
                          : 'Trip ${data.tripId}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TrackingRouteMapView(
                      shipment: data.shipment,
                      liveMode: true,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TripInfoChip(
                          icon: Icons.route_rounded,
                          label: data.statusLabel.isEmpty
                              ? 'Live'
                              : data.statusLabel,
                        ),
                        _TripInfoChip(
                          icon: Icons.payments_rounded,
                          label: data.paymentStatus.isEmpty
                              ? 'Payment pending'
                              : data.paymentStatus,
                        ),
                        _TripInfoChip(
                          icon: Icons.report_problem_rounded,
                          label: '${data.incidents.length} incidents',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Trip progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _TimelineSection(steps: data.shipment.timeline),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: data.tripId.isEmpty
                                ? null
                                : () => _reportIncident(data),
                            icon: const Icon(Icons.warning_amber_rounded),
                            label: const Text('Report issue'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: data.tripId.isEmpty
                                ? null
                                : () => _collectSettlement(data),
                            icon: const Icon(Icons.payments_rounded),
                            label: const Text('Settle'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: data.tripId.isEmpty
                                ? null
                                : () => _completeTrip(data),
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Mark complete'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Incidents',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (data.incidents.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FB),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE8EDF2)),
                        ),
                        child: Text(
                          data.tripId.isEmpty
                              ? 'No active trip incident data for this driver.'
                              : 'No incidents reported yet.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (final incident in data.incidents) ...[
                            _TripIncidentCard(
                              incident: incident,
                              onResolve: () => _resolveIncident(incident, data),
                              onMechanic: () =>
                                  _updateIncidentMechanic(incident, data),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BrokerDriverTripSnapshot {
  const _BrokerDriverTripSnapshot({
    required this.driver,
    required this.tripId,
    required this.shipment,
    required this.incidents,
    required this.statusLabel,
    required this.tripAmount,
    required this.paymentStatus,
  });

  factory _BrokerDriverTripSnapshot.fromDriver({
    required BrokerDriver driver,
    required String tripId,
    required String statusLabel,
  }) {
    final shipment = TrackingDemoShipment(
      packageName: driver.name,
      trackingId: tripId.isEmpty ? driver.id : tripId,
      fromLocation: driver.currentLocation.isEmpty
          ? 'Driver location'
          : driver.currentLocation,
      toLocation: driver.assignedVehicle.isEmpty
          ? 'Trip destination not available'
          : driver.assignedVehicle,
      status: statusLabel,
      customerName: driver.name,
      weight: driver.vehicleType.isEmpty
          ? 'Vehicle tracking'
          : driver.vehicleType,
      liveLat: driver.currentLatitude,
      liveLng: driver.currentLongitude,
      timeline: _driverTimelineFromStatus(statusLabel, driver),
      bookingId: tripId.isEmpty ? null : tripId,
      bookingStatus: statusLabel,
      assignedDriverName: driver.name,
      assignedTruckName: driver.assignedVehicle,
    );
    return _BrokerDriverTripSnapshot(
      driver: driver,
      tripId: tripId,
      shipment: shipment,
      incidents: const [],
      statusLabel: statusLabel,
      tripAmount: 0,
      paymentStatus: '',
    );
  }

  final BrokerDriver driver;
  final String tripId;
  final TrackingDemoShipment shipment;
  final List<_BrokerTripIncident> incidents;
  final String statusLabel;
  final double tripAmount;
  final String paymentStatus;
}

class _BrokerTripIncident {
  const _BrokerTripIncident({
    required this.id,
    required this.title,
    required this.status,
    required this.notes,
    required this.mechanicName,
    required this.createdAt,
  });

  factory _BrokerTripIncident.fromJson(Map<String, dynamic> json) {
    return _BrokerTripIncident(
      id: _tripString(json, const ['id', 'incident_id', 'uuid']),
      title: _tripString(json, const ['title', 'reason', 'type', 'name']),
      status: _tripString(json, const ['status', 'state']),
      notes: _tripString(json, const ['notes', 'description', 'message']),
      mechanicName: _tripString(json, const [
        'mechanicName',
        'mechanic_name',
        'mechanic',
      ]),
      createdAt: _tripString(json, const [
        'createdAt',
        'created_at',
        'reported_at',
        'updated_at',
      ]),
    );
  }

  final String id;
  final String title;
  final String status;
  final String notes;
  final String mechanicName;
  final String createdAt;
}

class _IncidentReportPayload {
  const _IncidentReportPayload({required this.reason, required this.notes});

  final String reason;
  final String notes;
}

class _TripInfoChip extends StatelessWidget {
  const _TripInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF1F88C9)),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF344054),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection({required this.steps});

  final List<TrackingTimelineStep> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _TimelineRow(step: steps[index]),
          if (index != steps.length - 1)
            Container(
              margin: const EdgeInsets.only(left: 10),
              width: 2,
              height: 18,
              color: const Color(0xFFE8EDF2),
            ),
        ],
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.step});

  final TrackingTimelineStep step;

  @override
  Widget build(BuildContext context) {
    final color = step.completed
        ? const Color(0xFF2FA56E)
        : const Color(0xFF98A2B3);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: step.completed
                ? const Color(0xFFEAF8EF)
                : const Color(0xFFF2F4F7),
            shape: BoxShape.circle,
          ),
          child: Icon(
            step.completed ? Icons.check_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  step.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TripIncidentCard extends StatelessWidget {
  const _TripIncidentCard({
    required this.incident,
    required this.onResolve,
    required this.onMechanic,
  });

  final _BrokerTripIncident incident;
  final VoidCallback onResolve;
  final VoidCallback onMechanic;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  incident.title.isEmpty ? 'Incident' : incident.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
              ),
              if (incident.status.isNotEmpty)
                Text(
                  incident.status,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF1F88C9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          if (incident.notes.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              incident.notes,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
            ),
          ],
          if (incident.mechanicName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Mechanic: ${incident.mechanicName}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF344054),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (incident.createdAt.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              incident.createdAt,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: const Color(0xFF98A2B3)),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onMechanic,
                  child: const Text('Mechanic'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onResolve,
                  child: const Text('Resolve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<TrackingTimelineStep> _driverTimelineFromStatus(
  String status,
  BrokerDriver driver,
) {
  final text = status.trim().toLowerCase();
  final origin = driver.currentLocation.isEmpty
      ? 'Driver location'
      : driver.currentLocation;
  final destination = driver.assignedVehicle.isEmpty
      ? 'Trip destination'
      : driver.assignedVehicle;
  if (const {'completed', 'delivered', 'closed', 'settled'}.contains(text)) {
    return [
      TrackingTimelineStep(
        title: 'Assigned',
        subtitle: origin,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In transit',
        subtitle: destination,
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Trip completed',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Settled',
        subtitle: 'Broker updated the payout',
        completed: true,
      ),
    ];
  }
  return [
    TrackingTimelineStep(title: 'Assigned', subtitle: origin, completed: true),
    TrackingTimelineStep(
      title: 'In transit',
      subtitle: destination,
      completed: true,
    ),
    TrackingTimelineStep(
      title: 'Delivered',
      subtitle: 'Pending',
      completed: false,
    ),
    TrackingTimelineStep(
      title: 'Settled',
      subtitle: 'Pending',
      completed: false,
    ),
  ];
}

TrackingDemoShipment _shipmentFromTripData({
  required BrokerDriver driver,
  required String tripId,
  required Map<String, dynamic> tripData,
}) {
  final status = _tripString(tripData, const [
    'status',
    'trip_status',
    'tripStatus',
    'delivery_status',
    'shipment_status',
  ]);
  final pickup = _tripString(tripData, const [
    'pickup_location',
    'pickupLocation',
    'origin',
    'from',
    'source_location',
  ]);
  final drop = _tripString(tripData, const [
    'dropoff_location',
    'dropoffLocation',
    'destination',
    'to',
    'target_location',
  ]);
  final currentLat = _tripDouble(tripData, const [
    'current_lat',
    'currentLat',
    'truck_lat',
    'truckLat',
    'lat',
  ]);
  final currentLng = _tripDouble(tripData, const [
    'current_lng',
    'currentLng',
    'truck_lng',
    'truckLng',
    'lng',
  ]);
  final pickupLat = _tripDouble(tripData, const [
    'pickup_lat',
    'pickupLat',
    'origin_lat',
    'source_lat',
  ]);
  final pickupLng = _tripDouble(tripData, const [
    'pickup_lng',
    'pickupLng',
    'origin_lng',
    'source_lng',
  ]);
  final dropLat = _tripDouble(tripData, const [
    'drop_lat',
    'dropLat',
    'destination_lat',
    'target_lat',
  ]);
  final dropLng = _tripDouble(tripData, const [
    'drop_lng',
    'dropLng',
    'destination_lng',
    'target_lng',
  ]);

  return TrackingDemoShipment(
    packageName:
        _tripString(tripData, const [
          'package_name',
          'packageName',
          'title',
          'cargo_name',
        ]).isEmpty
        ? driver.name
        : _tripString(tripData, const [
            'package_name',
            'packageName',
            'title',
            'cargo_name',
          ]),
    trackingId: tripId,
    fromLocation: pickup.isEmpty ? driver.currentLocation : pickup,
    toLocation: drop.isEmpty
        ? (driver.assignedVehicle.isEmpty
              ? 'Destination not available'
              : driver.assignedVehicle)
        : drop,
    status: status.isEmpty
        ? (driver.hasCompletedTrip ? 'Completed' : 'In transit')
        : status,
    customerName:
        _tripString(tripData, const [
          'client_name',
          'customer_name',
          'clientName',
          'customerName',
        ]).isEmpty
        ? driver.name
        : _tripString(tripData, const [
            'client_name',
            'customer_name',
            'clientName',
            'customerName',
          ]),
    weight:
        _tripString(tripData, const [
          'weight',
          'cargo_weight',
          'load_weight',
          'item_weight',
        ]).isEmpty
        ? (driver.vehicleType.isEmpty ? 'Vehicle tracking' : driver.vehicleType)
        : _tripString(tripData, const [
            'weight',
            'cargo_weight',
            'load_weight',
            'item_weight',
          ]),
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    dropLat: dropLat,
    dropLng: dropLng,
    liveLat: currentLat ?? driver.currentLatitude,
    liveLng: currentLng ?? driver.currentLongitude,
    timeline: _driverTimelineFromStatus(
      status.isEmpty ? driver.tripStatus : status,
      driver,
    ),
    bookingId: tripId,
    bookingStatus: status,
    assignedDriverName: driver.name,
    assignedTruckName: driver.assignedVehicle,
  );
}

Map<String, dynamic> _tripMapOf(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _tripListOfMaps(Object? value) {
  final items = <Map<String, dynamic>>[];
  if (value is List) {
    for (final item in value) {
      final map = _tripMapOf(item);
      if (map.isNotEmpty) {
        items.add(map);
      }
    }
  } else if (value is Map<String, dynamic>) {
    final data = value['data'];
    if (data is List) {
      for (final item in data) {
        final map = _tripMapOf(item);
        if (map.isNotEmpty) {
          items.add(map);
        }
      }
    } else {
      final map = _tripMapOf(value);
      if (map.isNotEmpty) {
        items.add(map);
      }
    }
  }
  return items;
}

String _tripString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

double? _tripDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}
