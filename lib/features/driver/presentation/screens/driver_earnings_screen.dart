import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
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
                  '₹18,450',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Congratulations you have done 2 deliveries!',
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
    return Column(
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
