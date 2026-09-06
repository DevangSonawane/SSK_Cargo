import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

enum _BrokerBookingFilter { all, pending, accepted, declined }

class BrokerHomeScreen extends ConsumerStatefulWidget {
  const BrokerHomeScreen({super.key});

  @override
  ConsumerState<BrokerHomeScreen> createState() => _BrokerHomeScreenState();
}

class _BrokerHomeScreenState extends ConsumerState<BrokerHomeScreen> {
  static const _requestsQuery = (page: 1, limit: 100);
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _jobRequestSubscription;

  _BrokerBookingFilter _filter = _BrokerBookingFilter.all;
  bool _sortNewestFirst = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_connectSocket());
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _jobRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
    await ref.read(brokerJobRequestsProvider(_requestsQuery).future);
  }

  Future<void> _connectSocket() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );

    await _jobRequestSubscription?.cancel();
    _jobRequestSubscription = socketService.jobRequestStream.listen((_) {
      if (!mounted) return;
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
    });
  }

  List<BookingRequest> _visibleRequests(List<BookingRequest> requests) {
    final query = _searchController.text.trim().toLowerCase();

    final filtered = requests.where((request) {
      final status = _normalizeStatus(request.status);
      final matchesFilter = switch (_filter) {
        _BrokerBookingFilter.all => true,
        _BrokerBookingFilter.pending => isPendingBookingRequest(request),
        _BrokerBookingFilter.accepted => isAcceptedBookingRequest(request),
        _BrokerBookingFilter.declined => isDeclinedBookingRequest(request),
      };
      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final haystack = [
        request.id,
        request.productName,
        request.from,
        request.to,
        request.weight,
        request.vehicleType,
        request.clientName,
        request.value,
        status,
      ].join(' ').toLowerCase();

      return haystack.contains(query);
    }).toList();

    filtered.sort((a, b) {
      final aTime = _parseDate(a.requestedAt);
      final bTime = _parseDate(b.requestedAt);
      final comparison = aTime.compareTo(bTime);
      return _sortNewestFirst ? -comparison : comparison;
    });

    return filtered;
  }

  DateTime _parseDate(String raw) {
    final parsed = DateTime.tryParse(raw);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  int _countMatching(
    List<BookingRequest> requests,
    bool Function(BookingRequest request) predicate,
  ) {
    return requests.where(predicate).length;
  }

  String _greetingName() {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName?.trim() ?? '';
    if (displayName.isEmpty) {
      return 'Test';
    }
    return displayName.split(' ').first;
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(brokerJobRequestsProvider(_requestsQuery));
    final requests = requestsAsync.valueOrNull ?? const <BookingRequest>[];
    final visibleRequests = _visibleRequests(requests);
    final pendingCount = _countMatching(requests, isPendingBookingRequest);
    final acceptedCount = _countMatching(requests, isAcceptedBookingRequest);
    final declinedCount = _countMatching(requests, isDeclinedBookingRequest);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF2152D0),
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              _BrokerHomeTopBar(
                greetingName: _greetingName(),
                onNotificationsTap: () => context.push('/broker/notifications'),
                onProfileTap: () => context.push('/broker/profile'),
              ),
              const SizedBox(height: 18),
              _NewBookingsHero(
                pendingCount: pendingCount,
                onTap: () {
                  setState(() => _filter = _BrokerBookingFilter.pending);
                },
              ),
              const SizedBox(height: 18),
              _SearchField(
                controller: _searchController,
                hintText: 'Search booking ID, location...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _FilterChip(
                    label: 'All',
                    count: requests.length,
                    selected: _filter == _BrokerBookingFilter.all,
                    color: const Color(0xFF2152D0),
                    onTap: () => setState(() => _filter = _BrokerBookingFilter.all),
                  ),
                  _FilterChip(
                    label: 'Pending',
                    count: pendingCount,
                    selected: _filter == _BrokerBookingFilter.pending,
                    color: const Color(0xFFF59E0B),
                    onTap: () =>
                        setState(() => _filter = _BrokerBookingFilter.pending),
                  ),
                  _FilterChip(
                    label: 'Accepted',
                    count: acceptedCount,
                    selected: _filter == _BrokerBookingFilter.accepted,
                    color: const Color(0xFF22C55E),
                    onTap: () =>
                        setState(() => _filter = _BrokerBookingFilter.accepted),
                  ),
                  _FilterChip(
                    label: 'Declined',
                    count: declinedCount,
                    selected: _filter == _BrokerBookingFilter.declined,
                    color: const Color(0xFFEF4444),
                    onTap: () =>
                        setState(() => _filter = _BrokerBookingFilter.declined),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Booking Requests',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _sortNewestFirst = !_sortNewestFirst),
                    icon: Icon(
                      _sortNewestFirst
                          ? Icons.south_rounded
                          : Icons.north_rounded,
                    ),
                    label: const Text('Sort'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3256D3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              requestsAsync.when(
                data: (_) {
                  if (visibleRequests.isEmpty) {
                    return _EmptyBookingsState(
                      title: 'No bookings match this filter',
                      subtitle:
                          'Try another status tab or clear the search field to see more requests.',
                    );
                  }

                  return Column(
                    children: [
                      for (var index = 0; index < visibleRequests.length; index++) ...[
                        _BookingRequestCard(
                          request: visibleRequests[index],
                          onTap: () => context.push(
                            '/broker/request',
                            extra: visibleRequests[index],
                          ),
                        ),
                        if (index != visibleRequests.length - 1)
                          const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _EmptyBookingsState(
                  title: 'Could not load bookings',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reload requests'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrokerHomeTopBar extends StatelessWidget {
  const _BrokerHomeTopBar({
    required this.greetingName,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final String greetingName;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Hello, ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                  children: [
                    TextSpan(
                      text: '$greetingName 👋',
                      style: const TextStyle(color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'Good morning',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        _NotificationButton(onTap: onNotificationsTap, count: 1),
        const SizedBox(width: 12),
        _AvatarButton(onTap: onProfileTap),
      ],
    );
  }
}

class _NewBookingsHero extends StatelessWidget {
  const _NewBookingsHero({
    required this.pendingCount,
    required this.onTap,
  });

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            colors: [Color(0xFF5F83FF), Color(0xFFB5CCFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5F83FF).withValues(alpha: 0.22),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New bookings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'waiting for you',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 1,
                    color: Colors.white.withValues(alpha: 0.24),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Text(
                        pendingCount.toString(),
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Pending',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF2F5AE5),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 50,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      const SizedBox(height: 8),
                      Icon(
                        Icons.location_on_outlined,
                        size: 34,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF64748B),
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Icon(Icons.tune_rounded, color: Color(0xFF64748B)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? color.withValues(alpha: 0.12) : Colors.white;
    final textColor = selected ? color : const Color(0xFF334155);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? color.withValues(alpha: 0.24) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: selected ? color : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF475569),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingRequestCard extends StatelessWidget {
  const _BookingRequestCard({
    required this.request,
    required this.onTap,
  });

  final BookingRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _bookingRequestVisual(request.status);
    final pickupText = _locationText(
      request.from,
      'Pickup location unavailable',
    );
    final dropText = _locationText(
      request.to,
      'Drop-off location unavailable',
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7EDF5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusBadge(visual: visual),
                const Spacer(),
                Text(
                  request.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF2152D0),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(Icons.more_vert_rounded, color: Color(0xFF334155)),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Load ID',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '#${request.id.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              request.requestedAt.isEmpty ? 'Requested just now' : request.requestedAt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667085),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(width: 36, child: _RouteLine()),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RoutePoint(
                        label: 'Pickup',
                        icon: Icons.location_on_rounded,
                        place: pickupText,
                      ),
                      const SizedBox(height: 16),
                      _RoutePoint(
                        label: 'Drop-off',
                        icon: Icons.send_rounded,
                        place: dropText,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F8FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: Color(0xFF2152D0)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${request.weight} • ${request.vehicleType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: visual.backgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: visual.borderColor),
              ),
              child: Row(
                children: [
                  Icon(visual.icon, size: 16, color: visual.textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      visual.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: visual.textColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.visual});

  final _BookingVisual visual;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: visual.backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        visual.label,
        style: TextStyle(
          color: visual.textColor,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _RoutePoint extends StatelessWidget {
  const _RoutePoint({
    required this.label,
    required this.icon,
    required this.place,
  });

  final String label;
  final IconData icon;
  final String place;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF4FF),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF2152D0), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                place,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF0F172A),
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

class _RouteLine extends StatelessWidget {
  const _RouteLine();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF2152D0),
            shape: BoxShape.circle,
          ),
        ),
        Container(
          width: 2,
          height: 56,
          margin: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: const Color(0xFF2152D0).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7EDF5)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF4FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_rounded,
              color: Color(0xFF2152D0),
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.onTap});

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
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset('assets/user.png', fit: BoxFit.cover),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({
    required this.onTap,
    required this.count,
  });

  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(Icons.notifications_none_rounded, color: Color(0xFF334155)),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 3,
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Icon(icon, color: iconColor),
      ),
    );
  }
}

class _SortSheet extends StatelessWidget {
  const _SortSheet({
    required this.newestFirst,
    required this.onChanged,
  });

  final bool newestFirst;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort bookings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _SortOption(
              label: 'Newest first',
              selected: newestFirst,
              onTap: () => onChanged(true),
            ),
            const SizedBox(height: 10),
            _SortOption(
              label: 'Oldest first',
              selected: !newestFirst,
              onTap: () => onChanged(false),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF4FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF2152D0) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _BookingVisual {
  const _BookingVisual({
    required this.label,
    required this.description,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final String description;
  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
}

_BookingVisual _bookingRequestVisual(String status) {
  final normalized = _normalizeStatus(status);
  switch (normalized) {
    case 'pending':
    case 'requested':
    case 'new':
      return const _BookingVisual(
        label: 'Pending',
        description: 'Waiting for your review',
        backgroundColor: Color(0xFFEFF4FF),
        borderColor: Color(0xFFC7D7FE),
        textColor: Color(0xFF2152D0),
        icon: Icons.schedule_rounded,
      );
    case 'accepted':
    case 'confirmed':
    case 'assigned':
      return const _BookingVisual(
        label: 'Accepted',
        description: 'Request accepted',
        backgroundColor: Color(0xFFEAF8EF),
        borderColor: Color(0xFFB7E4C7),
        textColor: Color(0xFF136F3E),
        icon: Icons.check_circle_rounded,
      );
    case 'declined':
    case 'rejected':
    case 'expired':
      return const _BookingVisual(
        label: 'Declined',
        description: 'Declined - no longer available',
        backgroundColor: Color(0xFFFDECEC),
        borderColor: Color(0xFFF8B4B4),
        textColor: Color(0xFFB42318),
        icon: Icons.cancel_rounded,
      );
    default:
      return _BookingVisual(
        label: status.isEmpty ? 'Pending' : _titleCase(status),
        description: status.isEmpty ? 'Waiting for your review' : _titleCase(status),
        backgroundColor: const Color(0xFFEFF4FF),
        borderColor: const Color(0xFFC7D7FE),
        textColor: const Color(0xFF2152D0),
        icon: Icons.inbox_rounded,
      );
  }
}

String _normalizeStatus(String status) {
  return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

String _titleCase(String value) {
  return value
      .split(RegExp(r'[_\s]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1))
      .join(' ');
}

String _locationText(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}
