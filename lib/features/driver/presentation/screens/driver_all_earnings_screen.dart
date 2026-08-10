import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../data/driver_dashboard_models.dart';

class DriverAllEarningsScreen extends ConsumerWidget {
  const DriverAllEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                error.toString().replaceFirst('Exception: ', ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFE23A4B)),
              ),
            ),
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
            final average = deliveries == 0 ? 0 : total / deliveries;

            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => context.pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6FB),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF101828),
                              size: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'All earnings',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF101828),
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
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
                                'All earnings summary',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF101828),
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'A complete view of your delivery earnings across all months.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF667085),
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFECEFF3),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'Months',
                                      value: '$months',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'Deliveries',
                                      value: '$deliveries',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'Total earned',
                                      value: '₹${total.toStringAsFixed(0)}',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SummaryChip(
                                      label: 'Average',
                                      value: '₹${average.toStringAsFixed(0)}',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (grouped.isEmpty)
                          const _EmptyHistory()
                        else
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
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFE),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EEF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w900,
            ),
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
        borderRadius: BorderRadius.circular(24),
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
          const Divider(height: 1, thickness: 1, color: Color(0xFFECEFF3)),
          const SizedBox(height: 12),
          ...deliveries.asMap().entries.expand(
            (entry) => [
              _DeliveryEarningRow(
                bookingNumber: entry.value.bookingNumber,
                amount: entry.value.amount,
              ),
              if (entry.key != deliveries.length - 1)
                const SizedBox(height: 10),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
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
            'No completed trips yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Settled earnings will show up here once trips are completed.',
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
