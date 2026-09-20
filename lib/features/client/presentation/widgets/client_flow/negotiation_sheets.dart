part of '../client_flow_widgets.dart';

enum _DirectNegotiationStage { compose, waiting, payment, confirmed }

enum _FindTruckNegotiationResult { dismissed, payment }

class _DirectNegotiationOutcome {
  const _DirectNegotiationOutcome._(
    this.accepted,
    this.bookingId,
    this.bookingNumber,
    this.amount,
  );

  factory _DirectNegotiationOutcome.rejected() =>
      const _DirectNegotiationOutcome._(false, '', '', null);

  final bool accepted;
  final String bookingId;
  final String bookingNumber;
  final double? amount;
}

class _DirectRequestSession {
  const _DirectRequestSession({
    required this.bookingId,
    required this.bookingNumber,
    required this.request,
  });

  final String bookingId;
  final String bookingNumber;
  final ClientBookingOffer? request;
}

class _BrokerNegotiationSheet extends ConsumerStatefulWidget {
  const _BrokerNegotiationSheet({
    required this.truck,
    required this.minPrice,
    required this.maxPrice,
    required this.initialPrice,
    required this.onTrack,
    required this.onHome,
    required this.onCreateRequest,
  });

  final NearbyTruck truck;
  final double minPrice;
  final double maxPrice;
  final double initialPrice;
  final VoidCallback onTrack;
  final VoidCallback onHome;
  final Future<_DirectRequestSession?> Function(double amount) onCreateRequest;

  @override
  ConsumerState<_BrokerNegotiationSheet> createState() =>
      _BrokerNegotiationSheetState();
}

class _BrokerNegotiationSheetState
    extends ConsumerState<_BrokerNegotiationSheet> {
  static const Duration _refreshInterval = Duration(seconds: 4);

  late double _value;
  _DirectNegotiationStage _stage = _DirectNegotiationStage.compose;
  ClientBookingOffer? _request;
  String? _bookingId;
  String? _bookingNumber;
  bool _submitting = false;
  bool _paymentSubmitting = false;
  bool _loading = false;
  bool _loadingAdvanceAmount = false;
  String? _errorMessage;
  double? _advanceAmount;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.googlePay;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _jobRequestSubscription;

  @override
  void initState() {
    super.initState();
    _value = widget.initialPrice;
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _driverRequestSubscription?.cancel();
    _jobRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _sendOffer() async {
    if (_submitting) {
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final session = await widget.onCreateRequest(_value);
      if (!mounted || session == null) {
        return;
      }

      setState(() {
        _bookingId = session.bookingId;
        _bookingNumber = session.bookingNumber;
        _request = session.request;
        _stage = _DirectNegotiationStage.waiting;
      });

      await _startLiveUpdates();
      await _loadCurrentRequest(silent: true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _startLiveUpdates() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _bookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(
      accessToken: session.tokens.accessToken,
    );

    _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      final payloadMap = _payloadAsMap(payload);
      if (payloadMap == null) {
        return;
      }

      final payloadBookingId = _readString(payloadMap, const [
        'bookingId',
        'booking_id',
      ]);
      final payloadRequestId = _readString(payloadMap, const [
        'id',
        'request_id',
        'driver_request_id',
      ]);

      if (payloadBookingId == bookingId ||
          (_request != null && payloadRequestId == _request!.id)) {
        _loadCurrentRequest(silent: true);
      }
    });

    _jobRequestSubscription?.cancel();
    _jobRequestSubscription = socketService.jobRequestStream.listen((payload) {
      final payloadMap = _payloadAsMap(payload);
      if (payloadMap == null) {
        return;
      }

      final payloadBookingId = _readString(payloadMap, const [
        'bookingId',
        'booking_id',
      ]);
      final payloadRequestId = _readString(payloadMap, const [
        'id',
        'request_id',
        'job_request_id',
      ]);

      if (payloadBookingId == bookingId || payloadRequestId.isNotEmpty) {
        _loadCurrentRequest(silent: true);
      }
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        _loadCurrentRequest(silent: true);
      }
    });
  }

  Map<String, dynamic>? _payloadAsMap(Object? payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    if (payload is Map) {
      return payload.cast<String, dynamic>();
    }
    return null;
  }

  Future<void> _loadCurrentRequest({bool silent = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _bookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    try {
      if (!silent) {
        setState(() {
          _loading = true;
          _errorMessage = null;
        });
      }

      final response = await ref
          .read(apiClientProvider)
          .getDriverRequestByBooking(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );
      final request = _extractDriverRequest(response);

      if (!mounted || request == null) {
        return;
      }

      if (request.normalizedStatus == 'accepted' &&
          _stage == _DirectNegotiationStage.waiting) {
        setState(() {
          _request = request;
          _stage = _DirectNegotiationStage.payment;
        });
        unawaited(_loadAdvanceAmount());
        return;
      }

      setState(() {
        _request = request;
      });
    } catch (_) {
      if (!mounted || silent) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not refresh the live request.';
      });
    } finally {
      if (mounted && !silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptRequest() async {
    final request = _request;
    if (request == null || _paymentSubmitting) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    setState(() {
      _paymentSubmitting = true;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .acceptDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
      if (!mounted) return;
      final responseData = _payloadAsMap(response['data']);
      final updatedRequest =
          _payloadAsMap(responseData?['request']) ?? responseData;
      final booking = _payloadAsMap(responseData?['booking']);
      final responseStatus = _readString(
        updatedRequest ?? const <String, dynamic>{},
        const ['status'],
      ).toLowerCase();
      if (booking != null || responseStatus == 'accepted') {
        setState(() {
          _stage = _DirectNegotiationStage.payment;
        });
        await _loadCurrentRequest(silent: true);
        unawaited(_loadAdvanceAmount());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accepted - waiting for the driver to confirm.'),
          ),
        );
        await _loadCurrentRequest();
      }
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _paymentSubmitting = false;
        });
      }
    }
  }

  Future<void> _rejectRequest() async {
    final request = _request;
    if (request == null || _paymentSubmitting) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    setState(() {
      _paymentSubmitting = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .rejectDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
      if (!mounted) return;
      Navigator.of(context).pop(_DirectNegotiationOutcome.rejected());
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _paymentSubmitting = false;
        });
      }
    }
  }

  Future<void> _counterRequest() async {
    final request = _request;
    if (request == null || _paymentSubmitting) {
      return;
    }

    try {
      final initialAmount = _parsePrice(request.amountText);
      final amount = await showDialog<double>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogContext) =>
            _CounterOfferSliderDialog(initialAmount: initialAmount),
      );
      if (amount == null) return;

      if (amount <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
        return;
      }

      final session = ref.read(authSessionProvider).valueOrNull;
      if (session == null) {
        return;
      }

      setState(() {
        _paymentSubmitting = true;
      });

      await ref
          .read(apiClientProvider)
          .counterDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
            amount: amount,
          );
      if (!mounted) return;
      await _loadCurrentRequest();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _paymentSubmitting = false;
        });
      }
    }
  }

  Future<void> _recordPayment() async {
    final bookingId = _bookingId;
    if (bookingId == null || bookingId.isEmpty || _paymentSubmitting) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    setState(() {
      _paymentSubmitting = true;
      _errorMessage = null;
    });

    final selectedMethod = _selectedPaymentMethod;
    if (selectedMethod == PaymentMethod.payLater) {
      if (!mounted) return;
      setState(() {
        _paymentSubmitting = false;
        _stage = _DirectNegotiationStage.confirmed;
      });
      return;
    }
    if (selectedMethod == PaymentMethod.toBeBilled) {
      try {
        await ref
            .read(apiClientProvider)
            .markBookingToBeBilled(
              accessToken: session.tokens.accessToken,
              id: bookingId,
            );
        if (!mounted) return;
        setState(() {
          _stage = _DirectNegotiationStage.confirmed;
        });
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _errorMessage = error.message;
        });
      } finally {
        if (mounted) {
          setState(() {
            _paymentSubmitting = false;
          });
        }
      }
      return;
    }

    final payType = selectedMethod == PaymentMethod.advance
        ? 'advance'
        : 'full';

    try {
      final paymentGateway = BookingPaymentGateway(
        apiClient: ref.read(apiClientProvider),
      );
      await paymentGateway.payBooking(
        accessToken: session.tokens.accessToken,
        bookingId: bookingId,
        payType: payType,
        contact: session.user.phone,
        email: session.user.email,
        description: selectedMethod == PaymentMethod.advance
            ? 'Advance payment'
            : 'Booking payment',
        context: context,
      );
      if (!mounted) return;
      setState(() {
        _stage = _DirectNegotiationStage.confirmed;
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _paymentSubmitting = false;
        });
      }
    }
  }

  Widget _buildWaitingView() {
    final request = _request;
    final title = request?.normalizedStatus == 'accepted'
        ? 'Driver accepted the request'
        : request?.isClientTurnToConfirm == true
        ? 'Driver accepted - your turn to confirm'
        : request?.isWaitingForCounterpartyConfirmation == true
        ? 'Waiting for driver confirmation'
        : request?.isCountered == true
        ? 'Counter offer received'
        : 'Waiting for driver response';
    final body = request?.normalizedStatus == 'accepted'
        ? 'The driver accepted your request. You can confirm the booking and continue to payment.'
        : request?.isClientTurnToConfirm == true
        ? 'The driver already committed. Confirm or decline to finish the handshake.'
        : request?.isWaitingForCounterpartyConfirmation == true
        ? 'You already confirmed this offer. We are waiting for the driver to confirm now.'
        : request?.isCountered == true
        ? 'The driver sent a counter. Review it here and respond instantly.'
        : request?.driverTimedOut == true
        ? 'The driver did not respond in time. The broker can step in now.'
        : 'Your request is live. We will update this popup as soon as the truck responds.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
        ),
        if (_bookingNumber != null && _bookingNumber!.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Booking #${_bookingNumber!}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2FA56E),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (_loading)
          const LinearProgressIndicator(minHeight: 3)
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.fillSubtle,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.colors.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request?.brokerName.isNotEmpty == true
                      ? request!.brokerName
                      : widget.truck.displayTitle,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request == null
                      ? 'Live updates will appear here.'
                      : request.isCountered
                      ? 'Counter offer: ${request.amountText}'
                      : 'Current amount: ${request.amountText}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.dangerEmphasis,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (request?.isActionableByClient == true) ...[
          const SizedBox(height: 16),
          _NegotiationActionButtons(
            acceptLabel: request!.isClientTurnToConfirm ? 'Confirm' : 'Accept',
            canCounter: request.isCountered,
            isBusy: _paymentSubmitting,
            onAccept: _acceptRequest,
            onCounter: _counterRequest,
            onReject: _rejectRequest,
          ),
        ] else ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: context.colors.fillSubtle,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: context.colors.line),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Waiting for a live counter offer...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: context.colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildComposeView() {
    return _NegotiationSliderStep(
      truck: widget.truck,
      value: _value,
      minPrice: widget.minPrice,
      maxPrice: widget.maxPrice,
      onChanged: (value) {
        setState(() {
          _value = value;
        });
      },
      onNegotiate: _sendOffer,
      isBusy: _submitting,
      errorMessage: _errorMessage,
    );
  }

  Widget _buildPaymentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose payment',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick how this freight booking should be settled. Advance uses the latest admin-configured amount.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Razorpay checkout will show the available payment methods before you pay.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
        ),
        const SizedBox(height: 16),
        _CheckoutChoiceCard(
          selectedMethod: _selectedPaymentMethod,
          advanceAmount: _advanceAmount,
          loadingAdvanceAmount: _loadingAdvanceAmount,
          allowToBeBilled: _bookingId?.isNotEmpty == true,
          onSelect: (method) {
            setState(() => _selectedPaymentMethod = method);
          },
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _paymentSubmitting ? null : _recordPayment,
            child: _paymentSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _selectedPaymentMethod == PaymentMethod.toBeBilled ||
                            _selectedPaymentMethod == PaymentMethod.payLater
                        ? 'Confirm payment stage'
                        : 'Continue to secure checkout',
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadAdvanceAmount() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _bookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) return;

    setState(() => _loadingAdvanceAmount = true);
    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingAdvanceAmount(
            accessToken: session.tokens.accessToken,
            id: bookingId,
          );
      if (!mounted) return;
      setState(() {
        _advanceAmount = _extractAdvanceAmount(response);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _advanceAmount = null;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingAdvanceAmount = false);
      }
    }
  }

  Widget _buildConfirmedView() {
    return _BookingSuccessCard(
      bookingReference: _bookingNumber,
      onTrack: widget.onTrack,
      onHome: widget.onHome,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.62,
      minChildSize: 0.42,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.colors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                switch (_stage) {
                  _DirectNegotiationStage.compose => _buildComposeView(),
                  _DirectNegotiationStage.waiting => _buildWaitingView(),
                  _DirectNegotiationStage.payment => _buildPaymentView(),
                  _DirectNegotiationStage.confirmed => _buildConfirmedView(),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FindTruckNegotiationSheet extends ConsumerStatefulWidget {
  const _FindTruckNegotiationSheet({
    required this.bookingId,
    required this.bookingNumber,
    required this.accessToken,
    required this.initialRequest,
    required this.askingPrice,
  });

  final String bookingId;
  final String? bookingNumber;
  final String accessToken;
  final ClientBookingOffer initialRequest;
  final double askingPrice;

  @override
  ConsumerState<_FindTruckNegotiationSheet> createState() =>
      _FindTruckNegotiationSheetState();
}

class _FindTruckNegotiationSheetState
    extends ConsumerState<_FindTruckNegotiationSheet> {
  static const Duration _refreshInterval = Duration(seconds: 4);

  late ClientBookingOffer _request;
  bool _busy = false;
  bool _loading = false;
  String? _errorMessage;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;

  @override
  void initState() {
    super.initState();
    _request = widget.initialRequest;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_request.normalizedStatus == 'accepted') {
          Navigator.of(context).pop(_FindTruckNegotiationResult.payment);
          return;
        }
        unawaited(_startLiveUpdates());
        unawaited(_loadRequest(silent: true));
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _driverRequestSubscription?.cancel();
    super.dispose();
  }

  Future<void> _startLiveUpdates() async {
    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(accessToken: widget.accessToken);

    await _driverRequestSubscription?.cancel();
    _driverRequestSubscription = socketService.driverRequestStream.listen((
      payload,
    ) {
      final payloadMap = _payloadAsMapLoose(payload);
      if (payloadMap == null) {
        return;
      }

      final payloadBookingId = _readString(payloadMap, const [
        'bookingId',
        'booking_id',
      ]);
      final payloadRequestId = _readString(payloadMap, const [
        'id',
        'request_id',
        'driver_request_id',
      ]);
      if (payloadBookingId == widget.bookingId ||
          payloadRequestId == _request.id) {
        unawaited(_loadRequest(silent: true));
      }
    });

    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_refreshInterval, (_) {
      if (mounted) {
        unawaited(_loadRequest(silent: true));
      }
    });
  }

  Future<void> _loadRequest({required bool silent}) async {
    if (_request.id.isEmpty) {
      return;
    }

    try {
      if (!silent) {
        setState(() {
          _loading = true;
          _errorMessage = null;
        });
      }

      final response = await ref
          .read(apiClientProvider)
          .getDriverRequestById(
            accessToken: widget.accessToken,
            id: _request.id,
          );
      final request = _extractDriverRequest(response);
      if (!mounted || request == null) {
        return;
      }
      setState(() {
        _request = request;
      });
      if (request.normalizedStatus == 'accepted') {
        Navigator.of(context).pop(_FindTruckNegotiationResult.payment);
      }
    } catch (_) {
      if (!mounted || silent) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not refresh the live driver offer.';
      });
    } finally {
      if (mounted && !silent) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _acceptRequest() async {
    if (_busy || _request.id.isEmpty) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .acceptDriverRequest(
            accessToken: widget.accessToken,
            id: _request.id,
          );
      if (!mounted) {
        return;
      }

      final request = _extractDriverRequest(response);
      if (request != null) {
        _request = request;
      }

      final data = _payloadAsMapLoose(response['data']);
      final booking = _payloadAsMapLoose(data?['booking']);
      final accepted =
          booking != null || _request.normalizedStatus == 'accepted';
      if (accepted) {
        Navigator.of(context).pop(_FindTruckNegotiationResult.payment);
        return;
      }

      await _loadRequest(silent: false);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _rejectRequest() async {
    if (_busy || _request.id.isEmpty) {
      return;
    }

    setState(() {
      _busy = true;
      _errorMessage = null;
    });

    try {
      await ref
          .read(apiClientProvider)
          .rejectDriverRequest(
            accessToken: widget.accessToken,
            id: _request.id,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(_FindTruckNegotiationResult.dismissed);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _counterRequest() async {
    if (_busy || _request.id.isEmpty) {
      return;
    }

    try {
      final initialAmount = _request.amountText.isNotEmpty
          ? _parsePrice(_request.amountText)
          : widget.askingPrice;
      final amount = await showDialog<double>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.45),
        builder: (dialogContext) =>
            _CounterOfferSliderDialog(initialAmount: initialAmount),
      );
      if (amount == null) {
        return;
      }

      if (amount <= 0) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
        return;
      }

      setState(() {
        _busy = true;
        _errorMessage = null;
      });
      await ref
          .read(apiClientProvider)
          .counterDriverRequest(
            accessToken: widget.accessToken,
            id: _request.id,
            amount: amount,
          );
      if (mounted) {
        await _loadRequest(silent: false);
      }
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = _request;
    final driverName = request.brokerName.isNotEmpty
        ? request.brokerName
        : 'Driver';
    final offerAmountText = request.amountText.isNotEmpty
        ? request.amountText
        : _formatRupees(widget.askingPrice);
    final title = request.normalizedStatus == 'accepted'
        ? 'Driver accepted the request'
        : request.isClientTurnToConfirm
        ? 'Driver accepted - confirm now'
        : request.isWaitingForCounterpartyConfirmation
        ? 'Waiting for driver confirmation'
        : request.isCountered
        ? 'Counter offer received'
        : 'Driver response received';
    final body = request.isClientTurnToConfirm
        ? 'The driver has committed to this booking. Confirm or decline to finish.'
        : request.isWaitingForCounterpartyConfirmation
        ? 'You accepted this offer. We are waiting for the driver to complete the handshake.'
        : request.isCountered
        ? 'Review the live counter offer and respond.'
        : 'This request is updating live from the driver side.';
    final canAct = request.isActionableByClient;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
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
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            body,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: context.colors.textSecondary,
                                  height: 1.35,
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.of(
                              context,
                            ).pop(_FindTruckNegotiationResult.dismissed),
                      icon: Icon(AppIcons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.fillSubtle,
                        foregroundColor: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: context.colors.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: context.colors.brandFill,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          AppIcons.local_shipping_rounded,
                          color: Color(0xFF2FA56E),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              driverName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (request.isCountered) ...[
                              const SizedBox(height: 3),
                              Text(
                                'Counter offer: $offerAmountText',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: const Color(0xFF2FA56E),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_loading) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(minHeight: 3),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.dangerEmphasis,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (canAct)
                  _NegotiationActionButtons(
                    acceptLabel: request.isClientTurnToConfirm
                        ? 'Confirm'
                        : 'Accept',
                    canCounter: request.isCountered,
                    isBusy: _busy,
                    onAccept: _acceptRequest,
                    onCounter: _counterRequest,
                    onReject: _rejectRequest,
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.colors.fillSubtle,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: context.colors.line),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Waiting for the next driver update...',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: context.colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
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

class _NegotiationSliderStep extends StatelessWidget {
  const _NegotiationSliderStep({
    required this.truck,
    required this.value,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
    required this.onNegotiate,
    required this.isBusy,
    required this.errorMessage,
  });

  final NearbyTruck truck;
  final double value;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<double> onChanged;
  final VoidCallback onNegotiate;
  final bool isBusy;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.roundToDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review price for ${truck.displayTitle}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: context.colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use the slider to set the amount you want to continue with.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: context.colors.textSecondary,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: context.colors.fillSubtle,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Offer price',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '₹${displayValue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Slider(
                value: value.clamp(minPrice, maxPrice),
                min: minPrice,
                max: maxPrice,
                divisions: 24,
                activeColor: const Color(0xFF2FA56E),
                inactiveColor: context.colors.line,
                label: '₹${displayValue.toStringAsFixed(0)}',
                onChanged: onChanged,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${minPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                  Text(
                    '₹${maxPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: context.colors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isBusy ? null : onNegotiate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2FA56E),
            ),
            child: isBusy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Continue with this price'),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.dangerEmphasis,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _CounterOfferSliderDialog extends StatefulWidget {
  const _CounterOfferSliderDialog({required this.initialAmount});

  final double initialAmount;

  @override
  State<_CounterOfferSliderDialog> createState() =>
      _CounterOfferSliderDialogState();
}

class _CounterOfferSliderDialogState extends State<_CounterOfferSliderDialog> {
  late final double _minAmount;
  late final double _maxAmount;
  late double _amount;

  @override
  void initState() {
    super.initState();
    final baseAmount = widget.initialAmount > 0 ? widget.initialAmount : 1000.0;
    _minAmount = max(1, baseAmount * 0.75).toDouble();
    _maxAmount = max(_minAmount + 100, baseAmount * 1.25).toDouble();
    _amount = baseAmount.clamp(_minAmount, _maxAmount).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surfaceElevated,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        AppIcons.swap_horiz_rounded,
                        color: Color(0xFF2FA56E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Counter offer',
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: context.colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Drag to set your price',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: context.colors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(AppIcons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: context.colors.fillSubtle,
                        foregroundColor: context.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.fillSubtle,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: context.colors.line),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatRupees(_amount),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: context.colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 7,
                          activeTrackColor: const Color(0xFF2FA56E),
                          inactiveTrackColor: context.colors.line,
                          thumbColor: Colors.white,
                          overlayColor: const Color(
                            0xFF2FA56E,
                          ).withValues(alpha: 0.14),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 13,
                            elevation: 4,
                            pressedElevation: 7,
                          ),
                        ),
                        child: Slider(
                          value: _amount,
                          min: _minAmount,
                          max: _maxAmount,
                          divisions: 100,
                          label: _formatRupees(_amount),
                          onChanged: (value) {
                            setState(() {
                              _amount = value;
                            });
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatRupees(_minAmount),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: context.colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Icon(
                              AppIcons.drag_indicator_rounded,
                              color: context.colors.textTertiary,
                              size: 18,
                            ),
                            Text(
                              _formatRupees(_maxAmount),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: context.colors.textTertiary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(_amount),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF2FA56E),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Send'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NegotiationActionButtons extends StatelessWidget {
  const _NegotiationActionButtons({
    required this.canCounter,
    required this.isBusy,
    required this.acceptLabel,
    required this.onAccept,
    required this.onCounter,
    required this.onReject,
  });

  final bool canCounter;
  final bool isBusy;
  final String acceptLabel;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    if (!canCounter) {
      return Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: isBusy ? null : onAccept,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: buttonShape,
              ),
              child: Text(acceptLabel),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: isBusy ? null : onReject,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE23A4B),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: buttonShape,
              ),
              child: const Text('Reject'),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isBusy ? null : onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2FA56E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
              shape: buttonShape,
            ),
            child: Text(acceptLabel),
          ),
        ),
        const SizedBox(height: 10),
        if (canCounter)
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: isBusy ? null : onReject,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFE23A4B),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                    shape: buttonShape,
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onCounter,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: buttonShape,
                  ),
                  child: const Text('Counter'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

// ignore: unused_element
