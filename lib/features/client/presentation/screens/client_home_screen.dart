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
  final TextEditingController _whereToController = TextEditingController();

  @override
  void dispose() {
    _whereToController.dispose();
    super.dispose();
  }

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
            const SizedBox(height: 14),
            _WhereToPill(controller: _whereToController),
            const SizedBox(height: 12),
            const _RecentAddressCard(),
            const SizedBox(height: 16),
            Text(
              'Vehicles we provide',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              itemCount: vehicleOptions.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 4,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final vehicle = vehicleOptions[index];
                return _VehiclePreviewTile(vehicle: vehicle);
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

class _VehiclePreviewTile extends StatelessWidget {
  const _VehiclePreviewTile({
    required this.vehicle,
  });

  final VehicleOption vehicle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          height: 88,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Image.asset(
              vehicle.assetPath,
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          vehicle.label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
        ),
      ],
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

class _WhereToPill extends StatelessWidget {
  const _WhereToPill({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6FA),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 18,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF101828),
                  ),
              decoration: const InputDecoration(
                hintText: 'Where to?',
                hintStyle: TextStyle(
                  color: Color(0xFF9AA4B2),
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFF9AA4B2),
          ),
        ],
        ),
    );
  }
}

class _RecentAddressCard extends StatelessWidget {
  const _RecentAddressCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE3E8EF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF2D6EF2),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent address',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF667085),
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ghanshyam Enclave, 1303/1304, Nagpur',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Home',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
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
