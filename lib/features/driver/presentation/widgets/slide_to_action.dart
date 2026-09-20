import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';

/// Minimal-light "slide to action" pill (Swiggy-partner style).
///
/// The trending slide-to-accept pattern: a soft white track, a light green
/// fill that grows under the thumb as you drag, hint text that fades away,
/// a spring snap-back on early release, and a green success morph with
/// haptics on completion.
class SlideToAction extends StatefulWidget {
  const SlideToAction({
    super.key,
    required this.label,
    required this.onCompleted,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onCompleted;
  final bool enabled;

  @override
  State<SlideToAction> createState() => _SlideToActionState();
}

class _SlideToActionState extends State<SlideToAction>
    with TickerProviderStateMixin {
  static const double _height = 64;
  static const double _pad = 6;
  static const double _thumbSize = 52;
  static const double _threshold = 0.9;

  double _progress = 0;
  bool _dragging = false;
  bool _completing = false;
  bool _touched = false;

  double _dragStartDx = 0;
  double _dragStartProgress = 0;

  late final AnimationController _snapController;
  late Animation<double> _snapAnimation;
  late final AnimationController _nudgeController;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _snapAnimation = Tween<double>(begin: 0, end: 0).animate(_snapController);
    _snapController.addListener(() {
      if (_dragging || _completing || !mounted) return;
      setState(() => _progress = _snapAnimation.value);
    });
    _nudgeController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..repeat();
  }

  @override
  void dispose() {
    _snapController.dispose();
    _nudgeController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    if (!widget.enabled || _completing) return;
    _snapController.stop();
    setState(() {
      _dragging = true;
      _touched = true;
      _dragStartDx = details.localPosition.dx;
      _dragStartProgress = _progress;
    });
    HapticFeedback.lightImpact();
  }

  void _onDragUpdate(DragUpdateDetails details, double travel) {
    if (!widget.enabled || !_dragging || _completing || travel <= 0) return;
    final next =
        (_dragStartProgress +
                (details.localPosition.dx - _dragStartDx) / travel)
            .clamp(0.0, 1.0);
    if (next >= _threshold) {
      _complete();
      return;
    }
    setState(() => _progress = next);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging || _completing) return;
    setState(() => _dragging = false);
    if (_progress >= _threshold) {
      _complete();
    } else {
      _snapBack();
    }
  }

  void _snapBack() {
    _snapAnimation =
        Tween<double>(
          begin: _progress,
          end: 0,
        ).animate(
          CurvedAnimation(parent: _snapController, curve: Curves.easeOutCubic),
        );
    _snapController.forward(from: 0);
  }

  Future<void> _complete() async {
    if (_completing) return;
    setState(() {
      _completing = true;
      _dragging = false;
      _progress = 1;
    });
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    widget.onCompleted();
    if (!mounted) return;
    setState(() {
      _completing = false;
      _progress = 0;
      _touched = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.label,
      child: Opacity(
        opacity: widget.enabled ? 1 : 0.55,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.of(context).size.width;
            final travel = math.max(0.0, width - _pad * 2 - _thumbSize);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: (details) =>
                  _onDragUpdate(details, travel),
              onHorizontalDragEnd: _onDragEnd,
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(
                    color: _completing
                        ? AppColors.brand
                        : AppColors.line,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Stack(
                    children: [
                      // Growing fill.
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.clamp(0.0, 1.0),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: _completing
                                    ? const LinearGradient(
                                        colors: [
                                          AppColors.brand,
                                          AppColors.brandDark,
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          AppColors.brandTint,
                                          Color(0xFFDFF2E6),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Hint label that fades and drifts as the thumb advances.
                      Positioned.fill(
                        child: Opacity(
                          opacity: _completing
                              ? 0
                              : (1 - _progress * 1.8).clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(_progress * travel * 0.22, 0),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: _thumbSize + _pad * 2,
                                ),
                                child: Text(
                                  widget.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.2,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Thumb.
                      AnimatedBuilder(
                        animation: _nudgeController,
                        builder: (context, _) {
                          final nudge =
                              (!_touched &&
                                  !_completing &&
                                  widget.enabled &&
                                  !_dragging)
                              ? math.sin(
                                      _nudgeController.value * 2 * math.pi,
                                    ) *
                                    5
                              : 0.0;
                          return Positioned(
                            left: _pad + _progress * travel + nudge,
                            top: (_height - _thumbSize) / 2,
                            child: Container(
                              width: _thumbSize,
                              height: _thumbSize,
                              decoration: BoxDecoration(
                                color: _completing
                                    ? AppColors.brand
                                    : AppColors.surface,
                                shape: BoxShape.circle,
                                border: _completing
                                    ? null
                                    : Border.all(color: AppColors.line),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.12,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: _completing
                                    ? const Icon(
                                        AppIcons.check_rounded,
                                        key: ValueKey('done'),
                                        color: Colors.white,
                                        size: 26,
                                      )
                                    : const Icon(
                                        AppIcons.arrow_forward_rounded,
                                        key: ValueKey('arrow'),
                                        color: AppColors.brand,
                                        size: 26,
                                      ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
