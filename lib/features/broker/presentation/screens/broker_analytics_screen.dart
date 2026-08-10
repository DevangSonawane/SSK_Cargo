import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'broker_settlements_screen.dart';

class BrokerAnalyticsScreen extends ConsumerWidget {
  const BrokerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_analyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Analytics'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_analyticsProvider);
          await ref.read(_analyticsProvider.future);
        },
        child: analyticsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _EmptyState(
                icon: Icons.bar_chart_rounded,
                title: 'Could not load analytics',
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (analytics) {
            final tripHistory = analytics.tripHistory;
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _MetricCard(
                        label: 'This month',
                        value: '₹${analytics.thisMonth.toStringAsFixed(0)}',
                        accent: const Color(0xFF1F88C9),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricCard(
                        label: 'Last month',
                        value: '₹${analytics.lastMonth.toStringAsFixed(0)}',
                        accent: const Color(0xFF2FA56E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Trip history',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 10),
                if (tripHistory.isEmpty)
                  const _EmptyState(
                    icon: Icons.timeline_rounded,
                    title: 'No trip history yet',
                    subtitle:
                        'Completed settlements will appear here once trips close.',
                  )
                else
                  ...tripHistory.asMap().entries.expand(
                    (entry) => [
                      _SettlementMiniCard(settlement: entry.value),
                      if (entry.key != tripHistory.length - 1)
                        const SizedBox(height: 10),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

final _analyticsProvider = FutureProvider.autoDispose<BrokerAnalytics>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    throw StateError('No active session');
  }

  final response = await ref
      .read(apiClientProvider)
      .getBrokerAnalytics(accessToken: session.tokens.accessToken);
  return BrokerAnalytics.fromJson(response);
});

class BrokerAnalytics {
  const BrokerAnalytics({
    required this.thisMonth,
    required this.lastMonth,
    required this.tripHistory,
  });

  factory BrokerAnalytics.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final history =
        data['tripHistory'] ?? data['trip_history'] ?? const <dynamic>[];
    return BrokerAnalytics(
      thisMonth: _readDouble(data['thisMonth'] ?? data['this_month']),
      lastMonth: _readDouble(data['lastMonth'] ?? data['last_month']),
      tripHistory: history is List
          ? history
                .whereType<Map<String, dynamic>>()
                .map(BrokerSettlement.fromJson)
                .toList()
          : const <BrokerSettlement>[],
    );
  }

  final double thisMonth;
  final double lastMonth;
  final List<BrokerSettlement> tripHistory;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementMiniCard extends StatelessWidget {
  const _SettlementMiniCard({required this.settlement});

  final BrokerSettlement settlement;

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
            settlement.bookingNumber,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settlement.route,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          const SizedBox(height: 8),
          Text(
            'Net earnings: ₹${settlement.netEarnings.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF2FA56E),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

double _readDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF667085), size: 34),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}
