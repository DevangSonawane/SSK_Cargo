import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/theme/app_tokens.dart';

class DriverDeliveryArrivedScreen extends ConsumerStatefulWidget {
  const DriverDeliveryArrivedScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<DriverDeliveryArrivedScreen> createState() =>
      _DriverDeliveryArrivedScreenState();
}

class _DriverDeliveryArrivedScreenState
    extends ConsumerState<DriverDeliveryArrivedScreen> {
  double _arrivalSlide = 0;
  bool _showSwipeControl = false;
  Timer? _revealTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(driverActiveTripIdProvider.notifier).state = widget.tripId;
    });
    _revealTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _showSwipeControl = true);
    });
  }

  @override
  void dispose() {
    _revealTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        title: const Text('Arrived at destination'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.brandTint,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          AppIcons.location_on_rounded,
                          color: AppColors.brand,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery complete at location',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'The on-route card is replaced with this arrival step.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.35,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trip ID',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textTertiary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.tripId,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _MiniStat(
                          label: 'Status',
                          value: 'Ready to confirm',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MiniStat(
                          label: 'Next step',
                          value: 'Upload proof photo',
                          alignRight: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: _showSwipeControl
                        ? Column(
                            key: const ValueKey('swipe-ready'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Slide to confirm arrival',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'This hides the route card and opens the photo upload page.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
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
                                        trackShape:
                                            const RoundedRectSliderTrackShape(),
                                        thumbShape: const _ArrivalThumbShape(),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 0,
                                            ),
                                        activeTrackColor: AppColors.line,
                                        inactiveTrackColor: AppColors.line,
                                        thumbColor: Colors.white,
                                        overlayColor: Colors.transparent,
                                        trackGap: 6,
                                      ),
                                      child: Slider(
                                        value: _arrivalSlide,
                                        onChanged: (value) {
                                          setState(() => _arrivalSlide = value);
                                          if (value >= 0.98) {
                                            Future.delayed(
                                              const Duration(milliseconds: 350),
                                              () {
                                                if (!context.mounted) return;
                                                context.push(
                                                  '/driver/delivery-proof/${widget.tripId}',
                                                );
                                                setState(
                                                  () => _arrivalSlide = 0,
                                                );
                                              },
                                            );
                                          }
                                        },
                                        min: 0,
                                        max: 1,
                                        divisions: 100,
                                      ),
                                    ),
                                    IgnorePointer(
                                      child: AnimatedOpacity(
                                        opacity: (1 - (_arrivalSlide * 1.7))
                                            .clamp(0.18, 1.0),
                                        duration: const Duration(
                                          milliseconds: 90,
                                        ),
                                        child: Text(
                                          'Swipe to continue',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: AppColors.textSecondary,
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
                          )
                        : Container(
                            key: const ValueKey('swipe-loading'),
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              vertical: 26,
                              horizontal: 18,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fillSubtle,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.divider,
                              ),
                            ),
                            child: Column(
                              children: [
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: AppColors.brand,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Preparing swipe control...',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'It will appear automatically after 2 seconds.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                ),
                              ],
                            ),
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

class _MiniStat extends StatelessWidget {
  const _MiniStat({
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
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ArrivalThumbShape extends SliderComponentShape {
  const _ArrivalThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(48, 48);

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
      ..color = AppColors.line
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final rect = Rect.fromCenter(center: center, width: 48, height: 48);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect.shift(const Offset(0, 2)),
        const Radius.circular(16),
      ),
      shadowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      fillPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(16)),
      borderPaint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(AppIcons.chevron_right_rounded.codePoint),
        style: TextStyle(
          color: AppColors.brand,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          fontFamily: AppIcons.chevron_right_rounded.fontFamily,
          package: AppIcons.chevron_right_rounded.fontPackage,
          height: 1,
        ),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.center,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
}
