import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../widgets/client_flow_widgets.dart';

class ClientDeliveryScreen extends ConsumerWidget {
  const ClientDeliveryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deliveries', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'This tab can later hold the full delivery list and booking history.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 18),
            const BannerCard(),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => showBookingFlow(
                context,
                onOpen: () => ref.read(bottomNavVisibleProvider.notifier).state = false,
                onClose: () {
                  if (context.mounted) {
                    ref.read(bottomNavVisibleProvider.notifier).state = true;
                  }
                },
              ),
              icon: const Icon(Icons.add),
              label: const Text('Book a shipment'),
            ),
          ],
        ),
      ),
    );
  }
}
