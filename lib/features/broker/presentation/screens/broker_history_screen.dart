import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../widgets/broker_flow_widgets.dart';

enum _HistoryFilter { all, completed, cancelled, accepted }

class BrokerHistoryScreen extends ConsumerStatefulWidget {
  const BrokerHistoryScreen({super.key});

  @override
  ConsumerState<BrokerHistoryScreen> createState() => _BrokerHistoryScreenState();
}

class _BrokerHistoryScreenState extends ConsumerState<BrokerHistoryScreen> {
  _HistoryFilter _filter = _HistoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final shipments = ref.watch(brokerHistoryProvider);
    final filteredShipments = shipments.where((shipment) {
      switch (_filter) {
        case _HistoryFilter.all:
          return true;
        case _HistoryFilter.completed:
          return shipment.status.toLowerCase().contains('completed');
        case _HistoryFilter.cancelled:
          return shipment.status.toLowerCase().contains('cancel');
        case _HistoryFilter.accepted:
          return shipment.status.toLowerCase().contains('accept');
      }
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        Text(
          'Booking history',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _HistoryFilterButton(
                label: 'All',
                selected: _filter == _HistoryFilter.all,
                onTap: () => setState(() => _filter = _HistoryFilter.all),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryFilterButton(
                label: 'Completed',
                selected: _filter == _HistoryFilter.completed,
                onTap: () => setState(() => _filter = _HistoryFilter.completed),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryFilterButton(
                label: 'Cancelled',
                selected: _filter == _HistoryFilter.cancelled,
                onTap: () => setState(() => _filter = _HistoryFilter.cancelled),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryFilterButton(
                label: 'Accepted',
                selected: _filter == _HistoryFilter.accepted,
                onTap: () => setState(() => _filter = _HistoryFilter.accepted),
              ),
            ),
          ],
          ),
        const SizedBox(height: 14),
        if (filteredShipments.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Center(
              child: Text(
                'No bookings found for this filter.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                    ),
              ),
            ),
          )
        else
          ...filteredShipments.asMap().entries.expand(
                (entry) => [
                  PackageTrackingCard(
                    shipment: entry.value,
                    onTap: () => context.push('/client/tracking/details', extra: entry.value),
                  ),
                  if (entry.key != filteredShipments.length - 1) const SizedBox(height: 12),
                ],
              ),
      ],
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  const _HistoryFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? const Color(0xFF1F88C9) : const Color(0xFF667085);
    final backgroundColor = selected ? const Color(0xFFEFF6FF) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1F88C9).withValues(alpha: 0.24)
                  : const Color(0xFFE8EDF2),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
