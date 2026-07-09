import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/client_flow_widgets.dart';

class TrackingDetailsScreen extends ConsumerStatefulWidget {
  const TrackingDetailsScreen({
    super.key,
    required this.shipment,
  });

  final TrackingDemoShipment shipment;

  @override
  ConsumerState<TrackingDetailsScreen> createState() => _TrackingDetailsScreenState();
}

class _TrackingDetailsScreenState extends ConsumerState<TrackingDetailsScreen> {
  bool _isLiveTracking = false;
  bool _isCancelling = false;
  bool _isBookingCancelled = false;

  bool get _canCancelBooking {
    final status = widget.shipment.bookingStatus?.toLowerCase();
    return widget.shipment.bookingId != null &&
        !_isBookingCancelled &&
        (status == null || const {'pending', 'confirmed', 'assigned'}.contains(status));
  }

  Future<void> _cancelBooking() async {
    final bookingId = widget.shipment.bookingId;
    if (bookingId == null || _isCancelling || !_canCancelBooking) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to cancel this booking.')),
      );
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      await ref.read(apiClientProvider).cancelBooking(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking cancelled successfully.')),
      );
      setState(() {
        _isBookingCancelled = true;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCancelling = false;
        });
      }
    }
  }

  Future<void> _confirmCancelBooking() async {
    if (!_canCancelBooking || _isCancelling) {
      return;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Cancel booking?'),
          content: const Text(
            'This booking will be cancelled and the status will be updated. Do you want to continue?',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE23A4B),
              ),
              child: const Text('Yes, cancel'),
            ),
          ],
        );
      },
    );

    if (shouldCancel == true && mounted) {
      await _cancelBooking();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isLiveTracking
            ? _LiveTrackingView(
                key: const ValueKey('live'),
                shipment: widget.shipment,
                onBack: () => setState(() => _isLiveTracking = false),
              )
            : SafeArea(
                key: const ValueKey('details'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CompactSummaryCard(shipment: widget.shipment),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: Stack(
                            children: [
                              const Positioned.fill(child: TrackingMapBackdrop()),
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.white.withValues(alpha: 0.18),
                                        Colors.white.withValues(alpha: 0.46),
                                        Colors.white.withValues(alpha: 0.84),
                                      ],
                                      stops: const [0.0, 0.42, 1.0],
                                    ),
                                  ),
                                ),
                              ),
                              SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(18, 18, 18, 160),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ...widget.shipment.timeline.asMap().entries.map(
                                          (entry) => Padding(
                                            padding: EdgeInsets.only(
                                              bottom: entry.key == widget.shipment.timeline.length - 1
                                                  ? 0
                                                  : 16,
                                            ),
                                            child: _TimelineStepItem(
                                              step: entry.value,
                                              showConnector:
                                                  entry.key != widget.shipment.timeline.length - 1,
                                            ),
                                          ),
                                        ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 18,
                                right: 18,
                                bottom: 0,
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    0,
                                    0,
                                    0,
                                    MediaQuery.of(context).padding.bottom + 14,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 18),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 48,
                                          child: FilledButton(
                                            onPressed: () => setState(() => _isLiveTracking = true),
                                            style: FilledButton.styleFrom(
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              backgroundColor: const Color(0xFF2FA56E),
                                            ),
                                            child: const Text(
                                              'Live Tracking',
                                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (widget.shipment.bookingId != null) ...[
                                        const SizedBox(height: 10),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 18),
                                          child: SizedBox(
                                            width: double.infinity,
                                            height: 48,
                                            child: OutlinedButton(
                                              onPressed: _canCancelBooking && !_isCancelling
                                                  ? _confirmCancelBooking
                                                  : null,
                                              style: OutlinedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(999),
                                                ),
                                                side: BorderSide(
                                                  color: _canCancelBooking
                                                      ? const Color(0xFFE23A4B)
                                                      : const Color(0xFFCFD4DC),
                                                ),
                                                foregroundColor: const Color(0xFFE23A4B),
                                                backgroundColor: Colors.white,
                                              ),
                                              child: Text(
                                                _isCancelling
                                                    ? 'Cancelling...'
                                                    : _isBookingCancelled
                                                        ? 'Booking cancelled'
                                                        : (_canCancelBooking
                                                            ? 'Cancel booking'
                                                            : 'Booking cannot be cancelled'),
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class _LiveTrackingView extends StatefulWidget {
  const _LiveTrackingView({
    super.key,
    required this.shipment,
    required this.onBack,
  });

  final TrackingDemoShipment shipment;
  final VoidCallback onBack;

  @override
  State<_LiveTrackingView> createState() => _LiveTrackingViewState();
}

class _LiveTrackingViewState extends State<_LiveTrackingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: TrackingMapBackdrop()),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              return _LiveRouteOverlay(pulse: _pulseController.value);
            },
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.36),
                  Colors.white.withValues(alpha: 0.66),
                ],
                stops: const [0.0, 0.42, 1.0],
              ),
            ),
          ),
        ),
        SafeArea(
          child: Stack(
            children: [
              Positioned(
                left: 14,
                top: 4,
                child: InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, size: 20),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'Live Tracking',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF111111),
                        ),
                  ),
                ),
              ),
              Positioned(
                right: 14,
                top: 110,
                child: Column(
                  children: [
                    _ZoomButton(
                      icon: Icons.remove,
                      onTap: () {},
                    ),
                    const SizedBox(height: 10),
                    _ZoomButton(
                      icon: Icons.add,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _LiveInfoCard(shipment: widget.shipment),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LiveInfoCard extends StatelessWidget {
  const _LiveInfoCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 56,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFE1E5EB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Package information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: const Color(0xFF101828),
                ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Type:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black45,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Express delivery',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Package weight:',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black45,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shipment.weight,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF0B0B14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF2FA56E)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rahul Patil',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Delivery man',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    _ContactIconButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      onTap: () {},
                    ),
                    const SizedBox(width: 10),
                    _ContactIconButton(
                      icon: Icons.call_rounded,
                      onTap: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactSummaryCard extends StatelessWidget {
  const _CompactSummaryCard({required this.shipment});

  final TrackingDemoShipment shipment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F3F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tracking Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF101828),
                      ),
                ),
              ),
              InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF0F3F7)),
                  ),
                  child: const Icon(Icons.close_rounded, size: 16),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset(
                    'assets/package.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.packageName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF101828),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '#Tracking ID: ${shipment.trackingId}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.black54,
                                  fontSize: 11,
                                ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF2FA56E)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFBFD),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFECEFF3)),
            ),
            child: Column(
              children: [
                _InfoGrid(
                  leftLabel: 'From',
                  leftValue: shipment.fromLocation,
                  rightLabel: 'Destination',
                  rightValue: shipment.toLocation,
                ),
                const SizedBox(height: 10),
                _InfoGrid(
                  leftLabel: 'Customer',
                  leftValue: shipment.customerName,
                  rightLabel: 'Weight',
                  rightValue: shipment.weight,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Status:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1C2430),
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                      color: const Color(0xFFE0F4E8),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2FA56E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'In Transit',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFF1C2430),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
  });

  final String leftLabel;
  final String leftValue;
  final String rightLabel;
  final String rightValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                leftValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2430),
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                rightLabel,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black45,
                      fontSize: 10,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                rightValue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1C2430),
                      fontSize: 13,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineStepItem extends StatelessWidget {
  const _TimelineStepItem({
    required this.step,
    required this.showConnector,
  });

  final TrackingTimelineStep step;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    final activeColor = step.completed ? const Color(0xFF2FA56E) : const Color(0xFFE0F4E8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: activeColor,
                shape: BoxShape.circle,
              ),
            ),
            if (showConnector)
              Container(
                width: 2,
                height: 38,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4E8),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                step.subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ContactIconButton extends StatelessWidget {
  const _ContactIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF2FA56E),
        ),
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  const _ZoomButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Icon(icon, size: 24, color: const Color(0xFF111111)),
      ),
    );
  }
}

class _LiveRouteOverlay extends StatelessWidget {
  const _LiveRouteOverlay({required this.pulse});

  final double pulse;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LiveRoutePainter(pulse: pulse),
    );
  }
}

class _LiveRoutePainter extends CustomPainter {
  const _LiveRoutePainter({required this.pulse});

  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final pathPaint = Paint()
      ..color = const Color(0xFF2FA56E).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final startGlow = Paint()..color = const Color(0xFF2FA56E).withValues(alpha: 0.24);
    final startCore = Paint()..color = const Color(0xFF2FA56E);
    final endCore = Paint()..color = const Color(0xFF2FA56E);
    final endGlow = Paint()
      ..color = const Color(0xFF2FA56E).withValues(alpha: 0.35 + (pulse * 0.40));

    final path = Path()
      ..moveTo(size.width * 0.28, size.height * 0.66)
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.45, size.width * 0.50, size.height * 0.40)
      ..quadraticBezierTo(size.width * 0.62, size.height * 0.36, size.width * 0.74, size.height * 0.28);

    canvas.drawPath(path, pathPaint);

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final metric = metrics.first;
      final animatedOffset = metric.length * pulse;

      for (double offset = 0; offset < metric.length; offset += 18) {
        final sample = metric.getTangentForOffset((offset + animatedOffset) % metric.length);
        if (sample == null) continue;

        final t = (offset / metric.length);
        final alpha = (0.06 + (1 - t) * 0.18) * (0.65 + pulse * 0.35);
        final radius = 2.2 + ((1 - t) * 1.6);

        canvas.drawCircle(
          sample.position,
          radius,
          Paint()..color = const Color(0xFF2FA56E).withValues(alpha: alpha),
        );
      }

      final livePoint = metric.getTangentForOffset(animatedOffset);
      if (livePoint != null) {
        canvas.drawCircle(
          livePoint.position,
          11 + (pulse * 5),
          Paint()..color = const Color(0xFF2FA56E).withValues(alpha: 0.18 + (pulse * 0.18)),
        );
        canvas.drawCircle(
          livePoint.position,
          5.5,
          Paint()..color = Colors.white,
        );
      }
    }

    final startCenter = Offset(size.width * 0.28, size.height * 0.66);
    final startOuter = 28 + (pulse * 10);
    final startInner = 12 + (pulse * 2.5);

    canvas.drawCircle(
      startCenter,
      startOuter,
      Paint()..color = const Color(0xFF2FA56E).withValues(alpha: 0.10 + (pulse * 0.12)),
    );
    canvas.drawCircle(startCenter, 34 + (pulse * 6), startGlow);
    canvas.drawCircle(startCenter, startInner, startCore);
    canvas.drawCircle(startCenter, 4.5, Paint()..color = Colors.white);

    final endCenter = Offset(size.width * 0.74, size.height * 0.28);
    final glowRadius = 28 + (pulse * 14);
    final coreRadius = 12 + (pulse * 3.0);

    canvas.drawCircle(
      endCenter,
      glowRadius + 10,
      Paint()..color = const Color(0xFF2FA56E).withValues(alpha: 0.10 + (pulse * 0.14)),
    );
    canvas.drawCircle(endCenter, glowRadius, endGlow);
    canvas.drawCircle(endCenter, 26 + (pulse * 4), startGlow);
    canvas.drawCircle(endCenter, coreRadius, endCore);
    canvas.drawCircle(endCenter, 4.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _LiveRoutePainter oldDelegate) => oldDelegate.pulse != pulse;
}

class TrackingMapBackdrop extends StatelessWidget {
  const TrackingMapBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _TrackingMapPainter(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF3F6FB),
              Color(0xFFE8EEF6),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrackingMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = const Color(0xFFD8DEE9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final roadAccentPaint = Paint()
      ..color = const Color(0xFFC8D2E4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final nodePaint = Paint()..color = const Color(0xFFF9FBFD);
    final nodeBorderPaint = Paint()
      ..color = const Color(0xFFCFEFDB)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF3F6FB),
    );

    final paths = [
      Path()
        ..moveTo(size.width * 0.08, size.height * 0.18)
        ..quadraticBezierTo(size.width * 0.4, size.height * 0.12, size.width * 0.62, size.height * 0.24)
        ..quadraticBezierTo(size.width * 0.82, size.height * 0.34, size.width * 0.95, size.height * 0.22),
      Path()
        ..moveTo(size.width * 0.05, size.height * 0.44)
        ..quadraticBezierTo(size.width * 0.32, size.height * 0.38, size.width * 0.5, size.height * 0.5)
        ..quadraticBezierTo(size.width * 0.72, size.height * 0.62, size.width * 0.98, size.height * 0.56),
      Path()
        ..moveTo(size.width * 0.14, size.height * 0.72)
        ..quadraticBezierTo(size.width * 0.38, size.height * 0.64, size.width * 0.58, size.height * 0.76)
        ..quadraticBezierTo(size.width * 0.78, size.height * 0.86, size.width * 0.94, size.height * 0.78),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, roadAccentPaint);
    }

    final nodes = [
      Offset(size.width * 0.18, size.height * 0.24),
      Offset(size.width * 0.46, size.height * 0.33),
      Offset(size.width * 0.72, size.height * 0.27),
      Offset(size.width * 0.28, size.height * 0.58),
      Offset(size.width * 0.63, size.height * 0.66),
      Offset(size.width * 0.84, size.height * 0.82),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 11, nodePaint);
      canvas.drawCircle(node, 11, nodeBorderPaint);
      canvas.drawCircle(node, 3.5, Paint()..color = const Color(0xFF2FA56E));
    }

    final gridPaint = Paint()
      ..color = const Color(0xFFE5EBF3)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = size.height * (0.12 + i * 0.18);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
