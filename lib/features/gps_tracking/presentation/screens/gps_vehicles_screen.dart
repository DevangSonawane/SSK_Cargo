import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/gps_sidebar_drawer.dart';

class GpsVehiclesScreen extends StatelessWidget {
  const GpsVehiclesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 390;

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
                  _SearchBar(isCompact: isCompact),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 82,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _statusChips.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        return _StatusChip(
                          data: _statusChips[index],
                          selected: index == 0,
                          compact: isCompact,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._vehicles.asMap().entries.expand(
                    (entry) => [
                      _VehicleCard(vehicle: entry.value, compact: isCompact),
                      if (entry.key != _vehicles.length - 1)
                        const SizedBox(height: 12),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _GpsVehiclesBottomNavBar(),
    );
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
    final subtitleSize = width < 390 ? 10.5 : 11.5;

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
        _ViewToggle(width: width),
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
  const _ViewToggle({required this.width});

  final double width;

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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
            child: Row(
              children: const [
                Icon(Icons.map_outlined, color: Color(0xFF72809B), size: 16),
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
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.isCompact});

  final bool isCompact;

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
            child: Text(
              'Search vehicles by number, name or driver...',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isCompact ? 11.5 : 12.5,
                color: const Color(0xFF93A0B8),
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

const _statusChips = <_StatusChipData>[
  _StatusChipData(
    label: 'All',
    count: '32',
    color: Color(0xFF0F1F44),
    background: Color(0xFF0F1F44),
  ),
  _StatusChipData(
    label: 'Running',
    count: '18',
    color: Color(0xFF13B36C),
    background: Color(0xFFEAF9F1),
  ),
  _StatusChipData(
    label: 'Stopped',
    count: '6',
    color: Color(0xFFFF595D),
    background: Color(0xFFFFEEEE),
  ),
  _StatusChipData(
    label: 'Offline',
    count: '4',
    color: Color(0xFF4B84F6),
    background: Color(0xFFEAF1FF),
  ),
  _StatusChipData(
    label: 'No Data',
    count: '4',
    color: Color(0xFF8F98AA),
    background: Color(0xFFF2F5FA),
  ),
];

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

class _VehicleData {
  const _VehicleData({
    required this.plate,
    required this.model,
    required this.driver,
    required this.status,
    required this.speed,
    required this.location,
    required this.timeAgo,
    required this.color,
    required this.icon,
  });

  final String plate;
  final String model;
  final String driver;
  final String status;
  final String speed;
  final String location;
  final String timeAgo;
  final Color color;
  final IconData icon;
}

const _vehicles = <_VehicleData>[
  _VehicleData(
    plate: 'MH12 AB 1234',
    model: 'Tata 407 • Cargo',
    driver: 'Rohit Sharma',
    status: 'Running',
    speed: '48 km/h',
    location: 'Andheri East, Mumbai',
    timeAgo: '2 mins ago',
    color: Color(0xFF13B36C),
    icon: Icons.local_shipping_rounded,
  ),
  _VehicleData(
    plate: 'MH12 CD 5678',
    model: 'Eicher Pro 2049 • Cargo',
    driver: 'Suresh Yadav',
    status: 'Stopped',
    speed: '45 mins',
    location: 'Jogeshwari, Mumbai',
    timeAgo: '45 mins ago',
    color: Color(0xFFFF595D),
    icon: Icons.local_shipping_rounded,
  ),
  _VehicleData(
    plate: 'MH12 EF 9012',
    model: 'BharatBenz 1617 • Cargo',
    driver: 'Imran Shaikh',
    status: 'Offline',
    speed: 'Offline',
    location: 'Borivali West, Mumbai',
    timeAgo: '1 hr ago',
    color: Color(0xFF4B84F6),
    icon: Icons.local_shipping_rounded,
  ),
  _VehicleData(
    plate: 'MH12 GH 3456',
    model: 'Ashok Leyland • Cargo',
    driver: 'Vikram Patil',
    status: 'No Data',
    speed: 'No Data',
    location: 'Unknown Location',
    timeAgo: '--',
    color: Color(0xFF8F98AA),
    icon: Icons.local_shipping_rounded,
  ),
];

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle, required this.compact});

  final _VehicleData vehicle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final statusColor = vehicle.color;

    return Container(
      height: compact ? 126 : 134,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
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
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Container(
                    width: compact ? 64 : 72,
                    height: compact ? 64 : 72,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      vehicle.icon,
                      color: statusColor,
                      size: compact ? 30 : 34,
                    ),
                  ),
                  const SizedBox(width: 12),
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
                                fontSize: compact ? 13.5 : 15,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF10213F),
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          vehicle.model,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontSize: compact ? 10.8 : 11.8,
                                color: const Color(0xFF33405C),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 9,
                              backgroundImage: AssetImage('assets/user.png'),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                vehicle.driver,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontSize: compact ? 10.8 : 11.8,
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
                      _StatusPill(color: statusColor, label: vehicle.status),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            vehicle.status == 'Offline'
                                ? Icons.wifi_off_rounded
                                : Icons.speed_rounded,
                            size: 15,
                            color: const Color(0xFF66758D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            vehicle.speed,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: compact ? 10.8 : 11.8,
                                  color: const Color(0xFF66758D),
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vehicle.location,
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: compact ? 10.3 : 11.2,
                          color: const Color(0xFF66758D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle.timeAgo,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: compact ? 9.8 : 10.8,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
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
