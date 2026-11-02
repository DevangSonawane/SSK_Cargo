import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Pill toggle whose highlight slides between options like a drop of
/// liquid: it stretches toward the target while moving, then settles back
/// with a slight squash.
class LiquidSegmentedToggle extends StatefulWidget {
  const LiquidSegmentedToggle({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
    this.icons,
    this.activeColor = const Color(0xFF2FA56E),
  });

  final List<String> labels;
  final List<IconData>? icons;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final Color activeColor;

  @override
  State<LiquidSegmentedToggle> createState() => _LiquidSegmentedToggleState();
}

class _LiquidSegmentedToggleState extends State<LiquidSegmentedToggle>
    with SingleTickerProviderStateMixin {
  static const double _height = 54;
  static const double _inset = 5;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );
  late double _from = widget.selectedIndex.toDouble();
  late double _to = widget.selectedIndex.toDouble();

  @override
  void didUpdateWidget(covariant LiquidSegmentedToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _from = _position;
      _to = widget.selectedIndex.toDouble();
      _controller.forward(from: 0);
    }
  }

  double get _position {
    final t = Curves.easeInOutCubic.transform(
      (_controller.value / 0.78).clamp(0.0, 1.0),
    );
    return lerpDouble(_from, _to, t)!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.labels.length;
    return Container(
      height: _height,
      padding: const EdgeInsets.all(_inset),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F7),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segment = constraints.maxWidth / count;
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final v = _controller.value;
              final pos = _position;
              final distance = (_to - _from).abs();
              // Stretch peaks mid-travel; a short squash wobble at the end.
              final stretch =
                  math.sin(math.pi * (v / 0.78).clamp(0.0, 1.0)) *
                  0.32 *
                  distance;
              final settle = v > 0.78
                  ? math.sin((v - 0.78) / 0.22 * math.pi) * 0.06
                  : 0.0;
              final width = segment * (1 + stretch - settle);
              final height =
                  (_height - _inset * 2) * (1 - stretch * 0.18 + settle);
              final left = pos * segment - (width - segment) / 2;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: left.clamp(-4.0, constraints.maxWidth - width + 4),
                    top: (_height - _inset * 2 - height) / 2,
                    width: width,
                    height: height,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.activeColor,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: widget.activeColor.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < count; i++)
                        Expanded(child: _segment(i, pos)),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _segment(int index, double pos) {
    // 1 when the highlight sits on this segment, fading as it leaves.
    final activeness = (1 - (pos - index).abs()).clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFF475467),
      Colors.white,
      activeness,
    )!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (index == widget.selectedIndex) return;
        HapticFeedback.selectionClick();
        widget.onChanged(index);
      },
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icons != null) ...[
              Icon(widget.icons![index], size: 17, color: color),
              const SizedBox(width: 8),
            ],
            Text(
              widget.labels[index],
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
