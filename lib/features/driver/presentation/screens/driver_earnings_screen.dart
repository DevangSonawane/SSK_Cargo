import 'package:flutter/material.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Text(
            'Earnings',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _EarningsSummaryCard(
            title: 'This week',
            amount: '₹18,450',
            subtitle: 'Up 12% from last week',
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  title: 'Today',
                  value: '₹2,150',
                  accent: Color(0xFF1F88C9),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Pending',
                  value: '₹4,300',
                  accent: Color(0xFF2FA56E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _MetricCard(
                  title: 'Trips',
                  value: '14',
                  accent: Color(0xFF7A5AF8),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _MetricCard(
                  title: 'Payouts',
                  value: '2',
                  accent: Color(0xFF12B76A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _EarningsListTile(
            title: 'Mumbai to Pune',
            amount: '+₹1,200',
            subtitle: 'Completed today',
          ),
          const SizedBox(height: 10),
          _EarningsListTile(
            title: 'Delhi pickup',
            amount: '+₹950',
            subtitle: 'Pending settlement',
          ),
        ],
      ),
    );
  }
}

class _EarningsSummaryCard extends StatelessWidget {
  const _EarningsSummaryCard({
    required this.title,
    required this.amount,
    required this.subtitle,
  });

  final String title;
  final String amount;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1F88C9).withValues(alpha: 0.96),
            const Color(0xFF7A5AF8).withValues(alpha: 0.96),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsListTile extends StatelessWidget {
  const _EarningsListTile({
    required this.title,
    required this.amount,
    required this.subtitle,
  });

  final String title;
  final String amount;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.payments_rounded, color: Color(0xFF1F88C9)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF12B76A),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
