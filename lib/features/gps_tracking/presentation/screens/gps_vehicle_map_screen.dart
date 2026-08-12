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

class GpsVehicleMapScreen extends ConsumerStatefulWidget {
  const GpsVehicleMapScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<GpsVehicleMapScreen> createState() =>
      _GpsVehicleMapScreenState();
}

class _GpsVehicleMapScreenState extends ConsumerState<GpsVehicleMapScreen> {
  Timer? _pollingTimer;
  GoogleMapController? _mapController;
  BitmapDescriptor? _truckIcon;
  GpsTrackerDevice? _vehicle;
  bool _loading = true;
  String _error = '';

  LatLngBounds? get _bounds {
    final vehicle = _vehicle;
    if (vehicle == null) {
      return null;
    }
    return LatLngBounds(
      southwest: vehicle.position,
      northeast: vehicle.position,
    );
  }

  Future<void> _fitCamera() async {
    final controller = _mapController;
    final bounds = _bounds;
    if (controller == null || bounds == null) {
      return;
    }

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 80));
    } catch (_) {
      // The first bounds fit can fail if the map is still laying out.
    }
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

  @override
  void initState() {
    super.initState();
    _loadTruckIcon();
    _loadVehicle();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadVehicle(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vehicle = _vehicle;

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FD),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (vehicle == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F9FD),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Vehicle not found'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/gps/maps'),
                child: const Text('Back to Fleet'),
              ),
            ],
          ),
        ),
      );
    }

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
                      _HeaderButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => context.go('/gps/vehicles'),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => context.go('/gps/maps'),
                        child: Text(
                                'Fleet',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F1F44),
                                      letterSpacing: -0.7,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vehicle live map',
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
                        onPressed: () => context.go('/gps/maps'),
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text('All Fleet'),
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
                  child: _VehicleSummaryCard(vehicle: vehicle),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: vehicle.position,
                          zoom: 13,
                        ),
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        markers: {
                          Marker(
                            markerId: MarkerId(vehicle.deviceImei),
                            position: LatLng(vehicle.latitude!, vehicle.longitude!),
                            infoWindow: InfoWindow(
                              title: vehicle.displayName,
                              snippet: vehicle.locationLabel,
                            ),
                            icon:
                                _truckIcon ??
                                BitmapDescriptor.defaultMarkerWithHue(
                                  BitmapDescriptor.hueAzure,
                                ),
                            anchor: const Offset(0.5, 0.5),
                          ),
                        },
                        onMapCreated: (controller) {
                          _mapController = controller;
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => _fitCamera(),
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
      bottomNavigationBar: const GpsMapBottomNavBar(
        currentRoute: '/gps/maps/detail',
      ),
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

class _VehicleSummaryCard extends StatelessWidget {
  const _VehicleSummaryCard({required this.vehicle});

  final GpsDemoVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: vehicle.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(vehicle.icon, color: vehicle.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vehicle.plate,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF10213F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${vehicle.driver} · ${vehicle.model}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11.5,
                    color: const Color(0xFF63708A),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: vehicle.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              vehicle.status,
              style: TextStyle(
                color: vehicle.color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
