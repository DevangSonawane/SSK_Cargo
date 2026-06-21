import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/broker_flow_widgets.dart';

class BrokerTrackingScreen extends ConsumerWidget {
  const BrokerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drivers = ref.watch(brokerDriversProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Row(
          children: [
            Text(
              'Driver tracking',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => context.push('/broker/drivers/add'),
              icon: const Icon(Icons.add),
              label: const Text('Add driver'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                shape: const StadiumBorder(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...drivers.asMap().entries.expand(
              (entry) => [
                DriverListTile(
                  driver: entry.value,
                  onTap: () {
                    context.push(
                      '/broker/drivers/${entry.value.id}',
                      extra: entry.value,
                    );
                  },
                  onRemove: () {
                    final notifier = ref.read(brokerDriversProvider.notifier);
                    notifier.state = notifier.state
                        .where((item) => item.id != entry.value.id)
                        .toList();
                  },
                ),
                if (entry.key != drivers.length - 1) const SizedBox(height: 12),
              ],
            ),
      ],
    );
  }
}
