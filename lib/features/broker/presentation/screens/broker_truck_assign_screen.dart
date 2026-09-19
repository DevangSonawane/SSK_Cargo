import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerTruckAssignScreen extends ConsumerStatefulWidget {
  const BrokerTruckAssignScreen({super.key, required this.truckId});

  final String truckId;

  @override
  ConsumerState<BrokerTruckAssignScreen> createState() =>
      _BrokerTruckAssignScreenState();
}

class _BrokerTruckAssignScreenState
    extends ConsumerState<BrokerTruckAssignScreen> {
  String? _driverId;
  bool _submitting = false;

  Future<void> _assign() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final driverId = _driverId;
    if (session == null || driverId == null || _submitting) return;

    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .assignDriverToTruck(
            accessToken: session.tokens.accessToken,
            truckId: widget.truckId,
            driverId: driverId,
          );
      ref.invalidate(brokerTrucksProvider((status: null, page: 1, limit: 50)));
      ref.invalidate(brokerVehiclesProvider);
      if (!mounted) return;
      context.go('/broker/vehicles');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver assigned to truck.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
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
    BrokerVehicle? truck;
    for (final item in trucksAsync.valueOrNull ?? const <BrokerVehicle>[]) {
      if (item.id == widget.truckId) {
        truck = item;
        break;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: ListView(
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
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign Driver',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Truck',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          truck?.plateNumber.isNotEmpty == true
                              ? truck!.plateNumber
                              : widget.truckId,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  driversAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      style: const TextStyle(color: Color(0xFFE23A4B)),
                    ),
                    data: (drivers) {
                      final activeDrivers = drivers
                          .where(
                            (driver) =>
                                driver.status == BrokerDriverStatus.idle,
                          )
                          .toList();
                      if (activeDrivers.isEmpty) {
                        return const Text(
                          'No active drivers available right now.',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _driverId,
                        decoration: InputDecoration(
                          labelText: 'Driver',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                        items: [
                          for (final driver in activeDrivers)
                            DropdownMenuItem(
                              value: driver.id,
                              child: Text(driver.name),
                            ),
                        ],
                        onChanged: (value) => setState(() => _driverId = value),
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _submitting
                              ? null
                              : () => context.go('/broker/vehicles'),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _driverId == null || _submitting
                              ? null
                              : _assign,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2152D0),
                          ),
                          child: Text(
                            _submitting ? 'Assigning...' : 'Assign Driver',
                          ),
                        ),
                      ),
                    ],
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
