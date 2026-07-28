import 'package:flutter/material.dart';

class GpsDashboardScreen extends StatelessWidget {
  const GpsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 390;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FD),
      body: Stack(
        children: [
          const _DashboardBackdrop(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(width: width),
                  const SizedBox(height: 16),
                  _HorizontalActionStrip(width: width, isCompact: isCompact),
                  const SizedBox(height: 16),
                  const _FleetStatusCard(),
                  const SizedBox(height: 16),
                  const _RecentActivityCard(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const _GpsBottomNavBar(),
    );
  }
}

class _DashboardBackdrop extends StatelessWidget {
  const _DashboardBackdrop();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFDFEFF), Color(0xFFF4F7FC)],
            ),
          ),
        ),
        Positioned(
          top: -140,
          right: -80,
          child: _BackdropBlob(
            size: 320,
            colors: [
              const Color(0xFFDAE6FF).withValues(alpha: 0.25),
              const Color(0xFFDAE6FF).withValues(alpha: 0.02),
            ],
          ),
        ),
        Positioned(
          top: -70,
          left: -120,
          child: _BackdropBlob(
            size: 260,
            colors: [
              Colors.white.withValues(alpha: 0.96),
              const Color(0xFFF2F6FC).withValues(alpha: 0.5),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackdropBlob extends StatelessWidget {
  const _BackdropBlob({required this.size, required this.colors});

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final titleSize = width < 390 ? 20.0 : 22.0;
    final subtitleSize = width < 390 ? 10.0 : 11.0;

    return Row(
      children: [
        _HeaderButton(
          icon: Icons.menu_rounded,
          size: width < 390 ? 50 : 56,
          onTap: () {},
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hello, Gadidost 👋',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F1F44),
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Welcome back to your Fleet Dashboard',
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
        const SizedBox(width: 12),
        _NotificationButton(size: width < 390 ? 50 : 56),
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
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.97),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF101828).withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, size: size * 0.52, color: const Color(0xFF182B4E)),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _HeaderButton(
          icon: Icons.notifications_none_rounded,
          size: size,
          onTap: () {},
        ),
        Positioned(
          right: 9,
          top: 9,
          child: Container(
            width: 9,
            height: 9,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4646),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _HorizontalActionStrip extends StatelessWidget {
  const _HorizontalActionStrip({required this.width, required this.isCompact});

  final double width;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final cardWidth = width < 390 ? 132.0 : 150.0;
    final cardHeight = width < 390 ? 130.0 : 142.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _actionCards.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          return SizedBox(
            width: cardWidth,
            child: _ActionCard(data: _actionCards[index], compact: isCompact),
          );
        },
      ),
    );
  }
}

class _ActionCardData {
  const _ActionCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tint,
    required this.background,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color tint;
  final Color background;
}

const _actionCards = <_ActionCardData>[
  _ActionCardData(
    title: 'Live Tracking',
    subtitle: 'Track vehicles in real-time',
    icon: Icons.location_on_rounded,
    tint: Color(0xFF13B36C),
    background: Color(0xFFEAF9F1),
  ),
  _ActionCardData(
    title: 'Reports',
    subtitle: 'View detailed fleet reports',
    icon: Icons.description_rounded,
    tint: Color(0xFF4B84F6),
    background: Color(0xFFEAF1FF),
  ),
  _ActionCardData(
    title: 'Alerts',
    subtitle: 'View recent notifications',
    icon: Icons.notifications_rounded,
    tint: Color(0xFFF3A21C),
    background: Color(0xFFFFF4E0),
  ),
  _ActionCardData(
    title: 'Driver List',
    subtitle: 'Manage your drivers',
    icon: Icons.groups_rounded,
    tint: Color(0xFF9D4EDD),
    background: Color(0xFFF4ECFF),
  ),
];

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.data, required this.compact});

  final _ActionCardData data;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: data.tint.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: compact ? 42 : 46,
            height: compact ? 42 : 46,
            decoration: BoxDecoration(
              color: data.background,
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.tint, size: compact ? 22 : 24),
          ),
          const Spacer(),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: compact ? 13 : 14,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF16213C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: compact ? 10.5 : 11.5,
              color: const Color(0xFF5F6E86),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetStatusCard extends StatelessWidget {
  const _FleetStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Fleet Status',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10213F),
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF33405C),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF8B96AB),
              ),
            ],
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              final chart = const SizedBox(
                width: 200,
                height: 200,
                child: _FleetDonutChart(),
              );

              if (isNarrow) {
                return Column(
                  children: [
                    SizedBox(width: constraints.maxWidth, child: chart),
                    const SizedBox(height: 12),
                    const _StatusBreakdownList(),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  chart,
                  const SizedBox(width: 18),
                  const Expanded(child: _StatusBreakdownList()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FleetDonutChart extends StatelessWidget {
  const _FleetDonutChart();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FleetDonutPainter(),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '32',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xFF10213F),
                height: 1,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Total\nVehicles',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7690),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetDonutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide * 0.34;
    final strokeWidth = 20.0;

    final basePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt
      ..color = const Color(0xFFD9DEE7);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,
      6.283185307179586,
      false,
      basePaint,
    );

    void drawSegment(double startDeg, double sweepDeg, Color color) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt
        ..color = color;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        _degToRad(startDeg),
        _degToRad(sweepDeg),
        false,
        paint,
      );
    }

    drawSegment(-90, 202, const Color(0xFF13B36C));
    drawSegment(112, 68, const Color(0xFF4B84F6));
    drawSegment(180, 34, const Color(0xFFFF595D));
    drawSegment(214, 56, const Color(0xFFD9DEE7));
  }

  double _degToRad(double deg) => deg * 3.141592653589793 / 180;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StatusBreakdownList extends StatelessWidget {
  const _StatusBreakdownList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _StatusRow(
          color: Color(0xFF13B36C),
          label: 'Running',
          percent: '56%',
          count: '18',
          fill: 0.56,
        ),
        SizedBox(height: 14),
        _StatusRow(
          color: Color(0xFFFF595D),
          label: 'Stopped',
          percent: '19%',
          count: '6',
          fill: 0.19,
        ),
        SizedBox(height: 14),
        _StatusRow(
          color: Color(0xFF4B84F6),
          label: 'Offline',
          percent: '12%',
          count: '4',
          fill: 0.12,
        ),
        SizedBox(height: 14),
        _StatusRow(
          color: Color(0xFF8F98AA),
          label: 'No Data',
          percent: '13%',
          count: '4',
          fill: 0.13,
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.color,
    required this.label,
    required this.percent,
    required this.count,
    required this.fill,
  });

  final Color color;
  final String label;
  final String percent;
  final String count;
  final double fill;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C2440),
                ),
              ),
            ),
            Text(
              percent,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: const Color(0xFF738199),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              count,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF10213F),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF98A2B3),
              size: 18,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 7,
            backgroundColor: const Color(0xFFE9EEF6),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101828).withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Recent Activity',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF10213F),
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF33405C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _ActivityRow(
            iconColor: Color(0xFFFF595D),
            icon: Icons.stop_circle_rounded,
            title: 'MH12 AB 1234',
            status: 'Stopped',
            location: 'Oshiwara, Mumbai',
            time: '2 mins ago',
            dotColor: Color(0xFFFF595D),
          ),
          const Divider(height: 24, color: Color(0xFFE9EEF6)),
          const _ActivityRow(
            iconColor: Color(0xFF13B36C),
            icon: Icons.local_shipping_rounded,
            title: 'DL01 XY 5521',
            status: 'Running',
            location: 'Noida, Uttar Pradesh',
            time: '8 mins ago',
            dotColor: Color(0xFF13B36C),
          ),
        ],
      ),
    );
  }
}

class _GpsBottomNavBar extends StatelessWidget {
  const _GpsBottomNavBar();

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
                children: const [
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.home_rounded,
                      label: 'Dashboard',
                      selected: true,
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.local_shipping_rounded,
                      label: 'Vehicles',
                    ),
                  ),
                  Expanded(child: SizedBox(width: 58)),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.insert_chart_rounded,
                      label: 'Reports',
                    ),
                  ),
                  Expanded(
                    child: _GpsNavItem(
                      icon: Icons.person_rounded,
                      label: 'Profile',
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
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF2D6EF2) : const Color(0xFF8692A8);

    return Padding(
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
          const SizedBox(height: 2),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: selected ? 28 : 0,
            height: 2.5,
            decoration: BoxDecoration(
              color: const Color(0xFF2D6EF2),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.status,
    required this.location,
    required this.time,
    required this.dotColor,
  });

  final Color iconColor;
  final IconData icon;
  final String title;
  final String status;
  final String location;
  final String time;
  final Color dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13.5,
                    color: const Color(0xFF16213C),
                  ),
                  children: [
                    TextSpan(
                      text: title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: ' $status',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                location,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 12,
                  color: const Color(0xFF66758D),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              time,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11.5,
                color: const Color(0xFF66758D),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
