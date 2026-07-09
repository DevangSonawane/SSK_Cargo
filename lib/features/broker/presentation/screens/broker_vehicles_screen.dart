import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/broker_flow_widgets.dart';
import 'add_vehicle_screen.dart';

class BrokerVehiclesScreen extends ConsumerWidget {
  const BrokerVehiclesScreen({super.key});

  static const BrokerTrucksQuery _query = (status: null, page: 1, limit: 50);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trucksAsync = ref.watch(brokerTrucksProvider(_query));

    Future<void> refreshTrucks() async {
      final refreshed = ref.refresh(brokerTrucksProvider(_query).future);
      await refreshed;
    }

    return RefreshIndicator(
      color: const Color(0xFF1F88C9),
      onRefresh: refreshTrucks,
      child: trucksAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: const [
            SizedBox(height: 140),
            Center(child: CircularProgressIndicator()),
          ],
        ),
        error: (error, _) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          children: [
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
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add truck'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1F88C9),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
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
                    '(${vehicles.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: const Color(0xFF667085),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add truck'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F88C9),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: const StadiumBorder(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (vehicles.isEmpty)
                const _FleetEmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: 'No trucks yet',
                  subtitle: 'Add your first truck to start managing your fleet.',
                )
              else
                ...vehicles.asMap().entries.expand(
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
                                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                        const SizedBox(height: 18),
                                        Text(
                                          entry.value.label,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF101828),
                                              ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          entry.value.plateNumber,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: const Color(0xFF667085),
                                              ),
                                        ),
                                        const SizedBox(height: 18),
                                OptionTile(
                                  title: 'Edit vehicle',
                                  subtitle: 'Update vehicle info and assignment',
                                  icon: Icons.edit_rounded,
                                  selected: false,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AddVehicleScreen(
                                          existingTruck: entry.value,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 10),
                                OptionTile(
                                  title: 'Remove vehicle',
                                  subtitle: 'Archive this vehicle from the fleet',
                                  icon: Icons.delete_rounded,
                                  selected: false,
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Truck removal is not wired yet.'),
                                      ),
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
                        if (entry.key != vehicles.length - 1) const SizedBox(height: 12),
                      ],
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}
