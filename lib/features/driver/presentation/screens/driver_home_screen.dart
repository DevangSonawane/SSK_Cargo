import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isOnline = true;
  double _acceptSlide = 0;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Offline',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _isOnline
                          ? const Color(0xFF98A2B3)
                          : const Color(0xFFE23A4B),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Switch(
                    value: _isOnline,
                    onChanged: (value) {
                      setState(() => _isOnline = value);
                    },
                    activeThumbColor: const Color(0xFF2FA56E),
                    activeTrackColor: const Color(
                      0xFF2FA56E,
                    ).withValues(alpha: 0.35),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(
                      0xFFE23A4B,
                    ).withValues(alpha: 0.35),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Online',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: _isOnline
                          ? const Color(0xFF2FA56E)
                          : const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF2)),
            const SizedBox(height: 18),
            Text(
              'Deliveries',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            if (_isOnline) ...[
              _DeliveryOrderCard(
                delivery: _deliveries.first,
                acceptSlide: _acceptSlide,
                onSlideChanged: (value) {
                  setState(() => _acceptSlide = value);
                  if (value >= 0.98) {
                    Future.delayed(const Duration(milliseconds: 450), () {
                      if (!context.mounted) return;
                      context.push('/driver/delivery-details');
                      setState(() => _acceptSlide = 0);
                    });
                  }
                },
              ),
            ] else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFE8EDF2)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF7FAFD),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.inbox_rounded,
                        color: Color(0xFF98A2B3),
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'No deliveries available',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Go online to receive deliveries.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF667085),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

const _deliveries = <_DriverDelivery>[
  _DriverDelivery(
    deliveryId: 'DEL-2048',
    amount: '₹103.5',
    dropLocation: 'Sector 137',
    stateAndPincode: 'Noida, Uttar Pradesh 201305',
    tripDistance: 'Trip distance',
    tripDistanceValue: '24 km',
    itemsLabel: 'Items',
    itemsValue: '8 kg',
  ),
];

class _DriverDelivery {
  const _DriverDelivery({
    required this.deliveryId,
    required this.amount,
    required this.dropLocation,
    required this.stateAndPincode,
    required this.tripDistance,
    required this.tripDistanceValue,
    required this.itemsLabel,
    required this.itemsValue,
  });

  final String deliveryId;
  final String amount;
  final String dropLocation;
  final String stateAndPincode;
  final String tripDistance;
  final String tripDistanceValue;
  final String itemsLabel;
  final String itemsValue;
}

class _DeliveryOrderCard extends StatelessWidget {
  const _DeliveryOrderCard({
    required this.delivery,
    required this.acceptSlide,
    required this.onSlideChanged,
  });

  final _DriverDelivery delivery;
  final double acceptSlide;
  final ValueChanged<double> onSlideChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery ID',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      delivery.deliveryId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF101828),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                delivery.amount,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE8EDF2)),
          const SizedBox(height: 14),
          Text(
            delivery.dropLocation,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            delivery.stateAndPincode,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DeliveryMetric(
                  label: delivery.tripDistance,
                  value: delivery.tripDistanceValue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DeliveryMetric(
                  label: delivery.itemsLabel,
                  value: delivery.itemsValue,
                  alignRight: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 92,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 52,
                    trackShape: const RoundedRectSliderTrackShape(),
                    thumbShape: const _AcceptOrderThumbShape(),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 0,
                    ),
                    activeTrackColor: const Color(0xFFE5E7EB),
                    inactiveTrackColor: const Color(0xFFE5E7EB),
                    thumbColor: Colors.white,
                    overlayColor: Colors.transparent,
                    trackGap: 6,
                  ),
                  child: Slider(
                    value: acceptSlide,
                    onChanged: onSlideChanged,
                    min: 0,
                    max: 1,
                    divisions: 100,
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: (1 - (acceptSlide * 1.7)).clamp(0.18, 1.0),
                    duration: const Duration(milliseconds: 90),
                    child: Text(
                      'Slide to accept delivery',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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

class _DeliveryMetric extends StatelessWidget {
  const _DeliveryMetric({
    required this.label,
    required this.value,
    this.alignRight = false,
  });

  final String label;
  final String value;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF98A2B3),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _AcceptOrderThumbShape extends SliderComponentShape {
  const _AcceptOrderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(56, 56);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.14)
      ..isAntiAlias = true
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fillPaint = Paint()
      ..color = Colors.white
      ..isAntiAlias = true;
    final borderPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    canvas.drawCircle(center + const Offset(0, 1.5), 22, shadowPaint);
    canvas.drawCircle(center, 22, fillPaint);
    canvas.drawCircle(center, 22, borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.chevron_right_rounded.codePoint),
        style: TextStyle(
          color: const Color(0xFF2FA56E),
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFamily: Icons.chevron_right_rounded.fontFamily,
          package: Icons.chevron_right_rounded.fontPackage,
          height: 1,
        ),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2 + 1),
    );
  }
}
