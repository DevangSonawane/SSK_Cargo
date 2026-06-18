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
            const SizedBox(height: 6),
            const _TrackingHeroCard(),
            const SizedBox(height: 18),
            Text(
              'Your shipments',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF101828),
                  ),
            ),
            const SizedBox(height: 12),
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

class _TrackingHeroCard extends StatelessWidget {
  const _TrackingHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF5D36F5),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5D36F5).withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Track your package',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please enter tracking number',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  fontSize: 13,
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const SizedBox(width: 10),
                const Icon(Icons.search_rounded, color: Colors.black45, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tracking number',
                      hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: const Color(0xFF101828),
                          fontSize: 15,
                        ),
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8B84D),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
