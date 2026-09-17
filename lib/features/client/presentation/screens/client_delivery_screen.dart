import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/app_providers.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';
import 'tracking_details_screen.dart';
import '../widgets/client_flow_widgets.dart';

class ClientDeliveryScreen extends ConsumerStatefulWidget {
  const ClientDeliveryScreen({super.key});

  @override
  ConsumerState<ClientDeliveryScreen> createState() =>
      _ClientDeliveryScreenState();
}

class _ClientDeliveryScreenState extends ConsumerState<ClientDeliveryScreen> {
  static const int _pageSize = 10;
  static const List<String> _filterTabs = [
    'All',
    'Active',
    'In Transit',
    'Delivered',
    'Cancelled',
  ];
  static const Map<String, String> _filterStatuses = {
    'Active': 'confirmed,assigned,en_route_pickup,picked_up,in_transit',
    'In Transit': 'in_transit',
    'Delivered': 'delivered',
    'Cancelled': 'cancelled',
  };

  final TextEditingController _trackingController = TextEditingController();
  String _activeFilter = 'All';
  String _searchQuery = '';
  int _page = 1;
  Timer? _searchDebounce;
  String? _liveRefreshToken;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _tripStatusSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreBottomNav());
  }

  void _restoreBottomNav() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route?.isCurrent ?? true) {
      ref.read(bottomNavVisibleProvider.notifier).state = true;
    }
  }

  ClientBookingsQuery get _currentQuery {
    final isSearching = _searchQuery.isNotEmpty;
    return (
      status: _filterStatuses[_activeFilter],
      page: isSearching ? 1 : _page,
      limit: isSearching ? 100 : _pageSize,
    );
  }

  Future<void> _refreshBookings() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    final refreshed = ref.refresh(clientBookingsProvider(_currentQuery).future);
    await refreshed;
  }

  void _changeFilter(String filter) {
    if (_activeFilter == filter) return;
    setState(() {
      _activeFilter = filter;
      _page = 1;
    });
  }

  void _handleSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _searchQuery = value.trim().toLowerCase();
        _page = 1;
      });
    });
  }

  String _csvCell(Object? value) {
    return '"${(value ?? '').toString().replaceAll('"', '""')}"';
  }

  Future<void> _exportBookings(List<ClientBooking> bookings) async {
    final rows = [
      ['Booking ID', 'Date', 'Pickup', 'Drop-off', 'Truck Type', 'Status'],
      ...bookings.map(
        (booking) => [
          _bookingRef(booking),
          _bookingDate(booking),
          booking.pickupLocation,
          booking.dropoffLocation,
          booking.vehicleType,
          booking.displayStatusLabel,
        ],
      ),
    ];
    final csv = rows.map((row) => row.map(_csvCell).join(',')).join('\n');
    await Clipboard.setData(ClipboardData(text: csv));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookings CSV copied to clipboard.'),
        backgroundColor: Color(0xFF2FA56E),
      ),
    );
  }

  Future<void> _openBooking(ClientBooking booking) async {
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrackingDetailsScreen(
          shipment: trackingShipmentFromBooking(booking),
        ),
      ),
    );
    _restoreBottomNav();
  }

  Future<void> _ensureLiveRefresh() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final accessToken = session?.tokens.accessToken;
    if (accessToken == null ||
        accessToken.isEmpty ||
        _liveRefreshToken == accessToken) {
      return;
    }

    _liveRefreshToken = accessToken;
    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(accessToken: accessToken);

    _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((_) {
      if (mounted) {
        ref.invalidate(clientBookingsProvider(_currentQuery));
      }
    });

    _tripStatusSubscription?.cancel();
    _tripStatusSubscription = socketService.tripStatusStream.listen((_) {
      if (mounted) {
        ref.invalidate(clientBookingsProvider(_currentQuery));
      }
    });
  }

  @override
  void dispose() {
    _driverRequestSubscription?.cancel();
    _tripStatusSubscription?.cancel();
    _searchDebounce?.cancel();
    _trackingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreBottomNav());
    final session = ref.watch(authSessionProvider).valueOrNull;
    final query = _currentQuery;
    final bookingsAsync = session == null
        ? null
        : ref.watch(clientBookingsProvider(query));

    if (session != null) {
      _ensureLiveRefresh();
    }

    return SafeArea(
      child: RefreshIndicator(
        color: const Color(0xFF2FA56E),
        onRefresh: _refreshBookings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _BookingsHeader(
              onExport: bookingsAsync?.valueOrNull?.bookings.isEmpty == false
                  ? () {
                      final visible = _visibleBookings(
                        bookingsAsync!.valueOrNull!,
                      ).bookings;
                      _exportBookings(visible);
                    }
                  : null,
              onNewBooking: () => context.go('/client/home'),
            ),
            const SizedBox(height: 18),
            _BookingsFiltersAndSearch(
              tabs: _filterTabs,
              activeFilter: _activeFilter,
              onFilterChanged: _changeFilter,
              controller: _trackingController,
              onSearchChanged: _handleSearchChanged,
            ),
            const SizedBox(height: 16),
            if (session == null)
              const _EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to view bookings',
                subtitle:
                    'We need an active client session before we can load your activity feed.',
              )
            else if (bookingsAsync == null)
              const SizedBox.shrink()
            else
              bookingsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load bookings',
                  subtitle: error.toString().replaceFirst('Exception: ', ''),
                  actionLabel: 'Try again',
                  onAction: _refreshBookings,
                ),
                data: (page) {
                  final visible = _visibleBookings(page);
                  final bookings = visible.bookings;
                  final total = visible.total;
                  final totalPages = visible.totalPages;
                  final rangeStart = total == 0
                      ? 0
                      : (_page - 1) * _pageSize + 1;
                  final rangeEnd = (_page * _pageSize).clamp(0, total);

                  if (bookings.isEmpty) {
                    if (_searchQuery.isNotEmpty && page.bookings.isNotEmpty) {
                      return _EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No bookings found',
                        subtitle:
                            'No bookings match the selected filter or search.',
                        actionLabel: 'Clear search',
                        onAction: () {
                          _trackingController.clear();
                          setState(() {
                            _searchQuery = '';
                            _page = 1;
                          });
                        },
                      );
                    }

                    return _EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'No bookings found',
                      subtitle:
                          'Once a booking is created, it will show up here.',
                      actionLabel: 'Refresh',
                      onAction: _refreshBookings,
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 720) {
                            return _BookingsTable(
                              bookings: bookings,
                              page: _page,
                              total: total,
                              totalPages: totalPages,
                              rangeStart: rangeStart,
                              rangeEnd: rangeEnd,
                              onPageChanged: (page) {
                                setState(() => _page = page);
                              },
                              onOpenBooking: _openBooking,
                            );
                          }
                          return _BookingsMobileList(
                            bookings: bookings,
                            page: _page,
                            totalPages: totalPages,
                            onPageChanged: (page) {
                              setState(() => _page = page);
                            },
                            onOpenBooking: _openBooking,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  ({List<ClientBooking> bookings, int total, int totalPages}) _visibleBookings(
    ClientBookingPage page,
  ) {
    if (_searchQuery.isEmpty) {
      return (
        bookings: page.bookings,
        total: page.total,
        totalPages: page.totalPages,
      );
    }

    final matches = page.bookings
        .where((booking) {
          final searchableText = <String>[
            booking.id,
            booking.bookingRef,
            booking.bookingNumber,
            booking.displaySubtitle,
            booking.displayTitle,
            booking.pickupLocation,
            booking.dropoffLocation,
          ].join(' ').toLowerCase();
          return searchableText.contains(_searchQuery);
        })
        .toList(growable: false);
    final start = (_page - 1) * _pageSize;
    final end = (_page * _pageSize).clamp(0, matches.length);
    return (
      bookings: start >= matches.length
          ? const <ClientBooking>[]
          : matches.sublist(start, end),
      total: matches.length,
      totalPages: (matches.length / _pageSize).ceil().clamp(1, 9999),
    );
  }
}

class _BookingsHeader extends StatelessWidget {
  const _BookingsHeader({required this.onExport, required this.onNewBooking});

  final VoidCallback? onExport;
  final VoidCallback onNewBooking;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      runSpacing: 14,
      spacing: 14,
      children: [
        SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Bookings',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF101828),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage and review your fleet transportation schedules.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF98A2B3),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _HeaderActionButton(
              icon: Icons.download_rounded,
              label: 'Export',
              onPressed: onExport,
              filled: false,
            ),
            const SizedBox(width: 8),
            _HeaderActionButton(
              icon: Icons.add_rounded,
              label: 'New Booking',
              onPressed: onNewBooking,
              filled: true,
            ),
          ],
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  const _HeaderActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.filled,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      children: [Icon(icon, size: 17), const SizedBox(width: 6), Text(label)],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(999),
    );
    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2FA56E),
          foregroundColor: Colors.white,
          shape: shape,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        ),
        child: child,
      );
    }
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF344054),
        side: const BorderSide(color: Color(0xFFE4E7EC)),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        backgroundColor: Colors.white,
      ),
      child: child,
    );
  }
}

class _BookingsFiltersAndSearch extends StatelessWidget {
  const _BookingsFiltersAndSearch({
    required this.tabs,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.controller,
    required this.onSearchChanged,
  });

  final List<String> tabs;
  final String activeFilter;
  final ValueChanged<String> onFilterChanged;
  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final tabsWidget = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in tabs) ...[
                _FilterTab(
                  label: tab,
                  selected: activeFilter == tab,
                  onTap: () => onFilterChanged(tab),
                ),
                const SizedBox(width: 18),
              ],
            ],
          ),
        );
        final searchWidget = _BookingsSearchField(
          controller: controller,
          onChanged: onSearchChanged,
        );
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [tabsWidget, const SizedBox(height: 12), searchWidget],
          );
        }
        return Row(
          children: [
            Expanded(child: tabsWidget),
            const SizedBox(width: 16),
            SizedBox(width: 270, child: searchWidget),
          ],
        );
      },
    );
  }
}

class _FilterTab extends StatelessWidget {
  const _FilterTab({
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
      child: Container(
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? const Color(0xFF2FA56E) : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFF98A2B3),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BookingsSearchField extends StatelessWidget {
  const _BookingsSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          const Icon(Icons.search_rounded, color: Color(0xFFD0D5DD), size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Filter by ID or route...',
                border: InputBorder.none,
                isDense: true,
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF344054),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onChanged('');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
              color: const Color(0xFF98A2B3),
            ),
        ],
      ),
    );
  }
}

class _BookingsTable extends StatelessWidget {
  const _BookingsTable({
    required this.bookings,
    required this.page,
    required this.total,
    required this.totalPages,
    required this.rangeStart,
    required this.rangeEnd,
    required this.onPageChanged,
    required this.onOpenBooking,
  });

  final List<ClientBooking> bookings;
  final int page;
  final int total;
  final int totalPages;
  final int rangeStart;
  final int rangeEnd;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ClientBooking> onOpenBooking;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _reactCardDecoration(radius: 18),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 48,
              dataRowMinHeight: 66,
              dataRowMaxHeight: 74,
              horizontalMargin: 20,
              columnSpacing: 28,
              headingTextStyle: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(
                    color: const Color(0xFF2FA56E),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
              columns: const [
                DataColumn(label: Text('BOOKING ID')),
                DataColumn(label: Text('DATE & TIME')),
                DataColumn(label: Text('ROUTE')),
                DataColumn(label: Text('TRUCK TYPE')),
                DataColumn(label: Text('STATUS')),
                DataColumn(label: Text('ACTIONS')),
              ],
              rows: [
                for (final booking in bookings)
                  DataRow(
                    onSelectChanged: (_) => onOpenBooking(booking),
                    cells: [
                      DataCell(_BookingIdCell(booking: booking)),
                      DataCell(_DateCell(booking: booking)),
                      DataCell(_RouteCell(booking: booking)),
                      DataCell(
                        Text(
                          booking.vehicleType.isEmpty
                              ? '-'
                              : booking.vehicleType,
                          style: _tableBodyStyle(context),
                        ),
                      ),
                      DataCell(_BookingStatusWithExpress(booking: booking)),
                      DataCell(
                        IconButton(
                          onPressed: () => onOpenBooking(booking),
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          color: const Color(0xFF98A2B3),
                          style: IconButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE4E7EC)),
                            shape: const CircleBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _BookingsPagination(
            page: page,
            totalPages: totalPages,
            rangeLabel: 'Showing $rangeStart to $rangeEnd of $total results',
            onPageChanged: onPageChanged,
            desktop: true,
          ),
        ],
      ),
    );
  }
}

class _BookingsMobileList extends StatelessWidget {
  const _BookingsMobileList({
    required this.bookings,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
    required this.onOpenBooking,
  });

  final List<ClientBooking> bookings;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ClientBooking> onOpenBooking;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < bookings.length; i++) ...[
          _MyBookingMobileCard(
            booking: bookings[i],
            onTap: () => onOpenBooking(bookings[i]),
          ),
          if (i != bookings.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 10),
        _BookingsPagination(
          page: page,
          totalPages: totalPages,
          rangeLabel: 'Page $page of $totalPages',
          onPageChanged: onPageChanged,
          desktop: false,
        ),
      ],
    );
  }
}

class _MyBookingMobileCard extends StatelessWidget {
  const _MyBookingMobileCard({required this.booking, required this.onTap});

  final ClientBooking booking;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _reactCardDecoration(radius: 18),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _bookingRef(booking),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF98A2B3),
                          fontSize: 10,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_locationLabel(booking.pickupLocation, 'Pickup')} → ${_locationLabel(booking.dropoffLocation, 'Drop')}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF344054),
                          fontSize: 14,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _BookingStatusWithExpress(booking: booking),
              ],
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: const Color(0xFFF2F4F7)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (booking.vehicleType.isNotEmpty) booking.vehicleType,
                      _bookingDate(booking),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  booking.amountText.isEmpty ? '-' : booking.amountText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF101828),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
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

class _BookingIdCell extends StatelessWidget {
  const _BookingIdCell({required this.booking});

  final ClientBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF6EF),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.assignment_outlined,
            color: Color(0xFF2FA56E),
            size: 17,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _bookingRef(booking),
          style: _tableBodyStyle(
            context,
          ).copyWith(fontFamily: 'monospace', fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({required this.booking});

  final ClientBooking booking;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_bookingDate(booking), style: _tableBodyStyle(context)),
        if (booking.requestedAt != null) ...[
          const SizedBox(height: 3),
          Text(
            _bookingTime(booking),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF98A2B3),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _RouteCell extends StatelessWidget {
  const _RouteCell({required this.booking});

  final ClientBooking booking;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Row(
        children: [
          Expanded(
            child: _RouteCellPoint(
              label: 'Origin',
              value: _locationLabel(booking.pickupLocation, 'Pickup'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.route_outlined,
              size: 16,
              color: Color(0xFFD0D5DD),
            ),
          ),
          Expanded(
            child: _RouteCellPoint(
              label: 'Destination',
              value: _locationLabel(booking.dropoffLocation, 'Drop'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteCellPoint extends StatelessWidget {
  const _RouteCellPoint({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: const Color(0xFFD0D5DD),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _tableBodyStyle(context).copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _BookingStatusWithExpress extends StatelessWidget {
  const _BookingStatusWithExpress({required this.booking});

  final ClientBooking booking;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatusBadge(
          label: booking.displayStatusLabel,
          color: _statusColor(booking.status),
        ),
        if (booking.isExpress) ...[
          const SizedBox(width: 6),
          const _ExpressIconOnly(),
        ],
      ],
    );
  }
}

class _ExpressIconOnly extends StatelessWidget {
  const _ExpressIconOnly();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF6EF),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.bolt_rounded, color: Color(0xFF2FA56E), size: 14),
    );
  }
}

class _BookingsPagination extends StatelessWidget {
  const _BookingsPagination({
    required this.page,
    required this.totalPages,
    required this.rangeLabel,
    required this.onPageChanged,
    required this.desktop,
  });

  final int page;
  final int totalPages;
  final String rangeLabel;
  final ValueChanged<int> onPageChanged;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final previous = page > 1;
    final next = page < totalPages;
    if (!desktop) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: previous ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            label: const Text('Prev'),
          ),
          Text(
            rangeLabel,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF98A2B3),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton.icon(
            onPressed: next ? () => onPageChanged(page + 1) : null,
            icon: const Text('Next'),
            label: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFF2F4F7))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              rangeLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF98A2B3),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: previous ? () => onPageChanged(page - 1) : null,
            icon: const Icon(Icons.chevron_left_rounded),
            color: const Color(0xFF98A2B3),
          ),
          for (var i = 1; i <= totalPages; i++)
            if (totalPages <= 7 ||
                i == 1 ||
                i == totalPages ||
                (i - page).abs() <= 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: InkWell(
                  onTap: () => onPageChanged(i),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == page
                          ? const Color(0xFF2FA56E)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$i',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: i == page
                            ? Colors.white
                            : const Color(0xFF667085),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
          IconButton(
            onPressed: next ? () => onPageChanged(page + 1) : null,
            icon: const Icon(Icons.chevron_right_rounded),
            color: const Color(0xFF98A2B3),
          ),
        ],
      ),
    );
  }
}

BoxDecoration _reactCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF101828).withValues(alpha: 0.07),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

TextStyle _tableBodyStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium!.copyWith(
    color: const Color(0xFF344054),
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
}

String _bookingRef(ClientBooking booking) {
  if (booking.bookingNumber.isNotEmpty) return booking.bookingNumber;
  if (booking.bookingRef.isNotEmpty) return booking.bookingRef;
  return booking.id.isEmpty ? 'Booking' : booking.id;
}

String _bookingDate(ClientBooking booking) {
  final value = booking.requestedAt;
  if (value == null) return '-';
  return '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
}

String _bookingTime(ClientBooking booking) {
  final value = booking.requestedAt;
  if (value == null) return '';
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _locationLabel(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: Color(0xFFF5F7FB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF667085), size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ClientBookingCard extends StatelessWidget {
  const ClientBookingCard({super.key, required this.booking, this.onTap});

  final ClientBooking booking;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(booking.status);

    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F3F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(7),
                child: Image.asset('assets/package.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking.displayTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF121826),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      booking.displaySubtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (booking.isExpress) ...[
                const _ExpressBadge(),
                const SizedBox(width: 6),
              ],
              _StatusBadge(
                label: booking.displayStatusLabel,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 14,
                child: Column(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 28,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking.pickupLocation.isEmpty
                          ? 'Pickup location not provided'
                          : booking.pickupLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Shipping to:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      booking.dropoffLocation.isEmpty
                          ? 'Drop-off location not provided'
                          : booking.dropoffLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (booking.packageName.isNotEmpty ||
              booking.weight.isNotEmpty ||
              booking.vehicleType.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FB),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inventory_2_rounded,
                    color: Color(0xFF667085),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      [
                        if (booking.packageName.isNotEmpty) booking.packageName,
                        if (booking.weight.isNotEmpty) booking.weight,
                        if (booking.vehicleType.isNotEmpty) booking.vehicleType,
                      ].join(' • '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (booking.amountText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        booking.amountText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF1F88C9),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if ((booking.pickupOtp ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            PickupOtpBanner(
              pickupOtp: booking.pickupOtp,
              pickupOtpVerified: booking.pickupOtpVerified,
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (booking.id.isNotEmpty)
                Text(
                  booking.id,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF98A2B3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }
}

class _ExpressBadge extends StatelessWidget {
  const _ExpressBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bolt_rounded, size: 13, color: Color(0xFFEA580C)),
          const SizedBox(width: 3),
          Text(
            'Express',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFFC2410C),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'completed':
    case 'delivered':
      return const Color(0xFF2FA56E);
    case 'cancelled':
      return const Color(0xFFE23A4B);
    case 'confirmed':
    case 'assigned':
    case 'in_transit':
    case 'en_route_pickup':
    case 'picked_up':
      return const Color(0xFF1F88C9);
    case 'pending':
      return const Color(0xFFF59E0B);
    default:
      return const Color(0xFF667085);
  }
}
