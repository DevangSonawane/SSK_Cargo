import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum OtpInputStatus { idle, verifying, error, success }

const _green = Color(0xFF2FA56E);
const _greenSoft = Color(0xFFE8F6EF);
const _red = Color(0xFFE23A4B);
const _redSoft = Color(0xFFFDECEE);
const _ink = Color(0xFF1B2A3A);
const _border = Color(0xFFD9E2EA);

/// Row of OTP digit boxes driven by one hidden [TextField].
///
/// The parent owns [status]:
/// * [OtpInputStatus.error] shakes the boxes red, then clears them.
/// * [OtpInputStatus.success] turns them green, slides them together into a
///   single circle and draws a tick; [onSuccessAnimationDone] fires after.
class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.length,
    required this.status,
    required this.onCompleted,
    this.onChanged,
    this.onErrorAnimationDone,
    this.onSuccessAnimationDone,
    this.autofocus = true,
  });

  final int length;
  final OtpInputStatus status;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onErrorAnimationDone;
  final VoidCallback? onSuccessAnimationDone;
  final bool autofocus;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput>
    with TickerProviderStateMixin {
  static const double _boxSize = 52;
  static const double _gap = 10;
  static const double _circleSize = 60;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  late final AnimationController _shake;
  late final AnimationController _success;
  late final AnimationController _cursor;
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _success = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _cursor = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _controller.addListener(() => setState(() {}));
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(covariant OtpCodeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status == widget.status) return;
    switch (widget.status) {
      case OtpInputStatus.error:
        _pulse.stop();
        _playError();
      case OtpInputStatus.success:
        _pulse.stop();
        _playSuccess();
      case OtpInputStatus.verifying:
        _pulse.repeat(reverse: true);
      case OtpInputStatus.idle:
        _pulse.stop();
        _pulse.value = 0;
        _success.value = 0;
    }
  }

  Future<void> _playError() async {
    HapticFeedback.heavyImpact();
    await _shake.forward(from: 0);
    await Future<void>.delayed(const Duration(milliseconds: 380));
    if (!mounted) return;
    _controller.clear();
    _focusNode.requestFocus();
    widget.onErrorAnimationDone?.call();
  }

  Future<void> _playSuccess() async {
    _focusNode.unfocus();
    HapticFeedback.mediumImpact();
    await _success.forward(from: 0);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    widget.onSuccessAnimationDone?.call();
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _shake.dispose();
    _success.dispose();
    _cursor.dispose();
    _pulse.dispose();
    super.dispose();
  }

  bool get _locked =>
      widget.status == OtpInputStatus.verifying ||
      widget.status == OtpInputStatus.success;

  void _onChanged(String value) {
    widget.onChanged?.call(value);
    if (value.length == widget.length) {
      widget.onCompleted(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalWidth = widget.length * _boxSize + (widget.length - 1) * _gap;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _locked ? null : _focusNode.requestFocus,
      child: SizedBox(
        width: totalWidth,
        height: _circleSize + 8,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // The real input: invisible, but it owns focus, the keyboard,
            // paste and SMS autofill.
            Opacity(
              opacity: 0,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: widget.autofocus,
                readOnly: _locked,
                keyboardType: TextInputType.number,
                autofillHints: const [AutofillHints.oneTimeCode],
                maxLength: widget.length,
                showCursor: false,
                enableInteractiveSelection: false,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: _onChanged,
              ),
            ),
            AnimatedBuilder(
              animation: Listenable.merge([_shake, _success, _cursor, _pulse]),
              builder: (context, _) => _buildBoxes(totalWidth),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxes(double totalWidth) {
    final text = _controller.text;
    final t = _success.value;
    // Success timeline: tint → slide together → pop into circle → tick.
    final tint = _interval(t, 0.0, 0.18, Curves.easeOut);
    final merge = _interval(t, 0.16, 0.50, Curves.easeInOutCubic);
    final pop = _interval(t, 0.46, 0.64, Curves.easeOutBack);
    final tick = _interval(t, 0.60, 0.92, Curves.easeOutCubic);
    final ring = _interval(t, 0.58, 1.0, Curves.easeOut);

    // Damped sine shake for the wrong-code state.
    final s = _shake.value;
    final shakeDx = math.sin(s * math.pi * 6) * 12 * (1 - s);

    final isError = widget.status == OtpInputStatus.error;
    final isSuccess = widget.status == OtpInputStatus.success;
    final center = totalWidth / 2;
    final children = <Widget>[];

    if (isSuccess && ring > 0) {
      final ringSize = _circleSize * (1 + ring * 0.9);
      children.add(
        Positioned(
          left: center - ringSize / 2,
          top: (_circleSize + 8 - ringSize) / 2,
          child: IgnorePointer(
            child: Container(
              width: ringSize,
              height: ringSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _green.withValues(alpha: 0.45 * (1 - ring)),
                  width: 2.5,
                ),
              ),
            ),
          ),
        ),
      );
    }

    for (var i = 0; i < widget.length; i++) {
      final restLeft = i * (_boxSize + _gap);
      final mergedSize = lerpDouble(_boxSize, _circleSize, pop)!;
      final size = isSuccess ? mergedSize : _boxSize;
      final restCenter = restLeft + _boxSize / 2;
      final boxCenter = lerpDouble(restCenter, center, merge)!;
      // Only the first box survives the merge; the rest fade into it.
      final fadeOut = i == 0 ? 1.0 : (1 - _interval(merge, 0.7, 1.0));
      final filled = i < text.length;
      final active =
          !isSuccess &&
          _focusNode.hasFocus &&
          (i == text.length || (i == widget.length - 1 && filled)) &&
          widget.status == OtpInputStatus.idle;

      Color borderColor = filled ? _ink.withValues(alpha: 0.35) : _border;
      Color fill = Colors.white;
      if (active) borderColor = _green;
      if (isError) {
        borderColor = _red;
        fill = _redSoft;
      }
      if (widget.status == OtpInputStatus.verifying) {
        borderColor = Color.lerp(_border, _green, 0.4 + _pulse.value * 0.5)!;
      }
      if (isSuccess) {
        final stagger = _interval(tint, i * 0.12, 0.64 + i * 0.12);
        borderColor = Color.lerp(borderColor, _green, stagger)!;
        fill = Color.lerp(Colors.white, _greenSoft, stagger)!;
        fill = Color.lerp(fill, _green, pop)!;
      }

      final radius = lerpDouble(14, size / 2, isSuccess ? pop : 0)!;
      final digitOpacity = isSuccess ? 1 - merge : 1.0;

      children.add(
        Positioned(
          left: boxCenter - size / 2 + (isError ? shakeDx : 0),
          top: (_circleSize + 8 - size) / 2,
          child: Opacity(
            opacity: fadeOut.clamp(0.0, 1.0),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: borderColor,
                  width: active || isError || isSuccess ? 2 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        (active
                                ? _green
                                : isError
                                ? _red
                                : isSuccess
                                ? _green
                                : Colors.black)
                            .withValues(
                              alpha: active || isError || isSuccess
                                  ? 0.18
                                  : 0.05,
                            ),
                    blurRadius: active || isSuccess ? 18 : 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (filled)
                    Opacity(
                      opacity: digitOpacity.clamp(0.0, 1.0),
                      child: _PoppingDigit(
                        key: ValueKey('digit-$i-${text[i]}'),
                        digit: text[i],
                        color: isError ? _red : _ink,
                      ),
                    ),
                  if (active && !filled)
                    Opacity(
                      opacity: _cursor.value,
                      child: Container(
                        width: 2,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _green,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  if (isSuccess && i == 0 && tick > 0)
                    CustomPaint(
                      size: Size.square(size * 0.5),
                      painter: _TickPainter(progress: tick),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Stack(clipBehavior: Clip.none, children: children);
  }
}

double _interval(
  double t,
  double begin,
  double end, [
  Curve curve = Curves.linear,
]) {
  if (t <= begin) return 0;
  if (t >= end) return 1;
  return curve.transform((t - begin) / (end - begin));
}

/// A digit that springs in when typed.
class _PoppingDigit extends StatelessWidget {
  const _PoppingDigit({super.key, required this.digit, required this.color});

  final String digit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Text(
        digit,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: color,
          height: 1,
        ),
      ),
    );
  }
}

class _TickPainter extends CustomPainter {
  const _TickPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.12, size.height * 0.54)
      ..lineTo(size.width * 0.40, size.height * 0.80)
      ..lineTo(size.width * 0.90, size.height * 0.22);
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.13
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final metric in path.computeMetrics()) {
      canvas.drawPath(metric.extractPath(0, metric.length * progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TickPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
