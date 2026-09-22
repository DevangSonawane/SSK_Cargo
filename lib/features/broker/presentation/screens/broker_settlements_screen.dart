import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

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
    try {
      await ref.read(_settlementsProvider(_query).future);
    } catch (_) {
      // Error UI is driven by the provider state.
    }
  }

  @override
  Widget build(BuildContext context) {
    final settlementsAsync = ref.watch(_settlementsProvider(_query));

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: settlementsAsync.when(
            loading: () => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              children: const [
                _TopRow(count: null),
                SizedBox(height: 18),
                _SettlementsSkeleton(),
              ],
            ),
            error: (error, _) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
              children: [
                const _TopRow(count: null),
                const SizedBox(height: 24),
                _EmptyState(
                  icon: AppIcons.payments_outlined,
                  title: 'Could not load settlements',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
              ],
            ),
            data: (settlements) {
              if (settlements.isEmpty) {
                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                  children: const [
                    _TopRow(count: 0),
                    SizedBox(height: 24),
                    _EmptyState(
                      icon: AppIcons.payments_rounded,
                      title: 'No settlements yet',
                      subtitle:
                          'Paid and pending settlement records will appear here.',
                    ),
                  ],
                );
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                itemCount: settlements.length + 1,
                separatorBuilder: (context, index) =>
                    SizedBox(height: index == 0 ? 18 : 12),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _TopRow(count: settlements.length);
                  }
                  final settlement = settlements[index - 1];
                  return _SettlementCard(
                    settlement: settlement,
                    onTap: () => _showSettlementDetails(context, settlement),
                  );
                },
              );
            },
          ),
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
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 14,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.line),
              boxShadow: AppShadows.float,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppColors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        settlement.bookingNumber,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 19,
                          letterSpacing: -0.2,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    _StatusPill(status: settlement.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  settlement.route.isEmpty ? 'Route pending' : settlement.route,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (settlement.truck.isNotEmpty ||
                    settlement.driver.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      settlement.truck,
                      settlement.driver,
                    ].where((part) => part.isNotEmpty).join(' • '),
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                _detailLine(
                  'Gross amount',
                  '₹${settlement.amount.toStringAsFixed(0)}',
                ),
                _detailLine(
                  'Platform fee',
                  '₹${settlement.platformFee.toStringAsFixed(2)}',
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.brandBorder),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Net earnings',
                          style: TextStyle(
                            color: AppColors.brandDark,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      Text(
                        '₹${settlement.netEarnings.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: AppColors.brandDark,
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                _detailLine('Status', settlement.status),
                _detailLine(
                  'Settled on',
                  _prettyDate(settlement.settledAt),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2FA56E), Color(0xFF1E7A4C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x402FA56E),
                          blurRadius: 16,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
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

class _TopRow extends StatelessWidget {
  const _TopRow({required this.count});

  final int? count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BrokerBackButton(onTap: () => Navigator.of(context).maybePop()),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Settlements',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (count != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandFill,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.brandBorder),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: AppColors.brandDark,
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement, required this.onTap});

  final BrokerSettlement settlement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = [
      settlement.truck,
      settlement.driver,
    ].where((part) => part.isNotEmpty).join(' • ');
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
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
            Row(
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
                      Text(
                        settlement.bookingNumber,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        settlement.route.isEmpty
                            ? 'Route pending'
                            : settlement.route,
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
                const SizedBox(width: 8),
                _StatusPill(status: settlement.status),
              ],
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 9),
              Text(
                meta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 11),
              child: Divider(height: 1, thickness: 1, color: AppColors.line),
            ),
            Row(
              children: [
                Expanded(
                  child: _MoneyMini(
                    label: 'Gross',
                    value: '₹${settlement.amount.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _MoneyMini(
                    label: 'Fee',
                    value: '₹${settlement.platformFee.toStringAsFixed(0)}',
                  ),
                ),
                Expanded(
                  child: _MoneyMini(
                    label: 'Net',
                    value: '₹${settlement.netEarnings.toStringAsFixed(0)}',
                    highlight: true,
                  ),
                ),
                const Icon(
                  AppIcons.chevron_right_rounded,
                  size: 19,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoneyMini extends StatelessWidget {
  const _MoneyMini({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlight ? AppColors.brandDark : AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
          ),
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
    final normalized = status.trim().toLowerCase();
    final fg = switch (normalized) {
      'paid' || 'settled' => AppColors.brandDark,
      'pending' => AppColors.warningText,
      _ => AppColors.textSecondary,
    };
    final bg = switch (normalized) {
      'paid' || 'settled' => AppColors.brandFill,
      'pending' => AppColors.warningFill,
      _ => AppColors.fillSubtle,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.isEmpty ? 'Pending' : status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
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
          child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
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

String _prettyDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Pending';
  final parsed = DateTime.tryParse(raw.trim());
  if (parsed == null) return raw.trim();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
}

class _SettlementsSkeleton extends StatelessWidget {
  const _SettlementsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        4,
        (_) => Container(
          height: 148,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.line),
          ),
        ),
      ),
    );
  }
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFEAF8EF), Color(0xFFDFF0E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brand, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: AppColors.textPrimary,
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
        ],
      ),
    );
  }
}
