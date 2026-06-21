import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/broker_flow_widgets.dart';
import 'add_vehicle_screen.dart';

class BrokerVehiclesScreen extends ConsumerWidget {
  const BrokerVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(brokerVehiclesProvider);

    return ListView(
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
              label: const Text('Add vehicle'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(height: 10),
                                OptionTile(
                                  title: 'Remove vehicle',
                                  subtitle: 'Archive this vehicle from the fleet',
                                  icon: Icons.delete_rounded,
                                  selected: false,
                                  onTap: () {
                                    final notifier = ref.read(brokerVehiclesProvider.notifier);
                                    notifier.state = notifier.state
                                        .where((item) => item.id != entry.value.id)
                                        .toList();
                                    Navigator.of(context).pop();
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
  }
}
