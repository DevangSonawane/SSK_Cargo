part of '../client_flow_widgets.dart';
class _FindTruckOfferCard extends StatefulWidget {
  const _FindTruckOfferCard({
    super.key,
    required this.request,
    required this.busy,
    this.errorText,
    this.onAccept,
    this.onReject,
    this.onCounter,
  });

  final ClientBookingOffer request;
  final bool busy;
  final String? errorText;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final Future<bool> Function(ClientBookingOffer request, double amount)?
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
  // Web parity (DriverOfferCard): once OUR counter is sent, this card waits
  // for the driver — no Confirm/Counter/Decline buttons — until the DRIVER
  // actually moves. Release happens only on a driver-side signal (they
  // accept, it's our turn to confirm, their history entry lands last, or
  // the amount moves off our sent value). Our own counter echoing back
  // must NOT release it.
  bool _waitingOnDriver = false;
  double _myCounterAmount = 0;

  @override
  void didUpdateWidget(covariant _FindTruckOfferCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_waitingOnDriver && !_sent) return;
    final row = widget.request;
    var driverActed =
        row.normalizedStatus == 'accepted' || row.isClientTurnToConfirm;
    if (!driverActed && row.offerHistory.isNotEmpty) {
      final lastBy = row.offerHistory.last.by;
      driverActed = lastBy.isNotEmpty && lastBy != 'client';
    }
    if (!driverActed &&
        row.isCountered &&
        _myCounterAmount > 0 &&
        row.amountValue > 0) {
      driverActed = (row.amountValue - _myCounterAmount).abs() > 0.5;
    }
    if (driverActed) {
      setState(() {
        _waitingOnDriver = false;
        _negotiating = false;
        _sent = false;
      });
    }
  }

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
      final sent = await onCounter(widget.request, _offerAmount);
      if (!mounted) return;
      if (sent) {
        setState(() {
          _sentAmount = _offerAmount;
          _myCounterAmount = _offerAmount;
          _waitingOnDriver = true;
          _sent = true;
        });
      }
      // On failure the parent already showed the error — stay on the slider
      // so the user retries right here instead of going back and reopening.
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
    // Actionable cards glow green like the selected inDrive bid; idle ones
    // stay neutral so attention lands where action is needed.
    final actionable = isConfirmTurn || request.isCountered;
    final initial = driverName.trim().isNotEmpty
        ? driverName.trim()[0].toUpperCase()
        : 'D';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: actionable
              ? const Color(0xFF2FA56E)
              : context.colors.line,
          width: actionable ? 1.4 : 1,
        ),
        boxShadow: [
          if (actionable)
            BoxShadow(
              color: const Color(0xFF2FA56E).withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profile picture on top-middle, then name, truck number, phone —
          // one centered stack.
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E).withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: const Color(0xFF167247),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (request.truckReg.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              request.truckReg,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (request.driverPhone.isNotEmpty)
            InkWell(
              onTap: () => _callDriver(request.driverPhone),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.phone_outlined,
                      size: 13,
                      color: Color(0xFF2FA56E),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        request.driverPhone,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall
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
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
          const SizedBox(height: 10),
          // The driver ask hides the moment Counter opens — the wheel
          // takes its place.
          if (!_negotiating)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: context.colors.fillSubtle,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Text(
                    isConfirmTurn
                        ? 'FINAL PRICE'
                        : request.isCountered
                        ? 'COUNTER OFFER'
                        : 'DRIVER ASK',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: context.colors.textTertiary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    amount,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF167247),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
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
            const SizedBox(height: 10),
            Text(
              'SET YOUR COUNTER',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: context.colors.textTertiary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
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
                    : (value) => setState(() => _offerAmount = value),
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
            const SizedBox(height: 8),
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
          ] else if (_waitingOnDriver) ...[
            // Web parity: after OUR counter lands, the card waits for the
            // driver — no Confirm/Counter/Decline until they move.
            const SizedBox(height: 4),
            Text(
              'Your counter of ${_rupees(_myCounterAmount > 0 ? _myCounterAmount : _sentAmount)} was sent — waiting for ${driverName == 'Driver' ? 'the driver' : driverName} to respond.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.colors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      widget.busy
                          ? '···'
                          : isConfirmTurn
                          ? 'Confirm'
                          : request.isCountered
                          ? 'Accept'
                          : 'Confirm',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
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
                        foregroundColor: const Color(0xFF167247),
                        side: const BorderSide(
                          color: Color(0xFF2FA56E),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Counter',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.busy || widget.onReject == null
                        ? null
                        : widget.onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD92D20),
                      side: const BorderSide(color: Color(0xFFF3B4B4)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (widget.errorText != null && widget.errorText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.errorText!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: const Color(0xFFD92D20),
                fontWeight: FontWeight.w700,
              ),
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

/// inDrive-style swipe deck: every live driver offer as its own negotiable
/// card in a horizontal pager with a peeking neighbour, dots, and counter.
class _FindTruckOffersPager extends StatefulWidget {
  const _FindTruckOffersPager({
    required this.requests,
    required this.actingId,
    this.onAccept,
    this.onReject,
    this.onCounter,
    this.errorFor,
  });

  final List<ClientBookingOffer> requests;
  final String? actingId;
  final ValueChanged<ClientBookingOffer>? onAccept;
  final ValueChanged<ClientBookingOffer>? onReject;
  final Future<bool> Function(ClientBookingOffer request, double amount)?
  onCounter;
  final String? Function(String id)? errorFor;

  @override
  State<_FindTruckOffersPager> createState() => _FindTruckOffersPagerState();
}

class _FindTruckOffersPagerState extends State<_FindTruckOffersPager> {
  late final PageController _controller = PageController(
    viewportFraction: 0.88,
  );
  int _page = 0;

  @override
  void didUpdateWidget(covariant _FindTruckOffersPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requests.length != oldWidget.requests.length &&
        widget.requests.isNotEmpty &&
        _page >= widget.requests.length) {
      _page = widget.requests.length - 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) {
          _controller.jumpToPage(_page);
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requests = widget.requests;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 390,
          child: PageView.builder(
            controller: _controller,
            itemCount: requests.length,
            onPageChanged: (index) => setState(() => _page = index),
            itemBuilder: (context, index) {
              final request = requests[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < requests.length - 1 ? 10 : 0,
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                    child: _FindTruckOfferCard(
                      key: ValueKey(request.id),
                      request: request,
                      busy: widget.actingId == request.id,
                      errorText: widget.errorFor?.call(request.id),
                    onAccept: widget.onAccept == null
                        ? null
                        : () => widget.onAccept!(request),
                    onReject: widget.onReject == null
                        ? null
                        : () => widget.onReject!(request),
                    onCounter: widget.onCounter,
                  ),
                ),
              );
            },
          ),
        ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                requests.length.clamp(0, 12),
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  margin: const EdgeInsets.symmetric(horizontal: 2.5),
                  width: index == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: index == _page
                        ? const Color(0xFF2FA56E)
                        : context.colors.line,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (requests.length > 1) ...[
                const SizedBox(width: 8),
                Text(
                  '${(_page + 1).clamp(1, requests.length)} of ${requests.length}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          if (requests.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Swipe to compare drivers',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: context.colors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ),
      ],
    );
  }
}

/// Cards-only bottom dialog for the live driver offers: the swipe deck plus
/// a cross button — nothing else.
class _FindTruckOffersSheet extends StatelessWidget {
  const _FindTruckOffersSheet({
    required this.requests,
    required this.totalCount,
    required this.actingId,
    this.onAccept,
    this.onReject,
    this.onCounter,
    this.errorFor,
    this.onClose,
    this.onKeepSearching,
    this.searchingAgain = false,
    this.offersError = false,
    this.onRetryOffers,
  });

  final List<ClientBookingOffer> requests;
  final int totalCount;
  final String? actingId;
  final ValueChanged<ClientBookingOffer>? onAccept;
  final ValueChanged<ClientBookingOffer>? onReject;
  final Future<bool> Function(ClientBookingOffer request, double amount)?
  onCounter;
  final String? Function(String id)? errorFor;
  // Cross button AND Go Back both leave the search for Choose Trucks.
  final VoidCallback? onClose;
  // Re-notifies drivers without leaving the dialog.
  final VoidCallback? onKeepSearching;
  final bool searchingAgain;
  final bool offersError;
  final VoidCallback? onRetryOffers;

  @override
  Widget build(BuildContext context) {
    final live =
        requests
            .where((request) => request.normalizedStatus != 'declined')
            .toList()
          ..sort((a, b) => b.negotiationRank.compareTo(a.negotiationRank));
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.zero,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            border: Border(
              top: BorderSide(color: context.colors.line, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.colors.line,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        live.isEmpty
                            ? 'Finding drivers'
                            : 'Driver offers (${live.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: onClose ?? () => Navigator.of(context).maybePop(),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.fillSubtle,
                        foregroundColor: context.colors.textSecondary,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(AppIcons.close_rounded, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (live.isNotEmpty)
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: _FindTruckOffersPager(
                        requests: live,
                        actingId: actingId,
                        onAccept: onAccept,
                        onReject: onReject,
                        onCounter: onCounter,
                        errorFor: errorFor,
                      ),
                    ),
                  )
                else if (totalCount == 0)
                  // Search just started — no rows yet. Offers slide in here
                  // the moment drivers respond.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.fillSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.line),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Color(0xFF2FA56E),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Finding nearby trucks…',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Notifying drivers — their offers will appear here.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                        ),
                        if (offersError) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: onRetryOffers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ],
                    ),
                  )
                else
                  // Every driver declined: stay in the same dialog with a
                  // way out — keep waiting on a rebroadcast, or go back to
                  // Choose Trucks.
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.fillSubtle,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.line),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: context.colors.brandFill,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            AppIcons.local_shipping_rounded,
                            color: Color(0xFF2FA56E),
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Oops! No driver accepted',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Every nearby driver declined or timed out. Keep searching to notify them again, or go back to choose trucks.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: searchingAgain
                                    ? null
                                    : onKeepSearching,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  searchingAgain
                                      ? 'Searching...'
                                      : 'Keep Searching',
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: onClose,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2FA56E),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 13,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text('Go Back'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                // Sits right above the Android system buttons — the padding
                // equals the device's own nav inset, so it adapts per phone.
                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
