import 'package:flutter/material.dart';

import '../widgets/client_flow_widgets.dart';

class ClientHomeScreen extends StatelessWidget {
  const ClientHomeScreen({super.key});

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
              onTap: () => showTripTypeSheet(context),
              child: const BannerCard(),
            ),
            const SizedBox(height: 18),
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
          ],
        ),
      ),
    );
  }
}
