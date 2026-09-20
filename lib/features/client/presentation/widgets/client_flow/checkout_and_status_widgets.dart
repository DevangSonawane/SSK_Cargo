part of '../client_flow_widgets.dart';

class _CheckoutChoiceCard extends StatelessWidget {
  const _CheckoutChoiceCard({
    required this.selectedMethod,
    required this.advanceAmount,
    required this.loadingAdvanceAmount,
    required this.allowToBeBilled,
    required this.onSelect,
  });

  final PaymentMethod selectedMethod;
  final double? advanceAmount;
  final bool loadingAdvanceAmount;
  final bool allowToBeBilled;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    final fullSelected =
        selectedMethod != PaymentMethod.advance &&
        selectedMethod != PaymentMethod.payLater &&
        selectedMethod != PaymentMethod.toBeBilled;
    final advanceSubtitle = advanceAmount == null
        ? 'Fetching configured advance amount'
        : '${_formatRupees(advanceAmount!)} now, balance on delivery';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _CheckoutChoiceTile(
            title: 'Pay Now',
            subtitle: 'Full amount now through secure checkout',
            icon: AppIcons.lock_outline_rounded,
            selected: fullSelected,
            onTap: () => onSelect(PaymentMethod.googlePay),
          ),
          _CheckoutChoiceTile(
            title: 'Advance',
            subtitle: advanceSubtitle,
            icon: loadingAdvanceAmount
                ? AppIcons.hourglass_top_rounded
                : AppIcons.payments_outlined,
            selected: selectedMethod == PaymentMethod.advance,
            enabled: advanceAmount != null && !loadingAdvanceAmount,
            onTap: () => onSelect(PaymentMethod.advance),
          ),
          _CheckoutChoiceTile(
            title: 'To Pay',
            subtitle: 'Full amount collected by the driver on delivery',
            icon: AppIcons.local_shipping_outlined,
            selected: selectedMethod == PaymentMethod.payLater,
            onTap: () => onSelect(PaymentMethod.payLater),
          ),
          _CheckoutChoiceTile(
            title: 'To Be Billed',
            subtitle: allowToBeBilled
                ? 'Nothing collected now or on delivery'
                : 'Available after a driver is confirmed',
            icon: AppIcons.receipt_long_outlined,
            selected: selectedMethod == PaymentMethod.toBeBilled,
            enabled: allowToBeBilled,
            onTap: () => onSelect(PaymentMethod.toBeBilled),
          ),
        ],
      ),
    );
  }
}

class _BookingCompleteOverlay extends StatelessWidget {
  const _BookingCompleteOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.20)),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.78, end: 1),
            duration: const Duration(milliseconds: 520),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: 1),
              duration: const Duration(milliseconds: 360),
              curve: Curves.easeOutCubic,
              builder: (context, opacity, child) {
                return Opacity(opacity: opacity, child: child);
              },
              child: Container(
                width: 178,
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                decoration: BoxDecoration(
                  color: context.colors.surfaceElevated,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.20),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF2FA56E,
                            ).withValues(alpha: 0.22),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        AppIcons.check_rounded,
                        color: Color(0xFF2FA56E),
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Booking confirmed',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Opening activity',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckoutMethodCard extends StatelessWidget {
  const _CheckoutMethodCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF2FA56E)
        : context.colors.line;
    final iconColor = enabled
        ? selected
              ? const Color(0xFF2FA56E)
              : context.colors.textSecondary
        : context.colors.textTertiary;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 154,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: enabled
                ? selected
                      ? context.colors.brandFill
                      : context.colors.fillSubtle
                : context.colors.fillSubtle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: context.colors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  const Spacer(),
                  Icon(
                    selected
                        ? AppIcons.radio_button_checked
                        : AppIcons.radio_button_off,
                    size: 18,
                    color: enabled
                        ? selected
                              ? const Color(0xFF2FA56E)
                              : context.colors.textTertiary
                        : context.colors.textTertiary,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: enabled
                      ? context.colors.textPrimary
                      : context.colors.textTertiary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: enabled
                      ? context.colors.textSecondary
                      : context.colors.textTertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutChoiceTile extends StatelessWidget {
  const _CheckoutChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: enabled ? onTap : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(
        icon,
        color: enabled
            ? selected
                  ? accent
                  : context.colors.textSecondary
            : context.colors.textTertiary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? context.colors.textPrimary : context.colors.textTertiary,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected ? AppIcons.radio_button_checked : AppIcons.radio_button_off,
        color: enabled
            ? selected
                  ? accent
                  : context.colors.textTertiary
            : context.colors.textTertiary,
      ),
    );
  }
}

class _LocationLaunchCard extends StatelessWidget {
  const _LocationLaunchCard({
    required this.pickupValue,
    required this.dropValue,
    required this.onPickupTap,
    required this.onDropTap,
  });

  final String pickupValue;
  final String dropValue;
  final VoidCallback onPickupTap;
  final VoidCallback onDropTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPickupTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38B47A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          AppIcons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: context.colors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.colors.textTertiary,
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: context.colors.line),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onDropTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF05252),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      AppIcons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dropValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.colors.textTertiary,
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightStepRouteSummary extends StatelessWidget {
  const _WeightStepRouteSummary({
    required this.pickupAddress,
    required this.dropAddress,
    required this.onEditTap,
  });

  final String pickupAddress;
  final String dropAddress;
  final VoidCallback onEditTap;

  String _headline(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'Add location';
    }
    return parts.first;
  }

  String _subtitle(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 1) {
      return address.isEmpty ? 'Tap + to add details' : address;
    }
    return parts.skip(1).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  AppIcons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              Container(
                width: 2,
                height: 22,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: context.colors.brandBorder,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF05252),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  AppIcons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headline(pickupAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(pickupAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _headline(dropAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(dropAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: context.colors.brandFill,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                AppIcons.edit_rounded,
                size: 15,
                color: Color(0xFF2FA56E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightStepActionChip extends StatelessWidget {
  const _WeightStepActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF2FA56E),
        side: BorderSide(color: context.colors.brandBorder),
        backgroundColor: context.colors.brandFill,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _HeaderScheduleIconButton extends StatelessWidget {
  const _HeaderScheduleIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF2FA56E) : context.colors.fillSubtle,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected
                  ? const Color(0xFF2FA56E)
                  : context.colors.line,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.white : context.colors.textSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _SchedulePickerSheet extends StatefulWidget {
  const _SchedulePickerSheet({
    required this.initialDateTime,
    required this.firstDateTime,
    required this.lastDateTime,
  });

  final DateTime initialDateTime;
  final DateTime firstDateTime;
  final DateTime lastDateTime;

  @override
  State<_SchedulePickerSheet> createState() => _SchedulePickerSheetState();
}

class _SchedulePickerSheetState extends State<_SchedulePickerSheet> {
  late DateTime _selectedDate;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(widget.initialDateTime);
    _hour = widget.initialDateTime.hour;
    _minute = _roundedMinute(widget.initialDateTime.minute);
    if (_minute == 60) {
      _minute = 0;
      _hour = (_hour + 1) % 24;
    }
  }

  DateTime get _selectedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _hour,
    _minute,
  );

  int get _displayHour {
    final hour = _hour % 12;
    return hour == 0 ? 12 : hour;
  }

  bool get _isPm => _hour >= 12;

  bool get _isValid => _selectedDateTime.isAfter(widget.firstDateTime);

  static int _roundedMinute(int minute) {
    final rounded = ((minute + 14) ~/ 15) * 15;
    return rounded;
  }

  void _changeHour(int delta) {
    setState(() {
      _hour = (_hour + delta) % 24;
      if (_hour < 0) _hour += 24;
    });
  }

  void _changeMinute(int delta) {
    setState(() {
      final next = _minute + delta;
      if (next >= 60) {
        _minute = 0;
        _hour = (_hour + 1) % 24;
      } else if (next < 0) {
        _minute = 45;
        _hour = (_hour - 1) % 24;
        if (_hour < 0) _hour += 24;
      } else {
        _minute = next;
      }
    });
  }

  void _setMeridiem(bool pm) {
    setState(() {
      if (pm && _hour < 12) {
        _hour += 12;
      } else if (!pm && _hour >= 12) {
        _hour -= 12;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final firstDate = DateUtils.dateOnly(widget.firstDateTime);
    final lastDate = DateUtils.dateOnly(widget.lastDateTime);

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, bottomInset + 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Book later',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: context.colors.fillSubtle,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.close_rounded,
                            color: context.colors.textSecondary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatSchedulePreview(_selectedDateTime),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: const Color(0xFF2FA56E),
                      onPrimary: Colors.white,
                      surface: context.colors.surfaceElevated,
                      onSurface: context.colors.textPrimary,
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: _selectedDate,
                    firstDate: firstDate,
                    lastDate: lastDate,
                    currentDate: DateTime.now(),
                    onDateChanged: (date) {
                      setState(() {
                        _selectedDate = DateUtils.dateOnly(date);
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.brandFill,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: context.colors.brandBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _TimeStepper(
                          label: 'Hour',
                          value: _displayHour.toString().padLeft(2, '0'),
                          onDecrease: () => _changeHour(-1),
                          onIncrease: () => _changeHour(1),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TimeStepper(
                          label: 'Minute',
                          value: _minute.toString().padLeft(2, '0'),
                          onDecrease: () => _changeMinute(-15),
                          onIncrease: () => _changeMinute(15),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _MeridiemToggle(isPm: _isPm, onChanged: _setMeridiem),
                    ],
                  ),
                ),
                if (!_isValid) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Choose a future pickup time.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFFE23A4B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isValid
                        ? () => Navigator.of(context).pop(_selectedDateTime)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                    child: const Text('Set Time'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeStepper extends StatelessWidget {
  const _TimeStepper({
    required this.label,
    required this.value,
    required this.onDecrease,
    required this.onIncrease,
  });

  final String label;
  final String value;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RoundIconButton(icon: AppIcons.remove_rounded, onTap: onDecrease),
            const SizedBox(width: 4),
            SizedBox(
              width: 30,
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: context.colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 4),
            _RoundIconButton(icon: AppIcons.add_rounded, onTap: onIncrease),
          ],
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: context.colors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 17, color: const Color(0xFF2FA56E)),
      ),
    );
  }
}

class _MeridiemToggle extends StatelessWidget {
  const _MeridiemToggle({required this.isPm, required this.onChanged});

  final bool isPm;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.colors.surfaceElevated,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          _MeridiemButton(
            label: 'AM',
            selected: !isPm,
            onTap: () => onChanged(false),
          ),
          const SizedBox(height: 4),
          _MeridiemButton(
            label: 'PM',
            selected: isPm,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _MeridiemButton extends StatelessWidget {
  const _MeridiemButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2FA56E) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: selected ? Colors.white : context.colors.textSecondary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _formatSchedulePreview(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day} ${months[value.month - 1]}, $hour:$minute $suffix';
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : context.colors.textSecondary,
        fontWeight: FontWeight.w800,
        fontSize: 12,
      ),
      selectedColor: const Color(0xFF2FA56E),
      backgroundColor: context.colors.surface,
      side: BorderSide(
        color: selected ? const Color(0xFF2FA56E) : context.colors.line,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}

class _BookingSuccessCard extends StatelessWidget {
  const _BookingSuccessCard({
    required this.bookingReference,
    required this.onTrack,
    required this.onHome,
    this.title = 'Booking confirmed',
    this.message = 'Your booking has been successfully placed.',
  });

  final String? bookingReference;
  final VoidCallback onTrack;
  final VoidCallback onHome;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: context.colors.canvas,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colors.brandFill,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              AppIcons.check_rounded,
              color: Color(0xFF2FA56E),
              size: 58,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            bookingReference == null || bookingReference!.isEmpty
                ? 'Booking Number: Pending'
                : 'Booking Number: $bookingReference',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTrack,
                  child: const Text('Track booking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  child: const Text('Go to home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingWaitingCard extends StatelessWidget {
  const _BookingWaitingCard({
    required this.bookingReference,
    required this.driverRequest,
    required this.requestCount,
    required this.declinedCount,
    required this.searchRadiusKm,
    this.showActions = true,
    required this.onTrack,
    required this.onHome,
  });

  final String? bookingReference;
  final ClientBookingOffer? driverRequest;
  final int requestCount;
  final int declinedCount;
  final double searchRadiusKm;
  final bool showActions;
  final VoidCallback onTrack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final request = driverRequest;
    final actionable = request?.isActionableByClient == true;
    final waitingForDriverConfirmation =
        request?.isWaitingForCounterpartyConfirmation == true;
    final activeCount = (requestCount - declinedCount).clamp(0, requestCount);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.brandBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: context.colors.brandFill,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: const [
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 4,
                    color: Color(0xFF2FA56E),
                  ),
                ),
                Icon(
                  AppIcons.local_shipping_rounded,
                  color: Color(0xFF2FA56E),
                  size: 34,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            actionable
                ? 'Driver offer received'
                : waitingForDriverConfirmation
                ? 'Confirming with driver'
                : 'Finding nearby trucks',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: context.colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            actionable
                ? 'Opening the live offer popup so you can accept, reject, or counter.'
                : waitingForDriverConfirmation
                ? 'You accepted the offer. We are waiting for the driver to complete the handshake.'
                : requestCount > 0
                ? 'Drivers inside ${searchRadiusKm.round()} km have been notified. We will show the offer popup when one responds.'
                : 'Your booking is live. We are notifying drivers inside ${searchRadiusKm.round()} km.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            bookingReference == null || bookingReference!.isEmpty
                ? 'Booking Number: Pending'
                : 'Booking Number: $bookingReference',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (request != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.colors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: context.colors.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.brokerName.isNotEmpty
                        ? request.brokerName
                        : 'Driver response',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    waitingForDriverConfirmation
                        ? 'Waiting for the driver to confirm your acceptance.'
                        : request.isCountered
                        ? 'Counter offer: ${request.amountText}'
                        : request.driverTimedOut
                        ? 'Driver response timed out.'
                        : 'Latest amount: ${request.amountText}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.colors.brandBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  AppIcons.radar_rounded,
                  color: Color(0xFF2FA56E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    requestCount == 0
                        ? 'Searching live'
                        : '$activeCount active request${activeCount == 1 ? '' : 's'} nearby',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (declinedCount > 0)
                  Text(
                    '$declinedCount declined',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textTertiary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onTrack,
                    child: const Text('Open tracking'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onHome,
                    child: const Text('Go to home'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _truckCategoryForVehicle(String label) {
  final text = label.toLowerCase();
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big')) return 'large';
  return 'pooling';
}

double _parsePrice(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

double _priceValue(String value) {
  if (_parsePrice(value) <= 0) {
    return 0;
  }
  return _parsePrice(value);
}

String _priceInputText(String value) {
  final parsed = _parsePrice(value);
  if (parsed <= 0) {
    return '';
  }
  return parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 2);
}

double _readDistanceValue(Object? data, Map<String, dynamic> fallback) {
  final value = _readDoubleValue(data, fallback, const ['distance']);
  return value ?? 0;
}

double? _readDoubleValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate == null) continue;
    final parsed = double.tryParse(candidate.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

double _readMoneyValue(Object? data, Map<String, dynamic> fallback) {
  return _readDoubleValue(data, fallback, const [
        'estimated_amount',
        'estimatedAmount',
        'amount',
        'total',
        'total_amount',
        'totalAmount',
        'fare',
        'price',
        'value',
        'quoted_price',
        'quotedPrice',
      ]) ??
      0;
}

int? _readIntValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate == null) continue;
    final parsed = int.tryParse(candidate.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _readDateTimeValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate is DateTime) return candidate;
    final parsed = DateTime.tryParse(candidate?.toString().trim() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

String _displayPriceLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Loading...' : trimmed;
}

double? _readBookingCoordinate(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _extractBookingNumber(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final booking = data['booking'];
    if (booking is Map<String, dynamic>) {
      for (final key in [
        'booking_number',
        'bookingNumber',
        'booking_no',
        'bookingNo',
        'booking_ref',
        'booking_reference',
        'reference',
        'tracking_number',
      ]) {
        final value = booking[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
    for (final key in [
      'booking_number',
      'bookingNumber',
      'booking_no',
      'bookingNo',
      'booking_ref',
      'booking_reference',
      'reference',
      'id',
      'tracking_number',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
  }
  for (final key in [
    'booking_number',
    'bookingNumber',
    'booking_no',
    'bookingNo',
    'booking_ref',
    'booking_reference',
    'reference',
    'id',
    'tracking_number',
  ]) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

String _extractBookingId(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    for (final key in const ['booking_id', 'bookingId', 'id', 'uuid']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final booking = data['booking'];
    if (booking is Map<String, dynamic>) {
      for (final key in const ['booking_id', 'bookingId', 'id', 'uuid']) {
        final value = booking[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
  }
  for (final key in const ['booking_id', 'bookingId', 'id', 'uuid']) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

ClientBookingOffer? _extractDriverRequest(Map<String, dynamic> json) {
  final data = json['data'];
  final root = data is Map<String, dynamic> ? data : json;

  final candidates = <Object?>[
    root['request'],
    root['driverRequest'],
    root['driver_request'],
    root['item'],
    root,
  ];

  for (final candidate in candidates) {
    if (candidate is Map<String, dynamic>) {
      if (candidate.containsKey('id') || candidate.containsKey('status')) {
        return ClientBookingOffer.fromJson(candidate);
      }
    } else if (candidate is Map) {
      final map = candidate.cast<String, dynamic>();
      if (map.containsKey('id') || map.containsKey('status')) {
        return ClientBookingOffer.fromJson(map);
      }
    }
  }

  return null;
}

Map<String, dynamic>? _payloadAsMapLoose(Object? payload) {
  if (payload is Map<String, dynamic>) {
    return payload;
  }
  if (payload is Map) {
    return payload.cast<String, dynamic>();
  }
  return null;
}

List<ClientBookingOffer> _driverRequestsFromResponse(
  Map<String, dynamic> response,
) {
  final data = _payloadAsMapLoose(response['data']);
  final roots = <Object?>[
    data?['requests'],
    data?['driverRequests'],
    data?['driver_requests'],
    data?['items'],
    data?['results'],
    data,
    response['requests'],
    response['driverRequests'],
    response['driver_requests'],
    response,
  ];

  for (final root in roots) {
    if (root is List) {
      return root
          .whereType<Object>()
          .map(_payloadAsMapLoose)
          .whereType<Map<String, dynamic>>()
          .where((item) => item.containsKey('id') || item.containsKey('status'))
          .map(ClientBookingOffer.fromJson)
          .toList();
    }
  }

  final single = _extractDriverRequest(response);
  return single == null ? const [] : [single];
}

ClientBookingOffer? _bestFindTruckDriverRequest(
  List<ClientBookingOffer> requests,
) {
  final active =
      requests
          .where(
            (request) =>
                request.normalizedStatus != 'declined' &&
                request.normalizedStatus != 'expired',
          )
          .toList()
        ..sort((a, b) {
          final rankCompare = _findTruckRequestRank(
            b,
          ).compareTo(_findTruckRequestRank(a));
          if (rankCompare != 0) {
            return rankCompare;
          }
          final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });

  if (active.isEmpty) {
    return null;
  }
  final best = active.first;
  return _findTruckRequestRank(best) >= 2 ? best : null;
}

int _findTruckRequestRank(ClientBookingOffer request) {
  switch (request.normalizedStatus) {
    case 'accepted':
      return 4;
    case 'awaiting_confirmation':
      return 3;
    case 'countered':
      return 2;
    case 'pending':
      return 1;
    default:
      return 0;
  }
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.pickupTitle,
    this.distanceText,
    this.amountText,
    this.dropValue,
  });

  final String pickupTitle;
  final String? distanceText;
  final String? amountText;
  final String? dropValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.colors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2FA56E),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE23A4B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                      ),
                      if (distanceText != null && distanceText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          distanceText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.textSecondary,
                                fontSize: 11,
                              ),
                        ),
                      ],
                      if (amountText != null && amountText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          amountText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.infoEmphasis,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dropValue ?? 'Where is your Drop ?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ],
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
