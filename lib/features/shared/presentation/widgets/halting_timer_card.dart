import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';

class HaltingTimerCard extends StatefulWidget {
  const HaltingTimerCard({
    super.key,
    required this.status,
    required this.startedAt,
    required this.haltingGraceHours,
    this.haltingRatePerHour,
    this.haltingHours = 0,
    this.haltingCharge = 0,
    this.showNotStarted = true,
    this.showLiveChargeEstimate = false,
    this.tickInterval = const Duration(seconds: 30),
  });

  final String status;
  final DateTime? startedAt;
  final double? haltingGraceHours;
  final double? haltingRatePerHour;
  final double haltingHours;
  final double haltingCharge;
  final bool showNotStarted;
  final bool showLiveChargeEstimate;
  final Duration tickInterval;

  @override
  State<HaltingTimerCard> createState() => _HaltingTimerCardState();
}

class _HaltingTimerCardState extends State<HaltingTimerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant HaltingTimerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.startedAt != widget.startedAt ||
        oldWidget.haltingGraceHours != widget.haltingGraceHours ||
        oldWidget.tickInterval != widget.tickInterval) {
      _syncTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.haltingGraceHours == null ||
        widget.startedAt == null ||
        _isTerminalStatus(widget.status)) {
      return;
    }
    _timer = Timer.periodic(widget.tickInterval, (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final graceHours = widget.haltingGraceHours;
    if (graceHours == null) {
      return const SizedBox.shrink();
    }

    final terminal = _isTerminalStatus(widget.status);
    if (terminal) {
      if (widget.haltingCharge <= 0) {
        return const SizedBox.shrink();
      }
      return _TimerShell(
        icon: AppIcons.receipt_long_rounded,
        title: 'Halting charge applied',
        message:
            '${_formatMoney(widget.haltingCharge)}${widget.haltingHours > 0 ? ' for ${_formatHours(widget.haltingHours)}' : ''} after the free ${_formatHours(graceHours)} window.',
        backgroundColor: const Color(0xFFFFF7ED),
        borderColor: const Color(0xFFFED7AA),
        accentColor: const Color(0xFFC2410C),
      );
    }

    final startedAt = widget.startedAt;
    if (startedAt == null) {
      if (!widget.showNotStarted) {
        return const SizedBox.shrink();
      }
      return _TimerShell(
        icon: AppIcons.hourglass_top_rounded,
        title: 'Free halting window',
        message: '${_formatHours(graceHours)} once the trip starts.',
        backgroundColor: const Color(0xFFF8FAFC),
        borderColor: const Color(0xFFE2E8F0),
        accentColor: const Color(0xFF475569),
      );
    }

    final graceDuration = Duration(
      milliseconds: (graceHours * Duration.millisecondsPerHour).round(),
    );
    final deadline = startedAt.add(graceDuration);
    final now = DateTime.now();
    final remaining = deadline.difference(now);

    if (!remaining.isNegative) {
      return _TimerShell(
        icon: AppIcons.timer_rounded,
        title: 'Free halting time remaining',
        message:
            '${_formatDuration(remaining)} left in the ${_formatHours(graceHours)} free window.',
        backgroundColor: const Color(0xFFEAF7EF),
        borderColor: const Color(0xFFCDEFD9),
        accentColor: const Color(0xFF2FA56E),
      );
    }

    final overage = now.difference(deadline);
    final rate = widget.haltingRatePerHour;
    final estimatedCharge =
        widget.showLiveChargeEstimate && rate != null && rate > 0
        ? (overage.inMinutes / 60) * rate
        : null;

    return _TimerShell(
      icon: AppIcons.warning_amber_rounded,
      title: 'Halting time exceeded',
      message: estimatedCharge == null
          ? '${_formatDuration(overage)} over the free window - a charge will be added on delivery.'
          : '${_formatDuration(overage)} over - ~${_formatMoney(estimatedCharge)} and counting (estimate, finalized at delivery).',
      backgroundColor: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFED7AA),
      accentColor: const Color(0xFFC2410C),
    );
  }
}

class _TimerShell extends StatelessWidget {
  const _TimerShell({
    required this.icon,
    required this.title,
    required this.message,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: accentColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF475467),
                    height: 1.35,
                    fontWeight: FontWeight.w600,
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

bool _isTerminalStatus(String status) {
  final normalized = status.trim().toLowerCase().replaceAll(
    RegExp(r'[\s-]+'),
    '_',
  );
  return normalized == 'delivered' || normalized == 'completed';
}

String _formatDuration(Duration duration) {
  final minutes = duration.inMinutes.abs();
  final hours = minutes ~/ 60;
  final remainingMinutes = minutes % 60;
  if (hours <= 0) {
    return '${remainingMinutes}m';
  }
  if (remainingMinutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${remainingMinutes}m';
}

String _formatHours(double hours) {
  return '${hours.toStringAsFixed(hours % 1 == 0 ? 0 : 1)}h';
}

String _formatMoney(double amount) {
  return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
}
