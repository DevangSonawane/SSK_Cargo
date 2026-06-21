import 'package:flutter/material.dart';

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
                onBack: () => setState(() => _isLiveView = false),
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
    return Stack(
      children: [
        const Positioned.fill(child: _BrokerTrackingMapBackdrop()),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return _LiveRouteOverlay(progress: _controller.value);
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.36),
                  Colors.white.withValues(alpha: 0.66),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 14,
                top: 4,
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Live Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111111),
                        ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 110,
                child: Column(
                  children: [
                    _ZoomButton(icon: Icons.remove, onTap: () {}),
                    const SizedBox(height: 10),
                    _ZoomButton(icon: Icons.add, onTap: () {}),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _DriverLiveInfoCard(driver: widget.driver),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DriverLiveInfoCard extends StatelessWidget {
  const _DriverLiveInfoCard({required this.driver});

  final BrokerDriver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E5EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Driver information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF101828),
                ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(title: 'Name', value: driver.name),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBlock(title: 'Phone', value: driver.phone),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoBlock(title: 'Vehicle', value: driver.assignedVehicle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoBlock(title: 'Status', value: driverStatusLabel(driver.status)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ContactIconButton(
                  icon: Icons.call_rounded,
                  color: const Color(0xFF2FA56E),
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ContactIconButton(
                  icon: Icons.message_rounded,
                  color: const Color(0xFF1F88C9),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
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

class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: color),
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

class _LiveRouteOverlay extends StatelessWidget {
  const _LiveRouteOverlay({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LiveRoutePainter(progress: progress),
    );
  }
}

class _LiveRoutePainter extends CustomPainter {
  _LiveRoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.76)
      ..quadraticBezierTo(size.width * 0.32, size.height * 0.58, size.width * 0.48, size.height * 0.62)
      ..quadraticBezierTo(size.width * 0.66, size.height * 0.67, size.width * 0.83, size.height * 0.40);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final partialPath = metric.extractPath(0, metric.length * progress.clamp(0.0, 1.0));

    final glowPaint = Paint()
      ..color = const Color(0xFF1F88C9).withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(partialPath, glowPaint);

    final routePaint = Paint()
      ..color = const Color(0xFF1F88C9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(partialPath, routePaint);

    final movingPoint = metric.getTangentForOffset(metric.length * progress.clamp(0.0, 1.0));
    if (movingPoint != null) {
      final pulsePaint = Paint()..color = const Color(0xFF1F88C9).withValues(alpha: 0.16);
      canvas.drawCircle(movingPoint.position, 18, pulsePaint);
      canvas.drawCircle(
        movingPoint.position,
        9,
        Paint()..color = const Color(0xFF1F88C9),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LiveRoutePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
