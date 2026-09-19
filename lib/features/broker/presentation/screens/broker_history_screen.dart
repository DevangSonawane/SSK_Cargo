import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../shared/presentation/widgets/express_badge.dart';

enum _HistoryTab { all, completed, cancelled }

final _brokerHistoryBookingsProvider =
    FutureProvider.autoDispose<List<ClientBooking>>((ref) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookings(
            accessToken: session.tokens.accessToken,
            status: 'completed,cancelled',
            page: 1,
            limit: 100,
          );
      return ClientBookingPage.fromJson(response).bookings;
    });

class BrokerHistoryScreen extends ConsumerStatefulWidget {
  const BrokerHistoryScreen({super.key});

  @override
  ConsumerState<BrokerHistoryScreen> createState() =>
      _BrokerHistoryScreenState();
}

class _BrokerHistoryScreenState extends ConsumerState<BrokerHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  _HistoryTab _tab = _HistoryTab.all;
  String? _deletingId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(_brokerHistoryBookingsProvider);
    await ref.read(_brokerHistoryBookingsProvider.future);
  }

  List<ClientBooking> _visibleBookings(List<ClientBooking> bookings) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = bookings.where((booking) {
      final status = _statusKey(booking.status);
      final matchesTab = switch (_tab) {
        _HistoryTab.all => true,
        _HistoryTab.completed => status == 'completed',
        _HistoryTab.cancelled => status == 'cancelled' || status == 'canceled',
      };
      if (!matchesTab) return false;
      if (query.isEmpty) return true;

      final haystack = [
        booking.id,
        booking.bookingNumber,
        booking.bookingRef,
        booking.pickupLocation,
        booking.dropoffLocation,
        booking.clientName,
        _driverName(booking),
        _truckReg(booking),
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aDate = a.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.requestedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return filtered;
  }

  Future<void> _deleteBooking(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _deletingId != null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from my list?'),
        content: const Text(
          "This only removes it from your own list. There's no undo.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.dangerIcon,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deletingId = booking.id);
    try {
      await ref
          .read(apiClientProvider)
          .deleteBooking(
            accessToken: session.tokens.accessToken,
            id: booking.id,
          );
      ref.invalidate(_brokerHistoryBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking removed from your list.'),
          backgroundColor: AppColors.brand,
        ),
      );
    } on ApiException catch (error) {
      ref.invalidate(_brokerHistoryBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(_brokerHistoryBookingsProvider);
    final bookings = bookingsAsync.valueOrNull ?? const <ClientBooking>[];
    final visibleBookings = _visibleBookings(bookings);
    final totalNet = visibleBookings.fold<double>(
      0,
      (sum, booking) => sum + (_amount(booking) - _platformFee(booking)),
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
            children: [
              _HistoryHeader(count: visibleBookings.length),
              const SizedBox(height: 18),
              _HistorySearchField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              _HistoryTabs(
                selected: _tab,
                onChanged: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 14),
              _NetEarningsCard(amount: totalNet),
              const SizedBox(height: 14),
              bookingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 60),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _HistoryEmptyState(
                  title: 'Could not load job history',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
                data: (_) {
                  if (visibleBookings.isEmpty) {
                    return const _HistoryEmptyState(
                      title: 'No bookings found',
                      subtitle: 'Completed and cancelled bookings appear here.',
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final useGrid = constraints.maxWidth >= 760;
                      return Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: [
                          for (final booking in visibleBookings)
                            SizedBox(
                              width: useGrid
                                  ? (constraints.maxWidth - 14) / 2
                                  : constraints.maxWidth,
                              child: _HistoryBookingCard(
                                booking: booking,
                                deleting: _deletingId == booking.id,
                                onOpen: () => context.push(
                                  '/broker/history/${booking.id}',
                                  extra: booking,
                                ),
                                onDelete: () => _deleteBooking(booking),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Job History',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count completed and cancelled bookings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySearchField extends StatelessWidget {
  const _HistorySearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.field),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(AppIcons.search_rounded, color: AppColors.textTertiary),
          hintText: 'Search bookings, routes, drivers...',
          hintStyle: TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _HistoryTabs extends StatelessWidget {
  const _HistoryTabs({
    required this.selected,
    required this.onChanged,
  });

  final _HistoryTab selected;
  final ValueChanged<_HistoryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_HistoryTab.all, 'All'),
      (_HistoryTab.completed, 'Completed'),
      (_HistoryTab.cancelled, 'Cancelled'),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _HistoryTabButton(
                label: tab.$2,
                selected: selected == tab.$1,
                onTap: () => onChanged(tab.$1),
              ),
            ),
        ],
      ),
    );
  }
}

class _HistoryTabButton extends StatelessWidget {
  const _HistoryTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : AppColors.textSecondary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        splashColor: Colors.transparent,
        highlightColor: selected
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.brand.withValues(alpha: 0.04),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _NetEarningsCard extends StatelessWidget {
  const _NetEarningsCard({required this.amount});

  final double amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.brandFill,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.brandBorder),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.account_balance_wallet_rounded,
            color: AppColors.brandInk,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total Net Earnings (filtered)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.brandInk,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _formatRupees(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.brandInk,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBookingCard extends StatelessWidget {
  const _HistoryBookingCard({
    required this.booking,
    required this.deleting,
    required this.onOpen,
    required this.onDelete,
  });

  final ClientBooking booking;
  final bool deleting;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = _statusKey(booking.status);
    final statusColor = status == 'completed'
        ? AppColors.brandInk
        : AppColors.dangerIcon;
    final amount = _amount(booking);
    final fee = _platformFee(booking);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.line),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 7,
                    runSpacing: 5,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        _bookingRef(booking),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textTertiary,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      _HistoryPill(
                        label: booking.displayStatusLabel,
                        color: statusColor,
                      ),
                      if (booking.isExpress) const ExpressBadge(compact: true),
                    ],
                  ),
                ),
                Text(
                  _formatRupees(amount),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),
            Text(
              '${_lead(booking.pickupLocation)} to ${_lead(booking.dropoffLocation)}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 12),
            _HistoryRouteLine(
              label: 'Pickup',
              value: booking.pickupLocation.isEmpty
                  ? 'Pickup location not available'
                  : booking.pickupLocation,
              color: AppColors.brandBright,
            ),
            const SizedBox(height: 8),
            _HistoryRouteLine(
              label: 'Drop',
              value: booking.dropoffLocation.isEmpty
                  ? 'Drop location not available'
                  : booking.dropoffLocation,
              color: AppColors.dangerIcon,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HistoryMetric(
                    label: 'Truck',
                    value: _truckReg(booking).isEmpty
                        ? '-'
                        : _truckReg(booking),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HistoryMetric(
                    label: 'Driver',
                    value: _driverName(booking).isEmpty
                        ? '-'
                        : _driverName(booking),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _HistoryAmountLine(
                    fee: fee,
                    net: amount - fee,
                    payment: _paymentStatus(booking),
                  ),
                ),
                IconButton(
                  onPressed: deleting ? null : onOpen,
                  icon: const Icon(AppIcons.visibility_rounded),
                  color: AppColors.brand,
                  tooltip: 'View details',
                ),
                IconButton(
                  onPressed: deleting ? null : onDelete,
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(AppIcons.delete_outline_rounded),
                  color: AppColors.dangerIcon,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRouteLine extends StatelessWidget {
  const _HistoryRouteLine({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(AppIcons.location_on_outlined, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
        borderRadius: BorderRadius.circular(AppRadius.field - 10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryAmountLine extends StatelessWidget {
  const _HistoryAmountLine({
    required this.fee,
    required this.net,
    required this.payment,
  });

  final double fee;
  final double net;
  final String payment;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 5,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          'Fee ${_formatRupees(fee)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.dangerIcon,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Net ${_formatRupees(net)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AppColors.brandInk,
            fontWeight: FontWeight.w900,
          ),
        ),
        _HistoryPill(
          label: payment.isEmpty ? 'pending' : payment,
          color: payment == 'paid'
              ? AppColors.brandInk
              : const Color(0xFFD97706),
        ),
      ],
    );
  }
}

class _HistoryPill extends StatelessWidget {
  const _HistoryPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _HistoryEmptyState extends StatelessWidget {
  const _HistoryEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 38),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          const Icon(
            AppIcons.history_rounded,
            color: AppColors.textTertiary,
            size: 36,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _statusKey(String status) {
  return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _bookingRef(ClientBooking booking) {
  final ref = booking.bookingNumber.isNotEmpty
      ? booking.bookingNumber
      : (booking.bookingRef.isNotEmpty ? booking.bookingRef : booking.id);
  return '#${ref.toUpperCase()}';
}

String _lead(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return 'Location pending';
  final index = trimmed.indexOf(',');
  if (index <= 0) return trimmed;
  return trimmed.substring(0, index).trim();
}

double _amount(ClientBooking booking) {
  final raw = booking.raw;
  return _readDouble(raw, const ['amount', 'price', 'fare', 'value']) ??
      _amountFromText(booking.amountText);
}

double _platformFee(ClientBooking booking) {
  return _readDouble(booking.raw, const [
        'platformFee',
        'platform_fee',
        'commission',
        'brokerage',
      ]) ??
      0;
}

String _truckReg(ClientBooking booking) {
  final truck = _asMap(booking.raw['truck']);
  return _firstNonEmpty([
    _readString(booking.raw, const ['truckReg', 'truck_reg', 'truckNumber']),
    _readString(truck, const ['registration', 'plate_number', 'plate']),
  ]);
}

String _driverName(ClientBooking booking) {
  final driver = _asMap(booking.raw['driver']);
  return _firstNonEmpty([
    _readString(booking.raw, const ['driverName', 'driver_name']),
    _readString(driver, const ['name', 'full_name', 'display_name']),
  ]);
}

String _paymentStatus(ClientBooking booking) {
  return _firstNonEmpty([
    _readString(booking.raw, const ['paymentStatus', 'payment_status']),
    'pending',
  ]).toLowerCase();
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    final text = value?.toString().trim();
    if (text != null && text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(
      value?.toString().replaceAll(RegExp(r'[^0-9.-]'), '') ?? '',
    );
    if (parsed != null) return parsed;
  }
  return null;
}

String _firstNonEmpty(List<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

double _amountFromText(String value) {
  return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
}

String _formatRupees(double amount) {
  final fixed = amount.round().toString();
  if (fixed.length <= 3) return '₹$fixed';
  final suffix = fixed.substring(fixed.length - 3);
  var prefix = fixed.substring(0, fixed.length - 3);
  final groups = <String>[];
  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }
  if (prefix.isNotEmpty) groups.insert(0, prefix);
  return '₹${groups.join(',')},$suffix';
}
