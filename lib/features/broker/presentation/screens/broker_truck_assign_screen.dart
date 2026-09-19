import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
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
          backgroundColor: AppColors.brand,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.dangerIcon,
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
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
          children: [
            BrokerBackButton(onTap: () => context.go('/broker/vehicles')),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Assign Driver',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Truck',
                          style: TextStyle(
                            color: AppColors.textTertiary,
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
                            color: AppColors.textPrimary,
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
                      style: const TextStyle(color: AppColors.dangerIcon),
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
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }
                      return DropdownButtonFormField<String>(
                        initialValue: _driverId,
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
                          labelText: 'Driver',
                          prefixIcon: AppIcons.person_rounded,
                        ),
                        items: [
                          for (final driver in activeDrivers)
                            DropdownMenuItem(
                              value: driver.id,
                              child: Text(
                                driver.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
                                ),
                              ),
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
                            backgroundColor: AppColors.brand,
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
