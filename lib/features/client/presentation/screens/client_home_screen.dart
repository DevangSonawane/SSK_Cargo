import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../widgets/client_flow_widgets.dart';
import '../widgets/home_schedule_sheet.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

/// Home-owned booking mode — mirrors web BookTruck.jsx step-1 pills
/// (Full Truck / Part Truck / Book Later). The choose-trucks sheet no
/// longer has a mode section; it follows whichever mode home passes in.
enum _HomeMode { full, part, later }

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen> {
  _HomeMode _mode = _HomeMode.full;
  DateTime? _scheduled;

  @override
  void initState() {
    super.initState();
    // Safety net: if login-time prefetch was skipped/denied, warm the
    // cache here so the booking flow still opens instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userLocationProvider.notifier).prefetch();
      }
    });
  }

  Future<void> _openBookingLocation() async {
    HapticFeedback.lightImpact();
    if (_mode == _HomeMode.later && _scheduled == null) {
      await _pickScheduledDateTime();
      if (_scheduled == null || !mounted) return;
    }
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      switch (_mode) {
        case _HomeMode.full:
          await showQuickBookingFlow(
            context,
            tripType: TripType.interCity,
            initialVehicleIndex: 0,
          );
        case _HomeMode.part:
          await showQuickBookingFlow(
            context,
            tripType: TripType.interCity,
            initialVehicleIndex: 0,
            initialSearchMode: BookingSearchMode.partLoad,
          );
        case _HomeMode.later:
          await showQuickBookingFlow(
            context,
            tripType: TripType.interCity,
            initialVehicleIndex: 0,
            initialScheduledDate: _scheduled,
          );
      }
    } finally {
      if (mounted) {
        ref.read(bottomNavVisibleProvider.notifier).state = true;
      }
    }
  }

  Future<void> _pickScheduledDateTime() async {
    final now = DateTime.now();
    final initial = _scheduled?.isAfter(now) == true
        ? _scheduled!
        : now.add(const Duration(hours: 3));
    final picked = await showHomeScheduleSheet(
      context,
      initialDateTime: initial,
    );
    if (picked == null || !mounted) return;
    setState(() => _scheduled = picked);
  }

  String _formatScheduled(DateTime value) {
    final hour12 =
        value.hour == 0 ? 12 : value.hour > 12 ? value.hour - 12 : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} at $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            'assets/client/home_page_photo.png',
            fit: BoxFit.cover,
            alignment: const Alignment(0, -0.18),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        Colors.black.withValues(alpha: 0.72),
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.0),
                      ]
                    : [
                        const Color(0xFF8ED7F0).withValues(alpha: 0.88),
                        const Color(0xFF8ED7F0).withValues(alpha: 0.30),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.0),
                      ],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
        ),
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ModeHeader(
                  mode: _mode,
                  onChanged: (value) {
                    if (_mode != value) {
                      HapticFeedback.lightImpact();
                    }
                    setState(() {
                      _mode = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeOutCubic,
                  child: switch (_mode) {
                    _HomeMode.full => _FullHeroCard(
                        key: const ValueKey('home-full'),
                        onTap: _openBookingLocation,
                      ),
                    _HomeMode.part => _PartHeroCard(
                        key: const ValueKey('home-part'),
                        onTap: _openBookingLocation,
                      ),
                    _HomeMode.later => _LaterHeroCard(
                        key: const ValueKey('home-later'),
                        scheduled: _scheduled,
                        scheduledLabel: _scheduled == null
                            ? null
                            : _formatScheduled(_scheduled!),
                        onPickSchedule: _pickScheduledDateTime,
                        onTap: _openBookingLocation,
                      ),
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Three mutually-exclusive booking modes — same pills as web BookTruck.jsx
/// step 1 (rounded-full group, exact lucide icons Zap / PackagePlus /
/// CalendarClock, no images). Home owns the choice; the choose-trucks
/// sheet follows it.
class _ModeHeader extends StatelessWidget {
  const _ModeHeader({required this.mode, required this.onChanged});

  final _HomeMode mode;
  final ValueChanged<_HomeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModePill(
              label: l10n.tripTypeFullTruck,
              icon: AppIcons.flash_on_rounded,
              selected: mode == _HomeMode.full,
              onTap: () => onChanged(_HomeMode.full),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModePill(
              label: l10n.tripTypePartTruck,
              icon: AppIcons.package_plus_rounded,
              selected: mode == _HomeMode.part,
              onTap: () => onChanged(_HomeMode.part),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _ModePill(
              label: l10n.checkoutBookLater,
              icon: AppIcons.calendar_clock_rounded,
              selected: mode == _HomeMode.later,
              onTap: () => onChanged(_HomeMode.later),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2FA56E) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? Colors.white : context.colors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : context.colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared hero-card shell — same sizing as the old booking prompt card:
/// surface, radius 24, line border, 0.04/14 shadow, route rows, 52px
/// radius-15 green button.
class _HeroCardShell extends StatelessWidget {
  const _HeroCardShell({
    required this.buttonLabel,
    required this.onTap,
    this.buttonEnabled = true,
    required this.children,
  });

  final String buttonLabel;
  final VoidCallback onTap;
  final bool buttonEnabled;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: buttonEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.colors.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...children,
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: buttonEnabled ? onTap : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA56E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFD8E1ED),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.zero,
                ),
                child: Text(
                  buttonLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRows extends StatelessWidget {
  const _RouteRows();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BookingRouteRow(
          icon: AppIcons.arrow_upward_rounded,
          iconColor: const Color(0xFF38B47A),
          hintText: l10n.clientHomeLoadingHint,
        ),
        const SizedBox(height: 12),
        const _BookingRouteDivider(),
        const SizedBox(height: 12),
        _BookingRouteRow(
          icon: AppIcons.arrow_downward_rounded,
          iconColor: const Color(0xFFF05252),
          hintText: l10n.clientHomeUnloadingHint,
        ),
      ],
    );
  }
}

class _FullHeroCard extends StatelessWidget {
  const _FullHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _HeroCardShell(
      buttonLabel: l10n.clientHomeBookAnyTruck,
      onTap: onTap,
      children: const [_RouteRows()],
    );
  }
}

class _PartHeroCard extends StatelessWidget {
  const _PartHeroCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _HeroCardShell(
      buttonLabel: 'Find shared truck',
      onTap: onTap,
      children: [
        const _RouteRows(),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.colors.brandFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.colors.brandBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.package_plus_rounded,
                color: Color(0xFF2FA56E),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Share space on a truck already heading your way — fixed price, no negotiation.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LaterHeroCard extends StatelessWidget {
  const _LaterHeroCard({
    super.key,
    required this.scheduled,
    required this.scheduledLabel,
    required this.onPickSchedule,
    required this.onTap,
  });

  final DateTime? scheduled;
  final String? scheduledLabel;
  final VoidCallback onPickSchedule;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = scheduledLabel;
    return _HeroCardShell(
      buttonLabel: l10n.checkoutBookLater,
      onTap: onTap,
      buttonEnabled: scheduled != null,
      children: [
        InkWell(
          onTap: onPickSchedule,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.fillSubtle,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.calendar_clock_rounded,
                  color: Color(0xFF2FA56E),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label ?? 'Select date & time',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: label == null
                          ? context.colors.textTertiary
                          : context.colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Icon(
                  AppIcons.chevron_right_rounded,
                  size: 18,
                  color: context.colors.textTertiary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "We'll notify nearby drivers about 2 hours before this time.",
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.colors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        const _RouteRows(),
      ],
    );
  }
}

class _BookingRouteRow extends StatelessWidget {
  const _BookingRouteRow({
    required this.icon,
    required this.iconColor,
    required this.hintText,
  });

  final IconData icon;
  final Color iconColor;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: iconColor,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: Colors.white, size: 15),
            ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hintText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.textTertiary,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BookingRouteDivider extends StatelessWidget {
  const _BookingRouteDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Center(
              child: SizedBox(
                width: 2,
                height: 18,
                child: CustomPaint(painter: _VerticalDotsPainter()),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 1, color: context.colors.line)),
        ],
      ),
    );
  }
}

class _VerticalDotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFBFC5D1)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dash = 2.5;
    const gap = 3.0;
    var y = 2.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dash),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
