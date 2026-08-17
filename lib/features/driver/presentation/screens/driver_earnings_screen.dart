import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../data/driver_dashboard_models.dart';

class DriverEarningsScreen extends ConsumerWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => RefreshIndicator(
            onRefresh: () async {
              final _ = await ref.refresh(driverDashboardProvider.future);
            },
            color: const Color(0xFF1F88C9),
            backgroundColor: Colors.white,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.55,
                  child: Center(
                    child: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFE23A4B)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          data: (dashboard) {
            final history = dashboard.history;
            final total = history.fold<double>(
              0,
              (sum, item) => sum + item.netEarnings,
            );
            final deliveredCount = history.length;
            final average = deliveredCount == 0 ? 0.0 : total / deliveredCount;
            final grouped = _groupByMonth(history);
            final recent = history.take(2).toList(growable: false);

            return RefreshIndicator(
              onRefresh: () async {
                final _ = await ref.refresh(driverDashboardProvider.future);
              },
              color: const Color(0xFF1F88C9),
              backgroundColor: Colors.white,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  _HeroBalanceCard(
                    total: total,
                    deliveredCount: deliveredCount,
                  ),
                  const SizedBox(height: 16),
                  _RecentEarningsCard(
                    recent: recent,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () => context.push('/driver/all-earnings'),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Center(
                        child: Text(
                          'View all earnings',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                color: const Color(0xFF1F8F49),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Average per delivery: ₹${average.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                  if (grouped.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    ...grouped.entries.expand(
                      (entry) => [
                        _MonthlyEarningsSection(
                          month: entry.key,
                          deliveries: entry.value,
                        ),
                        if (entry.key != grouped.keys.last)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFECEFF3),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({
    required this.total,
    required this.deliveredCount,
  });

  final double total;
  final int deliveredCount;

  @override
  Widget build(BuildContext context) {
    final hasBalance = total > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Balance',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '₹${total.toStringAsFixed(0)}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 16,
                        color: Color(0xFF1F8F49),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasBalance)
                      Text(
                        'Ready for payout',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1F8F49),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  deliveredCount == 0
                      ? 'You have not completed any deliveries yet.'
                      : 'You have completed $deliveredCount deliveries.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 1,
            height: 74,
            color: const Color(0xFFE4E7EC),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF8F1),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  child: Image.asset(
                    'assets/earnings/wallets.png',
                    width: 96,
                    height: 96,
                    fit: BoxFit.contain,
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

class _RecentEarningsCard extends StatelessWidget {
  const _RecentEarningsCard({required this.recent});

  final List<BrokerSettlement> recent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent Earnings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (recent.isEmpty)
            const _EmptyHistory()
          else
            ...recent.asMap().entries.expand(
              (entry) => [
                _RecentEarningRow(item: entry.value),
                if (entry.key != recent.length - 1)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      height: 1,
                      thickness: 1,
                      color: Color(0xFFECEFF3),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RecentEarningRow extends StatelessWidget {
  const _RecentEarningRow({required this.item});

  final BrokerSettlement item;

  @override
  Widget build(BuildContext context) {
    final settledAt = DateTime.tryParse(item.settledAt ?? '');
    final dateText = settledAt == null
        ? 'Recently'
        : '${settledAt.day} ${_shortMonth(settledAt.month)} ${settledAt.year} · ${_timeLabel(settledAt)}';

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF8EF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Color(0xFF1F8F49),
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.bookingNumber,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                dateText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '₹${item.netEarnings.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 6),
        const Icon(
          Icons.chevron_right_rounded,
          color: Color(0xFF98A2B3),
          size: 24,
        ),
      ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              month,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            Text(
              '₹${total.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...deliveries.asMap().entries.expand(
          (entry) => [
            _DeliveryEarningRow(
              bookingNumber: entry.value.bookingNumber,
              amount: entry.value.amount,
            ),
            if (entry.key != deliveries.length - 1) const SizedBox(height: 10),
          ],
        ),
      ],
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
        Expanded(
          child: Text(
            bookingNumber,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.payments_outlined,
            color: Color(0xFF98A2B3),
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            'No completed trips yet.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarnedTripRow {
  const _EarnedTripRow({
    required this.bookingNumber,
    required this.amount,
    required this.settledAt,
  });

  final String bookingNumber;
  final double amount;
  final DateTime? settledAt;
}

Map<String, List<_EarnedTripRow>> _groupByMonth(
  List<BrokerSettlement> history,
) {
  final buckets = <String, List<_EarnedTripRow>>{};
  for (final item in history) {
    final month = _monthLabel(item.settledAt);
    buckets
        .putIfAbsent(month, () => <_EarnedTripRow>[])
        .add(
          _EarnedTripRow(
            bookingNumber: item.bookingNumber,
            amount: item.netEarnings,
            settledAt: item.settledAt == null
                ? null
                : DateTime.tryParse(item.settledAt!),
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

String _shortMonth(int month) {
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
  return months[month - 1];
}

String _timeLabel(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour < 12 ? 'AM' : 'PM';
  return '$hour:$minute $period';
}
