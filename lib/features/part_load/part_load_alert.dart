// Global incoming part-load alert — shows on ANY driver/broker screen
// (tracking included), not just the inbox tab. A top slide-down card with
// route, amount and a countdown of the 2-minute driver window. Tap View to
// jump to the inbox; swipe/X to park it silently (badge keeps counting).
//
// Web has no equivalent (two tabs are fine on desktop, not on a phone).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ssk/core/theme/app_icons.dart';

import 'part_load_models.dart';

class PartLoadAlertState {
  const PartLoadAlertState({
    this.queue = const [],
    this.seen = const {},
  });

  final List<PartLoadJoinRequest> queue;
  final Set<String> seen;
}

class PartLoadAlertQueue extends StateNotifier<PartLoadAlertState> {
  PartLoadAlertQueue() : super(const PartLoadAlertState());

  void push(PartLoadJoinRequest req) {
    if (req.id.isEmpty || !req.isPending) return;
    if (state.seen.contains(req.id)) return;
    if (state.queue.any((r) => r.id == req.id)) {
      state = PartLoadAlertState(
        queue: [
          for (final r in state.queue) r.id == req.id ? req : r,
        ],
        seen: state.seen,
      );
      return;
    }
    state = PartLoadAlertState(
      queue: [...state.queue, req],
      seen: state.seen,
    );
  }

  void resolve(String id) {
    if (id.isEmpty) return;
    state = PartLoadAlertState(
      queue: [for (final r in state.queue) if (r.id != id) r],
      seen: {...state.seen, id},
    );
  }

  void dismiss(String id) => resolve(id);

  void clear() => state = const PartLoadAlertState();
}

final partLoadAlertQueueProvider =
    StateNotifierProvider<PartLoadAlertQueue, PartLoadAlertState>((ref) {
  return PartLoadAlertQueue();
});

/// Slide-down banner. Countdown runs 2:00 from first sight (the driver
/// window); the server's accept/decline/timeout push removes it earlier.
class PartLoadAlertBanner extends StatefulWidget {
  const PartLoadAlertBanner({
    super.key,
    required this.request,
    required this.extraCount,
    required this.onView,
    required this.onDismiss,
    required this.onExpire,
  });

  final PartLoadJoinRequest request;
  final int extraCount;
  final VoidCallback onView;
  final VoidCallback onDismiss;
  final VoidCallback onExpire;

  @override
  State<PartLoadAlertBanner> createState() => _PartLoadAlertBannerState();
}

class _PartLoadAlertBannerState extends State<PartLoadAlertBanner>
    with SingleTickerProviderStateMixin {
  static const _windowSeconds = 120;

  late final AnimationController _slide;
  late final Animation<Offset> _offset;
  Timer? _ticker;
  int _elapsed = 0;
  bool _expired = false;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _offset = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slide, curve: Curves.easeOutCubic));
    _slide.forward();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= _windowSeconds + 30 && !_expired) {
        _expired = true;
        widget.onExpire();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = (_windowSeconds - _elapsed).clamp(0, _windowSeconds);
    final mm = (remaining ~/ 60).toString();
    final ss = (remaining % 60).toString().padLeft(2, '0');
    final urgent = remaining <= 30;
    final req = widget.request;
    final refText =
        req.bookingNumber.isNotEmpty ? req.bookingNumber : req.bookingId;

    return SlideTransition(
      position: _offset,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD7EEDF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF0F7F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      AppIcons.package_plus_rounded,
                      color: Color(0xFF2FA56E),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'New shared-load request',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: Color(0xFF101828),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: urgent
                                    ? const Color(0xFFFDECEC)
                                    : const Color(0xFFF0F7F3),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$mm:$ss',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: urgent
                                      ? const Color(0xFFB42318)
                                      : const Color(0xFF2FA56E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${req.pickup} → ${req.drop}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF344054),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (req.weight.isNotEmpty) req.weight,
                            if (req.amount.isNotEmpty) '₹${req.amount}',
                            if (refText.isNotEmpty) refText,
                            if (widget.extraCount > 0)
                              '+${widget.extraCount} more',
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF667085),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.onView,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onDismiss,
                    icon: const Icon(
                      AppIcons.close_rounded,
                      size: 18,
                      color: Color(0xFF98A2B3),
                    ),
                    tooltip: 'Dismiss',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
