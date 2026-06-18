import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../widgets/client_flow_widgets.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  double _refreshTurns = 0;
  TripType _selectedTripType = TripType.interCity;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TripHeader(
              selectedTripType: _selectedTripType,
              onTripTypeChanged: (value) {
                setState(() {
                  _selectedTripType = value;
                });
              },
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
    );
  }
}

class _TripHeader extends StatelessWidget {
  const _TripHeader({
    required this.selectedTripType,
    required this.onTripTypeChanged,
  });

  final TripType selectedTripType;
  final ValueChanged<TripType> onTripTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _TripModeLabel(
                  label: 'Inter city',
                  imagePath: 'assets/trucks/inter-city.png',
                  selected: selectedTripType == TripType.interCity,
                  onTap: () => onTripTypeChanged(TripType.interCity),
                ),
              ),
              Container(
                width: 1,
                height: 28,
                color: const Color(0xFFE3E8EF),
              ),
              Expanded(
                child: _TripModeLabel(
                  label: 'Intra city',
                  imagePath: 'assets/trucks/intra-city.png',
                  selected: selectedTripType == TripType.intraCity,
                  onTap: () => onTripTypeChanged(TripType.intraCity),
                ),
              ),
            ],
          ),
          Container(
            width: double.infinity,
            height: 1,
            color: const Color(0xFFE3E8EF),
          ),
        ],
      ),
    );
  }
}

class _TripModeLabel extends StatelessWidget {
  const _TripModeLabel({
    required this.label,
    required this.imagePath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String imagePath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              imagePath,
              width: 20,
              height: 20,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: selected ? const Color(0xFF101828) : const Color(0xFF9AA4B2),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
