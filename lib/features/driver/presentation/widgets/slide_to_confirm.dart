import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssk/core/theme/app_icons.dart';

import '../../../../core/theme/app_tokens.dart';

/// Shared slide-to-confirm track, ported from logistics_app's `SlideConfirm`
/// (slide_to_act 2.0.2 `SlideAction`) in ssk brand dress.
///
/// Signature behaviour: the arrow thumb ROTATES as it travels
/// (`-pi * progress`), the label only fades, release past 80% runs
/// thumb-shrink -> bar-shrink-to-circle -> check-wipe -> reset.
class SlideToConfirm extends StatefulWidget {
  const SlideToConfirm({
    super.key,
    required this.enabled,
    required this.label,
    required this.onConfirmed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onConfirmed;

  @override
  State<SlideToConfirm> createState() => SlideToConfirmState();
}

class SlideToConfirmState extends State<SlideToConfirm>
    with TickerProviderStateMixin {
  static const _height = 72.0;
  static const _thumb = 58.0;
  static const _thumbPad = 8.0;
  static const _threshold = 0.8;
  static const _anim = Duration(milliseconds: 300);

  double _dx = 0;
  double _dz = 1;
  double _checkDx = 0;
  double? _narrowWidth;
  bool _submitted = false;
  bool _busy = false;
  bool _touched = false;

  late final AnimationController _cancelController;
  late final AnimationController _checkController;
  late final AnimationController _shrinkController;
  late final AnimationController _resizeController;

  double get _sliderWidth => _thumb + _thumbPad * 2;

  double _maxDx(double trackWidth) =>
      (trackWidth - _sliderWidth / 2 - 40).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    _cancelController = AnimationController(vsync: this, duration: _anim);
    _checkController = AnimationController(vsync: this, duration: _anim);
    _shrinkController = AnimationController(vsync: this, duration: _anim);
    _resizeController = AnimationController(vsync: this, duration: _anim);
  }

  @override
  void dispose() {
    _cancelController.dispose();
    _checkController.dispose();
    _shrinkController.dispose();
    _resizeController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDx) {
    if (_busy || _submitted) return;
    if (!_touched) {
      _touched = true;
      HapticFeedback.lightImpact();
    }
    setState(() => _dx = (_dx + details.delta.dx).clamp(0.0, maxDx));
  }

  Future<void> _onDragEnd(double maxDx, double trackWidth) async {
    if (_busy || _submitted) return;
    final progress = maxDx <= 0 ? 0 : _dx / maxDx;
    if (progress <= _threshold) {
      await _runCancel();
    } else {
      await _runSubmit(trackWidth);
    }
  }

  Future<void> _runTween(
    AnimationController controller,
    Curve curve,
    void Function(double value) apply,
  ) async {
    controller.reset();
    final animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: controller, curve: curve),
    );
    void listener() {
      if (mounted) setState(() => apply(animation.value));
    }

    animation.addListener(listener);
    try {
      await controller.forward();
    } finally {
      animation.removeListener(listener);
    }
  }

  Future<void> _reverseTween(
    AnimationController controller,
    void Function(double value) apply,
  ) async {
    void listener() {
      if (mounted) setState(() => apply(controller.value));
    }

    controller.addListener(listener);
    try {
      await controller.reverse();
    } finally {
      controller.removeListener(listener);
    }
  }

  Future<void> _runCancel() async {
    final startDx = _dx;
    await _runTween(
      _cancelController,
      Curves.fastOutSlowIn,
      (value) => _dx = startDx - startDx * value,
    );
    if (mounted) setState(() => _touched = false);
  }

  Future<void> _runSubmit(double trackWidth) async {
    if (_busy) return;
    _busy = true;
    HapticFeedback.mediumImpact();
    // 1. Thumb scales away.
    await _runTween(
      _resizeController,
      Curves.easeInBack,
      (value) => _dz = 1 - value,
    );
    if (!mounted) return;
    // 2. Bar shrinks into a circle.
    if (mounted) setState(() => _submitted = true);
    final diff = trackWidth - _height;
    await _runTween(
      _shrinkController,
      Curves.easeOutCirc,
      (value) => _narrowWidth = trackWidth - diff * value,
    );
    if (!mounted) return;
    // 3. Check wipes in.
    await _runTween(
      _checkController,
      Curves.slowMiddle,
      (value) => _checkDx = value,
    );
    if (!mounted) return;
    widget.onConfirmed();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    await _runReset(trackWidth, diff);
    _busy = false;
  }

  Future<void> _runReset(double trackWidth, double diff) async {
    await _reverseTween(_checkController, (value) => _checkDx = value);
    if (mounted) setState(() => _submitted = false);
    await _reverseTween(
      _shrinkController,
      (value) => _narrowWidth = trackWidth - diff * value,
    );
    await _reverseTween(_resizeController, (value) => _dz = 1 - value);
    await _runCancel();
    if (mounted) {
      setState(() {
        _narrowWidth = null;
        _checkDx = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.55,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final trackWidth = constraints.maxWidth;
          final maxDx = _maxDx(trackWidth);
          _dx = _dx.clamp(0.0, maxDx);
          final progress = maxDx <= 0 ? 0.0 : _dx / maxDx;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: widget.enabled
                ? (details) => _onDragUpdate(details, maxDx)
                : null,
            onHorizontalDragEnd: widget.enabled
                ? (_) => _onDragEnd(maxDx, trackWidth)
                : null,
            onHorizontalDragCancel: widget.enabled ? () => _runCancel() : null,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: _narrowWidth ?? double.infinity,
                height: _height,
                child: Material(
                  elevation: 6,
                  color: AppColors.brand,
                  borderRadius: BorderRadius.circular(999),
                  child: _submitted
                      ? Center(
                          child: Stack(
                            children: <Widget>[
                              const Icon(
                                AppIcons.check_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              Positioned.fill(
                                right: 0,
                                child: Transform(
                                  transform: Matrix4.rotationY(
                                    _checkDx * (math.pi / 2),
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Opacity(
                              opacity: 1 - progress,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 80,
                                ),
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 0,
                              child: Transform.scale(
                                scale: _dz,
                                origin: Offset(_dx, 0),
                                child: Transform.translate(
                                  offset: Offset(_dx, 0),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: _thumbPad,
                                    ),
                                    child: Container(
                                      width: _thumb,
                                      height: _thumb,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Transform.rotate(
                                        angle: -math.pi * progress,
                                        child: const Icon(
                                          AppIcons.arrow_forward_rounded,
                                          size: 28,
                                          color: AppColors.brand,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
