import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../widgets/client_flow_widgets.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LocationArc(),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                await showBookingFlow(
                  context,
                  onOpen: () => ref.read(bottomNavVisibleProvider.notifier).state = false,
                  onClose: () {
                    if (context.mounted) {
                      ref.read(bottomNavVisibleProvider.notifier).state = true;
                    }
                  },
                );
              },
              child: const BannerCard(),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'View all',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.black45,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Refreshing dashboard...'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          color: Colors.black54,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const PackageTrackingCard(
                      packageName: 'MacBook Air M3',
                      trackingId: 'TRK-SSK-20489',
                      fromLocation: 'Mumbai Warehouse',
                      toLocation: 'Pune Distribution Center',
                      status: 'Your package is in transit',
                    ),
                    const SizedBox(height: 12),
                    const PackageTrackingCard(
                      packageName: 'Apple iPhone 15 Pro',
                      trackingId: 'TRK-SSK-20841',
                      fromLocation: 'Navi Mumbai Hub',
                      toLocation: 'Bangalore Tech Park',
                      status: 'Arriving at next checkpoint',
                    ),
                    const SizedBox(height: 12),
                    const PackageTrackingCard(
                      packageName: 'Office Chair Set',
                      trackingId: 'TRK-SSK-21077',
                      fromLocation: 'Delhi DC-3',
                      toLocation: 'Jaipur Office',
                      status: 'Awaiting dispatch',
                    ),
                    const SizedBox(height: 12),
                    const PackageTrackingCard(
                      packageName: 'Printer Cartridge Box',
                      trackingId: 'TRK-SSK-21330',
                      fromLocation: 'Pune Cargo Yard',
                      toLocation: 'Hyderabad Retail Store',
                      status: 'Out for pickup',
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
