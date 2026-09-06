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
    final requestsAsync = ref.watch(brokerJobRequestsProvider((page: 1, limit: 100)));
    final requests = requestsAsync.valueOrNull ?? const <BookingRequest>[];
    final filteredRequests = requests.where((request) {
      switch (_filter) {
        case _HistoryFilter.all:
          return !isPendingBookingRequest(request);
        case _HistoryFilter.completed:
          return isCompletedBookingRequest(request);
        case _HistoryFilter.cancelled:
          return isCancelledBookingRequest(request);
        case _HistoryFilter.accepted:
          return isAcceptedBookingRequest(request);
      }
    }).toList();
    final shipments = filteredRequests.map(brokerRequestToShipment).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      children: [
        _HistoryPageHeader(
          onNotificationsTap: () => context.push('/broker/notifications'),
          onProfileTap: () => context.push('/broker/profile'),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Container(
              width: 6,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFF1478E8),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Booking History',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF10245B),
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _HistoryFilterButton(
                label: 'All',
                icon: Icons.grid_view_rounded,
                selected: _filter == _HistoryFilter.all,
                onTap: () => setState(() => _filter = _HistoryFilter.all),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryFilterButton(
                label: 'Completed',
                icon: Icons.check_circle_outline_rounded,
                selected: _filter == _HistoryFilter.completed,
                onTap: () => setState(() => _filter = _HistoryFilter.completed),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryFilterButton(
                label: 'Cancelled',
                icon: Icons.cancel_outlined,
                selected: _filter == _HistoryFilter.cancelled,
                onTap: () => setState(() => _filter = _HistoryFilter.cancelled),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _HistoryFilterButton(
                label: 'Accepted',
                icon: Icons.check_circle_outline_rounded,
                selected: _filter == _HistoryFilter.accepted,
                onTap: () => setState(() => _filter = _HistoryFilter.accepted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        requestsAsync.when(
          data: (_) {
            if (shipments.isEmpty) {
              return Container(
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
              );
            }

            return Column(
              children: [
                for (var index = 0; index < shipments.length; index++) ...[
                  PackageTrackingCard(
                    shipment: shipments[index],
                  ),
                  if (index != shipments.length - 1) const SizedBox(height: 12),
                ],
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.only(top: 36),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFFB42318),
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryPageHeader extends StatelessWidget {
  const _HistoryPageHeader({
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 12,
        20,
        24,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Review recent bookings',
                  style: TextStyle(
                    color: Color(0xE6FFFFFF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _HistoryHeaderIcon(
            icon: Icons.notifications_none_rounded,
            onTap: onNotificationsTap,
          ),
          const SizedBox(width: 10),
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset('assets/user.png', fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryHeaderIcon extends StatelessWidget {
  const _HistoryHeaderIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _HistoryFilterButton extends StatelessWidget {
  const _HistoryFilterButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foregroundColor = selected ? Colors.white : const Color(0xFF425A88);
    final backgroundColor = selected ? const Color(0xFF1478E8) : Colors.transparent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1478E8)
                  : const Color(0xFFD6E6FA),
            ),
          ),
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: foregroundColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: foregroundColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
