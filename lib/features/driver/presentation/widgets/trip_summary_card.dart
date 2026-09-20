import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import '../../data/driver_dashboard_models.dart';

/// Trip history row in the Rapido / Ola / Uber language: a clean light card
/// with date + status on top, a compact pickup → drop rail, and a
/// truck • distance + fare footer. Used by the Active tab history sections
/// and the All Trips screen.
class TripSummaryCard extends StatelessWidget {
  const TripSummaryCard({super.key, required this.trip, required this.onTap});

  final DriverTripSummary trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bookingId = trip.bookingId.isNotEmpty
        ? trip.bookingId
        : trip.bookingNumber;
    final status = trip.status.trim().toLowerCase();
    final statusLabel = tripStatusLabel(trip.status);
    final isCompleted =
        status == 'completed' ||
        status == 'delivered' ||
        status == 'paid' ||
        status == 'settled';
    final isCancelled =
        status == 'cancelled' ||
        status == 'canceled' ||
        status == 'rejected' ||
        status == 'declined' ||
        status == 'expired';
    final statusBg = isCompleted
        ? AppColors.brandTint
        : isCancelled
        ? AppColors.dangerFill
        : AppColors.warningFill;
    final statusBorder = isCompleted
        ? AppColors.brandBorder
        : isCancelled
        ? AppColors.dangerBorder
        : AppColors.warningBorder;
    final statusText = isCompleted
        ? AppColors.brandDark
        : isCancelled
        ? AppColors.dangerText
        : AppColors.warningText;
    final dropDot = isCompleted
        ? AppColors.brand
        : isCancelled
        ? AppColors.dangerText
        : AppColors.warningText;
    final amountText = isCancelled
        ? '—'
        : trip.amount > 0
        ? '₹${trip.amount.toStringAsFixed(0)}'
        : '₹0';
    final from = trip.fromLocation.isNotEmpty
        ? _locationLead(trip.fromLocation)
        : 'Location unavailable';
    final to = trip.toLocation.isNotEmpty
        ? _locationLead(trip.toLocation)
        : 'Location unavailable';
    final dateLine = [
      _formatTripTimestamp(
        trip.bookingTime.isNotEmpty ? trip.bookingTime : '—',
      ),
      if (bookingId.isNotEmpty) bookingId,
    ].join(' • ');
    final metaLine = [
      trip.truckReg.isEmpty ? 'Cargo' : trip.truckReg,
      trip.distanceLabel,
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 13, 14, 13),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dateLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    label: statusLabel,
                    background: statusBg,
                    border: statusBorder,
                    textColor: statusText,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      children: [
                        _RailDot(color: AppColors.textTertiary),
                        Container(
                          width: 2,
                          height: 24,
                          color: AppColors.line,
                        ),
                        _RailDot(color: dropDot),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          from,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textHeading,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          to,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textHeading,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 1, color: AppColors.fillSubtle),
              const SizedBox(height: 11),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metaLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    amountText,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isCancelled
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 19,
                    ),
                  ),
                  const Icon(
                    AppIcons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.background,
    required this.border,
    required this.textColor,
  });

  final String label;
  final Color background;
  final Color border;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _RailDot extends StatelessWidget {
  const _RailDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

/// Human-friendly driver trip status label shared by the history cards and
/// the active delivery card.
String tripStatusLabel(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'In Progress';
  }
  if (normalized == 'delivered') {
    return 'Delivered';
  }
  if (normalized == 'accepted' ||
      normalized == 'confirmed' ||
      normalized == 'en_route_pickup' ||
      normalized == 'en route' ||
      normalized == 'en_route' ||
      normalized == 'in_transit' ||
      normalized == 'in transit' ||
      normalized == 'picked_up' ||
      normalized == 'picked up') {
    return 'In Progress';
  }
  return normalized
      .split(RegExp(r'[_\s-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');
}

String _locationLead(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return '—';
  }
  final parts = trimmed.split(RegExp(r'\s[-|•]\s|,'));
  final first = parts.first.trim();
  return first.isEmpty ? trimmed : first;
}

String _formatTripTimestamp(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value;
  }

  final local = parsed.toLocal();
  final now = DateTime.now();
  final sameDay =
      local.year == now.year &&
      local.month == now.month &&
      local.day == now.day;
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
  final dateLabel = sameDay
      ? 'Today'
      : '${months[local.month - 1]} ${local.day}';
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = local.hour >= 12 ? 'PM' : 'AM';
  return '$dateLabel, $hour:$minute $period';
}
