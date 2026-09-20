part of '../client_flow_widgets.dart';

class _SheetGrabber extends StatelessWidget {
  const _SheetGrabber();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 46,
        height: 5,
        decoration: BoxDecoration(
          color: const Color(0xFFD0DAE8),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );
  }
}

class _CollapsedTruckSearchBar extends StatelessWidget {
  const _CollapsedTruckSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              AppIcons.local_shipping_rounded,
              color: Color(0xFF2FA56E),
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Choose trucks',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF0B1F3A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Icon(
            AppIcons.keyboard_arrow_up_rounded,
            color: Color(0xFF667085),
          ),
        ],
      ),
    );
  }
}

class _SearchModeCard extends StatelessWidget {
  const _SearchModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? const Color(0xFF167247)
        : const Color(0xFF475467);
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEAF7EF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF0B1F3A,
              ).withValues(alpha: selected ? 0.08 : 0.035),
              blurRadius: selected ? 16 : 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                style:
                    Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ) ??
                    const TextStyle(),
                child: Text(
                  title,
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

class _ChooseTruckCard extends StatelessWidget {
  const _ChooseTruckCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 60,
        padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FAF4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFE2E8F0),
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1F3A).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 52,
              height: 38,
              child: Image.asset(vehicle.assetPath, fit: BoxFit.contain),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: selected
                          ? const Color(0xFF167247)
                          : const Color(0xFF0B1F3A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _TruckSpec(
                    icon: AppIcons.scale_rounded,
                    label: vehicle.capacity,
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

class _TruckSpec extends StatelessWidget {
  const _TruckSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF7D8AA0)),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF6A7890),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchMethodSheet extends StatelessWidget {
  const _SearchMethodSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: const Border(
          top: BorderSide(color: Color(0xFFE6EDF5), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.14),
            blurRadius: 28,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EligibleBrokerTile extends StatelessWidget {
  const _EligibleBrokerTile({
    required this.broker,
    required this.selected,
    required this.onTap,
  });

  final _EligibleBroker broker;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = broker.isOnline
        ? const Color(0xFF2FA56E)
        : const Color(0xFF98A2B3);
    final initials = broker.name.trim().isEmpty
        ? 'B'
        : broker.name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part.characters.first.toUpperCase())
              .join();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0FAF4) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFE7EDF3),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1F3A).withValues(alpha: 0.045),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [Color(0xFF2FA56E), Color(0xFF1F8F5F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : const Color(0xFFF3F6F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? Colors.white : const Color(0xFF667085),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          broker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          broker.isOnline ? 'Online' : 'Offline',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _BrokerMetaPill(
                        icon: AppIcons.local_shipping_rounded,
                        label:
                            '${broker.truckCount} truck${broker.truckCount == 1 ? '' : 's'}',
                        highlighted: true,
                      ),
                      if (broker.serviceCity.isNotEmpty)
                        _BrokerMetaPill(
                          icon: AppIcons.location_city_rounded,
                          label: broker.serviceCity,
                        ),
                      if (broker.phone.isNotEmpty)
                        _BrokerMetaPill(
                          icon: AppIcons.call_rounded,
                          label: broker.phone,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: selected ? const Color(0xFF2FA56E) : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? const Color(0xFF2FA56E)
                      : const Color(0xFFD0D5DD),
                ),
              ),
              child: selected
                  ? const Icon(
                      AppIcons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrokerListHeader extends StatelessWidget {
  const _BrokerListHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EFE7)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.verified_user_rounded,
            color: Color(0xFF2FA56E),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$count verified broker${count == 1 ? '' : 's'} available',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF0B1F3A),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerMetaPill extends StatelessWidget {
  const _BrokerMetaPill({
    required this.icon,
    required this.label,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFE8F7EE) : const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: highlighted
                ? const Color(0xFF2FA56E)
                : const Color(0xFF667085),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: highlighted
                  ? const Color(0xFF167247)
                  : const Color(0xFF667085),
              fontWeight: FontWeight.w800,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerLoadingCard extends StatelessWidget {
  const _BrokerLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EFE8)),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Finding verified brokers for this route...',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrokerEmptyCard extends StatelessWidget {
  const _BrokerEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF4FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF667085), size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF0B1F3A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HaltingInfoCard extends StatelessWidget {
  const _HaltingInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2D58A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.timer_outlined,
            size: 20,
            color: Color(0xFFB88900),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6F5200),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryEstimateCard extends StatelessWidget {
  const _DeliveryEstimateCard({
    required this.estimatedDeliveryDate,
    required this.estimatedDeliveryDays,
    required this.expectedDeliveryHours,
    required this.isExpress,
  });

  final DateTime? estimatedDeliveryDate;
  final int? estimatedDeliveryDays;
  final double? expectedDeliveryHours;
  final bool isExpress;

  @override
  Widget build(BuildContext context) {
    final date = estimatedDeliveryDate;
    final days = estimatedDeliveryDays;
    final hours = expectedDeliveryHours;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            AppIcons.calendar_month_rounded,
            color: Color(0xFF1F88C9),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (date != null)
                  Text(
                    'Estimated delivery by ${_formatDateOnly(date)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF344054),
                      fontWeight: FontWeight.w800,
                      height: 1.35,
                    ),
                  ),
                if (hours != null) ...[
                  if (date != null) const SizedBox(height: 3),
                  Text(
                    'SLA window: ~${_formatHours(hours)}${isExpress ? ' (Express)' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ],
                if (days != null && days > 0) ...[
                  const SizedBox(height: 3),
                  Text(
                    '$days day${days == 1 ? '' : 's'} estimated from pickup.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpressBookingSummaryCard extends StatelessWidget {
  const _ExpressBookingSummaryCard({
    required this.surcharge,
    required this.expectedDeliveryHours,
    required this.insuranceIncluded,
  });

  final double surcharge;
  final double? expectedDeliveryHours;
  final bool insuranceIncluded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEA580C),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              AppIcons.bolt_rounded,
              color: Colors.white,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Express Delivery selected',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (surcharge > 0)
                      '+${_formatRupees(surcharge)} Express surcharge',
                    if (expectedDeliveryHours != null)
                      'expected in ~${_formatHours(expectedDeliveryHours!)}',
                    if (insuranceIncluded) 'transit insurance included',
                  ].join(' · '),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFC2410C),
                    fontWeight: FontWeight.w700,
                    height: 1.35,
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

class _ExpressDeliveryOptionCard extends StatelessWidget {
  const _ExpressDeliveryOptionCard({
    required this.selected,
    required this.loading,
    required this.surcharge,
    required this.expectedDeliveryHours,
    required this.insuranceIncluded,
    required this.onChanged,
  });

  final bool selected;
  final bool loading;
  final double surcharge;
  final double? expectedDeliveryHours;
  final bool insuranceIncluded;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final showQuote =
        selected &&
        !loading &&
        (surcharge > 0 || expectedDeliveryHours != null);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF7ED) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFFFFC89A) : const Color(0xFFE4EAF1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0xFFEA580C)
                  : const Color(0xFFF2F4F7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              AppIcons.bolt_rounded,
              color: selected ? Colors.white : const Color(0xFF98A2B3),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Express Delivery',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Faster deadline for intra-city bookings.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 6),
                  if (loading)
                    Text(
                      'Calculating surcharge...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFEA580C),
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  else if (showQuote)
                    Text(
                      [
                        if (surcharge > 0)
                          '+${_formatRupees(surcharge)} surcharge',
                        if (expectedDeliveryHours != null)
                          'expected in ~${_formatHours(expectedDeliveryHours!)}',
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFFEA580C),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  if (insuranceIncluded) ...[
                    const SizedBox(height: 3),
                    Text(
                      'Includes transit insurance',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF98A2B3),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
          Switch.adaptive(
            value: selected,
            onChanged: loading ? null : onChanged,
          ),
        ],
      ),
    );
  }
}
