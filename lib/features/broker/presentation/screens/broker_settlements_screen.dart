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
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Settlements'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: settlementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
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
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: const [
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
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: settlements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final settlement = settlements[index];
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
