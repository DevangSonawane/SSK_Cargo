import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../widgets/broker_flow_widgets.dart';

final _historyBookingDetailProvider = FutureProvider.autoDispose
    .family<ClientBooking, String>((ref, bookingId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookingById(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      final data = _asMap(response['data']);
      final booking = _asMap(data['booking']).isNotEmpty
          ? _asMap(data['booking'])
          : _asMap(response['booking']);
      if (booking.isEmpty) {
        throw const ApiException('Job not found');
      }
      return ClientBooking.fromJson(booking);
    });

final _historyReassignmentProvider = FutureProvider.autoDispose
    .family<List<_ReassignmentEntry>, String>((ref, bookingId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) return const <_ReassignmentEntry>[];
      try {
        final response = await ref
            .watch(apiClientProvider)
            .getBookingReassignmentHistory(
              accessToken: session.tokens.accessToken,
              bookingId: bookingId,
            );
        final data = _asMap(response['data']);
        final items = data['history'] is List
            ? data['history'] as List
            : response['history'] is List
            ? response['history'] as List
            : const [];
        return items
            .map((item) => _ReassignmentEntry.fromJson(_asMap(item)))
            .toList();
      } catch (_) {
        return const <_ReassignmentEntry>[];
      }
    });

class BrokerHistoryDetailScreen extends ConsumerStatefulWidget {
  const BrokerHistoryDetailScreen({
    super.key,
    required this.bookingId,
    this.initialBooking,
  });

  final String bookingId;
  final ClientBooking? initialBooking;

  @override
  ConsumerState<BrokerHistoryDetailScreen> createState() =>
      _BrokerHistoryDetailScreenState();
}

class _BrokerHistoryDetailScreenState
    extends ConsumerState<BrokerHistoryDetailScreen> {
  bool _deleting = false;
  bool _invoiceBusy = false;

  Future<void> _refresh() async {
    ref.invalidate(_historyBookingDetailProvider(widget.bookingId));
    ref.invalidate(_historyReassignmentProvider(widget.bookingId));
    await ref.read(_historyBookingDetailProvider(widget.bookingId).future);
  }

  Future<void> _deleteBooking(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _deleting) return;
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

    setState(() => _deleting = true);
    try {
      await ref
          .read(apiClientProvider)
          .deleteBooking(
            accessToken: session.tokens.accessToken,
            id: booking.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking removed from your list.'),
          backgroundColor: AppColors.brand,
        ),
      );
      context.go('/broker/history');
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  Future<void> _fetchInvoice(ClientBooking booking) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _invoiceBusy) return;
    setState(() => _invoiceBusy = true);
    try {
      await ref
          .read(apiClientProvider)
          .getBookingInvoice(
            accessToken: session.tokens.accessToken,
            id: booking.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice fetched for ${_bookingRef(booking)}.'),
          backgroundColor: AppColors.brand,
        ),
      );
    } on Object catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) setState(() => _invoiceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingAsync = ref.watch(
      _historyBookingDetailProvider(widget.bookingId),
    );
    final fallback = widget.initialBooking;
    final booking = bookingAsync.valueOrNull ?? fallback;
    final reassignments =
        ref.watch(_historyReassignmentProvider(widget.bookingId)).valueOrNull ??
        const <_ReassignmentEntry>[];

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              _DetailBackRow(onBack: () => context.go('/broker/history')),
              const SizedBox(height: 14),
              bookingAsync.when(
                loading: () => booking == null
                    ? const Padding(
                        padding: EdgeInsets.only(top: 100),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildContent(context, booking, reassignments),
                error: (error, _) => booking == null
                    ? _DetailEmptyState(
                        title: 'Could not load job details',
                        subtitle: error.toString().replaceFirst(
                          'Exception: ',
                          '',
                        ),
                        onRetry: _refresh,
                      )
                    : _buildContent(context, booking, reassignments),
                data: (loaded) => _buildContent(context, loaded, reassignments),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ClientBooking booking,
    List<_ReassignmentEntry> reassignments,
  ) {
    final shipment = trackingShipmentFromBooking(booking);
    final statusColor = _statusKey(booking.status) == 'completed'
        ? AppColors.brandInk
        : AppColors.dangerIcon;
    final amount = _amount(booking);
    final fee = _platformFee(booking);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailTopCard(
          booking: booking,
          statusColor: statusColor,
          onChat: () => context.push('/broker/chats/${booking.id}'),
          onInvoice: () => _fetchInvoice(booking),
          invoiceBusy: _invoiceBusy,
          onDelete: () => _deleteBooking(booking),
          deleting: _deleting,
        ),
        const SizedBox(height: 14),
        Container(
          height: 310,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: AppColors.line),
          ),
          child: TrackingRouteMapView(shipment: shipment, liveMode: true),
        ),
        const SizedBox(height: 14),
        _DetailInfoCard(booking: booking),
        const SizedBox(height: 14),
        _PaymentCard(booking: booking, amount: amount, fee: fee),
        if (reassignments.isNotEmpty) ...[
          const SizedBox(height: 14),
          _ReassignmentCard(entries: reassignments),
        ],
      ],
    );
  }
}

class _DetailBackRow extends StatelessWidget {
  const _DetailBackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BrokerBackButton(onTap: onBack);
  }
}

class _DetailTopCard extends StatelessWidget {
  const _DetailTopCard({
    required this.booking,
    required this.statusColor,
    required this.onChat,
    required this.onInvoice,
    required this.invoiceBusy,
    required this.onDelete,
    required this.deleting,
  });

  final ClientBooking booking;
  final Color statusColor;
  final VoidCallback onChat;
  final VoidCallback onInvoice;
  final bool invoiceBusy;
  final VoidCallback onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 7,
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
              _DetailPill(
                label: booking.displayStatusLabel,
                color: statusColor,
              ),
              if (booking.isExpress) const ExpressBadge(compact: true),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${_lead(booking.pickupLocation)} to ${_lead(booking.dropoffLocation)}',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
              height: 1.22,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _IconAction(
                  icon: AppIcons.chat_bubble_outline_rounded,
                  label: 'Chat',
                  onTap: onChat,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IconAction(
                  icon: AppIcons.receipt_long_rounded,
                  label: invoiceBusy ? 'Fetching...' : 'Invoice',
                  onTap: invoiceBusy ? null : onInvoice,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _IconAction(
                  icon: AppIcons.delete_outline_rounded,
                  label: deleting ? 'Removing...' : 'Remove',
                  color: AppColors.dangerIcon,
                  onTap: deleting ? null : onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailInfoCard extends StatelessWidget {
  const _DetailInfoCard({required this.booking});

  final ClientBooking booking;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Job Details',
      children: [
        _DetailRow(
          icon: AppIcons.local_shipping_rounded,
          label: 'Truck',
          value: _truckReg(booking).isEmpty ? '-' : _truckReg(booking),
        ),
        _DetailRow(
          icon: AppIcons.person_rounded,
          label: 'Driver',
          value: _driverName(booking).isEmpty ? '-' : _driverName(booking),
        ),
        _DetailRow(
          icon: AppIcons.calendar_today_rounded,
          label: 'Date',
          value: _formatDate(booking.requestedAt),
        ),
        _DetailRow(
          icon: AppIcons.route_rounded,
          label: 'Distance',
          value: _distance(booking),
        ),
        _DetailRow(
          icon: AppIcons.inventory_2_rounded,
          label: 'Cargo',
          value: _cargo(booking),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({
    required this.booking,
    required this.amount,
    required this.fee,
  });

  final ClientBooking booking;
  final double amount;
  final double fee;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Earnings & Payment',
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MoneyTile(label: 'Amount', value: _formatRupees(amount)),
            _MoneyTile(
              label: 'Platform Fee',
              value: _formatRupees(fee),
              color: AppColors.dangerIcon,
            ),
            _MoneyTile(
              label: 'Net Earnings',
              value: _formatRupees(amount - fee),
              color: AppColors.brandInk,
              background: AppColors.brandFill,
            ),
            _MoneyTile(label: 'Payment', value: _paymentStatus(booking)),
            _MoneyTile(label: 'Time Taken', value: _duration(booking)),
          ],
        ),
      ],
    );
  }
}

class _ReassignmentCard extends StatelessWidget {
  const _ReassignmentCard({required this.entries});

  final List<_ReassignmentEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _DetailSection(
      title: 'Reassignment History',
      children: [
        for (final entry in entries) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                AppIcons.repeat_rounded,
                color: AppColors.brand,
                size: 17,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.fromDriverName.isEmpty ? 'Unassigned' : entry.fromDriverName} → ${entry.toDriverName.isEmpty ? 'Unknown' : entry.toDriverName}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (entry.reason.isNotEmpty)
                      Text(
                        entry.reason,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    Text(
                      'By ${entry.reassignedByName.isEmpty ? '-' : entry.reassignedByName} · ${_formatDate(entry.createdAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (entry != entries.last) const Divider(height: 20),
        ],
      ],
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w900,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 17),
          const SizedBox(width: 10),
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
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
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

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.label,
    required this.value,
    this.color = AppColors.textPrimary,
    this.background = AppColors.fillSubtle,
  });

  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.button),
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
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  const _IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.brand,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final accent = color;
    final canTap = onTap != null;
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: InkWell(
        onTap: canTap ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: accent.withValues(alpha: 0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: accent),
              const SizedBox(width: 7),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  const _DetailPill({required this.label, required this.color});

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

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState({
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 48),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Text(
            title,
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
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _ReassignmentEntry {
  const _ReassignmentEntry({
    required this.id,
    required this.fromDriverName,
    required this.toDriverName,
    required this.reason,
    required this.reassignedByName,
    required this.createdAt,
  });

  factory _ReassignmentEntry.fromJson(Map<String, dynamic> json) {
    return _ReassignmentEntry(
      id: _readString(json, const ['id']),
      fromDriverName: _readString(json, const [
        'fromDriverName',
        'from_driver_name',
      ]),
      toDriverName: _readString(json, const ['toDriverName', 'to_driver_name']),
      reason: _readString(json, const ['reason']),
      reassignedByName: _readString(json, const [
        'reassignedByName',
        'reassigned_by_name',
      ]),
      createdAt: _parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  final String id;
  final String fromDriverName;
  final String toDriverName;
  final String reason;
  final String reassignedByName;
  final DateTime? createdAt;
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

String _formatDate(DateTime? date) {
  if (date == null) return '-';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _duration(ClientBooking booking) {
  final minutes = _readDouble(booking.raw, const [
    'timeTakenMinutes',
    'time_taken_minutes',
  ]);
  if (minutes == null || minutes <= 0) return '-';
  final hours = minutes ~/ 60;
  final mins = minutes.round() % 60;
  if (hours <= 0) return '${mins}m';
  return '${hours}h ${mins}m';
}

String _distance(ClientBooking booking) {
  final distance = _readDouble(booking.raw, const [
    'distance',
    'route_distance',
  ]);
  if (distance == null || distance <= 0) return '-';
  return '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km';
}

String _cargo(ClientBooking booking) {
  final material = booking.material.isEmpty
      ? booking.packageName
      : booking.material;
  final weight = booking.weight;
  if (material.isEmpty && weight.isEmpty) return '-';
  if (material.isEmpty) return weight;
  if (weight.isEmpty) return material;
  return '$material · $weight';
}

double _amount(ClientBooking booking) {
  return _readDouble(booking.raw, const ['amount', 'price', 'fare', 'value']) ??
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

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
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
