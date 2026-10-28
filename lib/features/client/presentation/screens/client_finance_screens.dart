import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/booking_payment_gateway.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/client_verification_gate.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Client prepaid wallet and postpaid bills.  These intentionally use the
/// server ledger as the source of truth; no balance/commission math is done
/// in the app.
class ClientWalletScreen extends ConsumerStatefulWidget {
  const ClientWalletScreen({super.key});
  @override
  ConsumerState<ClientWalletScreen> createState() => _ClientWalletScreenState();
}

class _ClientWalletScreenState extends ConsumerState<ClientWalletScreen> {
  late Future<_Ledger> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Ledger> _load() async {
    final token =
        ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
    final api = ref.read(apiClientProvider);
    final results = await Future.wait([
      api.getWalletBalance(accessToken: token),
      api.getWalletTransactions(accessToken: token),
    ]);
    final balance = _data(results[0])['balance'];
    final tx = _data(results[1])['transactions'];
    return _Ledger(
      _number(balance),
      tx is List
          ? tx.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList()
          : const [],
    );
  }

  Future<void> _recharge() async {
    final controller = TextEditingController();
    final amount = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCE3DF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Recharge wallet',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Choose an amount to add to your balance.',
                    style: TextStyle(color: Color(0xFF78818D)),
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [200, 500, 1000, 2000]
                        .map(
                          (value) => ActionChip(
                            label: Text('₹$value'),
                            onPressed: () => controller.text = '$value',
                            backgroundColor: AppColors.brandFill,
                            side: const BorderSide(
                              color: AppColors.brandBorder,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: const Color(0xFFF6F8F7),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        double.tryParse(controller.text),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'Continue to payment',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // The modal's reverse animation can still paint the TextField after the
    // Future resolves. Dispose after that frame instead of during the pop.
    Future<void>.delayed(const Duration(milliseconds: 350), controller.dispose);
    if (amount == null || amount < 100 || !mounted) {
      if (amount != null) _notice('Minimum recharge is ₹100');
      return;
    }
    try {
      final token =
          ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
      await BookingPaymentGateway(
        apiClient: ref.read(apiClientProvider),
      ).payWalletRecharge(accessToken: token, amount: amount, context: context);
      if (mounted) {
        _notice('Wallet recharged successfully.');
        setState(() => _future = _load());
      }
    } catch (e) {
      if (mounted) _notice(_message(e));
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  @override
  Widget build(BuildContext context) => ClientVerificationGate(
    messageContext: 'wallet',
    child: Scaffold(
      backgroundColor: AppColors.canvas,
      body: FutureBuilder<_Ledger>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return _Retry(
              message: _message(snapshot.error),
              onRetry: () => setState(() => _future = _load()),
            );
          final ledger = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => setState(() => _future = _load()),
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 26,
                20,
                112,
              ),
              children: [
                _WalletHero(balance: ledger.balance, onRecharge: _recharge),
                const SizedBox(height: 28),
                _SectionHeader(
                  title: 'Recent activity',
                  count: ledger.transactions.length,
                ),
                const SizedBox(height: 12),
                if (ledger.transactions.isEmpty)
                  const _Empty(text: 'No transactions yet')
                else
                  ...ledger.transactions.map((tx) => _TransactionTile(tx: tx)),
              ],
            ),
          );
        },
      ),
    ),
  );
}

class ClientBillsScreen extends ConsumerStatefulWidget {
  const ClientBillsScreen({super.key});
  @override
  ConsumerState<ClientBillsScreen> createState() => _ClientBillsScreenState();
}

class _ClientBillsScreenState extends ConsumerState<ClientBillsScreen> {
  late Future<_Bills> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Bills> _load() async {
    final token =
        ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
    final api = ref.read(apiClientProvider);
    final result = await Future.wait([
      api.getBillsAccount(accessToken: token),
      api.getBills(accessToken: token),
    ]);
    final account = _data(result[0]);
    final list = _data(result[1])['bills'];
    return _Bills(
      account,
      list is List
          ? list.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList()
          : const [],
    );
  }

  Future<void> _payBill(String billId) async {
    try {
      final token =
          ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
      await BookingPaymentGateway(
        apiClient: ref.read(apiClientProvider),
      ).payBill(accessToken: token, billId: billId, context: context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill paid successfully.')),
        );
        setState(() => _future = _load());
      }
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  Future<void> _showDetail(String billId) async {
    try {
      final token =
          ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
      final response = await ref
          .read(apiClientProvider)
          .getBillDetail(accessToken: token, billId: billId);
      final data = _data(response);
      final items = data['items'] is List
          ? (data['items'] as List)
                .whereType<Map>()
                .map((e) => e.cast<String, dynamic>())
                .toList()
          : const <Map<String, dynamic>>[];
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Bill details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...items.map(
                (item) => ListTile(
                  title: Text(
                    '${item['booking_number'] ?? 'Booking'} · ${_money(_number(item['amount']))}',
                  ),
                  subtitle: Text(
                    '${item['pickup_location'] ?? ''} → ${item['drop_location'] ?? ''}',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (error) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(error))));
    }
  }

  @override
  Widget build(BuildContext context) => ClientVerificationGate(
    child: Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: FutureBuilder<_Bills>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done)
            return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError)
            return _Retry(
              message: _message(snapshot.error),
              onRetry: () => setState(() => _future = _load()),
            );
          final data = snapshot.data!;
          return ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 26,
              20,
              112,
            ),
            children: [
              const _FinancePageHeading(
                title: 'My bills',
                subtitle: 'Account statements',
              ),
              const SizedBox(height: 22),
              _BillsHero(
                outstanding: _number(data.account['outstanding']),
                limit: _number(data.account['credit_limit']),
              ),
              const SizedBox(height: 28),
              _SectionHeader(title: 'Statements', count: data.bills.length),
              const SizedBox(height: 12),
              if (data.bills.isEmpty)
                const _Empty(text: 'No bills yet')
              else
                ...data.bills.map(
                  (bill) => _BillTile(
                    bill: bill,
                    onDetail: () => _showDetail('${bill['id']}'),
                    onPay: bill['status'] == 'pending'
                        ? () => _payBill('${bill['id']}')
                        : null,
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

class EarningsWalletScreen extends ConsumerStatefulWidget {
  const EarningsWalletScreen({super.key});
  @override
  ConsumerState<EarningsWalletScreen> createState() =>
      _EarningsWalletScreenState();
}

class _EarningsWalletScreenState extends ConsumerState<EarningsWalletScreen> {
  late Future<_Ledger> _future;
  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_Ledger> _load() async {
    final token =
        ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
    final api = ref.read(apiClientProvider);
    final r = await Future.wait([
      api.getWalletBalance(accessToken: token),
      api.getWalletTransactions(accessToken: token),
    ]);
    final tx = _data(r[1])['transactions'];
    return _Ledger(
      _number(_data(r[0])['balance']),
      tx is List
          ? tx.whereType<Map>().map((x) => x.cast<String, dynamic>()).toList()
          : const [],
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Wallet')),
    body: FutureBuilder<_Ledger>(
      future: _future,
      builder: (context, s) {
        if (s.connectionState != ConnectionState.done)
          return const Center(child: CircularProgressIndicator());
        if (s.hasError)
          return _Retry(
            message: _message(s.error),
            onRetry: () => setState(() => _future = _load()),
          );
        final ledger = s.data!;
        return RefreshIndicator(
          onRefresh: () async => setState(() => _future = _load()),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _BalanceCard(
                label: 'Available earnings',
                amount: ledger.balance,
                footer: 'Payouts are recorded when sent by the platform.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Wallet history',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 10),
              if (ledger.transactions.isEmpty)
                const _Empty(text: 'No earnings or payouts yet')
              else
                ...ledger.transactions.map((x) => _TransactionTile(tx: x)),
            ],
          ),
        );
      },
    ),
  );
}

class _FinancePageHeading extends StatelessWidget {
  const _FinancePageHeading({required this.title, required this.subtitle});
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF78818D), fontSize: 14),
      ),
    ],
  );
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(
        title,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
      ),
      const Spacer(),
      Text(
        '$count total',
        style: const TextStyle(
          color: Color(0xFF8B93A1),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _WalletHero extends StatelessWidget {
  const _WalletHero({required this.balance, required this.onRecharge});
  final double balance;
  final VoidCallback onRecharge;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 18,
            color: Color(0xFF78818D),
          ),
          SizedBox(width: 8),
          Text(
            'Available balance',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Text(
        _money(balance),
        style: const TextStyle(
          color: AppColors.brand,
          fontSize: 42,
          fontWeight: FontWeight.w700,
          letterSpacing: -1.2,
        ),
      ),
      const SizedBox(height: 28),
      Row(
        children: [
          Expanded(
            child: _WalletSplitCard(title: 'Cash', amount: balance),
          ),
          const SizedBox(width: 12),
          const Expanded(child: _WalletSplitCard(title: 'Bonus', amount: 0)),
        ],
      ),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: onRecharge,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Add money',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    ],
  );
}

class _WalletSplitCard extends StatelessWidget {
  const _WalletSplitCard({required this.title, required this.amount});
  final String title;
  final double amount;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE4E8EC)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          _money(amount),
          style: const TextStyle(
            color: AppColors.brand,
            fontSize: 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _BillsHero extends StatelessWidget {
  const _BillsHero({required this.outstanding, required this.limit});
  final double outstanding, limit;
  @override
  Widget build(BuildContext context) {
    final ratio = limit > 0
        ? (outstanding / limit).clamp(0, 1).toDouble()
        : 0.0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'OUTSTANDING',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _money(outstanding),
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: AppColors.fillSubtle,
              valueColor: const AlwaysStoppedAnimation(AppColors.brand),
            ),
          ),
          const SizedBox(height: 9),
          Text(
            'Credit limit ${_money(limit)}',
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

class _BillTile extends StatelessWidget {
  const _BillTile({required this.bill, required this.onDetail, this.onPay});
  final Map<String, dynamic> bill;
  final VoidCallback onDetail;
  final VoidCallback? onPay;
  @override
  Widget build(BuildContext context) {
    final pending = onPay != null;
    return InkWell(
      onTap: onDetail,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.colors.line),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (pending
                    ? AppColors.warningFill
                    : AppColors.successFill),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                color: pending ? AppColors.warningText : AppColors.successText,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bill['trigger'] == 'credit_limit'
                        ? 'Credit-limit bill'
                        : 'Monthly bill',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${bill['created_at'] ?? ''}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _money(_number(bill['total_amount'])),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                if (pending) ...[
                  const SizedBox(height: 7),
                  GestureDetector(
                    onTap: onPay,
                    child: const Text(
                      'Pay now',
                      style: TextStyle(
                        color: AppColors.brand,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ] else
                  const Padding(
                    padding: EdgeInsets.only(top: 7),
                    child: Text(
                      'Paid',
                      style: TextStyle(
                        color: AppColors.successText,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
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

class _Ledger {
  const _Ledger(this.balance, this.transactions);
  final double balance;
  final List<Map<String, dynamic>> transactions;
}

class _Bills {
  const _Bills(this.account, this.bills);
  final Map<String, dynamic> account;
  final List<Map<String, dynamic>> bills;
}

Map<String, dynamic> _data(Map<String, dynamic> json) =>
    json['data'] is Map ? (json['data'] as Map).cast<String, dynamic>() : json;
double _number(Object? value) =>
    value is num ? value.toDouble() : double.tryParse('${value ?? ''}') ?? 0;
String _money(double amount) => '₹${amount.toStringAsFixed(2)}';
String _message(Object? error) => error is ApiException
    ? error.message
    : 'Could not load data. Please try again.';

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.label,
    required this.amount,
    this.action,
    this.footer,
  });
  final String label;
  final String? footer;
  final double amount;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AppColors.brand,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 8),
        Text(
          _money(amount),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 30,
          ),
        ),
        if (footer != null) ...[
          const SizedBox(height: 8),
          Text(footer!, style: const TextStyle(color: Colors.white70)),
        ],
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.tx});
  final Map<String, dynamic> tx;
  @override
  Widget build(BuildContext context) {
    final type = '${tx['type'] ?? ''}';
    final credit = type == 'earning' || type == 'recharge' || type == 'refund';
    final title = switch (type) {
      'earning' => 'Trip earning',
      'payout' => 'Payout received',
      'booking_payment' => 'Booking payment',
      'refund' => 'Refund',
      _ => 'Recharge',
    };
    final color = credit ? const Color(0xFF16885B) : const Color(0xFFC24444);
    final detail = '${tx['note'] ?? tx['created_at'] ?? ''}'.trim();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: .14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 14,
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
              color: color.withValues(alpha: .10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              credit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (detail.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF707782),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${credit ? '+' : '-'}${_money(_number(tx['amount']))}',
                style: TextStyle(fontWeight: FontWeight.w900, color: color),
              ),
              const SizedBox(height: 4),
              Text(
                'BAL ${_money(_number(tx['balance_after']))}',
                style: const TextStyle(
                  fontSize: 10,
                  letterSpacing: .3,
                  color: Color(0xFF8B93A1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Center(
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    ),
  );
}

class _Retry extends StatelessWidget {
  const _Retry({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message),
        const SizedBox(height: 12),
        FilledButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
  );
}
