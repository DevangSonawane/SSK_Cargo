import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../widgets/broker_flow_widgets.dart';

final _brokerTruckLocationProvider = FutureProvider.autoDispose
    .family<_TruckLocationSnapshot, String>((ref, truckId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) throw StateError('No active session');

      final response = await ref
          .watch(apiClientProvider)
          .getTruckById(accessToken: session.tokens.accessToken, id: truckId);
      final data = _asMap(response['data']);
      final rawTruck = _asMap(data['truck'] ?? response['truck'] ?? data);
      if (rawTruck.isEmpty) throw const ApiException('Truck not found');
      return _TruckLocationSnapshot.fromJson(rawTruck);
    });

class BrokerTruckLocationScreen extends ConsumerStatefulWidget {
  const BrokerTruckLocationScreen({super.key, required this.truckId});

  final String truckId;

  @override
  ConsumerState<BrokerTruckLocationScreen> createState() =>
      _BrokerTruckLocationScreenState();
}

class _BrokerTruckLocationScreenState
    extends ConsumerState<BrokerTruckLocationScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      ref.invalidate(_brokerTruckLocationProvider(widget.truckId));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(_brokerTruckLocationProvider(widget.truckId));
    await ref.read(_brokerTruckLocationProvider(widget.truckId).future);
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync = ref.watch(
      _brokerTruckLocationProvider(widget.truckId),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              BrokerBackButton(onTap: () => context.go('/broker/vehicles')),
              const SizedBox(height: 14),
              snapshotAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 140),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _LocationEmptyState(
                  title: 'Could not load truck location',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
                data: (snapshot) => _TruckLocationContent(snapshot: snapshot),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TruckLocationContent extends StatelessWidget {
  const _TruckLocationContent({required this.snapshot});

  final _TruckLocationSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final hasLocation =
        snapshot.currentLat != null && snapshot.currentLng != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.brandFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  AppIcons.local_shipping_rounded,
                  color: AppColors.brand,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      snapshot.truck.plateNumber.isEmpty
                          ? snapshot.truck.label
                          : snapshot.truck.plateNumber,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      snapshot.truck.assignedDriverName.isEmpty
                          ? 'Unassigned'
                          : 'Driver: ${snapshot.truck.assignedDriverName}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              if (snapshot.lastLocationAt.isNotEmpty)
                Flexible(
                  child: Text(
                    'Updated ${snapshot.lastLocationAt}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          height: 440,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.line),
          ),
          child: hasLocation
              ? LiveLocationMapView(
                  latitude: snapshot.currentLat,
                  longitude: snapshot.currentLng,
                  label: snapshot.truck.plateNumber,
                  emptyTitle: 'Live location pending',
                  emptySubtitle: 'This truck has not reported a location yet.',
                )
              : const _LocationEmptyState(
                  title: 'Live location pending',
                  subtitle: 'This truck has not reported a location yet.',
                ),
        ),
      ],
    );
  }
}

class _LocationEmptyState extends StatelessWidget {
  const _LocationEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            AppIcons.location_off_outlined,
            color: AppColors.textTertiary,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
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

class _TruckLocationSnapshot {
  const _TruckLocationSnapshot({
    required this.truck,
    required this.currentLat,
    required this.currentLng,
    required this.lastLocationAt,
  });

  factory _TruckLocationSnapshot.fromJson(Map<String, dynamic> json) {
    return _TruckLocationSnapshot(
      truck: brokerVehicleFromJson(json),
      currentLat: _readDouble(json, const [
        'currentLat',
        'current_lat',
        'lat',
        'latitude',
      ]),
      currentLng: _readDouble(json, const [
        'currentLng',
        'current_lng',
        'lng',
        'longitude',
      ]),
      lastLocationAt: _readString(json, const [
        'lastLocationAt',
        'last_location_at',
        'updated_at',
      ]),
    );
  }

  final BrokerVehicle truck;
  final double? currentLat;
  final double? currentLng;
  final String lastLocationAt;
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
      final parsed = double.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}
