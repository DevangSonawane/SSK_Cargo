import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
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
              backgroundColor: const Color(0xFFE23A4B),
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
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
    } on ApiException catch (error) {
      ref.invalidate(_brokerHistoryBookingsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
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
    final completedCount = bookings
        .where((booking) => _statusKey(booking.status) == 'completed')
        .length;
    final cancelledCount = bookings.where((booking) {
      final status = _statusKey(booking.status);
      return status == 'cancelled' || status == 'canceled';
    }).length;
    final totalNet = visibleBookings.fold<double>(
      0,
      (sum, booking) => sum + (_amount(booking) - _platformFee(booking)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2152D0),
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
                completedCount: completedCount,
                cancelledCount: cancelledCount,
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
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$count completed and cancelled bookings',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
          prefixIcon: Icon(AppIcons.search_rounded, color: Color(0xFF94A3B8)),
          hintText: 'Search bookings, routes, drivers...',
          hintStyle: TextStyle(
            color: Color(0xFF94A3B8),
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
    required this.completedCount,
    required this.cancelledCount,
    required this.onChanged,
  });

  final _HistoryTab selected;
  final int completedCount;
  final int cancelledCount;
  final ValueChanged<_HistoryTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (_HistoryTab.all, 'All', completedCount + cancelledCount),
      (_HistoryTab.completed, 'Completed', completedCount),
      (_HistoryTab.cancelled, 'Cancelled', cancelledCount),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final tab in tabs)
            Expanded(
              child: _HistoryTabButton(
                label: tab.$2,
                count: tab.$3,
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
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF475569);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF2152D0) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: const Color(0xFF2152D0).withValues(alpha: 0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 7),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.transparent,
          highlightColor: selected
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFF2152D0).withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  constraints: const BoxConstraints(minWidth: 20),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.18)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? Colors.white.withValues(alpha: 0.24)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: foreground,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
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
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCDEFD9)),
      ),
      child: Row(
        children: [
          const Icon(
            AppIcons.account_balance_wallet_rounded,
            color: Color(0xFF047857),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Total Net Earnings (filtered)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF047857),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            _formatRupees(amount),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF047857),
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
        ? const Color(0xFF047857)
        : const Color(0xFFE23A4B);
    final amount = _amount(booking);
    final fee = _platformFee(booking);

    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFF2F6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
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
                          color: const Color(0xFF94A3B8),
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
                    color: const Color(0xFF0F172A),
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
                color: const Color(0xFF0F172A),
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
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 8),
            _HistoryRouteLine(
              label: 'Drop',
              value: booking.dropoffLocation.isEmpty
                  ? 'Drop location not available'
                  : booking.dropoffLocation,
              color: const Color(0xFFEF4444),
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
                  color: const Color(0xFF2152D0),
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
                  color: const Color(0xFFE23A4B),
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
                  color: const Color(0xFF94A3B8),
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
                  color: const Color(0xFF334155),
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
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF94A3B8),
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
              color: const Color(0xFF1E293B),
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
            color: const Color(0xFFE23A4B),
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          'Net ${_formatRupees(net)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFF047857),
            fontWeight: FontWeight.w900,
          ),
        ),
        _HistoryPill(
          label: payment.isEmpty ? 'pending' : payment,
          color: payment == 'paid'
              ? const Color(0xFF047857)
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFF2F6)),
      ),
      child: Column(
        children: [
          const Icon(
            AppIcons.history_rounded,
            color: Color(0xFF94A3B8),
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
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
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
