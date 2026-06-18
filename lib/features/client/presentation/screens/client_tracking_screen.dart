import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/client_flow_widgets.dart';

class ClientTrackingScreen extends StatelessWidget {
  const ClientTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tracking',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your active shipments are listed below.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.black54,
                  ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...trackingDemoShipments.asMap().entries.expand(
                          (entry) => [
                            PackageTrackingCard(
                              shipment: entry.value,
                              onTap: () {
                                context.push(
                                  '/client/tracking/details',
                                  extra: entry.value,
                                );
                              },
                            ),
                            if (entry.key != trackingDemoShipments.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
