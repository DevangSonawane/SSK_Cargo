import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/truck_marker_icon.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/gps_tracking_models.dart';
import '../../data/gps_tracking_repository.dart';
import '../widgets/gps_map_bottom_nav_bar.dart';
import '../widgets/gps_sidebar_drawer.dart';

class GpsFleetMapScreen extends ConsumerStatefulWidget {
  const GpsFleetMapScreen({super.key});

  @override
  ConsumerState<GpsFleetMapScreen> createState() => _GpsFleetMapScreenState();
}

class _GpsFleetMapScreenState extends ConsumerState<GpsFleetMapScreen> {
  Timer? _pollingTimer;
  GoogleMapController? _mapController;
  BitmapDescriptor? _truckIcon;
  List<GpsTrackerDevice> _devices = [];
  bool _loading = true;
  String _error = '';

  List<LatLng> get _points => _devices
      .where((device) => device.hasLocation)
      .map((device) => LatLng(device.latitude!, device.longitude!))
      .toList();

  LatLng get _initialCenter =>
      _points.isNotEmpty ? _points.first : const LatLng(19.0760, 72.8777);

  LatLngBounds? get _bounds {
    if (_points.isEmpty) {
      return null;
    }
    if (_points.length == 1) {
      final point = _points.first;
      return LatLngBounds(southwest: point, northeast: point);
    }

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;
    for (final point in _points) {
      minLat = minLat == null
          ? point.latitude
          : minLat < point.latitude
          ? minLat
          : point.latitude;
      maxLat = maxLat == null
          ? point.latitude
          : maxLat > point.latitude
          ? maxLat
          : point.latitude;
      minLng = minLng == null
          ? point.longitude
          : minLng < point.longitude
          ? minLng
          : point.longitude;
      maxLng = maxLng == null
          ? point.longitude
          : maxLng > point.longitude
          ? maxLng
          : point.longitude;
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Set<Marker> get _markers {
    return _devices.where((device) => device.hasLocation).map((device) {
      return Marker(
        markerId: MarkerId(device.deviceImei),
        position: LatLng(device.latitude!, device.longitude!),
        infoWindow: InfoWindow(
          title: device.displayName,
          snippet: device.locationLabel,
        ),
        icon:
            _truckIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        anchor: const Offset(0.5, 0.5),
        onTap: () => context.go('/gps/maps/${Uri.encodeComponent(device.deviceImei)}'),
      );
    }).toSet();
  }

  @override
  void initState() {
    super.initState();
    _loadTruckIcon();
    _loadDevices();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadDevices(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTruckIcon() async {
    try {
      final icon = await loadTruckMarkerIcon();
      if (!mounted) {
        return;
      }
      setState(() {
        _truckIcon = icon;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _truckIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
      });
    }
  }

  Future<void> _loadDevices({bool silent = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = [];
        _error = 'Please sign in again to view live fleet tracking.';
        _loading = false;
      });
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    try {
      final devices = await ref.read(gpsTrackingRepositoryProvider).fetchDevices(
            accessToken: session.tokens.accessToken,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
        _error = '';
        _loading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _fitBounds() async {
    final controller = _mapController;
    final bounds = _bounds;
    if (controller == null || bounds == null) {
      return;
    }

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 48));
    } catch (_) {
      // The map can briefly reject bounds fitting during the first render.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      drawer: const GpsSidebarDrawer(currentRoute: '/gps/maps'),
      body: Stack(
        children: [
          const _Backdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                  child: Row(
                    children: [
                      Builder(
                        builder: (drawerContext) {
                          return _HeaderButton(
                            icon: Icons.menu_rounded,
                            onTap: () =>
                                Scaffold.of(drawerContext).openDrawer(),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Fleet',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F1F44),
                                    letterSpacing: -0.7,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'All vehicles live map',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFF63708A),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () => context.go('/gps/vehicles'),
                        icon: const Icon(
                          Icons.local_shipping_rounded,
                          size: 18,
                        ),
                        label: const Text('Vehicles'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2D6EF2),
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _FleetSummaryCard(
                    count: _devices.length,
                    onlineCount: _devices
                        .where((device) =>
                            device.statusLabel.toLowerCase().contains('online'))
                        .length,
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 10),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: LinearProgressIndicator(minHeight: 2),
                  ),
                ],
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3C0C0)),
                      ),
                      child: Text(
                        _error,
                        style: const TextStyle(
                          color: Color(0xFFB3261E),
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _initialCenter,
                          zoom: 11,
                        ),
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _fitBounds(),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const GpsMapBottomNavBar(currentRoute: '/gps/maps'),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFEFF), Color(0xFFF4F7FC)],
        ),
      ),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(icon, size: 25, color: const Color(0xFF182B4E)),
        ),
      ),
    );
  }
}

class _FleetSummaryCard extends StatelessWidget {
  const _FleetSummaryCard({required this.count, required this.onlineCount});

  final int count;
  final int onlineCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6EF2).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.map_rounded, color: Color(0xFF2D6EF2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live fleet tracking',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10213F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count vehicles visible on the map · $onlineCount online',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF63708A),
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
