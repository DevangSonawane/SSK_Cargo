import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class BrokerSettlementsScreen extends ConsumerStatefulWidget {
  const BrokerSettlementsScreen({super.key});

  @override
  ConsumerState<BrokerSettlementsScreen> createState() =>
      _BrokerSettlementsScreenState();
}

class _BrokerSettlementsScreenState
    extends ConsumerState<BrokerSettlementsScreen> {
  static const _query = (page: 1, limit: 50);

  Future<void> _refresh() async {
    ref.invalidate(_settlementsProvider(_query));
    await ref.read(_settlementsProvider(_query).future);
  }

  @override
  Widget build(BuildContext context) {
    final settlementsAsync = ref.watch(_settlementsProvider(_query));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: settlementsAsync.when(
          loading: () => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: const [
              _SettlementsHeader(),
              SizedBox(height: 120),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const _SettlementsHeader(),
              const SizedBox(height: 24),
              _EmptyState(
                icon: Icons.payments_rounded,
                title: 'Could not load settlements',
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (settlements) {
            if (settlements.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  _SettlementsHeader(),
                  SizedBox(height: 24),
                  _EmptyState(
                    icon: Icons.payments_rounded,
                    title: 'No settlements yet',
                    subtitle:
                        'Paid and pending settlement records will appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: settlements.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const _SettlementsHeader();
                }
                final settlement = settlements[index - 1];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _showSettlementDetails(context, settlement),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EDF2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                settlement.bookingNumber,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF101828),
                                    ),
                              ),
                            ),
                            _StatusPill(status: settlement.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          settlement.route,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: const Color(0xFF667085)),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Gross: ₹${settlement.amount.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF101828),
                                  ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Net: ₹${settlement.netEarnings.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF1F88C9),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showSettlementDetails(
    BuildContext context,
    BrokerSettlement settlement,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1E5EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  settlement.bookingNumber,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(settlement.route),
                const SizedBox(height: 16),
                _detailLine(
                  'Amount',
                  '₹${settlement.amount.toStringAsFixed(0)}',
                ),
                _detailLine(
                  'Platform fee',
                  '₹${settlement.platformFee.toStringAsFixed(2)}',
                ),
                _detailLine(
                  'Net earnings',
                  '₹${settlement.netEarnings.toStringAsFixed(2)}',
                ),
                _detailLine('Status', settlement.status),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1F88C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SettlementsHeader extends StatelessWidget {
  const _SettlementsHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        MediaQuery.of(context).padding.top + 6,
        12,
        10,
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFEAF3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFF10245B),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settlements',
                  style: TextStyle(
                    color: Color(0xFF10245B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'View all settlement requests',
                  style: TextStyle(
                    color: Color(0xFF5B6B91),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x0D10245B),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.filter_alt_outlined,
              color: Color(0xFF60708D),
              size: 19,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement, required this.onTap});

  final BrokerSettlement settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0EBFA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1769D1).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEAF3FF),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF1769D1),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    settlement.bookingNumber,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF10245B),
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _StatusPill(status: settlement.status),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: onTap,
                  icon: const Icon(Icons.more_vert_rounded),
                  color: const Color(0xFF10245B),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(width: 28, height: 40),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFF8795AD), size: 14),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    settlement.route.isEmpty ? 'Route not provided' : settlement.route,
                    style: const TextStyle(
                      color: Color(0xFF5B6B91),
                      fontSize: 9,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            const Divider(height: 1, color: Color(0xFFDCE8F8)),
            const SizedBox(height: 7),
            Row(
              children: [
                Expanded(
                  child: _SettlementAmount(
                    label: 'Gross',
                    amount: '₹${settlement.amount.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_outlined,
                    color: const Color(0xFF10A866),
                  ),
                ),
                Container(width: 1, height: 28, color: const Color(0xFFE1E8F2)),
                Expanded(
                  child: _SettlementAmount(
                    label: 'Net',
                    amount: '₹${settlement.netEarnings.toStringAsFixed(0)}',
                    icon: Icons.payments_outlined,
                    color: const Color(0xFF1769D1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettlementAmount extends StatelessWidget {
  const _SettlementAmount({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
  });

  final String label;
  final String amount;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Color(0xFF5B6B91), fontSize: 8)),
            const SizedBox(height: 2),
            Text(
              amount,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ],
    );
  }
}

final _settlementsProvider = FutureProvider.autoDispose
    .family<List<BrokerSettlement>, ({int page, int limit})>((
      ref,
      query,
    ) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .read(apiClientProvider)
          .getBrokerSettlements(
            accessToken: session.tokens.accessToken,
            page: query.page,
            limit: query.limit,
          );
      final data = response['data'];
      final items = data is Map<String, dynamic>
          ? (data['settlements'] ?? data['items'] ?? data['results'])
          : response['settlements'] ?? response['items'] ?? response['results'];
      final list = items is List ? items : const <dynamic>[];
      return list
          .whereType<Map<String, dynamic>>()
          .map(BrokerSettlement.fromJson)
          .toList();
    });

class BrokerSettlement {
  const BrokerSettlement({
    required this.id,
    required this.bookingId,
    required this.bookingNumber,
    required this.route,
    required this.truck,
    required this.driver,
    required this.amount,
    required this.platformFee,
    required this.netEarnings,
    required this.status,
    required this.settledAt,
  });

  factory BrokerSettlement.fromJson(Map<String, dynamic> json) {
    return BrokerSettlement(
      id: json['id']?.toString() ?? '',
      bookingId:
          json['bookingId']?.toString() ?? json['booking_id']?.toString() ?? '',
      bookingNumber:
          json['bookingNumber']?.toString() ??
          json['booking_number']?.toString() ??
          'Booking',
      route: json['route']?.toString() ?? '',
      truck: json['truck']?.toString() ?? '',
      driver: json['driver']?.toString() ?? '',
      amount: _readDouble(json['amount']),
      platformFee: _readDouble(json['platformFee']),
      netEarnings: _readDouble(json['netEarnings'] ?? json['net']),
      status: json['status']?.toString() ?? 'pending',
      settledAt: json['settledAt']?.toString(),
    );
  }

  final String id;
  final String bookingId;
  final String bookingNumber;
  final String route;
  final String truck;
  final String driver;
  final double amount;
  final double platformFee;
  final double netEarnings;
  final String status;
  final String? settledAt;
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color = switch (normalized) {
      'paid' || 'settled' => const Color(0xFF2FA56E),
      'pending' => const Color(0xFFF59E0B),
      _ => const Color(0xFF667085),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

Widget _detailLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: Color(0xFF667085))),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
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
