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

    return SafeArea(
      top: false,
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
            padding: const EdgeInsets.all(20),
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
          final average = deliveredCount == 0 ? 0 : total / deliveredCount;
          final grouped = _groupByMonth(history);

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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Container(
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Current balance',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF98A2B3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '₹${total.toStringAsFixed(0)}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        deliveredCount == 0
                            ? 'No completed deliveries yet.'
                            : 'You have completed $deliveredCount deliveries.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF667085),
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                      const SizedBox(height: 2),
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
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => context.push('/driver/all-earnings'),
                  borderRadius: BorderRadius.circular(18),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'View all earnings',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: const Color(0xFF1F88C9),
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
                    color: const Color(0xFF98A2B3),
                  ),
                ),
              ],
            ),
          );
        },
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        'No completed trips yet.',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
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
