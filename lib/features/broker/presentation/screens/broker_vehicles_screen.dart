import 'package:flutter/material.dart';
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
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        16,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B68C7), Color(0xFF147BD6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicles',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Manage your fleet at a glance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _VehicleHeaderIcon(
                icon: Icons.notifications_none_rounded,
                showBadge: true,
                onTap: () => context.push('/broker/notifications'),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => context.push('/broker/profile'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset('assets/user.png', fit: BoxFit.cover),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: controller,
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search vehicles, drivers or location',
              hintStyle: const TextStyle(
                color: Color(0xFF98A2B3),
                fontSize: 11,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Color(0xFF667085),
                size: 18,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleHeaderIcon extends StatelessWidget {
  const _VehicleHeaderIcon({
    required this.icon,
    required this.showBadge,
    required this.onTap,
  });

  final IconData icon;
  final bool showBadge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          if (showBadge)
            Positioned(
              right: -1,
              top: -1,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF0B68C7)),
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

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(brokerTrucksProvider(BrokerVehiclesScreen._query));

    Future<void> refreshTrucks() async {
      final refreshed = ref.refresh(
        brokerTrucksProvider(BrokerVehiclesScreen._query).future,
      );
      await refreshed;
    }

    return RefreshIndicator(
      color: const Color(0xFF1F88C9),
      onRefresh: refreshTrucks,
      child: trucksAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            _VehiclesHeader(),
            SizedBox(height: 140),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
            const _VehiclesHeader(),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  'Your fleet',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () {
                    context.push('/broker/vehicles/add');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add truck'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F88C9),
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
              icon: Icons.error_outline_rounded,
              title: 'Could not load trucks',
              subtitle: error.toString().replaceFirst('Exception: ', ''),
              actionLabel: 'Try again',
              onAction: refreshTrucks,
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              _VehiclesHeader(
                controller: _searchController,
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Your fleet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF101828),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${visibleVehicles.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      context.push('/broker/vehicles/add');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add truck'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F88C9),
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
                  icon: Icons.local_shipping_outlined,
                  title: 'No matching vehicles',
                  subtitle: 'Try a different search or add a new truck.',
                )
              else
                ...visibleVehicles.asMap().entries.expand(
                  (entry) => [
                    VehicleCard(
                      vehicle: entry.value,
                      onTap: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return SheetContainer(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  14,
                                  20,
                                  28,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 54,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE1E5EB),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      entry.value.label,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF101828),
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      entry.value.plateNumber,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF667085),
                                          ),
                                    ),
                                    const SizedBox(height: 18),
                                    OptionTile(
                                      title: 'Edit vehicle',
                                      subtitle:
                                          'Update vehicle info and assignment',
                                      icon: Icons.edit_rounded,
                                      selected: false,
                                      onTap: () {
                                        Navigator.of(context).pop();
                                        context.push(
                                          '/broker/vehicles/add',
                                          extra: entry.value,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 10),
                                    OptionTile(
                                      title: 'Remove vehicle',
                                      subtitle:
                                          'Archive this vehicle from the fleet',
                                      icon: Icons.delete_rounded,
                                      selected: false,
                                      onTap: () async {
                                        Navigator.of(context).pop();
                                        await _confirmDeleteTruck(
                                          context,
                                          ref,
                                          entry.value,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                    if (entry.key != visibleVehicles.length - 1)
                      const SizedBox(height: 12),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _confirmDeleteTruck(
  BuildContext context,
  WidgetRef ref,
  BrokerVehicle vehicle,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Remove truck?'),
        content: Text(
          'This will delete ${vehicle.plateNumber} from the fleet.',
        ),
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
      const SnackBar(content: Text('Please sign in again to delete a truck.')),
    );
    return;
  }

  try {
    await ref
        .read(apiClientProvider)
        .deleteTruck(accessToken: session.tokens.accessToken, id: vehicle.id);
    if (!context.mounted) return;
    ref.invalidate(brokerTrucksProvider((status: null, page: 1, limit: 50)));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Truck removed from fleet.')),
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
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8EF)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF667085), size: 30),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
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
