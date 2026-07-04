import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverAllEarningsScreen extends StatelessWidget {
  const DriverAllEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: Padding(
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: const Color(0xFF101828),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A complete view of your delivery earnings across all months.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF667085),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFECEFF3)),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _SummaryChip(
                                  label: 'Months',
                                  value: '3',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryChip(
                                  label: 'Deliveries',
                                  value: '9',
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
                                  value: '₹1,280',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _SummaryChip(
                                  label: 'Average',
                                  value: '₹427',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._monthlyEarnings.asMap().entries.expand(
                          (entry) => [
                            _MonthlyEarningsSection(month: entry.value),
                            if (entry.key != _monthlyEarnings.length - 1)
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
        ),
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
  });

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
  const _MonthlyEarningsSection({required this.month});

  final _MonthlyEarningsMonth month;

  @override
  Widget build(BuildContext context) {
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
                month.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF101828),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Text(
                month.total,
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
          ...month.deliveries.asMap().entries.expand(
                (entry) => [
                  _DeliveryEarningRow(
                    deliveryId: entry.value.deliveryId,
                    amount: entry.value.amount,
                  ),
                  if (entry.key != month.deliveries.length - 1)
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
    required this.deliveryId,
    required this.amount,
  });

  final String deliveryId;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            deliveryId,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          amount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _MonthlyEarningsMonth {
  const _MonthlyEarningsMonth({
    required this.label,
    required this.total,
    required this.deliveries,
  });

  final String label;
  final String total;
  final List<_MonthlyEarningEntry> deliveries;
}

class _MonthlyEarningEntry {
  const _MonthlyEarningEntry({
    required this.deliveryId,
    required this.amount,
  });

  final String deliveryId;
  final String amount;
}

const _monthlyEarnings = <_MonthlyEarningsMonth>[
  _MonthlyEarningsMonth(
    label: 'Jan, 2026',
    total: '₹345',
    deliveries: [
      _MonthlyEarningEntry(deliveryId: 'DEL-2048', amount: '₹145'),
      _MonthlyEarningEntry(deliveryId: 'DEL-2032', amount: '₹95'),
      _MonthlyEarningEntry(deliveryId: 'DEL-2019', amount: '₹105'),
    ],
  ),
  _MonthlyEarningsMonth(
    label: 'Dec, 2025',
    total: '₹520',
    deliveries: [
      _MonthlyEarningEntry(deliveryId: 'DEL-1987', amount: '₹210'),
      _MonthlyEarningEntry(deliveryId: 'DEL-1979', amount: '₹180'),
      _MonthlyEarningEntry(deliveryId: 'DEL-1965', amount: '₹130'),
    ],
  ),
  _MonthlyEarningsMonth(
    label: 'Nov, 2025',
    total: '₹415',
    deliveries: [
      _MonthlyEarningEntry(deliveryId: 'DEL-1912', amount: '₹155'),
      _MonthlyEarningEntry(deliveryId: 'DEL-1908', amount: '₹120'),
      _MonthlyEarningEntry(deliveryId: 'DEL-1896', amount: '₹140'),
    ],
  ),
];
