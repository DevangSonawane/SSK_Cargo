import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class _VehiclesHeader extends StatelessWidget {
  const _VehiclesHeader({this.controller, this.onSearchChanged});

  final TextEditingController? controller;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 14,
        20,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Vehicles',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your fleet and truck availability',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.field),
              border: Border.all(color: AppColors.line),
            ),
            child: TextField(
              controller: controller,
              onChanged: onSearchChanged,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
                prefixIcon: Icon(
                  AppIcons.search_rounded,
                  color: AppColors.textTertiary,
                ),
                hintText: 'Search vehicles, drivers or location',
                hintStyle: TextStyle(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BrokerVehiclesScreen extends ConsumerStatefulWidget {
  const BrokerVehiclesScreen({super.key});

  static const BrokerTrucksQuery _query = (status: null, page: 1, limit: 50);

  @override
  ConsumerState<BrokerVehiclesScreen> createState() =>
      _BrokerVehiclesScreenState();
}

class _BrokerVehiclesScreenState extends ConsumerState<BrokerVehiclesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _deleteTruck(BrokerVehicle vehicle) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove Truck'),
        content: Text('Remove ${vehicle.plateNumber} from your fleet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerIcon,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    try {
      await ref
          .read(apiClientProvider)
          .deleteTruck(accessToken: session.tokens.accessToken, id: vehicle.id);
      ref.invalidate(brokerTrucksProvider(BrokerVehiclesScreen._query));
      ref.invalidate(brokerVehiclesProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Truck removed.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    }
  }

  Future<void> _showTruckActions(BrokerVehicle vehicle) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        backgroundColor: Colors.transparent,
        child: _TruckActionDialog(
          vehicle: vehicle,
          onEdit: () {
            Navigator.of(dialogContext).pop();
            context.push('/broker/vehicles/add', extra: vehicle);
          },
          onAssign: () {
            Navigator.of(dialogContext).pop();
            context.push('/broker/vehicles/${vehicle.id}/assign');
          },
          onTrack: () {
            Navigator.of(dialogContext).pop();
            context.push('/broker/vehicles/${vehicle.id}/location');
          },
          onHistory: () {
            Navigator.of(dialogContext).pop();
            context.push('/broker/vehicles/${vehicle.id}/history');
          },
          onRemove: () async {
            Navigator.of(dialogContext).pop();
            await _deleteTruck(vehicle);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(
      brokerTrucksProvider(BrokerVehiclesScreen._query),
    );

    Future<void> refreshTrucks() async {
      final refreshed = ref.refresh(
        brokerTrucksProvider(BrokerVehiclesScreen._query).future,
      );
      await refreshed;
    }

    return RefreshIndicator(
      color: AppColors.brand,
      onRefresh: refreshTrucks,
      child: trucksAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            _VehiclesHeader(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                children: [
                  SizedBox(height: 122),
                  Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          children: [
            const _VehiclesHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Your fleet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          context.push('/broker/vehicles/add');
                        },
                        icon: const Icon(AppIcons.add),
                        label: const Text('Add truck'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          shape: const StadiumBorder(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FleetEmptyState(
                    icon: AppIcons.error_outline_rounded,
                    title: 'Could not load trucks',
                    subtitle: error.toString().replaceFirst('Exception: ', ''),
                    actionLabel: 'Try again',
                    onAction: refreshTrucks,
                  ),
                ],
              ),
            ),
          ],
        ),
        data: (vehicles) {
          final query = _searchController.text.trim().toLowerCase();
          final visibleVehicles = query.isEmpty
              ? vehicles
              : vehicles.where((vehicle) {
                  final searchable = [
                    vehicle.label,
                    vehicle.plateNumber,
                    vehicle.truckType,
                    vehicle.category,
                    vehicle.assignedDriverName,
                  ].join(' ').toLowerCase();
                  return searchable.contains(query);
                }).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            children: [
              _VehiclesHeader(
                controller: _searchController,
                onSearchChanged: (_) => setState(() {}),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Your fleet',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${visibleVehicles.length})',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: () {
                            context.push('/broker/vehicles/add');
                          },
                          icon: const Icon(AppIcons.add),
                          label: const Text('Add truck'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (visibleVehicles.isEmpty)
                      const _FleetEmptyState(
                        icon: AppIcons.local_shipping_outlined,
                        title: 'No matching vehicles',
                        subtitle: 'Try a different search or add a new truck.',
                      )
                    else
                      ...visibleVehicles.asMap().entries.expand(
                        (entry) => [
                          VehicleCard(
                            vehicle: entry.value,
                            onTap: () => _showTruckActions(entry.value),
                          ),
                          if (entry.key != visibleVehicles.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FleetEmptyState extends StatelessWidget {
  const _FleetEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.brandFill,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand, size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _TruckActionDialog extends StatelessWidget {
  const _TruckActionDialog({
    required this.vehicle,
    required this.onEdit,
    required this.onAssign,
    required this.onTrack,
    required this.onHistory,
    required this.onRemove,
  });

  final BrokerVehicle vehicle;
  final VoidCallback onEdit;
  final VoidCallback onAssign;
  final VoidCallback onTrack;
  final VoidCallback onHistory;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.float,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.brandFill,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  AppIcons.local_shipping_rounded,
                  color: AppColors.brand,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vehicle.plateNumber.isEmpty
                          ? vehicle.label
                          : vehicle.plateNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    _VehicleStatusPill(status: vehicle.status),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(AppIcons.close_rounded),
                style: IconButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.fillSubtle,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.line),
            ),
            child: Column(
              children: [
                _TruckSummaryRow('Type', _vehicleType(vehicle)),
                _TruckSummaryRow(
                  'Capacity',
                  vehicle.capacity.isEmpty ? '-' : vehicle.capacity,
                ),
                _TruckSummaryRow(
                  'Driver',
                  vehicle.assignedDriverName.isEmpty
                      ? 'Unassigned'
                      : vehicle.assignedDriverName,
                ),
                _TruckSummaryRow(
                  'Insurance',
                  vehicle.insuranceExpiry.isEmpty
                      ? '-'
                      : vehicle.insuranceExpiry,
                  danger: _isInsuranceExpiring(vehicle.insuranceExpiry),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            childAspectRatio: 0.9,
            children: [
              _TruckDialogAction(
                icon: AppIcons.edit_rounded,
                label: 'Edit',
                onTap: onEdit,
              ),
              _TruckDialogAction(
                icon: AppIcons.manage_accounts_rounded,
                label: 'Assign',
                onTap: onAssign,
              ),
              _TruckDialogAction(
                icon: AppIcons.location_on_rounded,
                label: 'Track',
                onTap: onTrack,
              ),
              _TruckDialogAction(
                icon: AppIcons.history_rounded,
                label: 'History',
                onTap: onHistory,
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRemove,
            icon: const Icon(AppIcons.delete_outline_rounded),
            label: const Text('Remove Truck'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.dangerIcon,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TruckDialogAction extends StatelessWidget {
  const _TruckDialogAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.brand, size: 20),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TruckSummaryRow extends StatelessWidget {
  const _TruckSummaryRow(this.label, this.value, {this.danger = false});

  final String label;
  final String value;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: danger
                    ? AppColors.dangerIcon
                    : AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStatusPill extends StatelessWidget {
  const _VehicleStatusPill({required this.status});

  final BrokerVehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = vehicleStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: vehicleStatusBackground(status),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        vehicleStatusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _vehicleType(BrokerVehicle vehicle) {
  final value = vehicle.category.isNotEmpty
      ? vehicle.category
      : vehicle.truckType.isNotEmpty
      ? vehicle.truckType
      : vehicle.label;
  return value.isEmpty ? '-' : value;
}

bool _isInsuranceExpiring(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return false;
  return date.difference(DateTime.now()).inDays < 60;
}
