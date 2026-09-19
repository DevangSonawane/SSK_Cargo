import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../widgets/broker_flow_widgets.dart';

class BrokerHomeScreen extends ConsumerStatefulWidget {
  const BrokerHomeScreen({super.key});

  @override
  ConsumerState<BrokerHomeScreen> createState() => _BrokerHomeScreenState();
}

class _BrokerHomeScreenState extends ConsumerState<BrokerHomeScreen> {
  static const _requestsQuery = (page: 1, limit: 100);
  static const BrokerDriversQuery _driversQuery = (
    status: null,
    page: 1,
    limit: 100,
  );
  static const BrokerTrucksQuery _trucksQuery = (
    status: null,
    page: 1,
    limit: 100,
  );
  final TextEditingController _searchController = TextEditingController();
  StreamSubscription<Map<String, dynamic>>? _jobRequestSubscription;

  bool _sortNewestFirst = true;
  final Set<String> _busyRequestIds = <String>{};

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
      final aPending = isPendingBookingRequest(a);
      final bPending = isPendingBookingRequest(b);
      if (aPending != bPending) {
        return aPending ? -1 : 1;
      }
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

  Future<void> _runRequestAction(
    BookingRequest request,
    Future<void> Function(String accessToken) action, {
    required String successMessage,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _busyRequestIds.contains(request.id)) {
      return;
    }

    setState(() => _busyRequestIds.add(request.id));
    try {
      await action(session.tokens.accessToken);
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: const Color(0xFF2FA56E),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(request.id));
      }
    }
  }

  Future<void> _acceptRequest(BookingRequest request) {
    return _runRequestAction(
      request,
      (token) => ref
          .read(apiClientProvider)
          .acceptJobRequest(accessToken: token, id: request.id)
          .then((_) {}),
      successMessage: 'Request accepted.',
    );
  }

  Future<void> _declineRequest(BookingRequest request) {
    return _runRequestAction(
      request,
      (token) => ref
          .read(apiClientProvider)
          .declineJobRequest(accessToken: token, id: request.id)
          .then((_) {}),
      successMessage: 'Request declined.',
    );
  }

  Future<void> _counterRequest(BookingRequest request) async {
    final amount = await _showCounterAmountSheet(request);
    if (amount == null || amount <= 0) {
      return;
    }
    await _runRequestAction(
      request,
      (token) => ref
          .read(apiClientProvider)
          .counterJobRequest(accessToken: token, id: request.id, amount: amount)
          .then((_) {}),
      successMessage: 'Counter sent.',
    );
  }

  Future<bool> _assignRequest(
    BookingRequest request, {
    required String driverId,
    required String truckId,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _busyRequestIds.contains(request.id)) {
      return false;
    }

    setState(() => _busyRequestIds.add(request.id));
    try {
      await ref
          .read(apiClientProvider)
          .assignDriverToJob(
            accessToken: session.tokens.accessToken,
            id: request.id,
            driverId: driverId,
            truckId: truckId,
          );
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
      ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      ref.invalidate(brokerDriversApiProvider(_driversQuery));
      ref.invalidate(brokerTrucksProvider(_trucksQuery));

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Offer sent to the driver - waiting for response.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
      return false;
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(request.id));
      }
    }
  }

  Future<void> _showAssignmentSheet(BookingRequest request) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HomeAssignmentSheet(
        request: request,
        onAssign: (driverId, truckId) =>
            _assignRequest(request, driverId: driverId, truckId: truckId),
      ),
    );
  }

  Future<double?> _showCounterAmountSheet(BookingRequest request) {
    final initialAmount = _amountFromText(request.value);
    final controller = TextEditingController(
      text: initialAmount > 0 ? initialAmount.toStringAsFixed(0) : '',
    );
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send counter-offer',
                    style: Theme.of(sheetContext).textTheme.titleLarge
                        ?.copyWith(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Booking #${request.id} - propose a different amount.',
                    style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(AppIcons.currency_rupee_rounded),
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final amount = _amountFromText(controller.text);
                            Navigator.of(sheetContext).pop(amount);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF2152D0),
                          ),
                          child: const Text('Send counter'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  double _amountFromText(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _greetingName() {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName.trim() ?? '';
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
    final pendingCount = _countMatching(
      requests,
      isBrokerJobRequestAttentionCount,
    );

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
              const SizedBox(height: 14),
              _NewBookingsHero(pendingCount: pendingCount),
              const SizedBox(height: 14),
              _SearchField(
                controller: _searchController,
                hintText: 'Search booking ID, location...',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
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
                    onPressed: () =>
                        setState(() => _sortNewestFirst = !_sortNewestFirst),
                    icon: Icon(
                      _sortNewestFirst
                          ? AppIcons.south_rounded
                          : AppIcons.north_rounded,
                    ),
                    label: const Text('Sort'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3256D3),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              requestsAsync.when(
                data: (_) {
                  if (visibleRequests.isEmpty) {
                    return _EmptyBookingsState(
                      title: 'No bookings found',
                      subtitle: pendingCount > 0
                          ? 'There are $pendingCount request(s), but none match the current search.'
                          : 'Try clearing the search field to see more requests.',
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final useGrid = constraints.maxWidth >= 760;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final request in visibleRequests)
                            SizedBox(
                              width: useGrid
                                  ? (constraints.maxWidth - 12) / 2
                                  : constraints.maxWidth,
                              child: _BookingRequestCard(
                                request: request,
                                busy: _busyRequestIds.contains(request.id),
                                onTap: () async {
                                  final changed = await context.push<bool>(
                                    '/broker/request',
                                    extra: request,
                                  );
                                  if (changed == true && mounted) {
                                    await _refresh();
                                  }
                                },
                                onAccept: () => _acceptRequest(request),
                                onCounter: () => _counterRequest(request),
                                onDecline: () => _declineRequest(request),
                                onAssign: () => _showAssignmentSheet(request),
                              ),
                            ),
                        ],
                      );
                    },
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
                  icon: const Icon(AppIcons.refresh_rounded),
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
  const _NewBookingsHero({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              AppIcons.inventory_2_outlined,
              color: Color(0xFF2152D0),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New bookings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  pendingCount == 1
                      ? '1 request needs attention'
                      : '$pendingCount requests need attention',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              pendingCount.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
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
            AppIcons.search_rounded,
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

class _BookingRequestCard extends StatelessWidget {
  const _BookingRequestCard({
    required this.request,
    required this.busy,
    required this.onTap,
    required this.onAccept,
    required this.onCounter,
    required this.onDecline,
    required this.onAssign,
  });

  final BookingRequest request;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onDecline;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final pickupText = _locationText(
      request.from,
      'Pickup location unavailable',
    );
    final dropText = _locationText(request.to, 'Drop-off location unavailable');
    final status = _normalizeStatus(request.status);
    final amountText = _formatRequestAmount(request.value);
    final counterLimitReached =
        request.maxCountersPerSide > 0 &&
        request.respondentCountersUsed >= request.maxCountersPerSide;
    final showPrimaryActions = _isOpenRequestStatus(status);
    final showConfirmActions =
        status == 'awaiting_confirmation' &&
        const {
          'client',
          '',
        }.contains(request.pendingConfirmationBy.trim().toLowerCase());
    final showAssignAction = const {
      'accepted',
      'confirmed',
      'assigned',
    }.contains(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 5,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            _bookingRef(request),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF94A3B8),
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          _TruckTypeBadge(label: request.vehicleType),
                          if (request.isExpress)
                            const ExpressBadge(compact: true),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_locationLead(pickupText)} to ${_locationLead(dropText)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: const Color(0xFF0F172A),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              height: 1.25,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF0F172A),
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          AppIcons.schedule_rounded,
                          size: 12,
                          color: Color(0xFF94A3B8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.requestedAt.isEmpty
                              ? 'Just now'
                              : request.requestedAt,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                _JobLocationRow(
                  label: 'Pickup',
                  value: pickupText,
                  iconColor: const Color(0xFF10B981),
                ),
                const SizedBox(height: 8),
                _JobLocationRow(
                  label: 'Drop',
                  value: dropText,
                  iconColor: const Color(0xFFEF4444),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _JobMetricTile(
                    label: 'Distance',
                    value: _distanceText(request.distance),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _JobMetricTile(
                    label: 'Weight',
                    value: request.weight.trim().isEmpty ? '-' : request.weight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _JobMetricTile(
                    label: 'Client',
                    value: request.clientName,
                  ),
                ),
              ],
            ),
            if (request.offerHistory.length > 1) ...[
              const SizedBox(height: 12),
              _NegotiationHistory(entries: request.offerHistory),
            ],
            const SizedBox(height: 12),
            if (showAssignAction) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAssign,
                  icon: const Icon(AppIcons.local_shipping_rounded, size: 17),
                  label: const Text('Assign Driver & Truck'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2152D0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ] else if (status == 'countered') ...[
              _InlineStatusNote(
                icon: AppIcons.schedule_rounded,
                text: 'Waiting for client response to your $amountText offer',
                color: const Color(0xFFD97706),
                backgroundColor: const Color(0xFFFFFBEB),
                borderColor: const Color(0xFFFDE68A),
              ),
            ] else if (status == 'awaiting_confirmation' &&
                !showConfirmActions) ...[
              _InlineStatusNote(
                icon: AppIcons.schedule_rounded,
                text: 'You accepted - waiting for the client to confirm',
                color: const Color(0xFF0F766E),
                backgroundColor: const Color(0xFFF0FDFA),
                borderColor: const Color(0xFF99F6E4),
              ),
            ] else if (showConfirmActions) ...[
              Row(
                children: [
                  Expanded(
                    child: _JobActionButton(
                      label: 'Confirm',
                      icon: AppIcons.check_circle_outline_rounded,
                      color: const Color(0xFF047857),
                      borderColor: const Color(0xFFA7F3D0),
                      onPressed: busy ? null : onAccept,
                      loading: busy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JobActionButton(
                      label: 'Decline',
                      icon: AppIcons.cancel_outlined,
                      color: const Color(0xFF64748B),
                      borderColor: const Color(0xFFE2E8F0),
                      onPressed: busy ? null : onDecline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _ActionHint(
                text:
                    'The client accepted at $amountText - confirm to finalize the booking.',
              ),
            ] else if (showPrimaryActions) ...[
              Row(
                children: [
                  Expanded(
                    child: _JobActionButton(
                      label: 'Accept',
                      icon: AppIcons.check_circle_outline_rounded,
                      color: const Color(0xFF047857),
                      borderColor: const Color(0xFFA7F3D0),
                      onPressed: busy ? null : onAccept,
                      loading: busy,
                    ),
                  ),
                  if (!counterLimitReached) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _JobActionButton(
                        label: 'Counter',
                        icon: AppIcons.currency_rupee_rounded,
                        color: const Color(0xFF2152D0),
                        borderColor: const Color(0xFFC7D7FE),
                        onPressed: busy ? null : onCounter,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JobActionButton(
                      label: 'Decline',
                      icon: AppIcons.cancel_outlined,
                      color: const Color(0xFF64748B),
                      borderColor: const Color(0xFFE2E8F0),
                      onPressed: busy ? null : onDecline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _ActionHint(
                text: counterLimitReached
                    ? 'You have used your counter-offers - accept or decline instead.'
                    : 'Your offer of $amountText is live - accept to lock it in, or counter/decline.',
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(AppIcons.open_in_new_rounded, size: 16),
                  label: const Text('Review request'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF2152D0),
                    side: const BorderSide(color: Color(0xFFC7D7FE)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  AppIcons.phone_outlined,
                  size: 13,
                  color: Color(0xFF94A3B8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      request.clientName,
                      if (request.clientPhone.isNotEmpty) request.clientPhone,
                      if (request.requestedAt.isNotEmpty) request.requestedAt,
                    ].join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w700,
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

class _HomeAssignmentSheet extends ConsumerStatefulWidget {
  const _HomeAssignmentSheet({required this.request, required this.onAssign});

  final BookingRequest request;
  final Future<bool> Function(String driverId, String truckId) onAssign;

  @override
  ConsumerState<_HomeAssignmentSheet> createState() =>
      _HomeAssignmentSheetState();
}

class _HomeAssignmentSheetState extends ConsumerState<_HomeAssignmentSheet> {
  String? _driverId;
  String? _truckId;
  bool _defaultsApplied = false;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(
      brokerDriversApiProvider(_BrokerHomeScreenState._driversQuery),
    );
    final trucksAsync = ref.watch(
      brokerTrucksProvider(_BrokerHomeScreenState._trucksQuery),
    );

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: driversAsync.when(
              loading: () => const _AssignmentLoadingState(),
              error: (error, _) => _AssignmentErrorState(
                message: error.toString().replaceFirst('Exception: ', ''),
                onRetry: () {
                  ref.invalidate(
                    brokerDriversApiProvider(
                      _BrokerHomeScreenState._driversQuery,
                    ),
                  );
                },
              ),
              data: (drivers) => trucksAsync.when(
                loading: () => const _AssignmentLoadingState(),
                error: (error, _) => _AssignmentErrorState(
                  message: error.toString().replaceFirst('Exception: ', ''),
                  onRetry: () {
                    ref.invalidate(
                      brokerTrucksProvider(_BrokerHomeScreenState._trucksQuery),
                    );
                  },
                ),
                data: (trucks) => _buildContent(drivers, trucks),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<BrokerDriver> drivers, List<BrokerVehicle> trucks) {
    _applyDefaults(drivers, trucks);
    final selectedDriver = _findDriverById(drivers, _driverId);
    final selectedTruck = _findTruckById(trucks, _truckId);
    final canConfirm =
        selectedDriver != null &&
        selectedTruck != null &&
        _isAssignableDriver(selectedDriver) &&
        _isAssignableTruck(selectedTruck) &&
        !_submitting;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                AppIcons.local_shipping_rounded,
                color: Color(0xFF2152D0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign Driver & Truck',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF0F172A),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${_bookingRef(widget.request)} - choose an idle driver and truck.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AssignmentDropdown<BrokerDriver>(
          label: 'Driver',
          icon: AppIcons.person_rounded,
          value: selectedDriver?.id,
          items: drivers,
          idOf: (driver) => driver.id,
          enabledOf: _isAssignableDriver,
          titleOf: (driver) => driver.name.isNotEmpty ? driver.name : driver.id,
          subtitleOf: (driver) => [
            if (driver.phone.isNotEmpty) driver.phone,
            driverStatusLabel(driver.status),
          ].join(' - '),
          onChanged: (value) {
            if (value == null) return;
            final driver = _findDriverById(drivers, value);
            setState(() {
              _driverId = value;
              final linkedTruck = _truckForDriver(trucks, driver);
              if (linkedTruck != null) {
                _truckId = linkedTruck.id;
              }
            });
          },
        ),
        const SizedBox(height: 12),
        _AssignmentDropdown<BrokerVehicle>(
          label: 'Truck',
          icon: AppIcons.fire_truck_rounded,
          value: selectedTruck?.id,
          items: trucks,
          idOf: (truck) => truck.id,
          enabledOf: _isAssignableTruck,
          titleOf: _truckTitle,
          subtitleOf: (truck) => [
            if (truck.capacity.isNotEmpty) truck.capacity,
            vehicleStatusLabel(truck.status),
          ].join(' - '),
          onChanged: (value) => setState(() => _truckId = value),
        ),
        if (!canConfirm) ...[
          const SizedBox(height: 10),
          Text(
            'Select one idle driver and one idle truck to continue.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFFE23A4B)),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: canConfirm
                    ? () async {
                        setState(() => _submitting = true);
                        final saved = await widget.onAssign(
                          selectedDriver.id,
                          selectedTruck.id,
                        );
                        if (!mounted) return;
                        if (saved) {
                          Navigator.of(context).pop();
                        } else {
                          setState(() => _submitting = false);
                        }
                      }
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2152D0),
                ),
                child: Text(_submitting ? 'Sending...' : 'Send Assignment'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _applyDefaults(List<BrokerDriver> drivers, List<BrokerVehicle> trucks) {
    if (_defaultsApplied) return;
    _driverId = _defaultDriverId(drivers);
    _truckId = _defaultTruckId(trucks);
    final driver = _findDriverById(drivers, _driverId);
    final linkedTruck = _truckForDriver(trucks, driver);
    if (linkedTruck != null) {
      _truckId = linkedTruck.id;
    }
    _defaultsApplied = true;
  }

  String? _defaultDriverId(List<BrokerDriver> drivers) {
    final explicitId = widget.request.driverId.trim();
    if (explicitId.isNotEmpty) {
      for (final driver in drivers) {
        if (driver.id == explicitId && _isAssignableDriver(driver)) {
          return driver.id;
        }
      }
    }
    for (final driver in drivers) {
      if (_isAssignableDriver(driver)) return driver.id;
    }
    return null;
  }

  String? _defaultTruckId(List<BrokerVehicle> trucks) {
    final explicitId = widget.request.truckId.trim();
    if (explicitId.isNotEmpty) {
      for (final truck in trucks) {
        if (truck.id == explicitId && _isAssignableTruck(truck)) {
          return truck.id;
        }
      }
    }
    for (final truck in trucks) {
      if (_isAssignableTruck(truck) &&
          truck.label.toLowerCase() ==
              widget.request.vehicleType.trim().toLowerCase()) {
        return truck.id;
      }
    }
    for (final truck in trucks) {
      if (_isAssignableTruck(truck)) return truck.id;
    }
    return null;
  }

  BrokerDriver? _findDriverById(List<BrokerDriver> drivers, String? id) {
    if (id == null) return null;
    for (final driver in drivers) {
      if (driver.id == id) return driver;
    }
    return null;
  }

  BrokerVehicle? _findTruckById(List<BrokerVehicle> trucks, String? id) {
    if (id == null) return null;
    for (final truck in trucks) {
      if (truck.id == id) return truck;
    }
    return null;
  }

  BrokerVehicle? _truckForDriver(
    List<BrokerVehicle> trucks,
    BrokerDriver? driver,
  ) {
    if (driver == null) return null;
    final assigned = driver.assignedVehicle.trim().toLowerCase();
    if (assigned.isEmpty) return null;
    for (final truck in trucks) {
      final plate = truck.plateNumber.trim().toLowerCase();
      final id = truck.id.trim().toLowerCase();
      if (_isAssignableTruck(truck) && (assigned == plate || assigned == id)) {
        return truck;
      }
    }
    return null;
  }

  bool _isAssignableDriver(BrokerDriver driver) {
    return driver.status == BrokerDriverStatus.idle;
  }

  bool _isAssignableTruck(BrokerVehicle truck) {
    return truck.status == BrokerVehicleStatus.idle;
  }

  String _truckTitle(BrokerVehicle truck) {
    final plate = truck.plateNumber.isNotEmpty ? truck.plateNumber : truck.id;
    return '${truck.label} - $plate';
  }
}

class _AssignmentDropdown<T> extends StatelessWidget {
  const _AssignmentDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.idOf,
    required this.enabledOf,
    required this.titleOf,
    required this.subtitleOf,
    required this.onChanged,
  });

  final String label;
  final IconData icon;
  final String? value;
  final List<T> items;
  final String Function(T item) idOf;
  final bool Function(T item) enabledOf;
  final String Function(T item) titleOf;
  final String Function(T item) subtitleOf;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedExists = items.any((item) => idOf(item) == value);
    return DropdownButtonFormField<String>(
      initialValue: selectedExists ? value : null,
      isExpanded: true,
      itemHeight: 64,
      menuMaxHeight: 320,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2152D0)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      hint: Text('Select ${label.toLowerCase()}'),
      selectedItemBuilder: (context) => [
        for (final item in items)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              titleOf(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
      items: [
        for (final item in items)
          DropdownMenuItem<String>(
            value: idOf(item),
            enabled: enabledOf(item),
            child: SizedBox(
              height: 56,
              child: Opacity(
                opacity: enabledOf(item) ? 1 : 0.48,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleOf(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleOf(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _AssignmentLoadingState extends StatelessWidget {
  const _AssignmentLoadingState();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _AssignmentErrorState extends StatelessWidget {
  const _AssignmentErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Could not load assignment options',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF64748B)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refresh_rounded),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2152D0),
            ),
          ),
        ),
      ],
    );
  }
}

class _TruckTypeBadge extends StatelessWidget {
  const _TruckTypeBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.trim().isEmpty ? 'Truck' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: const Color(0xFF2152D0),
          fontWeight: FontWeight.w900,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _JobLocationRow extends StatelessWidget {
  const _JobLocationRow({
    required this.label,
    required this.value,
    required this.iconColor,
  });

  final String label;
  final String value;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            AppIcons.location_on_outlined,
            size: 14,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF334155),
                  fontWeight: FontWeight.w700,
                  height: 1.32,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JobMetricTile extends StatelessWidget {
  const _JobMetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
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

class _NegotiationHistory extends StatelessWidget {
  const _NegotiationHistory({required this.entries});

  final List<BookingOfferHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                AppIcons.history_rounded,
                size: 12,
                color: Color(0xFF94A3B8),
              ),
              const SizedBox(width: 5),
              Text(
                'NEGOTIATION HISTORY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          for (final entry in entries) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.by == 'broker' ? 'You offered' : 'Client offered',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatRupees(entry.amount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: const Color(0xFF334155),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            if (entry != entries.last) const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }
}

class _JobActionButton extends StatelessWidget {
  const _JobActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.borderColor,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color borderColor;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 15),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: borderColor),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _ActionHint extends StatelessWidget {
  const _ActionHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: const Color(0xFF94A3B8),
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    );
  }
}

class _InlineStatusNote extends StatelessWidget {
  const _InlineStatusNote({
    required this.icon,
    required this.text,
    this.color = const Color(0xFF64748B),
    this.backgroundColor = const Color(0xFFF8FAFC),
    this.borderColor = const Color(0xFFE2E8F0),
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyBookingsState extends StatelessWidget {
  const _EmptyBookingsState({required this.title, required this.subtitle});

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
              AppIcons.inbox_rounded,
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
  const _NotificationButton({required this.onTap, required this.count});

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
            child: const Icon(
              AppIcons.notifications_none_rounded,
              color: Color(0xFF334155),
            ),
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

String _normalizeStatus(String status) {
  return status.trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
}

bool _isOpenRequestStatus(String status) {
  return const {
    '',
    'unknown',
    'pending',
    'requested',
    'new',
    'open',
    'open_request',
    'review',
    'review_request',
    'awaiting',
    'awaiting_action',
    'waiting',
  }.contains(status);
}

String _locationText(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String _locationLead(String value) {
  final trimmed = _locationText(value, 'Location unavailable');
  final index = trimmed.indexOf(',');
  if (index <= 0) {
    return trimmed;
  }
  return trimmed.substring(0, index).trim();
}

String _bookingRef(BookingRequest request) {
  final id = request.id.trim();
  if (id.isEmpty) return '#REQUEST';
  final normalized = id.startsWith('#') ? id.substring(1) : id;
  return '#${normalized.toUpperCase()}';
}

String _formatRequestAmount(String raw) {
  final numeric = double.tryParse(raw.replaceAll(RegExp(r'[^0-9.]'), ''));
  if (numeric == null || numeric <= 0) {
    return raw.trim().isEmpty ? '₹0' : raw.trim();
  }
  return _formatRupees(numeric);
}

String _formatRupees(double amount) {
  final fixed = amount.round().toString();
  if (fixed.length <= 3) {
    return '₹$fixed';
  }
  final suffix = fixed.substring(fixed.length - 3);
  var prefix = fixed.substring(0, fixed.length - 3);
  final groups = <String>[];
  while (prefix.length > 2) {
    groups.insert(0, prefix.substring(prefix.length - 2));
    prefix = prefix.substring(0, prefix.length - 2);
  }
  if (prefix.isNotEmpty) {
    groups.insert(0, prefix);
  }
  return '₹${groups.join(',')},$suffix';
}

String _distanceText(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty || trimmed == '0') return '-';
  if (trimmed.toLowerCase().contains('km')) return trimmed;
  return '$trimmed km';
}
