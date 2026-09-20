part of '../client_flow_widgets.dart';

class SelectVehicleScreen extends ConsumerStatefulWidget {
  const SelectVehicleScreen({
    super.key,
    required this.bookingData,
    this.initialIndex = 0,
  });

  final BookingData bookingData;
  final int initialIndex;

  @override
  ConsumerState<SelectVehicleScreen> createState() =>
      _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends ConsumerState<SelectVehicleScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pricingState = ref.watch(clientPricingProvider);
    final options = resolveVehicleOptions(
      tripType: widget.bookingData.tripType,
      pricing: pricingState.valueOrNull,
      isLoading: pricingState.isLoading,
    );
    final safeIndex = options.isEmpty
        ? 0
        : _selectedIndex.clamp(0, options.length - 1).toInt();
    final selected = options[safeIndex];
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 132 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(AppIcons.arrow_back_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookingSummaryCard(
                    pickupTitle: widget.bookingData.from,
                    distanceText: widget.bookingData.distanceText,
                    amountText: widget.bookingData.amountText,
                    dropValue: widget.bookingData.to,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your vehicle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...options.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VehicleOptionTile(
                        option: entry.value,
                        selected: safeIndex == entry.key,
                        onTap: () => setState(() => _selectedIndex = entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: bottomInset + 12,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(selected);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text('Proceed with ${selected.label}'),
                    ),
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

class _VehicleOptionTile extends StatelessWidget {
  const _VehicleOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Per-vehicle accent brightened slightly on dark surfaces so the
    // selected border + label keep their identity without going muddy.
    final accent =
        Theme.of(context).brightness == Brightness.dark
            ? Color.lerp(option.accentColor, Colors.white, 0.3)!
            : option.accentColor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? accent : context.colors.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.045 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1.14 : 1.0,
              curve: Curves.easeOutBack,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(option.assetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.capacity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _displayPriceLabel(option.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? 'Selected' : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? accent : Colors.transparent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClientBottomBar extends StatelessWidget {
  const ClientBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final items = <_ClientNavItem>[
      const _ClientNavItem(label: 'Home', icon: LucideIcons.house),
      const _ClientNavItem(label: 'Activity', icon: LucideIcons.map),
      const _ClientNavItem(label: 'Profile', icon: LucideIcons.user),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(72, 0, 72, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.colors.surfaceElevated.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: context.colors.surfaceElevated.withValues(alpha: 0.72),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: SizedBox(
                height: 58,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / items.length;
                    const indicatorSize = 50.0;
                    final selectedIndex = currentIndex.clamp(
                      0,
                      items.length - 1,
                    );
                    final left =
                        (itemWidth * selectedIndex) +
                        ((itemWidth - indicatorSize) / 2);

                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 360),
                          curve: Curves.easeOutCubic,
                          left: left,
                          top: 4,
                          width: indicatorSize,
                          height: indicatorSize,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2FA56E),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF2FA56E,
                                  ).withValues(alpha: 0.34),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            for (var index = 0; index < items.length; index++)
                              Expanded(
                                child: _ClientBottomBarItem(
                                  item: items[index],
                                  selected: selectedIndex == index,
                                  onTap: () => onTap(index),
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ClientNavItem {
  const _ClientNavItem({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _ClientBottomBarItem extends StatelessWidget {
  const _ClientBottomBarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _ClientNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.white : context.colors.textSecondary;

    return Tooltip(
      message: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: onTap,
        child: Center(
          child: SizedBox(
            width: 50,
            height: 50,
            child: AnimatedScale(
              scale: selected ? 1.14 : 1,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              child: Icon(item.icon, size: 22, color: iconColor),
            ),
          ),
        ),
      ),
    );
  }
}
