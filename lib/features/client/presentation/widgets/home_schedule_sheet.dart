import 'package:flutter/material.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../l10n/app_localizations.dart';

Future<DateTime?> showHomeScheduleSheet(
  BuildContext context, {
  required DateTime initialDateTime,
}) {
  final now = DateTime.now();
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (context) => HomeScheduleSheet(
      initialDateTime: initialDateTime,
      firstDateTime: now,
      lastDateTime: now.add(const Duration(days: 180)),
    ),
  );
}

class HomeScheduleSheet extends StatefulWidget {
  const HomeScheduleSheet({
    super.key,
    required this.initialDateTime,
    required this.firstDateTime,
    required this.lastDateTime,
  });

  final DateTime initialDateTime;
  final DateTime firstDateTime;
  final DateTime lastDateTime;

  @override
  State<HomeScheduleSheet> createState() => _HomeScheduleSheetState();
}

class _HomeScheduleSheetState extends State<HomeScheduleSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  DateTime get _selectedDateTime => DateTime(
    _selectedDate.year,
    _selectedDate.month,
    _selectedDate.day,
    _selectedTime.hour,
    _selectedTime.minute,
  );

  bool get _isFuture => _selectedDateTime.isAfter(widget.firstDateTime);

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDateTime.isAfter(widget.firstDateTime)
        ? widget.initialDateTime
        : widget.firstDateTime.add(const Duration(hours: 3));
    _selectedDate = DateUtils.dateOnly(initial);
    _selectedTime = TimeOfDay.fromDateTime(initial);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateUtils.dateOnly(widget.firstDateTime),
      lastDate: DateUtils.dateOnly(widget.lastDateTime),
      builder: _pickerTheme,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = DateUtils.dateOnly(picked));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      initialEntryMode: TimePickerEntryMode.dial,
      builder: _pickerTheme,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedTime = picked);
  }

  Widget _pickerTheme(BuildContext context, Widget? child) {
    final colors = context.colors;
    final base = Theme.of(context);
    final scheme = base.colorScheme.copyWith(
      primary: const Color(0xFF2FA56E),
      onPrimary: Colors.white,
      surface: colors.surfaceElevated,
      onSurface: colors.textPrimary,
    );
    return Theme(
      data: base.copyWith(
        colorScheme: scheme,
        dialogTheme: DialogThemeData(
          backgroundColor: colors.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    final clearance = viewInsets > 0 ? 12.0 : 92.0;
    final selected = _selectedDateTime;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 0, 12, viewInsets + clearance),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: context.colors.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: context.colors.brandBorder),
                      ),
                      child: const Icon(
                        AppIcons.calendar_clock_rounded,
                        color: Color(0xFF2FA56E),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pickup date & time',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _summary(l10n, selected),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _isFuture
                                      ? context.colors.textSecondary
                                      : context.colors.dangerEmphasis,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(AppIcons.close_rounded),
                      color: context.colors.textSecondary,
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.fillSubtle,
                        fixedSize: const Size(36, 36),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _ScheduleField(
                        label: 'Date',
                        value: _dateLabel(l10n, _selectedDate),
                        icon: AppIcons.calendar_today_rounded,
                        onTap: _pickDate,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _ScheduleField(
                        label: 'Time',
                        value: _timeLabel(l10n, _selectedTime),
                        icon: AppIcons.schedule_rounded,
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _ScheduleNotice(
                  color: _isFuture
                      ? context.colors.textTertiary
                      : context.colors.dangerEmphasis,
                  text: _isFuture
                      ? "We'll notify nearby drivers or brokers about 2 hours before pickup."
                      : l10n.chooseFuturePickupTime,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: !_isFuture
                        ? null
                        : () => Navigator.of(context).pop(selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFD8E1ED),
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(l10n.setTime),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _summary(AppLocalizations l10n, DateTime value) {
    return '${_dateLabel(l10n, value)} at ${_timeLabel(l10n, TimeOfDay.fromDateTime(value))}';
  }

  String _dateLabel(AppLocalizations l10n, DateTime value) {
    final today = DateUtils.dateOnly(DateTime.now());
    final date = DateUtils.dateOnly(value);
    final diff = date.difference(today).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    final months = <String>[
      l10n.monthJan,
      l10n.monthFeb,
      l10n.monthMar,
      l10n.monthApr,
      l10n.monthMay,
      l10n.monthJun,
      l10n.monthJul,
      l10n.monthAug,
      l10n.monthSep,
      l10n.monthOct,
      l10n.monthNov,
      l10n.monthDec,
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _timeLabel(AppLocalizations l10n, TimeOfDay value) {
    final hour12 = value.hour == 0
        ? 12
        : value.hour > 12
        ? value.hour - 12
        : value.hour;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? l10n.timePeriodPm : l10n.timePeriodAm;
    return '$hour12:$minute $period';
  }
}

class _ScheduleField extends StatelessWidget {
  const _ScheduleField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.colors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: context.colors.textTertiary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: context.colors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleNotice extends StatelessWidget {
  const _ScheduleNotice({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.info_outline_rounded, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
