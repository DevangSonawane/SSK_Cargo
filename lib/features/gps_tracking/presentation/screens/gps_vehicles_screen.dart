import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/gps_tracking_models.dart';
import '../../data/gps_tracking_repository.dart';
import '../widgets/gps_sidebar_drawer.dart';

class GpsVehiclesScreen extends ConsumerStatefulWidget {
  const GpsVehiclesScreen({super.key});

  @override
  ConsumerState<GpsVehiclesScreen> createState() => _GpsVehiclesScreenState();
}

class _GpsVehiclesScreenState extends ConsumerState<GpsVehiclesScreen> {
  Timer? _pollingTimer;
  List<GpsTrackerDevice> _devices = [];
  bool _loading = true;
  String _error = '';
  String _searchTerm = '';
  int _currentPage = 1;

  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadDevices();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _loadDevices(silent: true);
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevices({bool silent = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = [];
        _error = 'Please sign in again to view live fleet devices.';
        _loading = false;
      });
      return;
    }

    if (!silent && mounted) {
      setState(() {
        _loading = true;
        _error = '';
      });
    }

    try {
      final devices = await ref
          .read(gpsTrackingRepositoryProvider)
          .fetchDevices(accessToken: session.tokens.accessToken);
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = devices;
        _loading = false;
        _error = '';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.message;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 390;
    final filtered = _devices.where((device) {
      final query = _searchTerm.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      return device.displayName.toLowerCase().contains(query) ||
          device.deviceImei.toLowerCase().contains(query) ||
          device.statusLabel.toLowerCase().contains(query) ||
          device.subtitle.toLowerCase().contains(query);
    }).toList();

    final totalPages = filtered.isEmpty
        ? 0
        : ((filtered.length - 1) / _itemsPerPage).floor() + 1;
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final paginated = filtered.skip(startIndex).take(_itemsPerPage).toList();
    final statusChips = _buildStatusChips(_devices);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      drawer: const GpsSidebarDrawer(currentRoute: '/gps/vehicles'),
      body: Stack(
        children: [
          const _VehiclesBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _VehiclesHeader(width: width),
                  const SizedBox(height: 14),
                  _SearchBar(
                    isCompact: isCompact,
                    onChanged: (value) {
                      setState(() {
                        _searchTerm = value;
                        _currentPage = 1;
                      });
                    },
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: statusChips.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _StatusChip(
                          data: statusChips[index],
                          selected: index == 0,
                          compact: isCompact,
                        );
                      },
                    ),
                  ),
                  if (_loading) ...[
                    const SizedBox(height: 16),
                    const Center(child: CircularProgressIndicator()),
                  ],
                  if (_error.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4F4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3C0C0)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text('', style: TextStyle(fontSize: 0)),
                          ),
                          Expanded(
                            flex: 9,
                            child: Text(
                              _error,
                              style: const TextStyle(
                                color: Color(0xFFB3261E),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _loadDevices,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ...paginated.asMap().entries.expand(
                    (entry) => [
                      _VehicleCard(vehicle: entry.value, compact: isCompact),
                      if (entry.key != paginated.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ),
                  if (totalPages > 1) ...[
                    const SizedBox(height: 14),
                    _PaginationBar(
                      currentPage: _currentPage,
                      totalPages: totalPages,
                      totalItems: filtered.length,
                      startIndex: startIndex,
                      itemsPerPage: _itemsPerPage,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _GpsVehiclesBottomNavBar(),
    );
  }

  List<_StatusChipData> _buildStatusChips(List<GpsTrackerDevice> devices) {
    final onlineCount = devices
        .where((device) => device.statusLabel.toLowerCase().contains('online'))
        .length;
    final offlineCount = devices
        .where((device) => device.statusLabel.toLowerCase().contains('offline'))
        .length;
    final cachedCount = devices
        .where((device) => device.source == 'cached')
        .length;

    return [
      _StatusChipData(
        label: 'All',
        count: devices.length.toString(),
        color: const Color(0xFF0F1F44),
        background: const Color(0xFF0F1F44),
      ),
      _StatusChipData(
        label: 'Online',
        count: onlineCount.toString(),
        color: const Color(0xFF13B36C),
        background: const Color(0xFFEAF9F1),
      ),
      _StatusChipData(
        label: 'Offline',
        count: offlineCount.toString(),
        color: const Color(0xFFFF595D),
        background: const Color(0xFFFFEEEE),
      ),
      _StatusChipData(
        label: 'Cached',
        count: cachedCount.toString(),
        color: const Color(0xFFD19A00),
        background: const Color(0xFFFFF4DA),
      ),
    ];
  }
}

class _VehiclesBackdrop extends StatelessWidget {
  const _VehiclesBackdrop();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFDFEFF), Color(0xFFF4F7FC)],
        ),
      ),
    );
  }
}

class _VehiclesHeader extends StatelessWidget {
  const _VehiclesHeader({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final titleSize = width < 390 ? 21.0 : 24.0;
    final subtitleSize = width < 390 ? 9.5 : 10.2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _HeaderButton(
          icon: Icons.menu_rounded,
          size: width < 390 ? 48 : 52,
          onTap: () => Scaffold.of(context).openDrawer(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Vehicles',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F1F44),
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Manage and track all your vehicles',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: subtitleSize,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF63708A),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _ViewToggle(width: width, onMapTap: () => context.go('/gps/maps')),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: size * 0.48,
                color: const Color(0xFF182B4E),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.width, required this.onMapTap});

  final double width;
  final VoidCallback onMapTap;

  @override
  Widget build(BuildContext context) {
    final padH = width < 390 ? 8.0 : 10.0;
    final padV = width < 390 ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.all(padV),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF101828).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.view_list_rounded,
                  color: Color(0xFF182B4E),
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'List',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF182B4E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: onMapTap,
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
                child: Row(
                  children: const [
                    Icon(
                      Icons.map_outlined,
                      color: Color(0xFF72809B),
                      size: 16,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Map',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF72809B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isCompact, required this.onChanged});

  final bool isCompact;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: Color(0xFF72809B), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Search vehicles by number, name or driver...',
              ),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isCompact ? 11.5 : 12.5,
                color: const Color(0xFF182B4E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Color(0xFF182B4E),
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChipData {
  const _StatusChipData({
    required this.label,
    required this.count,
    required this.color,
    required this.background,
  });

  final String label;
  final String count;
  final Color color;
  final Color background;
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.data,
    required this.selected,
    required this.compact,
  });

  final _StatusChipData data;
  final bool selected;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? const Color(0xFF0F1F44) : data.background;
    final fg = selected ? Colors.white : data.color;

    return Container(
      width: compact ? 80 : 92,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? bg : data.color.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: selected ? Colors.white : data.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: compact ? 10.5 : 11,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            data.count,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w900,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.compact});

  final GpsTrackerDevice vehicle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statusColor = vehicle.color;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () =>
            context.go('/gps/maps/${Uri.encodeComponent(vehicle.deviceImei)}'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: compact ? 112 : 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Row(
                    children: [
                      Container(width: 4, color: statusColor),
                      Expanded(child: Container(color: Colors.white)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 56 : 60,
                        height: compact ? 56 : 60,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          vehicle.icon,
                          color: statusColor,
                          size: compact ? 26 : 28,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              vehicle.plate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontSize: compact ? 12.5 : 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF10213F),
                                  ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              vehicle.model,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: compact ? 9.8 : 10.5,
                                    color: const Color(0xFF33405C),
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 8,
                                  backgroundImage: AssetImage(
                                    'assets/user.png',
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    vehicle.driver,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontSize: compact ? 9.8 : 10.5,
                                          color: const Color(0xFF33405C),
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _StatusPill(
                            color: statusColor,
                            label: vehicle.statusLabel,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                vehicle.statusLabel.toLowerCase().contains(
                                      'offline',
                                    )
                                    ? Icons.wifi_off_rounded
                                    : Icons.speed_rounded,
                                size: 14,
                                color: const Color(0xFF66758D),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                vehicle.speedLabel,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: compact ? 9.8 : 10.5,
                                      color: const Color(0xFF66758D),
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            vehicle.locationLabel,
                            textAlign: TextAlign.right,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: compact ? 9.2 : 10,
                                  color: const Color(0xFF66758D),
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vehicle.timeAgoLabel,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: compact ? 9 : 9.6,
                                  color: const Color(0xFF8A96AB),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF8A96AB),
                        size: 20,
                      ),
                    ],
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.startIndex,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int startIndex;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${startIndex + 1} to ${startIndex + itemsPerPage > totalItems ? totalItems : startIndex + itemsPerPage} of $totalItems entries',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 11.5,
              color: const Color(0xFF63708A),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: currentPage <= 1
                    ? null
                    : () => onPageChanged(currentPage - 1),
                icon: const Icon(Icons.chevron_left_rounded),
                visualDensity: VisualDensity.compact,
              ),
              Text(
                '$currentPage / $totalPages',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF10213F),
                ),
              ),
              IconButton(
                onPressed: currentPage >= totalPages
                    ? null
                    : () => onPageChanged(currentPage + 1),
                icon: const Icon(Icons.chevron_right_rounded),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GpsVehiclesBottomNavBar extends StatelessWidget {
  const _GpsVehiclesBottomNavBar();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 4),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              height: 58,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.07),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.home_rounded,
                      label: 'Dashboard',
                      onTap: () => context.go('/gps/dashboard'),
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Vehicles',
                      selected: true,
                      onTap: () => context.go('/gps/vehicles'),
                    ),
                  ),
                  const Expanded(child: SizedBox(width: 58)),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.insert_chart_rounded,
                      label: 'Reports',
                      onTap: () => context.go('/gps/reports'),
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      onTap: () => context.go('/gps/profile'),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -20,
              child: InkWell(
                onTap: () => context.go('/gps/maps'),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E68F5), Color(0xFF234CC8)],
                    ),
                  ),
                  child: const Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GpsNavItem extends StatelessWidget {
  const _GpsNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2D6EF2) : const Color(0xFF8692A8);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
