import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/broker_flow_widgets.dart';

class BrokerTrackingScreen extends ConsumerWidget {
  const BrokerTrackingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driversAsync = ref.watch(
      brokerDriversApiProvider((status: null, page: 1, limit: 10)),
    );

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
            FilledButton(
              onPressed: () => context.push('/broker/drivers/add'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                fixedSize: const Size(40, 40),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Icon(Icons.add, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 14),
        driversAsync.when(
          data: (drivers) {
            if (drivers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No drivers yet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Create a driver from the + button to start tracking.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF667085),
                          ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                for (var index = 0; index < drivers.length; index++) ...[
                DriverListTile(
                  driver: drivers[index],
                  onTap: () {
                    context.push(
                      '/broker/drivers/${drivers[index].id}',
                      extra: drivers[index],
                    );
                  },
                  onEdit: () {
                    context.push(
                      '/broker/drivers/add',
                      extra: drivers[index],
                    );
                  },
                  onRemove: () {},
                ),
                  if (index != drivers.length - 1) const SizedBox(height: 10),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 36),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stackTrace) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}
