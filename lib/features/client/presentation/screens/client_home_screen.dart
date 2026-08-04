import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../widgets/client_flow_widgets.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  TripType _selectedTripType = TripType.interCity;

  Future<void> _openBookingLocation({required int vehicleIndex}) async {
    HapticFeedback.lightImpact();
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BookingLocationScreen(
            tripType: _selectedTripType,
            initialVehicleIndex: vehicleIndex,
            autoOpenLocationFlow: true,
          ),
        ),
      );
    } finally {
      if (mounted) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/client/home_page_photo.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8ED7F0).withValues(alpha: 0.88),
                  const Color(0xFF8ED7F0).withValues(alpha: 0.30),
                  const Color(0xFFFFFFFF).withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TripHeader(
                  selectedTripType: _selectedTripType,
                  onTripTypeChanged: (value) {
                    if (_selectedTripType != value) {
                      HapticFeedback.lightImpact();
                    }
                    setState(() {
                      _selectedTripType = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                _BookingPromptCard(
                  onTap: () {
                    _openBookingLocation(vehicleIndex: 0);
                  },
                ),
              ],
            ),
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
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: Row(
              children: [
                Expanded(
                  child: _TripModeLabel(
                    label: TripType.interCity.displayLabel,
                    imagePath: 'assets/trucks/inter-city.png',
                    selected: selectedTripType == TripType.interCity,
                    onTap: () => onTripTypeChanged(TripType.interCity),
                  ),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFE3E8EF)),
                Expanded(
                  child: _TripModeLabel(
                    label: TripType.intraCity.displayLabel,
                    imagePath: 'assets/trucks/intra-city.png',
                    selected: selectedTripType == TripType.intraCity,
                    onTap: () => onTripTypeChanged(TripType.intraCity),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
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
                    color: selected
                        ? const Color(0xFF101828)
                        : const Color(0xFF9AA4B2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              height: 2,
              width: selected ? 30 : 0,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingPromptCard extends StatelessWidget {
  const _BookingPromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE3E8EF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BookingRouteRow(
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFF38B47A),
              hintText: 'Enter loading location (e.g. delhi)',
              dividerColor: const Color(0xFFE4E7EC),
              showConnector: true,
            ),
            const SizedBox(height: 10),
            _BookingRouteRow(
              icon: Icons.arrow_downward_rounded,
              iconColor: const Color(0xFFF05252),
              hintText: 'Search your unloading location',
              dividerColor: Colors.transparent,
              showConnector: false,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  'Book Any Truck',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingRouteRow extends StatelessWidget {
  const _BookingRouteRow({
    required this.icon,
    required this.iconColor,
    required this.hintText,
    required this.dividerColor,
    required this.showConnector,
  });

  final IconData icon;
  final Color iconColor;
  final String hintText;
  final Color dividerColor;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: Colors.white, size: 15),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 30,
                margin: const EdgeInsets.symmetric(vertical: 1),
                decoration: BoxDecoration(
                  color: dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: CustomPaint(painter: _VerticalDotsPainter()),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF9B9B9B),
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 7),
              if (showConnector)
                Container(height: 1, color: const Color(0xFFE8EAF0)),
            ],
          ),
        ),
      ],
    );
  }
}

class _VerticalDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBFC5D1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dash = 2.5;
    const gap = 3.0;
    var y = 2.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dash),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
