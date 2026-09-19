import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../broker/presentation/screens/broker_settlements_screen.dart';
import '../../data/driver_dashboard_models.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() =>
      _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(driverDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: dashboardAsync.when(
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
          final thisMonth = _sumForMonth(history, DateTime.now());
          final lastMonth = _sumForMonth(
            history,
            DateTime(DateTime.now().year, DateTime.now().month - 1),
          );

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
                _HeroBalanceCard(total: total, deliveredCount: deliveredCount),
                const SizedBox(height: 16),
                _EarningsStatsGrid(
                  thisMonth: thisMonth,
                  lastMonth: lastMonth,
                  total: total,
                  deliveredCount: deliveredCount,
                ),
                const SizedBox(height: 14),
                _AveragePerDeliveryText(average: average),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => context.push('/driver/all-earnings'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1F8F49),
                    textStyle: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  child: const Text('View all earnings'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroBalanceCard extends StatelessWidget {
  const _HeroBalanceCard({required this.total, required this.deliveredCount});

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
                        AppIcons.account_balance_wallet_outlined,
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
          Container(width: 1, height: 74, color: const Color(0xFFE4E7EC)),
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

class _EarningsStatsGrid extends StatelessWidget {
  const _EarningsStatsGrid({
    required this.thisMonth,
    required this.lastMonth,
    required this.total,
    required this.deliveredCount,
  });

  final double thisMonth;
  final double lastMonth;
  final double total;
  final int deliveredCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _EarningsStatTile(
            icon: AppIcons.currency_rupee_rounded,
            label: 'This Month',
            value: '₹${thisMonth.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EarningsStatTile(
            icon: AppIcons.account_balance_wallet_outlined,
            label: 'Last Month',
            value: '₹${lastMonth.toStringAsFixed(0)}',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _EarningsStatTile(
            icon: AppIcons.trending_up_rounded,
            label: 'Trips',
            value: deliveredCount.toString(),
            helper: '₹${total.toStringAsFixed(0)}',
          ),
        ),
      ],
    );
  }
}

class _EarningsStatTile extends StatelessWidget {
  const _EarningsStatTile({
    required this.icon,
    required this.label,
    required this.value,
    this.helper,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF2152D0), size: 20),
          const SizedBox(height: 18),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (helper != null) ...[
            const SizedBox(height: 1),
            Text(
              helper!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFF1F8F49),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AveragePerDeliveryText extends StatelessWidget {
  const _AveragePerDeliveryText({required this.average});

  final double average;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Average per delivery: ₹${average.toStringAsFixed(0)}',
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: const Color(0xFF667085),
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

double _sumForMonth(List<BrokerSettlement> history, DateTime month) {
  return history.fold<double>(0, (sum, item) {
    final settledAt = DateTime.tryParse(item.settledAt ?? '');
    if (settledAt == null ||
        settledAt.year != month.year ||
        settledAt.month != month.month) {
      return sum;
    }
    return sum + item.netEarnings;
  });
}
