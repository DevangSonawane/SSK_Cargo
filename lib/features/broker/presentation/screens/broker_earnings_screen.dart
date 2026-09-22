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
            try {
              await ref.read(_brokerEarningsProvider.future);
            } catch (_) {
              // Error UI is driven by the provider state.
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              BrokerBackButton(onTap: () => context.go('/broker/profile')),
              const SizedBox(height: 12),
              const Text(
                'Earnings',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Revenue, momentum and settlements at a glance.',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 18),
              earningsAsync.when(
                loading: () => const _EarningsSkeleton(),
                error: (error, _) => _EarningsStateCard(
                  icon: AppIcons.payments_outlined,
                  title: 'Failed to load earnings',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                  actionLabel: 'Try again',
                  onAction: () => ref.invalidate(_brokerEarningsProvider),
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

    final double comparisonMax = math
        .max(math.max(bundle.thisMonth, bundle.lastMonth), 1)
        .toDouble();
    final change = bundle.lastMonth > 0
        ? ((bundle.thisMonth - bundle.lastMonth) / bundle.lastMonth * 100)
              .round()
        : null;

    final recent = bundle.settlements.take(5).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NetHeroCard(totalNet: totalNet, change: change),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Gross revenue',
                value: _formatCurrency(totalGross),
                icon: AppIcons.currency_rupee_rounded,
                tint: AppColors.brandFill,
                border: AppColors.brandBorder,
                iconColor: AppColors.brandDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Platform fees',
                value: _formatCurrency(totalFees),
                icon: AppIcons.account_balance_wallet_rounded,
                tint: AppColors.warningFill,
                border: AppColors.warningBorder,
                iconColor: AppColors.warningText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _MomentumCard(
          thisMonth: bundle.thisMonth,
          lastMonth: bundle.lastMonth,
          comparisonMax: comparisonMax,
          change: change,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Recent settlements',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/broker/settings/settlements'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.brandDark,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'See all',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (bundle.settlements.isEmpty)
          const _EarningsStateCard(
            icon: AppIcons.receipt_long_rounded,
            title: 'No settlements yet',
            subtitle:
                'Completed settlements will appear here with route and payout details.',
          )
        else
          for (final settlement in recent) ...[
            _SettlementCard(settlement: settlement),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

// ---------- hero ----------

class _NetHeroCard extends StatelessWidget {
  const _NetHeroCard({required this.totalNet, required this.change});

  final double totalNet;
  final int? change;

  @override
  Widget build(BuildContext context) {
    final positive = (change ?? 0) >= 0;
    final delta = change;
    final trendBg = delta == null
        ? AppColors.fillSubtle
        : delta == 0
        ? AppColors.fillSubtle
        : positive
        ? AppColors.brandFill
        : AppColors.dangerFill;
    final trendFg = delta == null || delta == 0
        ? AppColors.textSecondary
        : positive
        ? AppColors.brandDark
        : AppColors.dangerText;
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
                      const Text(
                        'NET EARNINGS',
                        style: TextStyle(
                          color: AppColors.brandDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const Spacer(),
                      if (delta != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: trendBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                delta == 0
                                    ? AppIcons.remove_rounded
                                    : positive
                                    ? AppIcons.trending_up_rounded
                                    : AppIcons.trending_down_rounded,
                                color: trendFg,
                                size: 13,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${positive && delta != 0 ? '+' : ''}$delta%',
                                style: TextStyle(
                                  color: trendFg,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatCurrency(totalNet),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.8,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    delta == null
                        ? 'Across all settled trips'
                        : 'Across all settled trips • vs last month',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () =>
                          context.push('/broker/settings/settlements'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'View settlements',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
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

// ---------- mini stats ----------

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
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
      padding: const EdgeInsets.all(15),
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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: border),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- momentum ----------

class _MomentumCard extends StatelessWidget {
  const _MomentumCard({
    required this.thisMonth,
    required this.lastMonth,
    required this.comparisonMax,
    required this.change,
  });

  final double thisMonth;
  final double lastMonth;
  final double comparisonMax;
  final int? change;

  @override
  Widget build(BuildContext context) {
    final delta = change;
    return Container(
      padding: const EdgeInsets.all(18),
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
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Monthly momentum',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _MonthBar(
                  label: 'This month',
                  value: _formatCurrency(thisMonth),
                  fraction: thisMonth / comparisonMax,
                  barColor: AppColors.brand,
                  valueColor: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _MonthBar(
                  label: 'Last month',
                  value: _formatCurrency(lastMonth),
                  fraction: lastMonth / comparisonMax,
                  barColor: AppColors.line,
                  valueColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          if (delta != null) ...[
            const SizedBox(height: 14),
            _TrendLine(change: delta),
          ],
        ],
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.barColor,
    required this.valueColor,
  });

  final String label;
  final String value;
  final double fraction;
  final Color barColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: valueColor,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: fraction.clamp(0, 1)),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: animated,
                minHeight: 9,
                backgroundColor: AppColors.fillSubtle,
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TrendLine extends StatelessWidget {
  const _TrendLine({required this.change});

  final int change;

  @override
  Widget build(BuildContext context) {
    final positive = change > 0;
    final neutral = change == 0;
    final color = neutral
        ? AppColors.textSecondary
        : positive
        ? AppColors.brandDark
        : AppColors.dangerIcon;
    final bg = neutral
        ? AppColors.fillSubtle
        : positive
        ? AppColors.brandFill
        : AppColors.dangerFill;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(
            neutral
                ? AppIcons.remove_rounded
                : positive
                ? AppIcons.trending_up_rounded
                : AppIcons.trending_down_rounded,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              neutral
                  ? 'Flat vs last month — steady performance.'
                  : positive
                  ? 'Up $change% vs last month — keep the momentum.'
                  : 'Down ${change.abs()}% vs last month.',
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- settlements ----------

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement});

  final BrokerSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final normalized = settlement.status.trim().toLowerCase();
    final pillColor = switch (normalized) {
      'paid' || 'settled' => AppColors.brandDark,
      'pending' => AppColors.warningText,
      _ => AppColors.textSecondary,
    };
    final pillBg = switch (normalized) {
      'paid' || 'settled' => AppColors.brandFill,
      'pending' => AppColors.warningFill,
      _ => AppColors.fillSubtle,
    };
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.brandFill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.brandBorder),
            ),
            child: const Icon(
              AppIcons.receipt_long_rounded,
              color: AppColors.brandDark,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        settlement.bookingNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: pillBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        settlement.status.isEmpty
                            ? 'Pending'
                            : settlement.status,
                        style: TextStyle(
                          color: pillColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  settlement.route.isEmpty
                      ? _prettyDate(settlement.settledAt)
                      : settlement.route,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _formatCurrency(settlement.netEarnings),
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
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

// ---------- states ----------

class _EarningsSkeleton extends StatelessWidget {
  const _EarningsSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height, {double? width}) {
      return Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line),
        ),
      );
    }

    return Column(
      children: [
        block(210),
        const SizedBox(height: 12),
        Row(
          children: [Expanded(child: block(118)), const SizedBox(width: 12), Expanded(child: block(118))],
        ),
        const SizedBox(height: 14),
        block(190),
        const SizedBox(height: 14),
        block(86),
        const SizedBox(height: 10),
        block(86),
      ],
    );
  }
}

class _EarningsStateCard extends StatelessWidget {
  const _EarningsStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
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
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF8EF), Color(0xFFDFF0E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: AppColors.brand),
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
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brand,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 26,
                  vertical: 12,
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
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

String _prettyDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Settlement pending';
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw.trim();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}
