import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import 'broker_settlements_screen.dart';

class BrokerAnalyticsScreen extends ConsumerWidget {
  const BrokerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_analyticsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(_analyticsProvider);
          await ref.read(_analyticsProvider.future);
        },
        child: analyticsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              _AnalyticsHeader(),
              SizedBox(height: 180),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _AnalyticsHeader(),
              const SizedBox(height: 24),
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
              padding: EdgeInsets.zero,
              children: [
                _AnalyticsHeader(onBack: () => context.pop()),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _MetricCard(
                              label: 'This month',
                              value:
                                  '₹${analytics.thisMonth.toStringAsFixed(0)}',
                              accent: const Color(0xFF1F88C9),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _MetricCard(
                              label: 'Last month',
                              value:
                                  '₹${analytics.lastMonth.toStringAsFixed(0)}',
                              accent: const Color(0xFF2FA56E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Trip history',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                    color: const Color(0xFF10245B),
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0D10245B),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.filter_list_rounded,
                                  color: Color(0xFF1769D1),
                                  size: 18,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    color: Color(0xFF1769D1),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AnalyticsHeader extends StatelessWidget {
  const _AnalyticsHeader({this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        26,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B5DCC), Color(0xFF147BDF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: onBack ?? () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Track your earnings and trip history',
                  style: TextStyle(color: Color(0xE6FFFFFF), fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: Color(0x26FFFFFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
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
      height: 174,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.trending_up_rounded, color: accent, size: 27),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF425A88),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Total earnings',
                style: TextStyle(color: Color(0xFF425A88), fontSize: 13),
              ),
            ],
          ),
          Positioned(
            top: 18,
            right: 0,
            child: Icon(Icons.chevron_right_rounded, color: accent, size: 28),
          ),
          Positioned(
            left: -16,
            right: -16,
            bottom: -14,
            child: SizedBox(
              height: 34,
              child: CustomPaint(painter: _WaveLinePainter(color: accent)),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveLinePainter extends CustomPainter {
  const _WaveLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.65)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()..moveTo(0, size.height * 0.62);
    for (var x = 0.0; x <= size.width; x += 1) {
      final y =
          size.height * 0.62 +
          (size.height * 0.18) * math.sin(x / size.width * math.pi * 2 * 3);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SettlementMiniCard extends StatelessWidget {
  const _SettlementMiniCard({required this.settlement});

  final BrokerSettlement settlement;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0EBFA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1769D1).withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            settlement.bookingNumber,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF10245B),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            settlement.route,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF5B6B91),
              fontSize: 12,
              height: 1.4,
            ),
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
