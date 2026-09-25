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
    this.negotiateLabel,
    this.onNegotiate,
    this.requests = const [],
    this.actingId,
    this.onAccept,
    this.onReject,
    this.onCounter,
    this.searchingAgain = false,
    this.onSearchAgain,
    this.offersError = false,
    this.onRetryOffers,
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

  /// Broker-mode escape hatch: the broker hasn't acted yet, so nothing
  /// auto-opens — but the client can still start negotiating manually.
  final String? negotiateLabel;
  final VoidCallback? onNegotiate;

  /// Multi-offer fan-out (web parity with DriverFanOutWaiting): every live
  /// driver_requests row rendered as its own negotiable card.
  final List<ClientBookingOffer> requests;
  final String? actingId;
  final ValueChanged<ClientBookingOffer>? onAccept;
  final ValueChanged<ClientBookingOffer>? onReject;
  final Future<void> Function(ClientBookingOffer request, double amount)?
  onCounter;

  /// Web parity (FindTruckSearch.jsx "Search Again"): re-notifies drivers
  /// server-side. While true the search-again buttons show a busy state.
  final bool searchingAgain;
  final VoidCallback? onSearchAgain;

  /// Offers-poll failure flag with a retry entry point (web parity with the
  /// "Couldn't load driver responses → Retry" banner).
  final bool offersError;
  final VoidCallback? onRetryOffers;

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
    widget.onSearchAgain?.call();
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
    // Shared sorted live list (web RANK: accepted → awaiting → countered →
    // pending) so the header, chip, and cards all agree on what's visible.
    final liveRequests =
        widget.requests
            .where(
              (request) => request.normalizedStatus != 'declined',
            )
            .toList()
          ..sort(
            (a, b) => b.negotiationRank.compareTo(a.negotiationRank),
          );
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
                        // Web parity: offers-poll failure surfaces a retry
                        // banner instead of failing silently.
                        if (widget.offersError) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Couldn't load driver responses.",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: const Color(0xFFB42318),
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: widget.onRetryOffers,
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFFB42318),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],
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
                        // Web parity: same signal as Ola/Uber's search screen —
                        // the first driver to accept gets the job.
                        if (_active && liveRequests.isNotEmpty) ...[
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.brandFill,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  AppIcons.schedule_rounded,
                                  size: 14,
                                  color: Color(0xFF2FA56E),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'First to accept gets the job',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFF167247),
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Multi-offer fan-out (web parity with
                        // DriverFanOutWaiting + DriverOfferCard): every live
                        // (non-declined) driver gets its own negotiable card
                        // right here in the search overlay.
                        Builder(
                          builder: (context) {
                            final live = liveRequests;
                            if (live.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const ClampingScrollPhysics(),
                                  itemCount: live.length,
                                  separatorBuilder:
                                      (_, _) => const SizedBox(
                                        height: 10,
                                      ),
                                  itemBuilder: (context, index) {
                                    final request = live[index];
                                    return _FindTruckOfferCard(
                                      key: ValueKey(request.id),
                                      request: request,
                                      busy:
                                          widget.actingId ==
                                          request.id,
                                      onAccept:
                                          widget.onAccept == null
                                          ? null
                                          : () => widget.onAccept!(
                                              request,
                                            ),
                                      onReject:
                                          widget.onReject == null
                                          ? null
                                          : () => widget.onReject!(
                                              request,
                                            ),
                                      onCounter: widget.onCounter,
                                    );
                                  },
                                ),
                              ),
                            );
                          },
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
                        if (widget.onNegotiate != null &&
                            widget.negotiateLabel != null) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: widget.onNegotiate,
                              icon: const Icon(
                                AppIcons.handshake_rounded,
                                size: 18,
                              ),
                              label: Text(widget.negotiateLabel!),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF167247),
                                side: const BorderSide(
                                  color: Color(0xFF2FA56E),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                        // Web parity: once every fanned-out driver has declined
                        // or timed out, offer a real way out — Search Again
                        // re-notifies drivers server-side.
                        if (_allDeclined) ...[
                          const SizedBox(height: 14),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.colors.fillSubtle,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context.colors.line,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No drivers accepted yet',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(
                                        color: context.colors.textPrimary,
                                        fontWeight: FontWeight.w900,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Every driver nearby declined or didn\'t respond. You can notify them again, or cancel and start over.',
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
                                        onPressed:
                                            widget.isCancelling ||
                                                widget.searchingAgain
                                            ? null
                                            : _searchAgain,
                                        child: Text(
                                          widget.searchingAgain
                                              ? 'Searching...'
                                              : 'Search Again',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed:
                                            widget.isCancelling ||
                                                widget.searchingAgain
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
                                        onPressed:
                                            widget.isCancelling ||
                                                widget.searchingAgain
                                            ? null
                                            : _searchAgain,
                                        child: Text(
                                          widget.searchingAgain
                                              ? 'Searching...'
                                              : 'Search Again',
                                        ),
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

/// One independently-negotiable driver offer card — Flutter twin of the web
/// `DriverOfferCard.jsx`, rendered once per live driver_requests row inside
/// the find-truck search overlay.
class _FindTruckOfferCard extends StatefulWidget {
  const _FindTruckOfferCard({
    super.key,
    required this.request,
    required this.busy,
    this.onAccept,
    this.onReject,
    this.onCounter,
  });

  final ClientBookingOffer request;
  final bool busy;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final Future<void> Function(ClientBookingOffer request, double amount)?
  onCounter;

  @override
  State<_FindTruckOfferCard> createState() => _FindTruckOfferCardState();
}

class _FindTruckOfferCardState extends State<_FindTruckOfferCard> {
  bool _historyOpen = false;
  // Inline negotiate flow — mirrors web DriverOfferCard's
  // `negotiate` { min, max, stage: 'set' | 'sent' } state.
  bool _negotiating = false;
  bool _sent = false;
  bool _sending = false;
  double _min = 0;
  double _max = 0;
  double _offerAmount = 0;
  double _sentAmount = 0;

  void _openNegotiate() {
    final double base = widget.request.amountValue > 0
        ? widget.request.amountValue
        : 1000;
    final min = (base * 0.78).round().toDouble();
    setState(() {
      _min = min;
      _max = base < min + 1 ? min + 1 : base;
      _offerAmount = base.clamp(_min, _max).toDouble();
      _negotiating = true;
      _sent = false;
    });
  }

  void _closeNegotiate() {
    setState(() {
      _negotiating = false;
      _sent = false;
    });
  }

  Future<void> _submitNegotiate() async {
    final onCounter = widget.onCounter;
    if (onCounter == null || _sending) return;
    setState(() => _sending = true);
    try {
      await onCounter(widget.request, _offerAmount);
      if (!mounted) return;
      setState(() {
        _sentAmount = _offerAmount;
        _sent = true;
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _rupees(double value) {
    return '₹${value.toStringAsFixed(value % 1 == 0 ? 0 : 2)}';
  }

  Future<void> _callDriver(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: digits);
    try {
      await launchUrl(uri);
    } catch (_) {
      // Dialer unavailable — the number is still visible on the card.
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    final driverName = request.brokerName.isNotEmpty
        ? request.brokerName
        : 'Driver';
    final amount = request.amountText.isNotEmpty ? request.amountText : '—';

    final String statusLabel;
    final Color pillBg;
    final Color pillFg;
    if (request.isClientTurnToConfirm) {
      statusLabel = 'Your turn to confirm';
      pillBg = const Color(0xFFE8F5EE);
      pillFg = const Color(0xFF167247);
    } else if (request.isWaitingForCounterpartyConfirmation) {
      statusLabel = 'Waiting for them to confirm';
      pillBg = const Color(0xFFF0F2F5);
      pillFg = const Color(0xFF667085);
    } else if (request.isCountered) {
      statusLabel = 'Countered — your turn';
      pillBg = const Color(0xFFFFF4E0);
      pillFg = const Color(0xFFB54708);
    } else if (request.normalizedStatus == 'accepted') {
      statusLabel = 'Confirmed';
      pillBg = const Color(0xFFE8F5EE);
      pillFg = const Color(0xFF167247);
    } else {
      statusLabel = request.driverTimedOut
          ? 'No response — broker notified'
          : 'Waiting for response';
      pillBg = const Color(0xFFF0F2F5);
      pillFg = const Color(0xFF667085);
    }

    final isConfirmTurn = request.isClientTurnToConfirm;
    final isWaiting = request.isWaitingForCounterpartyConfirmation;
    final canCounter =
        request.normalizedStatus == 'pending' || request.isCountered;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.colors.brandFill,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  AppIcons.local_shipping_rounded,
                  color: Color(0xFF2FA56E),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driverName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (request.truckReg.isNotEmpty)
                      Text(
                        request.truckReg,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: context.colors.textSecondary),
                      ),
                    if (request.driverPhone.isNotEmpty)
                      InkWell(
                        onTap: () => _callDriver(request.driverPhone),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.phone_outlined,
                                size: 12,
                                color: Color(0xFF2FA56E),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  request.driverPhone,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: const Color(0xFF167247),
                                        fontWeight: FontWeight.w700,
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: pillFg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: const Color(0xFF167247),
              fontWeight: FontWeight.w900,
            ),
          ),
          if (_negotiating && _sent) ...[
            const SizedBox(height: 8),
            Text(
              'Your offer of ${_rupees(_sentAmount)} was sent — this card updates automatically once ${driverName == 'Driver' ? 'they' : driverName} respond.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _closeNegotiate,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Back', style: TextStyle(fontSize: 12)),
              ),
            ),
          ] else if (_negotiating) ...[
            const SizedBox(height: 8),
            Text(
              'Current Offer'.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            Text(
              amount,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF167247),
                fontWeight: FontWeight.w900,
              ),
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: const Color(0xFF2FA56E),
                thumbColor: const Color(0xFF2FA56E),
                overlayColor: const Color(
                  0xFF2FA56E,
                ).withValues(alpha: 0.15),
              ),
              child: Slider(
                min: _min,
                max: _max,
                value: _offerAmount.clamp(_min, _max).toDouble(),
                onChanged: _sending
                    ? null
                    : (value) =>
                          setState(() => _offerAmount = value),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _rupees(_min),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
                Text(
                  _rupees(_max),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textTertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Your Counter-Offer: ${_rupees(_offerAmount)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFFB54708),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _sending || widget.busy
                        ? null
                        : _submitNegotiate,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _sending ? 'Sending...' : 'Send Offer',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _sending ? null : _closeNegotiate,
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ] else if (isWaiting) ...[
            const SizedBox(height: 4),
            Text(
              'You accepted — waiting for ${driverName == 'Driver' ? 'the driver' : driverName} to confirm.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ] else if (!isConfirmTurn &&
              !request.isCountered &&
              request.normalizedStatus != 'pending') ...[
            const SizedBox(height: 4),
            Text(
              'This offer is no longer actionable.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: widget.busy || widget.onAccept == null
                        ? null
                        : widget.onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.busy
                          ? 'Sending...'
                          : isConfirmTurn
                          ? 'Confirm'
                          : request.isCountered
                          ? 'Accept This Price'
                          : 'Confirm Now',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                if (canCounter) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.busy
                          ? null
                          : _openNegotiate,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Counter',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: widget.busy || widget.onReject == null
                      ? null
                      : widget.onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD92D20),
                    side: const BorderSide(color: Color(0xFFF3B4B4)),
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          if (request.offerHistory.length > 1) ...[
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _historyOpen = !_historyOpen),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _historyOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: context.colors.textSecondary,
                      ),
                    ),
                    Text(
                      'Negotiation history (${request.offerHistory.length})',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_historyOpen)
              ...request.offerHistory.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    '${entry.displayBy} offered ₹${entry.amount.toStringAsFixed(entry.amount % 1 == 0 ? 0 : 2)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
