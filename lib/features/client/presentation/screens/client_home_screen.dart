import 'package:flutter/material.dart';
import 'package:gadidost/core/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../../../core/providers/client_kyc_gate_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';
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
  bool _kycStatusResolved = false;

  @override
  void initState() {
    super.initState();
    // Safety net: if login-time prefetch was skipped/denied, warm the
    // cache here so the booking flow still opens instantly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(userLocationProvider.notifier).prefetch();
        ref.read(clientKycGateProvider.notifier).ensureLoaded().whenComplete(
          () {
            if (mounted) setState(() => _kycStatusResolved = true);
          },
        );
      }
    });
  }

  Future<void> _openBookingLocation() async {
    if (_kycStatusResolved && !ref.read(clientKycGateProvider).verified) return;
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

  Future<void> _bookAgain(ClientBooking booking) async {
    if (_kycStatusResolved && !ref.read(clientKycGateProvider).verified) return;
    final pickup = booking.pickupLocation.trim();
    final drop = booking.dropoffLocation.trim();
    if (pickup.isEmpty || drop.isEmpty) return;

    HapticFeedback.lightImpact();
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    try {
      final tripType = _tripTypeFor(booking);
      var coordinates = _BookingCoordinates.fromBooking(booking);
      // Most booking responses include the saved coordinates. For older
      // responses that only contain addresses, resolve them before skipping
      // the location screen so the remaining booking flow stays unchanged.
      if (!coordinates.isComplete) {
        try {
          final places = ref.read(googlePlacesServiceProvider);
          final locations = await Future.wait([
            places.geocodeAddress(address: pickup),
            places.geocodeAddress(address: drop),
          ]);
          coordinates = coordinates.withMissing(
            pickupLat: locations[0].latitude,
            pickupLng: locations[0].longitude,
            dropLat: locations[1].latitude,
            dropLng: locations[1].longitude,
          );
        } catch (_) {
          // The original addresses are retained; the flow can still let the
          // user amend the route from its back navigation if needed.
        }
      }
      if (!mounted) return;
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => BookingLocationScreen(
            tripType: tripType,
            initialVehicleIndex: 0,
            skipLocationStep: true,
            initialBookingData: BookingData(
              from: pickup,
              to: drop,
              tripType: tripType,
              pickupLat: coordinates.pickupLat,
              pickupLng: coordinates.pickupLng,
              dropLat: coordinates.dropLat,
              dropLng: coordinates.dropLng,
              scheduledDate: DateTime.now().add(const Duration(hours: 3)),
              searchMode: BookingSearchMode.truck,
            ),
          ),
        ),
      );
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
    final hour12 = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '${value.day}/${value.month}/${value.year} at $hour12:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final bookingLocked =
        _kycStatusResolved && !ref.watch(clientKycGateProvider).verified;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgAsset = switch (_mode) {
      _HomeMode.full => 'assets/client/home_page_photo.png',
      _HomeMode.part => 'assets/client/part-truck.png',
      _HomeMode.later => 'assets/client/booklaters.png',
    };
    final recentBookings = ref
        .watch(clientBookingsProvider((status: null, page: 1, limit: 3)))
        .valueOrNull
        ?.bookings
        .where(
          (booking) =>
              booking.pickupLocation.trim().isNotEmpty &&
              booking.dropoffLocation.trim().isNotEmpty,
        )
        .take(3)
        .toList(growable: false);
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 380),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInOutCubic,
            transitionBuilder: (child, animation) {
              final fade = FadeTransition(opacity: animation, child: child);
              final scale = ScaleTransition(
                scale: Tween<double>(begin: 1.06, end: 1.0).animate(animation),
                child: fade,
              );
              return scale;
            },
            layoutBuilder: (currentChild, previousChildren) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ...previousChildren,
                  currentChild ?? const SizedBox.shrink(),
                ],
              );
            },
            child: SizedBox.expand(
              key: ValueKey(bgAsset),
              child: Image.asset(
                bgAsset,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.18),
              ),
            ),
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
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.fastOutSlowIn,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    final fade = FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                    final slide = SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(animation),
                      child: fade,
                    );
                    return slide;
                  },
                  layoutBuilder: (currentChild, previousChildren) => Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      ...previousChildren,
                      currentChild ?? const SizedBox.shrink(),
                    ],
                  ),
                  child: Opacity(
                    opacity: bookingLocked ? 0.42 : 1,
                    child: IgnorePointer(
                      ignoring: bookingLocked,
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
                  ),
                ),
                if (recentBookings?.isNotEmpty == true) ...[
                  const SizedBox(height: 22),
                  Opacity(
                    opacity: bookingLocked ? 0.42 : 1,
                    child: IgnorePointer(
                      ignoring: bookingLocked,
                      child: _PreviousTripSection(
                        bookings: recentBookings!,
                        onBookAgain: _bookAgain,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviousTripSection extends StatelessWidget {
  const _PreviousTripSection({
    required this.bookings,
    required this.onBookAgain,
  });

  final List<ClientBooking> bookings;
  final ValueChanged<ClientBooking> onBookAgain;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous trips',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(20),
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
            children: [
              for (var index = 0; index < bookings.length; index++) ...[
                _PreviousTripRow(
                  booking: bookings[index],
                  onBookAgain: () => onBookAgain(bookings[index]),
                ),
                if (index != bookings.length - 1) ...[
                  const SizedBox(height: 12),
                  Divider(height: 1, color: context.colors.line),
                  const SizedBox(height: 12),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PreviousTripRow extends StatelessWidget {
  const _PreviousTripRow({required this.booking, required this.onBookAgain});

  final ClientBooking booking;
  final VoidCallback onBookAgain;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _PreviousTripRoute(
            pickup: booking.pickupLocation,
            drop: booking.dropoffLocation,
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 96,
          height: 42,
          child: FilledButton(
            onPressed: onBookAgain,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2FA56E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500),
            ),
            child: const Text('Book again', textAlign: TextAlign.center),
          ),
        ),
      ],
    );
  }
}

class _PreviousTripRoute extends StatelessWidget {
  const _PreviousTripRoute({required this.pickup, required this.drop});

  final String pickup;
  final String drop;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PreviousTripPoint(
          icon: AppIcons.arrow_upward_rounded,
          color: const Color(0xFF38B47A),
          value: pickup,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(width: 1, height: 14, color: context.colors.line),
          ),
        ),
        _PreviousTripPoint(
          icon: AppIcons.arrow_downward_rounded,
          color: const Color(0xFFF05252),
          value: drop,
        ),
      ],
    );
  }
}

class _PreviousTripPoint extends StatelessWidget {
  const _PreviousTripPoint({
    required this.icon,
    required this.color,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingCoordinates {
  const _BookingCoordinates({
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
  });

  factory _BookingCoordinates.fromBooking(ClientBooking booking) {
    final raw = booking.raw;
    final pickup = _nestedMap(raw, const ['pickup', 'origin', 'source']);
    final drop = _nestedMap(raw, const [
      'drop',
      'dropoff',
      'destination',
      'target',
    ]);
    return _BookingCoordinates(
      pickupLat:
          _coordinate(raw, const ['pickup_lat', 'pickupLat']) ??
          _coordinate(pickup, const ['lat', 'latitude']),
      pickupLng:
          _coordinate(raw, const ['pickup_lng', 'pickupLng']) ??
          _coordinate(pickup, const ['lng', 'longitude', 'lon']),
      dropLat:
          _coordinate(raw, const ['drop_lat', 'dropLat', 'dropoff_lat']) ??
          _coordinate(drop, const ['lat', 'latitude']),
      dropLng:
          _coordinate(raw, const ['drop_lng', 'dropLng', 'dropoff_lng']) ??
          _coordinate(drop, const ['lng', 'longitude', 'lon']),
    );
  }

  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;

  bool get isComplete =>
      pickupLat != null &&
      pickupLng != null &&
      dropLat != null &&
      dropLng != null;

  _BookingCoordinates withMissing({
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
  }) {
    return _BookingCoordinates(
      pickupLat: this.pickupLat ?? pickupLat,
      pickupLng: this.pickupLng ?? pickupLng,
      dropLat: this.dropLat ?? dropLat,
      dropLng: this.dropLng ?? dropLng,
    );
  }
}

Map<String, dynamic> _nestedMap(
  Map<String, dynamic> source,
  List<String> keys,
) {
  for (final key in keys) {
    final value = source[key];
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.cast<String, dynamic>();
  }
  return const {};
}

double? _coordinate(Map<String, dynamic> source, List<String> keys) {
  for (final key in keys) {
    final value = source[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

TripType _tripTypeFor(ClientBooking booking) {
  final raw = booking.raw;
  final value =
      [
            raw['transport_type'],
            raw['transportType'],
            raw['trip_type'],
            raw['tripType'],
          ]
          .map((value) => value?.toString().trim().toLowerCase() ?? '')
          .firstWhere((value) => value.isNotEmpty, orElse: () => '');
  return value.contains('intra') ? TripType.intraCity : TripType.interCity;
}

/// Three mutually-exclusive booking modes — same pills as web BookTruck.jsx
/// step 1 (rounded-full group, exact lucide icons Zap / PackagePlus /
/// CalendarClock, no images). Home owns the choice; the choose-trucks
/// sheet follows it.
///
/// Fluid gliding thumb (same feel as the bottom bar / history segment bar —
/// AnimatedPositioned, no backdrop blur / liquid glass here).
class _ModeHeader extends StatelessWidget {
  const _ModeHeader({required this.mode, required this.onChanged});

  final _HomeMode mode;
  final ValueChanged<_HomeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedIndex = switch (mode) {
      _HomeMode.full => 0,
      _HomeMode.part => 1,
      _HomeMode.later => 2,
    };
    final entries = [
      (
        label: l10n.tripTypeFullTruck,
        icon: AppIcons.flash_on_rounded,
        mode: _HomeMode.full,
      ),
      (
        label: l10n.tripTypePartTruck,
        icon: AppIcons.package_plus_rounded,
        mode: _HomeMode.part,
      ),
      (
        label: l10n.checkoutBookLater,
        icon: AppIcons.calendar_clock_rounded,
        mode: _HomeMode.later,
      ),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(999),
      ),
      child: SizedBox(
        height: 38,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final segmentWidth = constraints.maxWidth / 3;
            return Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOutCubic,
                  left: selectedIndex * segmentWidth,
                  top: 0,
                  bottom: 0,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA56E),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF2FA56E,
                          ).withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (var i = 0; i < entries.length; i++)
                      Expanded(
                        child: _ModePill(
                          label: entries[i].label,
                          icon: entries[i].icon,
                          selected: i == selectedIndex,
                          onTap: () => onChanged(entries[i].mode),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
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
    final color = selected ? Colors.white : context.colors.textSecondary;
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 38,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Icon(
                icon,
                key: ValueKey(selected),
                size: 14,
                color: color,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style:
                    Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ) ??
                    TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    required this.children,
  });

  final String buttonLabel;
  final VoidCallback onTap;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
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
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2FA56E),
                  foregroundColor: Colors.white,
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
    return _HeroCardShell(
      buttonLabel: 'Book truck',
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
