import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/kyc_gate_dialog.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../shared/presentation/widgets/express_badge.dart';
import '../widgets/broker_flow_widgets.dart';
import 'package:ssk/l10n/app_localizations.dart';

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
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;

  bool _sortNewestFirst = true;
  final Set<String> _busyRequestIds = <String>{};

  /// Driver offers sent from this inbox via assign-driver, keyed by job
  /// request id (web `JobRequests.jsx` `pendingAssignments` parity). Keeps
  /// each card showing "waiting on driver / countered / timed-out" instead
  /// of going silent after assignment.
  final Map<String, _PendingDriverOffer> _pendingAssignments = {};

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
    _driverRequestSubscription?.cancel();
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

    // Driver responses to assign-driver offers arrive live here (web
    // `useDriverRequestSocket` parity) — only relevant for job requests
    // this inbox assigned (matched on jobRequestId).
    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen(
      _handleDriverRequestEvent,
    );
    unawaited(_seedPendingAssignments());
  }

  String _payloadString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return '';
  }

  bool _payloadBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) return value;
      if (value is num) return value != 0;
      final text = value?.toString().trim().toLowerCase();
      if (text == 'true' || text == '1') return true;
    }
    return false;
  }

  _PendingDriverOffer? _offerFromPayload(Map<String, dynamic> payload) {
    final jobRequestId = _payloadString(payload, const [
      'jobRequestId',
      'job_request_id',
    ]);
    if (jobRequestId.isEmpty) return null;
    final status = _payloadString(payload, const ['status']).toLowerCase();
    return _PendingDriverOffer(
      jobRequestId: jobRequestId,
      driverName: _payloadString(payload, const ['driverName', 'driver_name']),
      status: status.isEmpty ? 'pending' : status,
      driverTimedOut: _payloadBool(payload, const [
        'driverTimedOut',
        'driver_timed_out',
      ]),
    );
  }

  /// Seeds pending assignments from the broker's driver-requests so cards
  /// assigned in a previous session still show their live state on load.
  Future<void> _seedPendingAssignments() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || !mounted) return;
    try {
      final response = await ref
          .read(apiClientProvider)
          .getDriverRequests(
            accessToken: session.tokens.accessToken,
            page: 1,
            limit: 100,
          );
      final data = response['data'];
      final map = data is Map<String, dynamic> ? data : response;
      Object? raw;
      for (final key in const [
        'requests',
        'driverRequests',
        'driver_requests',
        'items',
        'rows',
        'results',
      ]) {
        raw = map[key] ?? response[key];
        if (raw is List) break;
        raw = null;
      }
      if (raw is! List || !mounted) return;
      var changed = false;
      for (final item in raw) {
        if (item is! Map<String, dynamic>) continue;
        final offer = _offerFromPayload(item);
        if (offer == null || !_isLiveOfferStatus(offer.status)) continue;
        _pendingAssignments[offer.jobRequestId] = offer;
        changed = true;
      }
      if (changed && mounted) setState(() {});
    } catch (_) {
      // Best-effort seeding; live socket events still keep cards fresh.
    }
  }

  bool _isLiveOfferStatus(String status) {
    return const {
      'pending',
      'countered',
      'awaiting_confirmation',
      'requested',
    }.contains(status);
  }

  void _handleDriverRequestEvent(Map<String, dynamic> payload) {
    if (!mounted) return;
    final offer = _offerFromPayload(payload);
    if (offer == null) return;
    final tracked =
        _pendingAssignments.containsKey(offer.jobRequestId) ||
        _isVisibleJobRequest(offer.jobRequestId);
    if (!tracked) return;
    if (offer.status == 'declined' || offer.status == 'expired') {
      final removed = _pendingAssignments.remove(offer.jobRequestId) != null;
      final name = offer.driverName.isNotEmpty
          ? offer.driverName
          : AppLocalizations.of(context)!.brokerHomeTheDriver;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.brokerHomeDeclinedPickADifferentDriverForThis(name),
          ),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
      if (removed && mounted) setState(() {});
      return;
    }
    if (offer.status == 'accepted') {
      _pendingAssignments.remove(offer.jobRequestId);
      final name = offer.driverName.isNotEmpty
          ? offer.driverName
          : AppLocalizations.of(context)!.brokerHomeTheDriver;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.brokerHomeConfirmedTripCreated(name)),
          backgroundColor: AppColors.brand,
        ),
      );
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
      if (mounted) setState(() {});
      return;
    }
    _pendingAssignments[offer.jobRequestId] = offer;
    if (mounted) setState(() {});
  }

  bool _isVisibleJobRequest(String jobRequestId) {
    try {
      final requests = ref
          .read(brokerJobRequestsProvider(_requestsQuery))
          .valueOrNull;
      if (requests == null) return false;
      return requests.any((request) => request.id == jobRequestId);
    } catch (_) {
      return false;
    }
  }

  List<BookingRequest> _visibleRequests(List<BookingRequest> requests) {
    final query = _searchController.text.trim().toLowerCase();

    // Web parity (JobRequests.jsx): Declined/Expired never render in the
    // inbox. Cancelled/completed stay visible but never offer Assign.
    const hiddenFromInbox = {'declined', 'rejected', 'expired'};

    final filtered = requests.where((request) {
      final status = _normalizeStatus(request.status);
      if (hiddenFromInbox.contains(status)) return false;
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
          backgroundColor: AppColors.brand,
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _busyRequestIds.remove(request.id));
      }
    }
  }

  Future<void> _acceptRequest(BookingRequest request) {
    return _acceptRequestWithKycGate(request);
  }

  Future<void> _acceptRequestWithKycGate(BookingRequest request) async {
    if (!await ensureKycVerifiedForAccept(
      context: context,
      ref: ref,
      role: 'broker',
    )) {
      return;
    }
    return _runRequestAction(
      request,
      (token) => ref
          .read(apiClientProvider)
          .acceptJobRequest(accessToken: token, id: request.id)
          .then((_) {}),
      successMessage:
          AppLocalizations.of(context)!.brokerHomeRequestAccepted,
    );
  }

  Future<void> _declineRequest(BookingRequest request) {
    return _runRequestAction(
      request,
      (token) => ref
          .read(apiClientProvider)
          .declineJobRequest(accessToken: token, id: request.id)
          .then((_) {}),
      successMessage:
          AppLocalizations.of(context)!.brokerHomeRequestDeclined,
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
      successMessage:
          AppLocalizations.of(context)!.brokerHomeFareChangeSent,
    );
  }

  Future<bool> _assignRequest(
    BookingRequest request, {
    required String driverId,
    required String truckId,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null ||
        _busyRequestIds.contains(request.id) ||
        _pendingAssignments.containsKey(request.id)) {
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
      // Optimistically mark as waiting so the Assign button hides immediately
      // and re-taps can't spam the driver. Socket + seed will confirm it.
      var driverName = '';
      try {
        final drivers = ref
            .read(brokerDriversApiProvider(_driversQuery))
            .valueOrNull;
        if (drivers != null) {
          for (final driver in drivers) {
            if (driver.id == driverId) {
              driverName = driver.name;
              break;
            }
          }
        }
      } catch (_) {}
      _pendingAssignments[request.id] = _PendingDriverOffer(
        jobRequestId: request.id,
        driverName: driverName,
        status: 'pending',
        driverTimedOut: false,
      );
      if (mounted) setState(() {});
      ref.invalidate(brokerJobRequestsProvider(_requestsQuery));
      ref.invalidate(brokerDriverRequestsProvider((page: 1, limit: 100)));
      ref.invalidate(brokerDriversApiProvider(_driversQuery));
      ref.invalidate(brokerTrucksProvider(_trucksQuery));
      // Card stays in the list showing "waiting on driver" (web parity) —
      // seed from the fresh driver-requests so the banner shows immediately.
      unawaited(_seedPendingAssignments());

      if (!mounted) return true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.brokerHomeOfferSentToTheDriverWaitingFor),
          backgroundColor: AppColors.brand,
        ),
      );
      return true;
    } on ApiException catch (error) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
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
    // Already sent — don't reopen the sheet to spam the driver.
    if (_busyRequestIds.contains(request.id) ||
        _pendingAssignments.containsKey(request.id)) {
      return Future.value();
    }
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620),
          child: _HomeAssignmentSheet(
            request: request,
            onAssign: (driverId, truckId) =>
                _assignRequest(request, driverId: driverId, truckId: truckId),
          ),
        ),
      ),
    );
  }

  Future<double?> _showCounterAmountSheet(BookingRequest request) {
    final initialAmount = _amountFromText(request.value);
    final initialText = initialAmount > 0
        ? initialAmount.toStringAsFixed(0)
        : '';
    return showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (sheetContext) =>
          _HomeCounterSheet(request: request, initialText: initialText),
    );
  }

  double _amountFromText(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _greetingName() {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final displayName = session?.user.displayName.trim() ?? '';
    if (displayName.isEmpty) {
      return 'Broker';
    }
    return displayName.split(' ').first;
  }

  String? _profileImage() {
    final image = ref
        .watch(authSessionProvider)
        .valueOrNull
        ?.user
        .profileImage
        ?.trim();
    return (image == null || image.isEmpty) ? null : image;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final requestsAsync = ref.watch(brokerJobRequestsProvider(_requestsQuery));
    final requests = requestsAsync.valueOrNull ?? const <BookingRequest>[];
    final visibleRequests = _visibleRequests(requests);
    final pendingCount = _countMatching(
      requests,
      isBrokerJobRequestAttentionCount,
    );

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.brand,
          onRefresh: _refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              _BrokerHomeTopBar(
                greetingName: _greetingName(),
                profileImage: _profileImage(),
                onNotificationsTap: () => context.push('/broker/notifications'),
                onProfileTap: () => context.push('/broker/profile'),
              ),
              const SizedBox(height: 14),
              _NewBookingsHero(pendingCount: pendingCount),
              const SizedBox(height: 14),
              _SearchField(
                controller: _searchController,
                hintText: l10n.brokerHomeSearchBookingIDLocation,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.brokerHomeBookingRequests,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textPrimary,
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
                    label: Text(l10n.brokerHomeSort),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brand,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              requestsAsync.when(
                data: (_) {
                  if (visibleRequests.isEmpty) {
                    return _EmptyBookingsState(
                      title: l10n.brokerHomeNoBookingsFound,
                      subtitle: pendingCount > 0
                          ? l10n.brokerHomeNoMatchButPending(pendingCount)
                          : l10n.brokerHomeTryClearingSearch,
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
                                busy:
                                    _busyRequestIds.contains(request.id) ||
                                    _pendingAssignments.containsKey(
                                      request.id,
                                    ),
                                pendingOffer: _pendingAssignments[request.id],
                                onOpenDriverRequests: () =>
                                    context.push('/broker/driver-requests'),
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
                loading: () => Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _EmptyBookingsState(
                  title: AppLocalizations.of(context)!.brokerHomeCouldNotLoadBookings,
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(AppIcons.refresh_rounded),
                  label: Text(AppLocalizations.of(context)!.brokerHomeReloadRequests),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeCounterSheet extends StatefulWidget {
  const _HomeCounterSheet({required this.request, required this.initialText});

  final BookingRequest request;
  final String initialText;

  @override
  State<_HomeCounterSheet> createState() => _HomeCounterSheetState();
}

class _HomeCounterSheetState extends State<_HomeCounterSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _amountFromText(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: media.viewInsets.bottom + media.viewPadding.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                    l10n.brokerHomeChangeFare,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.brokerHomeBookingProposeADifferentAmount(
                      widget.request.id,
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: Icon(
                        AppIcons.currency_rupee_rounded,
                        color: AppColors.brand,
                      ),
                      hintText: l10n.brokerHomeEnterAmount,
                      filled: true,
                      fillColor: AppColors.fillSubtle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.line),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(l10n.brokerHomeCancel),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final amount = _amountFromText(_controller.text);
                            Navigator.of(context).pop(amount);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brand,
                          ),
                          child: Text(
                            l10n.brokerHomeChangeFare2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
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

class _BrokerHomeTopBar extends StatelessWidget {
  const _BrokerHomeTopBar({
    required this.greetingName,
    required this.profileImage,
    required this.onNotificationsTap,
    required this.onProfileTap,
  });

  final String greetingName;
  final String? profileImage;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.brokerHomeHelloName(greetingName),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        _NotificationButton(onTap: onNotificationsTap, count: 1),
        const SizedBox(width: 12),
        _AvatarButton(imageUrl: profileImage, onTap: onProfileTap),
      ],
    );
  }
}

class _NewBookingsHero extends StatelessWidget {
  const _NewBookingsHero({required this.pendingCount});

  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandBright],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
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
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              AppIcons.inventory_2_outlined,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.brokerHomeNewBookings,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.brokerHomeRequestsNeedAttention(pendingCount),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.24),
                width: 1,
              ),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(
            AppIcons.search_rounded,
            color: AppColors.textSecondary,
          ),
          hintText: hintText,
          hintStyle: const TextStyle(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A driver offer sent via assign-driver that hasn't resolved yet (web
/// `JobRequests.jsx` `pendingAssignments[id]` parity).
class _PendingDriverOffer {
  const _PendingDriverOffer({
    required this.jobRequestId,
    required this.driverName,
    required this.status,
    required this.driverTimedOut,
  });

  final String jobRequestId;
  final String driverName;
  final String status;
  final bool driverTimedOut;
}

/// Tappable "waiting on driver / countered / timed-out" banner (web
/// `JobRequests.jsx` parity) that routes to Driver Requests to respond.
class _PendingAssignmentBanner extends StatelessWidget {
  const _PendingAssignmentBanner({required this.offer, required this.onTap});

  final _PendingDriverOffer offer;
  final VoidCallback? onTap;

  String text(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final name = offer.driverName.isNotEmpty
        ? offer.driverName
        : l10n.brokerHomeDriverFallback;
    if (offer.status == 'countered') {
      return l10n.brokerHomeDriverChangedFare(name);
    }
    if (offer.driverTimedOut) {
      return l10n.brokerHomeDriverNoResponse(name);
    }
    return l10n.brokerHomeWaitingForDriver(name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDFA),
          border: Border.all(color: const Color(0xFF99F6E4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              AppIcons.schedule_rounded,
              size: 14,
              color: Color(0xFF0F766E),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text(context),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F766E),
                ),
              ),
            ),
            const Icon(
              AppIcons.arrow_forward_rounded,
              size: 14,
              color: Color(0xFF0F766E),
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
    required this.busy,
    required this.onTap,
    required this.onAccept,
    required this.onCounter,
    required this.onDecline,
    required this.onAssign,
    this.pendingOffer,
    this.onOpenDriverRequests,
  });

  final BookingRequest request;
  final bool busy;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onDecline;
  final VoidCallback onAssign;
  final _PendingDriverOffer? pendingOffer;
  final VoidCallback? onOpenDriverRequests;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pickupText = _locationText(
      request.from,
      l10n.brokerHomePickupUnavailable,
    );
    final dropText =
        _locationText(request.to, l10n.brokerHomeDropUnavailable);
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
    // Web parity (JobRequests.jsx): Assign is offered only for Accepted.
    // Terminal states (cancelled/completed/declined/expired) never show it —
    // those trips live in History / Active Jobs, not the inbox.
    final isTerminal = const {
      'declined',
      'rejected',
      'expired',
      'cancelled',
      'canceled',
      'completed',
      'delivered',
      'closed',
    }.contains(status);
    final showAssignAction = !isTerminal && status == 'accepted';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
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
                                  color: AppColors.textTertiary,
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
                        l10n.brokerHomeTo(
                          _locationLead(l10n, pickupText),
                          _locationLead(l10n, dropText),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
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
                        color: AppColors.textPrimary,
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
                          color: AppColors.textTertiary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          brokerRelativeTimeDisplay(
                            AppLocalizations.of(context)!,
                            request.requestedAt,
                          )
                              .isEmpty
                              ? l10n.brokerHomeJustNow
                              : brokerRelativeTimeDisplay(
                                  AppLocalizations.of(context)!,
                                  request.requestedAt,
                                ),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textTertiary,
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
                  label: AppLocalizations.of(context)!.brokerHomePickup,
                  value: pickupText,
                  iconColor: AppColors.brandBright,
                ),
                const SizedBox(height: 8),
                _JobLocationRow(
                  label: AppLocalizations.of(context)!.brokerHomeDrop,
                  value: dropText,
                  iconColor: AppColors.dangerIcon,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _JobMetricTile(
                    label: AppLocalizations.of(context)!.brokerHomeDistance,
                    value: _distanceText(request.distance),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _JobMetricTile(
                    label: AppLocalizations.of(context)!.brokerHomeWeight,
                    value: request.weight.trim().isEmpty ? '-' : request.weight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _JobMetricTile(
                    label: AppLocalizations.of(context)!.brokerHomeClient,
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
            if (pendingOffer != null) ...[
              _PendingAssignmentBanner(
                offer: pendingOffer!,
                onTap: onOpenDriverRequests,
              ),
            ] else if (showAssignAction) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: busy ? null : onAssign,
                  icon: const Icon(AppIcons.local_shipping_rounded, size: 17),
                  label: Text(AppLocalizations.of(context)!.brokerHomeAssignDriverTruck),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brand,
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
                text: l10n.brokerHomeWaitingClientResponse(amountText),
                color: AppColors.warningText,
                backgroundColor: AppColors.warningFill,
                borderColor: AppColors.warningBorder,
              ),
            ] else if (status == 'awaiting_confirmation' &&
                !showConfirmActions) ...[
              _InlineStatusNote(
                icon: AppIcons.schedule_rounded,
                text: l10n.brokerHomeYouAcceptedWaiting,
                color: AppColors.accentBlue,
                backgroundColor: const Color(0xFFEAF4FB),
                borderColor: AppColors.accentBlueBorder,
              ),
            ] else if (showConfirmActions) ...[
              Row(
                children: [
                  Expanded(
                    child: _JobActionButton(
                      label: AppLocalizations.of(context)!.brokerHomeConfirm,
                      icon: AppIcons.check_circle_outline_rounded,
                      color: AppColors.brand,
                      borderColor: AppColors.successBorder,
                      onPressed: busy ? null : onAccept,
                      loading: busy,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JobActionButton(
                      label: AppLocalizations.of(context)!.brokerHomeDecline,
                      icon: AppIcons.cancel_outlined,
                      color: AppColors.textSecondary,
                      borderColor: AppColors.line,
                      onPressed: busy ? null : onDecline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _ActionHint(
                text: l10n.brokerHomeClientAcceptedConfirm(amountText),
              ),
            ] else if (showPrimaryActions) ...[
              Row(
                children: [
                  Expanded(
                    child: _JobActionButton(
                      label: AppLocalizations.of(context)!.brokerHomeAccept,
                      icon: AppIcons.check_circle_outline_rounded,
                      color: AppColors.brand,
                      borderColor: AppColors.successBorder,
                      onPressed: busy ? null : onAccept,
                      loading: busy,
                    ),
                  ),
                  if (!counterLimitReached) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: _JobActionButton(
                        label: AppLocalizations.of(context)!.brokerHomeChangeFare2,
                        icon: AppIcons.currency_rupee_rounded,
                        color: AppColors.accentBlue,
                        borderColor: AppColors.accentBlueBorder,
                        onPressed: busy ? null : onCounter,
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: _JobActionButton(
                      label: AppLocalizations.of(context)!.brokerHomeDecline,
                      icon: AppIcons.cancel_outlined,
                      color: AppColors.textSecondary,
                      borderColor: AppColors.line,
                      onPressed: busy ? null : onDecline,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _ActionHint(
                text: counterLimitReached
                    ? l10n.brokerHomeFareChangesUsed
                    : l10n.brokerHomeOfferLive(amountText),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onTap,
                  icon: const Icon(AppIcons.open_in_new_rounded, size: 16),
                  label: Text(AppLocalizations.of(context)!.brokerHomeReviewRequest),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brandBorder),
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
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [
                      request.clientName,
                      if (request.clientPhone.isNotEmpty) request.clientPhone,
                      if (request.requestedAt.isNotEmpty)
                        brokerRelativeTimeDisplay(
                          AppLocalizations.of(context)!,
                          request.requestedAt,
                        ),
                    ].join(' - '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textTertiary,
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
    final l10n = AppLocalizations.of(context)!;
    final driversAsync = ref.watch(
      brokerDriversApiProvider(_BrokerHomeScreenState._driversQuery),
    );
    final trucksAsync = ref.watch(
      brokerTrucksProvider(_BrokerHomeScreenState._trucksQuery),
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 560),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: driversAsync.when(
            loading: () => _AssignmentLoadingState(),
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
              loading: () => _AssignmentLoadingState(),
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
                color: AppColors.brandFill,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                AppIcons.local_shipping_rounded,
                color: AppColors.brand,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.brokerHomeAssignDriverTruck,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context)!.brokerHomeChooseAnIdleDriverAndTruck(_bookingRef(widget.request)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AssignmentDropdown<BrokerDriver>(
          label: AppLocalizations.of(context)!.brokerHomeDriver,
          icon: AppIcons.person_rounded,
          value: selectedDriver?.id,
          items: drivers,
          idOf: (driver) => driver.id,
          enabledOf: _isAssignableDriver,
          titleOf: (driver) => driver.name.isNotEmpty ? driver.name : driver.id,
          subtitleOf: (driver) => [
            if (driver.phone.isNotEmpty) driver.phone,
            driverStatusLabel(driver.status, AppLocalizations.of(context)!),
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
          label: AppLocalizations.of(context)!.brokerHomeTruck,
          icon: AppIcons.fire_truck_rounded,
          value: selectedTruck?.id,
          items: trucks,
          idOf: (truck) => truck.id,
          enabledOf: _isAssignableTruck,
          titleOf: _truckTitle,
          subtitleOf: (truck) => [
            if (truck.capacity.isNotEmpty) truck.capacity,
            vehicleStatusLabel(truck.status, AppLocalizations.of(context)!),
          ].join(' - '),
          onChanged: (value) => setState(() => _truckId = value),
        ),
        if (!canConfirm) ...[
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.brokerHomeSelectOneIdleDriverAndOneIdle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.dangerText),
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
                child: Text(AppLocalizations.of(context)!.brokerHomeCancel),
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
                style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
                child: Text(
                    _submitting
                        ? AppLocalizations.of(context)!.brokerHomeSending
                        : AppLocalizations.of(context)!
                            .brokerHomeSendAssignment),
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
    final l10n = AppLocalizations.of(context)!;
    final selectedExists = items.any((item) => idOf(item) == value);
    return DropdownButtonFormField<String>(
      initialValue: selectedExists ? value : null,
      isExpanded: true,
      isDense: true,
      itemHeight: 56,
      menuMaxHeight: 320,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.field),
      icon: const Icon(
        AppIcons.keyboard_arrow_down_rounded,
        color: AppColors.textSecondary,
      ),
      decoration: brokerFieldDecoration(labelText: label, prefixIcon: icon),
      hint: Text(l10n.brokerHomeSelect(label.toLowerCase())),
      selectedItemBuilder: (context) => [
        for (final item in items)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              titleOf(item),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
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
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitleOf(item),
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
              ),
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _AssignmentLoadingState extends StatelessWidget {
  _AssignmentLoadingState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.brokerHomeCouldNotLoadAssignmentOptions,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(AppIcons.refresh_rounded),
            label: Text(l10n.brokerHomeRetry),
            style: FilledButton.styleFrom(backgroundColor: AppColors.brand),
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.trim().isEmpty ? 'Truck' : label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.brandInk,
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
    final l10n = AppLocalizations.of(context)!;
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
                  color: AppColors.textTertiary,
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
                  color: AppColors.textPrimary,
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
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
              color: AppColors.textTertiary,
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
              color: AppColors.textPrimary,
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.fillSubtle,
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
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 5),
              Text(
                l10n.brokerHomeNEGOTIATIONHISTORY,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textTertiary,
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
                    entry.by == 'broker'
                        ? AppLocalizations.of(context)!.brokerHomeYouOffered
                        : AppLocalizations.of(context)!.brokerHomeClientOffered,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _formatRupees(entry.amount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textPrimary,
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
    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: loading
          ? SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          : Icon(icon, size: 15),
      label: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
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
    final l10n = AppLocalizations.of(context)!;
    return Text(
      text,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: AppColors.textTertiary,
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
    this.color = AppColors.textSecondary,
    this.backgroundColor = AppColors.fillSubtle,
    this.borderColor = AppColors.line,
  });

  final IconData icon;
  final String text;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: AppColors.brandFill,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              AppIcons.inbox_rounded,
              color: AppColors.brand,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarButton extends StatelessWidget {
  const _AvatarButton({required this.imageUrl, required this.onTap});

  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final photo = imageUrl?.trim() ?? '';
    final hasPhoto = photo.startsWith('http');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFBBF24), Color(0xFFF97316)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: Container(
            decoration: const BoxDecoration(shape: BoxShape.circle),
            clipBehavior: Clip.antiAlias,
            child: hasPhoto
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, _) => _AvatarPlaceholder(),
                  )
                : _AvatarPlaceholder(),
          ),
        ),
      ),
    );
  }
}

/// Platform-style placeholder (Uber/Ola/Rapido): neutral slate disc with a
/// dark person glyph — no brand color, lets the photo be the identity.
class _AvatarPlaceholder extends StatelessWidget {
  _AvatarPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      alignment: Alignment.center,
      color: const Color(0xFFE8EDF3),
      child: const Icon(
        AppIcons.person_rounded,
        color: Color(0xFF475569),
        size: 26,
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
    final l10n = AppLocalizations.of(context)!;
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
              border: Border.all(color: AppColors.line),
            ),
            child: const Icon(
              AppIcons.notifications_none_rounded,
              color: AppColors.textSecondary,
            ),
          ),
          if (count > 0)
            Positioned(
              right: 2,
              top: 3,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: AppColors.brand,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.4),
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

String _locationLead(AppLocalizations l10n, String value) {
  final trimmed = _locationText(value, l10n.tripSummaryLocationUnavailable);
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