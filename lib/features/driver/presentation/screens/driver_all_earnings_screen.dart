import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../data/driver_dashboard_models.dart';
import '../widgets/driver_currency.dart';

class DriverAllEarningsScreen extends ConsumerWidget {
  const DriverAllEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: RefreshIndicator(
            color: AppColors.brand,
            onRefresh: () async {
              ref.invalidate(driverDashboardProvider);
              try {
                await ref.read(driverDashboardProvider.future);
              } catch (_) {
                // Error UI is driven by the provider state.
              }
            },
            child: dashboardAsync.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: const [
                  _TopBar(),
                  SizedBox(height: 16),
                  _EarningsSkeleton(),
                ],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  const _TopBar(),
                  const SizedBox(height: 24),
                  _EmptyHistory(
                    icon: AppIcons.payments_outlined,
                    title: 'Could not load earnings',
                    subtitle: error
                        .toString()
                        .replaceFirst('Exception: ', ''),
                  ),
                ],
              ),
              data: (dashboard) {
                final history = dashboard.history;
                final total = history.fold<double>(
                  0,
                  (sum, item) => sum + item.netEarnings,
                );
                final grouped = _groupByMonth(history);
                final months = grouped.length;
                final deliveries = history.length;
                final average = deliveries == 0 ? 0.0 : total / deliveries;
                final monthlyTotals = grouped.entries
                    .map(
                      (entry) => (
                        label: entry.key,
                        total: entry.value.fold<double>(
                          0,
                          (sum, row) => sum + row.amount,
                        ),
                      ),
                    )
                    .toList(growable: false);

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  children: [
                    const _TopBar(),
                    const SizedBox(height: 16),
                    _HeroCard(
                      total: total,
                      average: average,
                      deliveries: deliveries,
                      months: months,
                    ),
                    const SizedBox(height: 12),
                    _KpiRow(
                      months: months,
                      deliveries: deliveries,
                      average: average,
                    ),
                    if (monthlyTotals.length >= 2) ...[
                      const SizedBox(height: 12),
                      _TrendCard(monthlyTotals: monthlyTotals),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Breakdown by month',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (grouped.isEmpty)
                      const _EmptyHistory(
                        icon: AppIcons.payments_rounded,
                        title: 'No completed trips yet',
                        subtitle:
                            'Settled earnings will show up here once trips are completed.',
                      )
                    else
                      for (final entry in grouped.entries) ...[
                        _MonthlyEarningsSection(
                          month: entry.key,
                          deliveries: entry.value,
                        ),
                        const SizedBox(height: 12),
                      ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => context.pop(),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadows.card,
            ),
            child: const Icon(
              AppIcons.arrow_back_rounded,
              color: AppColors.textPrimary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'All earnings',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// Light hero: white card, green accent strip, dark amount —
/// total earned dominates without the heavy dark block.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.total,
    required this.average,
    required this.deliveries,
    required this.months,
  });

  final double total;
  final double average;
  final int deliveries;
  final int months;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 5,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF38B47A), Color(0xFF1E7A4C)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.brand,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      const Text(
                        'TOTAL EARNED',
                        style: TextStyle(
                          color: AppColors.brandDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    formatDriverCurrency(total),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.0,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.fillSubtle,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _HeroMeta(
                            label: 'Per delivery',
                            value: formatDriverCurrency(average),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.line,
                        ),
                        Expanded(
                          child: _HeroMeta(
                            label: 'Deliveries',
                            value: '$deliveries',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 30,
                          color: AppColors.line,
                        ),
                        Expanded(
                          child: _HeroMeta(label: 'Months', value: '$months'),
                        ),
                      ],
                    ),
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

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.months,
    required this.deliveries,
    required this.average,
  });

  final int months;
  final int deliveries;
  final double average;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'Active months',
            value: '$months',
            icon: AppIcons.calendar_month_outlined,
            tint: AppColors.brandFill,
            border: AppColors.brandBorder,
            iconColor: AppColors.brandDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: 'Trips done',
            value: '$deliveries',
            icon: AppIcons.local_shipping_outlined,
            tint: const Color(0xFFEFF6FF),
            border: const Color(0xFFD7E7F4),
            iconColor: AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _KpiCard(
            label: 'Avg / trip',
            value: formatDriverCurrency(average),
            icon: AppIcons.trending_up_rounded,
            tint: AppColors.warningFill,
            border: AppColors.warningBorder,
            iconColor: AppColors.warningText,
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.tint,
    required this.border,
    required this.iconColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final Color border;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Monthly bar trend — bars grow in on load, best month in brand green.
class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.monthlyTotals});

  final List<({String label, double total})> monthlyTotals;

  @override
  Widget build(BuildContext context) {
    final max = monthlyTotals.fold<double>(
      1,
      (peak, entry) => entry.total > peak ? entry.total : peak,
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monthly trend',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Net earnings per month',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, progress, _) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (var i = 0; i < monthlyTotals.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 110 * progress,
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height:
                                  (110 *
                                          (monthlyTotals[i].total / max))
                                      .clamp(6.0, 110.0),
                              decoration: BoxDecoration(
                                gradient: monthlyTotals[i].total >= max
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF38B47A),
                                          Color(0xFF1E7A4C),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      )
                                    : null,
                                color: monthlyTotals[i].total >= max
                                    ? null
                                    : AppColors.brandBorder,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(7),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            _shortMonth(monthlyTotals[i].label),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: monthlyTotals[i].total >= max
                                  ? AppColors.brandDark
                                  : AppColors.textTertiary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MonthlyEarningsSection extends StatelessWidget {
  const _MonthlyEarningsSection({
    required this.month,
    required this.deliveries,
  });

  final String month;
  final List<_EarnedTripRow> deliveries;

  @override
  Widget build(BuildContext context) {
    final total = deliveries.fold<double>(0, (sum, row) => sum + row.amount);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.brandFill,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: AppColors.brandBorder),
                ),
                child: const Icon(
                  AppIcons.calendar_month_outlined,
                  color: AppColors.brandDark,
                  size: 19,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      month,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${deliveries.length} trip${deliveries.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatDriverCurrency(total),
                style: const TextStyle(
                  color: AppColors.brandDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 1, color: AppColors.line),
          ),
          ...deliveries.asMap().entries.expand(
            (entry) => [
              _DeliveryEarningRow(
                bookingNumber: entry.value.bookingNumber,
                amount: entry.value.amount,
              ),
              if (entry.key != deliveries.length - 1)
                const SizedBox(height: 11),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeliveryEarningRow extends StatelessWidget {
  const _DeliveryEarningRow({
    required this.bookingNumber,
    required this.amount,
  });

  final String bookingNumber;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: AppColors.brandBorder,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            bookingNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          formatDriverCurrency(amount),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 38, 24, 34),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEAF8EF), Color(0xFFDFF0E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsSkeleton extends StatelessWidget {
  const _EarningsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.line),
        ),
      );
    }

    return Column(
      children: [
        block(218),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: block(128)),
            const SizedBox(width: 12),
            Expanded(child: block(128)),
            const SizedBox(width: 12),
            Expanded(child: block(128)),
          ],
        ),
        const SizedBox(height: 12),
        block(220),
        const SizedBox(height: 12),
        block(150),
      ],
    );
  }
}

class _EarnedTripRow {
  const _EarnedTripRow({required this.bookingNumber, required this.amount});

  final String bookingNumber;
  final double amount;
}

Map<String, List<_EarnedTripRow>> _groupByMonth(List<dynamic> history) {
  final buckets = <String, List<_EarnedTripRow>>{};
  for (final item in history) {
    if (item is! BrokerSettlement) continue;
    final month = _monthLabel(item.settledAt);
    buckets
        .putIfAbsent(month, () => <_EarnedTripRow>[])
        .add(
          _EarnedTripRow(
            bookingNumber: item.bookingNumber,
            amount: item.netEarnings,
          ),
        );
  }
  return buckets;
}

String _monthLabel(String? value) {
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) {
    return 'Recent';
  }
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
  return '${months[parsed.month - 1]}, ${parsed.year}';
}

String _shortMonth(String label) {
  final comma = label.indexOf(',');
  if (comma <= 0) return label;
  return label.substring(0, comma).trim();
}
