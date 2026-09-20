part of '../client_flow_widgets.dart';

class _BrokerDiscoveryLoader extends StatefulWidget {
  const _BrokerDiscoveryLoader({required this.messages});

  final List<String> messages;

  @override
  State<_BrokerDiscoveryLoader> createState() => _BrokerDiscoveryLoaderState();
}

class _BrokerDiscoveryLoaderState extends State<_BrokerDiscoveryLoader> {
  Timer? _timer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || widget.messages.isEmpty) {
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % widget.messages.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _BrokerDiscoveryLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages) {
      _messageIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.messages.isEmpty
        ? 'Connecting brokers near you'
        : widget.messages[_messageIndex % widget.messages.length];

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: context.colors.line),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  color: Color(0xFF2FA56E),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 28),
                Text(
                  message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Dont worry, I will help you reach your package in its proper destination safely.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.colors.textSecondary,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.brandFill,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Searching live rates and nearby partners',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
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

class _FindTruckScreenLoader extends StatefulWidget {
  const _FindTruckScreenLoader({
    required this.bookingReference,
    required this.requestCount,
    required this.declinedCount,
    required this.searchRadiusKm,
    required this.isCancelling,
    required this.onCancel,
    required this.pickup,
    required this.drop,
    required this.amountText,
  });

  final String? bookingReference;
  final int requestCount;
  final int declinedCount;
  final double searchRadiusKm;
  final bool isCancelling;
  final VoidCallback onCancel;
  final String pickup;
  final String drop;
  final String amountText;

  @override
  State<_FindTruckScreenLoader> createState() => _FindTruckScreenLoaderState();
}

class _FindTruckScreenLoaderState extends State<_FindTruckScreenLoader> {
  static const int _searchWindowSeconds = 120;

  Timer? _elapsedTimer;
  int _elapsedSeconds = 0;

  bool get _allDeclined =>
      widget.requestCount > 0 && widget.declinedCount >= widget.requestCount;

  bool get _active => !_allDeclined;

  bool get _timedOut => _active && _elapsedSeconds >= _searchWindowSeconds;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(covariant _FindTruckScreenLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncTimer();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    if (!_active) {
      _elapsedTimer?.cancel();
      _elapsedTimer = null;
      if (_elapsedSeconds != 0) {
        _elapsedSeconds = 0;
      }
      return;
    }
    _elapsedTimer ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || !_active) {
        return;
      }
      setState(() {
        _elapsedSeconds += 1;
      });
    });
  }

  void _searchAgain() {
    setState(() {
      _elapsedSeconds = 0;
    });
  }

  String _elapsedLabel() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeCount = (widget.requestCount - widget.declinedCount).clamp(
      0,
      widget.requestCount,
    );
    final hasNotifiedDrivers = activeCount > 0;
    final progress = (_elapsedSeconds / _searchWindowSeconds).clamp(0.0, 1.0);
    return SafeArea(
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (_active) const Positioned.fill(child: _FindTruckRadarPulse()),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: context.colors.surfaceElevated.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: context.colors.brandBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 26,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: context.colors.brandFill,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                AppIcons.radar_rounded,
                                color: Color(0xFF2FA56E),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _allDeclined
                                        ? 'No drivers accepted yet'
                                        : hasNotifiedDrivers
                                        ? 'Notified $activeCount driver${activeCount == 1 ? '' : 's'} nearby'
                                        : 'Finding nearby trucks',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.w900,
                                          height: 1.12,
                                        ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    _allDeclined
                                        ? 'Every notified driver declined or timed out.'
                                        : hasNotifiedDrivers
                                        ? 'Waiting for the first live response.'
                                        : 'Scanning the route for available trucks.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: context.colors.textSecondary,
                                          height: 1.35,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Cancel search',
                              onPressed: widget.isCancelling
                                  ? null
                                  : widget.onCancel,
                              style: IconButton.styleFrom(
                                backgroundColor: context.colors.fillSubtle,
                                foregroundColor: context.colors.textSecondary,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: widget.isCancelling
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      AppIcons.close_rounded,
                                      size: 18,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_active) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    color: const Color(0xFF2FA56E),
                                    backgroundColor: context.colors.fillSubtle,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _elapsedLabel(),
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: context.colors.textSecondary,
                                      fontWeight: FontWeight.w800,
                                      fontFeatures: const [
                                        ui.FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                        Row(
                          children: [
                            Expanded(
                              child: _FindTruckStatusChip(
                                icon: AppIcons.local_shipping_rounded,
                                label: hasNotifiedDrivers
                                    ? '$activeCount active'
                                    : 'Live scan',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _FindTruckStatusChip(
                                icon: AppIcons.near_me_rounded,
                                label:
                                    '${widget.searchRadiusKm.round()} km radius',
                              ),
                            ),
                          ],
                        ),
                        if (widget.pickup.isNotEmpty ||
                            widget.drop.isNotEmpty ||
                            widget.amountText.isNotEmpty ||
                            widget.bookingReference?.isNotEmpty == true) ...[
                          const SizedBox(height: 12),
                          _FindTruckSummaryLine(
                            pickup: widget.pickup,
                            drop: widget.drop,
                            amountText: widget.amountText,
                            bookingReference: widget.bookingReference,
                          ),
                        ],
                        if (_timedOut) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFAEB),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFFEDFA7),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Still no driver yet',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Search again to keep waiting, or cancel and start over.',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: context.colors.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: widget.isCancelling
                                            ? null
                                            : _searchAgain,
                                        child: const Text('Search Again'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: widget.isCancelling
                                            ? null
                                            : widget.onCancel,
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFD92D20,
                                          ),
                                          foregroundColor: Colors.white,
                                        ),
                                        child: Text(
                                          widget.isCancelling
                                              ? 'Cancelling...'
                                              : 'Cancel Search',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FindTruckRadarPulse extends StatefulWidget {
  const _FindTruckRadarPulse();

  @override
  State<_FindTruckRadarPulse> createState() => _FindTruckRadarPulseState();
}

class _FindTruckRadarPulseState extends State<_FindTruckRadarPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                for (final delay in const [0.0, 0.33, 0.66])
                  _RadarRing(progress: (_controller.value + delay) % 1),
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2FA56E),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.95),
                        spreadRadius: 5,
                      ),
                      BoxShadow(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.30),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RadarRing extends StatelessWidget {
  const _RadarRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = ui.lerpDouble(18, 252, progress)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(
            0xFF2FA56E,
          ).withValues(alpha: (0.52 * (1 - progress)).clamp(0.0, 0.52)),
          width: 2,
        ),
        color: const Color(
          0xFF2FA56E,
        ).withValues(alpha: (0.12 * (1 - progress)).clamp(0.0, 0.12)),
      ),
    );
  }
}

class _FindTruckSummaryLine extends StatelessWidget {
  const _FindTruckSummaryLine({
    required this.pickup,
    required this.drop,
    required this.amountText,
    required this.bookingReference,
  });

  final String pickup;
  final String drop;
  final String amountText;
  final String? bookingReference;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (pickup.isNotEmpty && drop.isNotEmpty) '$pickup to $drop',
      if (amountText.isNotEmpty) amountText,
      if (bookingReference?.isNotEmpty == true) 'Booking #$bookingReference',
    ];
    return Text(
      parts.join(' · '),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: const Color(0xFF2FA56E),
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _FindTruckStatusChip extends StatelessWidget {
  const _FindTruckStatusChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 40),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: context.colors.fillSubtle,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.colors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2FA56E)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
