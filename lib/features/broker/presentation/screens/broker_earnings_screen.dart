import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import '../widgets/broker_flow_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'broker_settlements_screen.dart';

final _brokerEarningsProvider = FutureProvider.autoDispose<_EarningsBundle>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) throw StateError('No active session');

  final api = ref.watch(apiClientProvider);
  final responses = await Future.wait([
    api.getBrokerSettlements(
      accessToken: session.tokens.accessToken,
      page: 1,
      limit: 100,
    ),
    api.getBrokerAnalytics(accessToken: session.tokens.accessToken),
  ]);

  final settlementData = _asMap(responses[0]['data']);
  final rawSettlements =
      settlementData['settlements'] ??
      settlementData['items'] ??
      responses[0]['settlements'] ??
      responses[0]['items'] ??
      const [];
  final settlements = rawSettlements is List
      ? rawSettlements
            .whereType<Map<String, dynamic>>()
            .map(BrokerSettlement.fromJson)
            .toList()
      : const <BrokerSettlement>[];

  final analyticsData = _asMap(responses[1]['data']);
  final analytics = analyticsData.isEmpty ? responses[1] : analyticsData;

  return _EarningsBundle(
    settlements: settlements,
    thisMonth: _readDouble(analytics['thisMonth'] ?? analytics['this_month']),
    lastMonth: _readDouble(analytics['lastMonth'] ?? analytics['last_month']),
  );
});

class BrokerEarningsScreen extends ConsumerWidget {
  const BrokerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(_brokerEarningsProvider);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: () async {
            ref.invalidate(_brokerEarningsProvider);
            await ref.read(_brokerEarningsProvider.future);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              BrokerBackButton(onTap: () => context.go('/broker/profile')),
              const SizedBox(height: 10),
              Text(
                'Earnings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Broker revenue and settlement performance.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              earningsAsync.when(
                loading: () => const _EarningsLoadingState(),
                error: (error, _) => _EarningsEmptyState(
                  title: 'Failed to load earnings',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
                data: (bundle) => _EarningsContent(bundle: bundle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EarningsContent extends StatelessWidget {
  const _EarningsContent({required this.bundle});

  final _EarningsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final totalGross = bundle.settlements.fold<double>(
      0,
      (sum, row) => sum + row.amount,
    );
    final totalFees = bundle.settlements.fold<double>(
      0,
      (sum, row) => sum + row.platformFee,
    );
    final totalNet = bundle.settlements.fold<double>(
      0,
      (sum, row) => sum + row.netEarnings,
    );

    final comparisonMax = math.max(
      math.max(bundle.thisMonth, bundle.lastMonth),
      1,
    );
    final change = bundle.lastMonth > 0
        ? ((bundle.thisMonth - bundle.lastMonth) / bundle.lastMonth * 100)
              .round()
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EarningsStatCard(
          label: 'Gross Revenue',
          value: _formatCurrency(totalGross),
          icon: AppIcons.currency_rupee_rounded,
          color: AppColors.brand,
          background: AppColors.brandFill,
        ),
        const SizedBox(height: 12),
        _EarningsStatCard(
          label: 'Platform Fees',
          value: _formatCurrency(totalFees),
          icon: AppIcons.account_balance_wallet_rounded,
          color: AppColors.dangerIcon,
          background: const Color(0xFFFDECEC),
        ),
        const SizedBox(height: 12),
        _EarningsStatCard(
          label: 'Net Earnings',
          value: _formatCurrency(totalNet),
          icon: AppIcons.trending_up_rounded,
          color: AppColors.brand,
          background: AppColors.brandFill,
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Monthly Comparison',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MonthValue(
                      label: 'This Month',
                      value: _formatCurrency(bundle.thisMonth),
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 42,
                    color: AppColors.line,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _MonthValue(
                      label: 'Last Month',
                      value: _formatCurrency(bundle.lastMonth),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (change != null) ...[
                const SizedBox(height: 12),
                _TrendPill(change: change),
              ],
              const SizedBox(height: 14),
              _ProgressBar(
                value: bundle.thisMonth / comparisonMax,
                color: AppColors.brand,
              ),
              const SizedBox(height: 7),
              _ProgressBar(
                value: bundle.lastMonth / comparisonMax,
                color: AppColors.line,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (bundle.settlements.isEmpty)
          const _EarningsEmptyState(
            title: 'No settlements yet',
            subtitle: 'Completed settlements will appear here.',
          )
        else
          for (final settlement in bundle.settlements) ...[
            _SettlementRow(settlement: settlement),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _EarningsStatCard extends StatelessWidget {
  const _EarningsStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
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

class _MonthValue extends StatelessWidget {
  const _MonthValue({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final positive = change > 0;
    final neutral = change == 0;
    final color = neutral
        ? AppColors.textSecondary
        : positive
        ? AppColors.brand
        : AppColors.dangerIcon;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              neutral
                  ? AppIcons.remove_rounded
                  : positive
                  ? AppIcons.trending_up_rounded
                  : AppIcons.trending_down_rounded,
              color: color,
              size: 15,
            ),
            const SizedBox(width: 5),
            Text(
              '${positive ? '+' : ''}$change% vs last month',
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0, 1),
        minHeight: 8,
        backgroundColor: AppColors.line,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.settlement});

  final BrokerSettlement settlement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  settlement.bookingNumber,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settlement.route.isEmpty ? 'Route pending' : settlement.route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(settlement.netEarnings),
            style: const TextStyle(
              color: AppColors.brand,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _EarningsLoadingState extends StatelessWidget {
  const _EarningsLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 80),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EarningsEmptyState extends StatelessWidget {
  const _EarningsEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _EarningsBundle {
  const _EarningsBundle({
    required this.settlements,
    required this.thisMonth,
    required this.lastMonth,
  });

  final List<BrokerSettlement> settlements;
  final double thisMonth;
  final double lastMonth;
}

Map<String, dynamic> _asMap(Object? value) {
  return value is Map
      ? value.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _formatCurrency(double value) {
  return 'Rs ${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
}
