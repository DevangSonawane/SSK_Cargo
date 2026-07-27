import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../widgets/broker_flow_widgets.dart';

class DriverDetailScreen extends StatefulWidget {
  const DriverDetailScreen({
    super.key,
    required this.driver,
  });

  final BrokerDriver driver;

  @override
  State<DriverDetailScreen> createState() => _DriverDetailScreenState();
}

class _DriverDetailScreenState extends State<DriverDetailScreen> {
  bool _isLiveView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isLiveView
            ? _DriverLiveView(
                key: const ValueKey('live'),
                driver: widget.driver,
                onBack: () => context.go('/broker/tracking'),
              )
            : SafeArea(
                key: const ValueKey('detail'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    children: [
                      _DriverSummaryCard(driver: widget.driver),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              const Positioned.fill(child: _BrokerTrackingMapBackdrop()),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.18),
                                        Colors.white.withValues(alpha: 0.46),
                                        Colors.white.withValues(alpha: 0.84),
                                      ],
                                      stops: const [0.0, 0.42, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(18, 18, 18, 86),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _InfoBlock(
                                      title: 'Vehicle',
                                      value: widget.driver.assignedVehicle,
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoBlock(
                                      title: 'Location',
                                      value: widget.driver.currentLocation,
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoBlock(
                                      title: 'License',
                                      value: widget.driver.licenseNo,
                                    ),
                                    const SizedBox(height: 12),
                                    _InfoBlock(
                                      title: 'On trip since',
                                      value: widget.driver.onTripSince.isEmpty
                                          ? 'Not on trip'
                                          : widget.driver.onTripSince,
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 18,
                                right: 18,
                                bottom: 14,
                                child: SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: FilledButton(
                                    onPressed: () => setState(() => _isLiveView = true),
                                    style: FilledButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      backgroundColor: const Color(0xFF1F88C9),
                                    ),
                                    child: const Text(
                                      'Live tracking',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _DriverLiveView extends StatefulWidget {
  const _DriverLiveView({
    super.key,
    required this.driver,
    required this.onBack,
  });

  final BrokerDriver driver;
  final VoidCallback onBack;

  @override
  State<_DriverLiveView> createState() => _DriverLiveViewState();
}

class _DriverLiveViewState extends State<_DriverLiveView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Live Tracking',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF101828),
                        ),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: DriverLocationOverviewCard(
                driver: widget.driver,
                title: 'Live driver position',
                subtitle: widget.driver.currentLocation.isEmpty
                    ? 'Awaiting live location'
                    : widget.driver.currentLocation,
                height: null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverSummaryCard extends StatelessWidget {
  const _DriverSummaryCard({required this.driver});

  final BrokerDriver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: driverAvatarColor(driver.status),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _driverInitials(driver.name),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: driverAvatarTextColor(driver.status),
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  driver.assignedVehicle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                StatusPill(
                  label: driverStatusLabel(driver.status),
                  backgroundColor: driverStatusBackground(driver.status),
                  textColor: driverStatusColor(driver.status),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _driverInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4FA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF98A2B3),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _BrokerTrackingMapBackdrop extends StatelessWidget {
  const _BrokerTrackingMapBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BrokerMapPainter(),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEFF6FF),
              const Color(0xFFF7FAFC),
              const Color(0xFFEFF6FF).withValues(alpha: 0.65),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrokerMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFBFD3E6).withValues(alpha: 0.28)
      ..strokeWidth = 1;

    const gridStep = 42.0;
    for (double x = 0; x <= size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final routePaint = Paint()
      ..color = const Color(0xFF1F88C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final route = Path()
      ..moveTo(size.width * 0.16, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.32, size.height * 0.58, size.width * 0.48, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.66, size.height * 0.67, size.width * 0.83, size.height * 0.40);
    canvas.drawPath(route, routePaint);

    final start = Paint()..color = const Color(0xFF2FA56E);
    final end = Paint()..color = const Color(0xFFE23A4B);
    canvas.drawCircle(Offset(size.width * 0.16, size.height * 0.76), 10, start);
    canvas.drawCircle(Offset(size.width * 0.83, size.height * 0.40), 10, end);

    final accentPaint = Paint()..color = const Color(0xFF1F88C9).withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.72, size.height * 0.28), 58, accentPaint);
    canvas.drawCircle(Offset(size.width * 0.33, size.height * 0.22), 42, accentPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
