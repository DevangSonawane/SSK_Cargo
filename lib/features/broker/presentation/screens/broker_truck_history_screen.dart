import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

final _brokerTruckHistoryProvider = FutureProvider.autoDispose
    .family<_TruckHistoryBundle, String>((ref, truckId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) throw StateError('No active session');
      final api = ref.watch(apiClientProvider);
      final responses = await Future.wait([
        api.getTruckById(accessToken: session.tokens.accessToken, id: truckId),
        api.getTrips(
          accessToken: session.tokens.accessToken,
          truckId: truckId,
          limit: 100,
        ),
      ]);
      final truckData = _asMap(responses[0]['data']);
      final rawTruck = _asMap(
        truckData['truck'] ?? responses[0]['truck'] ?? truckData,
      );
      final trips = _extractList(responses[1], const ['trips'])
          .whereType<Map>()
          .map((trip) => _TruckTrip.fromJson(_asMap(trip)))
          .toList();
      return _TruckHistoryBundle(
        truck: brokerVehicleFromJson(rawTruck),
        trips: trips,
      );
    });

class BrokerTruckHistoryScreen extends ConsumerStatefulWidget {
  const BrokerTruckHistoryScreen({super.key, required this.truckId});

  final String truckId;

  @override
  ConsumerState<BrokerTruckHistoryScreen> createState() =>
      _BrokerTruckHistoryScreenState();
}

class _BrokerTruckHistoryScreenState
    extends ConsumerState<BrokerTruckHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(_brokerTruckHistoryProvider(widget.truckId));
    await ref.read(_brokerTruckHistoryProvider(widget.truckId).future);
  }

  List<_TruckTrip> _filter(List<_TruckTrip> trips) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return trips;
    return trips.where((trip) {
      return [
        trip.id,
        trip.bookingId,
        trip.bookingNumber,
        trip.pickup,
        trip.drop,
        trip.driverName,
        trip.status,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(_brokerTruckHistoryProvider(widget.truckId));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2152D0),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/broker/vehicles'),
                  icon: const Icon(AppIcons.arrow_back_rounded, size: 18),
                  label: const Text('Back to Trucks'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              historyAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 140),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _HistoryEmptyState(
                  title: 'Could not load trip history',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
                data: (bundle) {
                  final trips = _filter(bundle.trips);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HistoryHeader(bundle: bundle),
                      const SizedBox(height: 14),
                      _HistorySearchField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 14),
                      if (trips.isEmpty)
                        _HistoryEmptyState(
                          title: bundle.trips.isEmpty
                              ? 'No trips yet'
                              : 'No trips match your search',
                          subtitle:
                              'Truck trips will appear here once jobs are assigned.',
                        )
                      else
                        for (final trip in trips) ...[
                          _TripHistoryCard(
                            trip: trip,
                            onTap: trip.bookingId.isEmpty
                                ? null
                                : () => context.push(
                                    '/broker/history/${trip.bookingId}',
                                  ),
                          ),
                          const SizedBox(height: 12),
                        ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.bundle});

  final _TruckHistoryBundle bundle;

  @override
  Widget build(BuildContext context) {
    final truck = bundle.truck;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              AppIcons.local_shipping_rounded,
              color: Color(0xFF2152D0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  truck.plateNumber.isEmpty ? truck.label : truck.plateNumber,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${truck.assignedDriverName} · ${bundle.trips.length} trip${bundle.trips.length == 1 ? '' : 's'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
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

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(AppIcons.search_rounded, color: Color(0xFF94A3B8)),
          hintText: 'Search by booking ID, route...',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TripHistoryCard extends StatelessWidget {
  const _TripHistoryCard({required this.trip, this.onTap});

  final _TruckTrip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      trip.bookingNumber.isEmpty
                          ? trip.bookingId.isEmpty
                                ? trip.id
                                : trip.bookingId
                          : trip.bookingNumber,
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _TripStatusPill(status: trip.status),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${trip.pickup.isEmpty ? '-' : trip.pickup} → ${trip.drop.isEmpty ? '-' : trip.drop}',
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _TripMetric(
                    icon: AppIcons.person_rounded,
                    label: trip.driverName.isEmpty
                        ? 'Driver pending'
                        : trip.driverName,
                  ),
                  _TripMetric(
                    icon: AppIcons.route_rounded,
                    label: trip.distance > 0
                        ? '${trip.distance.toStringAsFixed(trip.distance % 1 == 0 ? 0 : 1)} km'
                        : 'Distance pending',
                  ),
                  _TripMetric(
                    icon: AppIcons.payments_rounded,
                    label: _formatRupees(trip.earnings),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TripMetric extends StatelessWidget {
  const _TripMetric({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TripStatusPill extends StatelessWidget {
  const _TripStatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final key = status.trim().toLowerCase();
    final danger = key.contains('cancel');
    final success = key.contains('complete') || key.contains('deliver');
    final color = danger
        ? const Color(0xFFE23A4B)
        : success
        ? const Color(0xFF2FA56E)
        : const Color(0xFFB7791F);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'Pending' : status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(
            AppIcons.navigation_rounded,
            color: Color(0xFF94A3B8),
            size: 30,
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _TruckHistoryBundle {
  const _TruckHistoryBundle({required this.truck, required this.trips});

  final BrokerVehicle truck;
  final List<_TruckTrip> trips;
}

class _TruckTrip {
  const _TruckTrip({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.pickup,
    required this.drop,
    required this.driverName,
    required this.status,
    required this.distance,
    required this.earnings,
  });

  factory _TruckTrip.fromJson(Map<String, dynamic> json) {
    final booking = _asMap(json['booking']);
    final pickup = _asMap(json['pickup']);
    final drop = _asMap(json['drop']);
    return _TruckTrip(
      id: _readString(json, const ['id', 'trip_id']),
      bookingId: _firstNonEmpty([
        _readString(json, const ['bookingId', 'booking_id']),
        _readString(booking, const ['id']),
      ]),
      bookingNumber: _firstNonEmpty([
        _readString(json, const ['bookingNumber', 'booking_number']),
        _readString(booking, const ['bookingNumber', 'booking_number']),
      ]),
      pickup: _firstNonEmpty([
        _readString(json, const ['pickup', 'pickup_location']),
        _readString(pickup, const ['location', 'address']),
        _readString(booking, const ['pickupLocation', 'pickup_location']),
      ]),
      drop: _firstNonEmpty([
        _readString(json, const ['drop', 'drop_location']),
        _readString(drop, const ['location', 'address']),
        _readString(booking, const ['dropoffLocation', 'drop_location']),
      ]),
      driverName: _firstNonEmpty([
        _readString(json, const ['driverName', 'driver_name']),
        _readString(_asMap(json['driver']), const ['name']),
      ]),
      status: _readString(json, const ['status']),
      distance: _readDouble(json, const ['distance', 'distance_km']) ?? 0,
      earnings: _readDouble(json, const ['earnings', 'amount', 'fare']) ?? 0,
    );
  }

  final String id;
  final String bookingId;
  final String bookingNumber;
  final String pickup;
  final String drop;
  final String driverName;
  final String status;
  final double distance;
  final double earnings;
}

List<dynamic> _extractList(Map<String, dynamic> json, List<String> keys) {
  final data = _asMap(json['data']);
  for (final source in [data, json]) {
    for (final key in keys) {
      final value = source[key];
      if (value is List) return value;
    }
  }
  return const [];
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString().trim();
    }
  }
  return '';
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    if (value is String) {
      final parsed = double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), ''));
      if (parsed != null) return parsed;
    }
  }
  return null;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String _formatRupees(double value) {
  if (value <= 0) return 'Earnings pending';
  final fixed = value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
  return 'Rs $fixed';
}
