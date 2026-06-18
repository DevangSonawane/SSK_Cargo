import 'package:flutter/material.dart';

import '../widgets/client_flow_widgets.dart';

class TrackingDetailsScreen extends StatelessWidget {
  const TrackingDetailsScreen({
    super.key,
    required this.shipment,
  });

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CompactSummaryCard(shipment: shipment),
              const SizedBox(height: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      const Positioned.fill(child: TrackingMapBackdrop()),
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
                            ...shipment.timeline.asMap().entries.map(
                                  (entry) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: entry.key == shipment.timeline.length - 1 ? 0 : 16,
                                    ),
                                    child: _TimelineStepItem(
                                      step: entry.value,
                                      showConnector: entry.key != shipment.timeline.length - 1,
                                    ),
                                  ),
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
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              backgroundColor: const Color(0xFF6C63FF),
                            ),
                            child: const Text(
                              'Live Tracking',
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
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F3F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tracking Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF0F3F7)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/package.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#Tracking ID: ${shipment.trackingId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF6C63FF)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECEFF3)),
            ),
            child: Column(
              children: [
                _InfoGrid(
                  leftLabel: 'From',
                  leftValue: shipment.fromLocation,
                  rightLabel: 'Destination',
                  rightValue: shipment.toLocation,
                ),
                const SizedBox(height: 10),
                _InfoGrid(
                  leftLabel: 'Customer',
                  leftValue: shipment.customerName,
                  rightLabel: 'Weight',
                  rightValue: shipment.weight,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Status:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C2430),
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2EFFF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6C63FF),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Transit',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF1C2430),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                leftValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2430),
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                rightValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2430),
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineStepItem extends StatelessWidget {
  const _TimelineStepItem({
    required this.step,
    required this.showConnector,
  });

  final TrackingTimelineStep step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final activeColor = step.completed ? const Color(0xFF6C63FF) : const Color(0xFFE0DDFB);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 38,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE7E6FF),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                step.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TrackingMapBackdrop extends StatelessWidget {
  const TrackingMapBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackingMapPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3F6FB),
              Color(0xFFE8EEF6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD8DEE9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final roadAccentPaint = Paint()
      ..color = const Color(0xFFC8D2E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = const Color(0xFFF9FBFD);
    final nodeBorderPaint = Paint()
      ..color = const Color(0xFFE0E7F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF3F6FB),
    );

    final paths = [
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.18)
        ..quadraticBezierTo(size.width * 0.4, size.height * 0.12, size.width * 0.62, size.height * 0.24)
        ..quadraticBezierTo(size.width * 0.82, size.height * 0.34, size.width * 0.95, size.height * 0.22),
      Path()
        ..moveTo(size.width * 0.05, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.32, size.height * 0.38, size.width * 0.5, size.height * 0.5)
        ..quadraticBezierTo(size.width * 0.72, size.height * 0.62, size.width * 0.98, size.height * 0.56),
      Path()
        ..moveTo(size.width * 0.14, size.height * 0.72)
        ..quadraticBezierTo(size.width * 0.38, size.height * 0.64, size.width * 0.58, size.height * 0.76)
        ..quadraticBezierTo(size.width * 0.78, size.height * 0.86, size.width * 0.94, size.height * 0.78),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, roadAccentPaint);
    }

    final nodes = [
      Offset(size.width * 0.18, size.height * 0.24),
      Offset(size.width * 0.46, size.height * 0.33),
      Offset(size.width * 0.72, size.height * 0.27),
      Offset(size.width * 0.28, size.height * 0.58),
      Offset(size.width * 0.63, size.height * 0.66),
      Offset(size.width * 0.84, size.height * 0.82),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 11, nodePaint);
      canvas.drawCircle(node, 11, nodeBorderPaint);
      canvas.drawCircle(node, 3.5, Paint()..color = const Color(0xFFCBD5E1));
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EBF3)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.12 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
