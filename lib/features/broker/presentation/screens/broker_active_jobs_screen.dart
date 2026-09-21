import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../shared/data/trip_route_stop.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../widgets/broker_flow_widgets.dart';

const int _activeJobsFetchPageLimit = 100;
const int _activeJobsFetchMaxPages = 50;
const double _activeJobsBottomNavClearance = 84;

final _brokerActiveJobsProvider =
    FutureProvider.autoDispose<List<_ActiveBrokerJob>>((ref) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final api = ref.watch(apiClientProvider);
      final token = session.tokens.accessToken;
      final responses = await Future.wait([
        _fetchAllActiveBookings(api, accessToken: token),
        _fetchAllActiveTrips(api, accessToken: token),
        _fetchAllActiveJobRequestMaps(api, accessToken: token),
      ]);

      final bookings = responses[0];
      final trips = responses[1];
      final requests = responses[2];
      final tripByBooking = <String, Map<String, dynamic>>{};
      for (final trip in trips) {
        final map = _asStringMap(trip);
        final bookingId = _readString(map, const ['bookingId', 'booking_id']);
        if (bookingId.isNotEmpty) tripByBooking[bookingId] = map;
      }
      final requestByBooking = <String, Map<String, dynamic>>{};
      for (final request in requests) {
        final map = _asStringMap(request);
        final bookingId = _readString(map, const ['bookingId', 'booking_id']);
        if (bookingId.isNotEmpty) requestByBooking[bookingId] = map;
      }

      final jobs = <_ActiveBrokerJob>[];
      for (final booking in bookings) {
        final bookingMap = _asStringMap(booking);
        final id = _readString(bookingMap, const ['id', 'bookingId', 'uuid']);
        if (id.isEmpty) continue;
        final trip = tripByBooking[id] ?? const <String, dynamic>{};
        final request = requestByBooking[id] ?? const <String, dynamic>{};
        final tripId = _readString(trip, const ['id', 'tripId', 'trip_id']);
        _ActiveIncident? incident;
        if (tripId.isNotEmpty) {
          try {
            final incidentResponse = await api.getTripIncidents(
              accessToken: token,
              tripId: tripId,
            );
            final incidents = _extractList(incidentResponse, const [
              'incidents',
            ]);
            for (final item in incidents) {
              final parsed = _ActiveIncident.fromJson(_asStringMap(item));
              if (parsed.status.toLowerCase() != 'resolved') {
                incident = parsed;
                break;
              }
            }
          } catch (_) {
            incident = null;
          }
        }
        jobs.add(
          _ActiveBrokerJob.fromJson(
            booking: bookingMap,
            trip: trip,
            request: request,
            incident: incident,
          ),
        );
      }
      return jobs;
    });

Future<List<Map<String, dynamic>>> _fetchAllActiveBookings(
  SskApiClient api, {
  required String accessToken,
}) {
  return _fetchPagedActiveMaps(
    itemKeys: const ['bookings'],
    fetchPage: (page, limit) => api.getBookings(
      accessToken: accessToken,
      status: 'confirmed,en_route_pickup,picked_up,in_transit',
      page: page,
      limit: limit,
    ),
  );
}

Future<List<Map<String, dynamic>>> _fetchAllActiveTrips(
  SskApiClient api, {
  required String accessToken,
}) {
  return _fetchPagedActiveMaps(
    itemKeys: const ['trips'],
    fetchPage: (page, limit) =>
        api.getTrips(accessToken: accessToken, page: page, limit: limit),
  );
}

Future<List<Map<String, dynamic>>> _fetchAllActiveJobRequestMaps(
  SskApiClient api, {
  required String accessToken,
}) {
  return _fetchPagedActiveMaps(
    itemKeys: const ['requests'],
    fetchPage: (page, limit) =>
        api.getJobRequests(accessToken: accessToken, page: page, limit: limit),
  );
}

Future<List<Map<String, dynamic>>> _fetchPagedActiveMaps({
  required List<String> itemKeys,
  required Future<Map<String, dynamic>> Function(int page, int limit) fetchPage,
}) async {
  final items = <Map<String, dynamic>>[];
  final seenKeys = <String>{};

  for (var page = 1; page <= _activeJobsFetchMaxPages; page++) {
    final response = await fetchPage(page, _activeJobsFetchPageLimit);
    final pageItems = _extractList(response, itemKeys)
        .map(_asStringMap)
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    var addedThisPage = 0;
    for (final item in pageItems) {
      final key = _activeItemKey(item);
      if (key.isNotEmpty && !seenKeys.add(key)) {
        continue;
      }
      items.add(item);
      addedThisPage += 1;
    }

    if (page > 1 && addedThisPage == 0) {
      break;
    }

    if (!_hasMoreActivePages(
      response,
      page: page,
      pageItemCount: pageItems.length,
      accumulatedItemCount: items.length,
      limit: _activeJobsFetchPageLimit,
    )) {
      break;
    }
  }

  return items;
}

class BrokerActiveJobsScreen extends ConsumerStatefulWidget {
  const BrokerActiveJobsScreen({super.key});

  @override
  ConsumerState<BrokerActiveJobsScreen> createState() =>
      _BrokerActiveJobsScreenState();
}

class _BrokerActiveJobsScreenState
    extends ConsumerState<BrokerActiveJobsScreen> {
  Future<void> _refresh() async {
    ref.invalidate(_brokerActiveJobsProvider);
    ref.invalidate(brokerActiveJobsCountProvider);
    await ref.read(_brokerActiveJobsProvider.future);
  }

  @override
  Widget build(BuildContext context) {
    final jobsAsync = ref.watch(_brokerActiveJobsProvider);
    final driversAsync = ref.watch(
      brokerDriversApiProvider((status: null, page: 1, limit: 100)),
    );
    final bottomPadding = _activeJobsBottomNavClearance;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(20, 14, 20, bottomPadding),
            children: [
              _ActiveJobsHeader(total: jobsAsync.valueOrNull?.length ?? 0),
              const SizedBox(height: 18),
              jobsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ActiveEmptyState(
                  title: 'Could not load active jobs',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
                data: (jobs) {
                  if (jobs.isEmpty) {
                    return const _ActiveEmptyState(
                      title: 'No active jobs found',
                      subtitle:
                          'Assigned and in-transit jobs will appear here.',
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final useGrid = constraints.maxWidth >= 760;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final job in jobs)
                            SizedBox(
                              width: useGrid
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _ActiveJobCard(
                                job: job,
                                onTrack: () => context.push(
                                  '/broker/tracking/details',
                                  extra: job.toShipment(),
                                ),
                                onChat: () => context.push(
                                  '/broker/chats/${job.bookingId}',
                                ),
                                onDispute: () => _showDisputeSheet(job),
                                onReassign: () => _showReassignSheet(
                                  job,
                                  driversAsync.valueOrNull ??
                                      const <BrokerDriver>[],
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
      ),
    );
  }

  Future<void> _showDisputeSheet(_ActiveBrokerJob job) async {
    const issueTypes = [
      ('damaged_goods', 'Damaged Goods'),
      ('payment_delay', 'Payment Delay'),
      ('cancellation_fee', 'Cancellation Fee'),
      ('route_dispute', 'Route Dispute'),
      ('late_delivery', 'Late Delivery'),
      ('fuel_surcharge', 'Fuel Surcharge'),
      ('wrong_items', 'Wrong Items'),
      ('weight_discrepancy', 'Weight Discrepancy'),
    ];
    String issueType = issueTypes.first.$1;
    final descriptionController = TextEditingController();
    var submitting = false;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return _ActiveSheet(
                title: 'Report a Problem',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${job.pickup} to ${job.drop}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: issueType,
                      isExpanded: true,
                      isDense: true,
                      itemHeight: 56,
                      dropdownColor: Colors.white,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      icon: const Icon(
                        AppIcons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      decoration: brokerFieldDecoration(
                        labelText: 'Issue Type',
                        prefixIcon: AppIcons.report_problem_rounded,
                      ),
                      items: [
                        for (final issue in issueTypes)
                          DropdownMenuItem(
                            value: issue.$1,
                            child: Text(issue.$2),
                          ),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => issueType = value ?? issueType),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      maxLength: 2000,
                      cursorColor: AppColors.brand,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _sheetInputDecoration(
                        'Description',
                      ).copyWith(hintText: 'Describe what went wrong...'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(sheetContext).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: submitting
                                ? null
                                : () async {
                                    final description = descriptionController
                                        .text
                                        .trim();
                                    if (description.isEmpty) return;
                                    setSheetState(() => submitting = true);
                                    final ok = await _submitDispute(
                                      job,
                                      issueType,
                                      description,
                                    );
                                    if (!sheetContext.mounted) return;
                                    if (ok) Navigator.of(sheetContext).pop();
                                    setSheetState(() => submitting = false);
                                  },
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.dangerIcon,
                            ),
                            child: Text(
                              submitting ? 'Submitting...' : 'Submit',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).whenComplete(descriptionController.dispose);
  }

  Future<bool> _submitDispute(
    _ActiveBrokerJob job,
    String issueType,
    String description,
  ) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return false;
    try {
      await ref
          .read(apiClientProvider)
          .raiseBookingDispute(
            accessToken: session.tokens.accessToken,
            bookingId: job.bookingId,
            issueType: issueType,
            description: description,
          );
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dispute raised - our team will review it shortly.'),
          backgroundColor: AppColors.brand,
        ),
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      return false;
    }
  }

  Future<void> _showReassignSheet(
    _ActiveBrokerJob job,
    List<BrokerDriver> drivers,
  ) async {
    String? driverId;
    final reasonController = TextEditingController();
    var submitting = false;
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620),
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              return _ActiveSheet(
                title: 'Reassign Driver',
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MiniInfoTile(
                      icon: AppIcons.local_shipping_rounded,
                      label: 'Currently Assigned',
                      value: job.driverName.isEmpty
                          ? 'Not Assigned'
                          : job.driverName,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: driverId,
                      isExpanded: true,
                      isDense: true,
                      itemHeight: 56,
                      dropdownColor: Colors.white,
                      menuMaxHeight: 320,
                      borderRadius: BorderRadius.circular(AppRadius.field),
                      icon: const Icon(
                        AppIcons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                      ),
                      decoration: brokerFieldDecoration(
                        labelText: 'Reassign to',
                        prefixIcon: AppIcons.person_rounded,
                      ),
                      items: [
                        for (final driver in drivers)
                          DropdownMenuItem(
                            value: driver.id,
                            enabled: driver.status == BrokerDriverStatus.idle,
                            child: Text(
                              [
                                driver.name.isEmpty ? driver.id : driver.name,
                                driverStatusLabel(driver.status),
                              ].join(' - '),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setSheetState(() => driverId = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      minLines: 2,
                      maxLines: 3,
                      cursorColor: AppColors.brand,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _sheetInputDecoration(
                        'Reason',
                      ).copyWith(hintText: 'Optional reason for reassignment'),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: submitting || driverId == null
                            ? null
                            : () async {
                                setSheetState(() => submitting = true);
                                final ok = await _reassignDriver(
                                  job,
                                  driverId!,
                                  reasonController.text.trim(),
                                );
                                if (!sheetContext.mounted) return;
                                if (ok) Navigator.of(sheetContext).pop();
                                setSheetState(() => submitting = false);
                              },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                        ),
                        child: Text(
                          submitting ? 'Reassigning...' : 'Reassign Driver',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).whenComplete(reasonController.dispose);
  }

  Future<bool> _reassignDriver(
    _ActiveBrokerJob job,
    String driverId,
    String reason,
  ) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return false;
    if (job.jobRequestId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Can't find the original job request for this booking.",
          ),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      return false;
    }
    try {
      await ref
          .read(apiClientProvider)
          .assignDriverToJob(
            accessToken: session.tokens.accessToken,
            id: job.jobRequestId,
            driverId: driverId,
            truckId: job.truckId,
            reason: reason,
          );
      ref.invalidate(_brokerActiveJobsProvider);
      ref.invalidate(brokerActiveJobsCountProvider);
      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver reassigned.'),
          backgroundColor: AppColors.brand,
        ),
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      return false;
    }
  }
}

class _ActiveJobsHeader extends StatelessWidget {
  const _ActiveJobsHeader({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Active Jobs',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$total jobs currently in progress',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
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

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({
    required this.job,
    required this.onTrack,
    required this.onChat,
    required this.onDispute,
    required this.onReassign,
  });

  final _ActiveBrokerJob job;
  final VoidCallback onTrack;
  final VoidCallback onChat;
  final VoidCallback onDispute;
  final VoidCallback onReassign;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(job.statusKey);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 7,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '#${job.bookingId.toUpperCase()}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    _StatusPill(label: job.statusLabel, color: statusColor),
                    if (job.isExpress) const ExpressBadge(compact: true),
                    if (job.incident != null)
                      _StatusPill(
                        label: job.incident!.reason == 'breakdown'
                            ? 'Breakdown Reported'
                            : 'Issue Reported',
                        color: AppColors.dangerIcon,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatCurrency(job.amount),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_lead(job.pickup)} to ${_lead(job.drop)}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            job.distance <= 0
                ? 'Route distance pending'
                : '${job.distance} km route',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _RouteLine(
            label: 'Pickup',
            value: job.pickup,
            color: AppColors.brandBright,
          ),
          for (final stop in job.stops.where((stop) => stop.isExtraStop)) ...[
            const SizedBox(height: 10),
            _RouteLine(
              label: stop.label,
              value: stop.location.isEmpty ? '-' : stop.location,
              color: stop.isDone
                  ? AppColors.brandBright
                  : const Color(0xFFF59E0B),
              done: stop.isDone,
            ),
          ],
          const SizedBox(height: 10),
          _RouteLine(
            label: 'Drop',
            value: job.drop,
            color: AppColors.dangerIcon,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniInfoTile(
                  icon: AppIcons.local_shipping_rounded,
                  label: 'Truck',
                  value: job.truckReg.isEmpty ? 'Not Assigned' : job.truckReg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniInfoTile(
                  icon: AppIcons.person_rounded,
                  label: 'Driver',
                  value: job.driverName.isEmpty
                      ? 'Not Assigned'
                      : job.driverName,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'TRIP PROGRESS',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          _ProgressDots(status: job.statusKey),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _TextAction(
                      icon: AppIcons.flag_rounded,
                      label: 'Report a Problem',
                      color: AppColors.dangerIcon,
                      onTap: onDispute,
                    ),
                    _TextAction(
                      icon: AppIcons.navigation_rounded,
                      label: 'Track Live',
                      color: AppColors.brand,
                      onTap: onTrack,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    _TextAction(
                      icon: AppIcons.repeat_rounded,
                      label: 'Reassign Driver',
                      color: AppColors.brand,
                      onTap: onReassign,
                    ),
                    _TextAction(
                      icon: AppIcons.chat_bubble_outline_rounded,
                      label: 'Chat',
                      color: AppColors.brand,
                      onTap: onChat,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSheet extends StatelessWidget {
  const _ActiveSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _ActiveEmptyState extends StatelessWidget {
  const _ActiveEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(
            AppIcons.assignment_turned_in_rounded,
            color: AppColors.textTertiary,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoTile extends StatelessWidget {
  const _MiniInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(AppRadius.field),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.brand),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
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

class _RouteLine extends StatelessWidget {
  const _RouteLine({
    required this.label,
    required this.value,
    required this.color,
    this.done = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          done ? AppIcons.check_circle_rounded : AppIcons.location_on_outlined,
          size: 15,
          color: color,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textPrimary,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    const steps = [
      ('assigned', 'Assigned'),
      ('en_route_pickup', 'En Route'),
      ('picked_up', 'Picked Up'),
      ('in_transit', 'In Transit'),
      ('delivered', 'Delivered'),
    ];
    final index = steps.indexWhere((step) => step.$1 == status);
    final activeIndex = index < 0 ? 0 : index;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: i <= activeIndex ? AppColors.brand : AppColors.line,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  steps[i].$2,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: i <= activeIndex
                        ? AppColors.brand
                        : AppColors.textTertiary,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (i != steps.length - 1)
            Container(
              height: 2,
              width: 12,
              color: i < activeIndex ? AppColors.brand : AppColors.line,
            ),
        ],
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveBrokerJob {
  const _ActiveBrokerJob({
    required this.bookingId,
    required this.tripId,
    required this.jobRequestId,
    required this.statusKey,
    required this.statusLabel,
    required this.pickup,
    required this.drop,
    required this.distance,
    required this.amount,
    required this.truckId,
    required this.truckReg,
    required this.driverName,
    required this.driverPhone,
    required this.weight,
    required this.isExpress,
    required this.incident,
    required this.stops,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.liveLat,
    this.liveLng,
  });

  factory _ActiveBrokerJob.fromJson({
    required Map<String, dynamic> booking,
    required Map<String, dynamic> trip,
    required Map<String, dynamic> request,
    required _ActiveIncident? incident,
  }) {
    final route = _asStringMap(booking['route']);
    final driver = _asStringMap(booking['driver']);
    final truck = _asStringMap(booking['truck']);
    final statusKey = _normalizeStatus(
      _firstNonEmpty([
        _readString(trip, const ['status', 'trip_status']),
        _readString(booking, const ['status', 'booking_status']),
      ]),
    );
    return _ActiveBrokerJob(
      bookingId: _readString(booking, const ['id', 'bookingId', 'uuid']),
      tripId: _readString(trip, const ['id', 'tripId', 'trip_id']),
      jobRequestId: _readString(request, const [
        'id',
        'requestId',
        'request_id',
      ]),
      statusKey: statusKey.isEmpty ? 'assigned' : statusKey,
      statusLabel: _statusLabel(statusKey.isEmpty ? 'assigned' : statusKey),
      pickup: _firstNonEmpty([
        _readLocation(booking, const [
          'pickup',
          'pickupLocation',
          'pickup_location',
          'from',
        ]),
        _readLocation(route, const ['pickup', 'origin', 'from']),
      ], fallback: 'Pickup location not available'),
      drop: _firstNonEmpty([
        _readLocation(booking, const [
          'drop',
          'dropoff',
          'dropLocation',
          'drop_location',
          'to',
        ]),
        _readLocation(route, const ['drop', 'destination', 'to']),
      ], fallback: 'Drop location not available'),
      distance:
          _readDouble(booking, const ['distance', 'route_distance']) ??
          _readDouble(route, const ['distance']) ??
          0,
      amount:
          _readDouble(booking, const [
            'amount',
            'fare',
            'price',
            'total_amount',
          ]) ??
          0,
      truckId: _firstNonEmpty([
        _readString(booking, const ['truckId', 'truck_id']),
        _readString(trip, const ['truckId', 'truck_id']),
        _readString(truck, const ['id', 'truck_id']),
      ]),
      truckReg: _firstNonEmpty([
        _readString(booking, const ['truckReg', 'truck_reg', 'truckNumber']),
        _readString(truck, const ['registration', 'plate_number', 'plate']),
      ]),
      driverName: _firstNonEmpty([
        _readString(booking, const ['driverName', 'driver_name']),
        _readString(driver, const ['name', 'full_name', 'display_name']),
      ]),
      driverPhone: _firstNonEmpty([
        _readString(booking, const ['driverPhone', 'driver_phone']),
        _readString(driver, const ['phone', 'mobile']),
      ]),
      weight: _readString(booking, const [
        'weight',
        'load_weight',
        'cargo_weight',
      ]),
      isExpress: _readBool(booking, const ['isExpress', 'is_express']),
      incident: incident,
      stops: tripRouteStopsFromSource({...booking, 'trip': trip}),
      pickupLat: _readDouble(booking, const ['pickupLat', 'pickup_lat']),
      pickupLng: _readDouble(booking, const ['pickupLng', 'pickup_lng']),
      dropLat: _readDouble(booking, const ['dropLat', 'drop_lat']),
      dropLng: _readDouble(booking, const ['dropLng', 'drop_lng']),
      liveLat: _readDouble(trip, const ['currentLat', 'current_lat', 'lat']),
      liveLng: _readDouble(trip, const ['currentLng', 'current_lng', 'lng']),
    );
  }

  final String bookingId;
  final String tripId;
  final String jobRequestId;
  final String statusKey;
  final String statusLabel;
  final String pickup;
  final String drop;
  final double distance;
  final double amount;
  final String truckId;
  final String truckReg;
  final String driverName;
  final String driverPhone;
  final String weight;
  final bool isExpress;
  final _ActiveIncident? incident;
  final List<TripRouteStop> stops;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? liveLat;
  final double? liveLng;

  TrackingDemoShipment toShipment() {
    return TrackingDemoShipment(
      packageName: 'Active job',
      trackingId: tripId.isEmpty ? bookingId : tripId,
      fromLocation: pickup,
      toLocation: drop,
      status: statusLabel,
      customerName: driverName.isEmpty ? 'Driver pending' : driverName,
      weight: weight.isEmpty ? 'Load details pending' : weight,
      timeline: _timelineFor(statusKey),
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      dropLat: dropLat,
      dropLng: dropLng,
      liveLat: liveLat,
      liveLng: liveLng,
      bookingId: bookingId,
      tripId: tripId,
      bookingStatus: statusKey,
      assignedDriverName: driverName,
      assignedDriverPhone: driverPhone,
      assignedTruckName: truckReg,
      isExpress: isExpress,
      amount: amount,
      stops: stops,
    );
  }
}

class _ActiveIncident {
  const _ActiveIncident({
    required this.id,
    required this.reason,
    required this.status,
  });

  factory _ActiveIncident.fromJson(Map<String, dynamic> json) {
    return _ActiveIncident(
      id: _readString(json, const ['id', 'incidentId', 'incident_id']),
      reason: _readString(json, const ['reason', 'type']),
      status: _readString(json, const ['status']),
    );
  }

  final String id;
  final String reason;
  final String status;
}

InputDecoration _sheetInputDecoration(String label) {
  return InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    hintStyle: const TextStyle(color: AppColors.textTertiary),
    filled: true,
    fillColor: AppColors.fillSubtle,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.field),
      borderSide: const BorderSide(color: AppColors.line),
    ),
  );
}

List<dynamic> _extractList(Map<String, dynamic> root, List<String> keys) {
  for (final key in keys) {
    final value = root[key];
    if (value is List) return value;
  }
  final data = _asStringMap(root['data']);
  for (final key in [...keys, 'items', 'results', 'rows', 'data']) {
    final value = data[key];
    if (value is List) return value;
  }
  return const [];
}

bool _hasMoreActivePages(
  Map<String, dynamic> response, {
  required int page,
  required int pageItemCount,
  required int accumulatedItemCount,
  required int limit,
}) {
  if (pageItemCount <= 0) {
    return false;
  }

  final totalPages = _readPaginationInt(response, const [
    'totalPages',
    'total_pages',
    'pages',
    'pageCount',
    'page_count',
  ]);
  if (totalPages != null) {
    return page < totalPages;
  }

  final totalItems = _readPaginationInt(response, const [
    'total',
    'totalItems',
    'total_items',
    'totalCount',
    'total_count',
  ]);
  if (totalItems != null && totalItems > 0) {
    return accumulatedItemCount < totalItems;
  }

  return pageItemCount >= limit;
}

int? _readPaginationInt(Map<String, dynamic> response, List<String> keys) {
  final data = _asStringMap(response['data']);
  final meta = _asStringMap(response['meta']);
  final pagination = _asStringMap(response['pagination']);
  final dataMeta = _asStringMap(data['meta']);
  final dataPagination = _asStringMap(data['pagination']);

  return _readInt(response, keys) ??
      _readInt(data, keys) ??
      _readInt(meta, keys) ??
      _readInt(pagination, keys) ??
      _readInt(dataMeta, keys) ??
      _readInt(dataPagination, keys);
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString().trim() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

String _activeItemKey(Map<String, dynamic> item) {
  return _firstNonEmpty([
    _readString(item, const ['id', 'uuid']),
    _readString(item, const ['bookingId', 'booking_id']),
    _readString(item, const ['requestId', 'request_id', 'jobRequestId']),
  ]);
}

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

String _readLocation(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) {
      final map = _asStringMap(value);
      final nested = _firstNonEmpty([
        _readString(map, const [
          'formattedAddress',
          'formatted_address',
          'address',
          'location',
          'name',
          'label',
          'city',
        ]),
      ]);
      if (nested.isNotEmpty) return nested;
    }
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

String _firstNonEmpty(List<String> values, {String fallback = ''}) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return fallback;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(
      value?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '',
    );
    if (parsed != null) return parsed;
  }
  return null;
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value?.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
  }
  return false;
}

String _normalizeStatus(String status) {
  return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _statusLabel(String status) {
  return status
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

Color _statusColor(String status) {
  // Matches the app-wide convention in client_delivery_screen._statusColor:
  // completed/delivered -> green, cancelled -> red,
  // confirmed/assigned/in-progress -> info blue, pending -> amber.
  return switch (status) {
    'delivered' || 'completed' => AppColors.brand,
    'cancelled' || 'canceled' => AppColors.dangerIcon,
    'confirmed' ||
    'assigned' ||
    'en_route_pickup' ||
    'in_transit' ||
    'picked_up' => AppColors.accentBlue,
    'pending' => const Color(0xFFD97706),
    _ => AppColors.textSecondary,
  };
}

String _formatCurrency(double amount) {
  if (amount <= 0) return '₹0';
  final fixed = amount.round().toString();
  if (fixed.length <= 3) return '₹$fixed';
  final suffix = fixed.substring(fixed.length - 3);
  var prefix = fixed.substring(0, fixed.length - 3);
  final groups = <String>[];
  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }
  if (prefix.isNotEmpty) groups.insert(0, prefix);
  return '₹${groups.join(',')},$suffix';
}

String _lead(String value) {
  final index = value.indexOf(',');
  if (index <= 0) return value;
  return value.substring(0, index).trim();
}

List<TrackingTimelineStep> _timelineFor(String status) {
  const order = [
    'assigned',
    'en_route_pickup',
    'picked_up',
    'in_transit',
    'delivered',
  ];
  final activeIndex = order.indexOf(status);
  final index = activeIndex < 0 ? 0 : activeIndex;
  return [
    TrackingTimelineStep(
      title: 'Assigned',
      subtitle: 'Driver assigned',
      completed: index >= 0,
    ),
    TrackingTimelineStep(
      title: 'En Route Pickup',
      subtitle: 'Driver heading to pickup',
      completed: index >= 1,
    ),
    TrackingTimelineStep(
      title: 'Picked Up',
      subtitle: 'Shipment picked up',
      completed: index >= 2,
    ),
    TrackingTimelineStep(
      title: 'In Transit',
      subtitle: 'Shipment on the road',
      completed: index >= 3,
    ),
    TrackingTimelineStep(
      title: 'Delivered',
      subtitle: 'Drop completed',
      completed: index >= 4,
    ),
  ];
}
