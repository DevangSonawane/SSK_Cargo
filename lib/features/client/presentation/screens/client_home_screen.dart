import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../widgets/client_flow_widgets.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  double _refreshTurns = 0;

  @override
  Widget build(BuildContext context) {
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
                            setState(() {
                              _refreshTurns += 1;
                            });
                          },
                          icon: AnimatedRotation(
                            turns: _refreshTurns,
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeInOut,
                            child: const Icon(Icons.refresh_rounded),
                          ),
                          color: Colors.black54,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
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
