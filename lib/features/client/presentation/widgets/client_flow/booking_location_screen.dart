part of '../client_flow_widgets.dart';

class BookingLocationScreen extends ConsumerStatefulWidget {
  const BookingLocationScreen({
    super.key,
    required this.tripType,
    this.initialVehicleIndex = 0,
    this.initialBookingData,
    this.skipLocationStep = false,
    this.autoOpenLocationFlow = false,
  });

  final TripType tripType;
  final int initialVehicleIndex;
  final BookingData? initialBookingData;
  final bool skipLocationStep;
  final bool autoOpenLocationFlow;

  @override
  ConsumerState<BookingLocationScreen> createState() =>
      _BookingLocationScreenState();
}

enum _BookingFlowStep {
  location,
  itemDetails,
  brokerSelection,
  payment,
  waiting,
}

enum _TruckAction { continueBooking, negotiate }

enum BookingSearchMode { truck, broker }

class _EligibleBroker {
  const _EligibleBroker({
    required this.id,
    required this.name,
    required this.phone,
    required this.serviceCity,
    required this.isOnline,
    required this.truckCount,
  });

  factory _EligibleBroker.fromJson(Map<String, dynamic> json) {
    return _EligibleBroker(
      id: _readString(json, const ['id', 'broker_id', 'uuid']),
      name: _readString(json, const [
        'name',
        'broker_name',
        'displayName',
      ]).ifEmpty('Broker'),
      phone: _readString(json, const ['phone', 'mobile', 'phone_number']),
      serviceCity: _readString(json, const [
        'serviceCity',
        'service_city',
        'city',
      ]),
      isOnline: _readBool(json['isOnline'] ?? json['is_online']),
      truckCount: _readIntLoose(json['truckCount'] ?? json['truck_count']),
    );
  }

  final String id;
  final String name;
  final String phone;
  final String serviceCity;
  final bool isOnline;
  final int truckCount;
}

extension _EmptyStringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

bool _readBool(Object? value) {
  if (value is bool) return value;
  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

int _readIntLoose(Object? value) {
  if (value is num) return value.round();
  return int.tryParse(value?.toString().trim() ?? '') ?? 0;
}

double _readNumberLoose(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '') ?? 0;
}

double? _readOptionalNumberLoose(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().trim() ?? '');
}

double? _extractAdvanceAmount(Map<String, dynamic> response) {
  final data = _payloadAsMapLoose(response['data']);
  return _readOptionalNumberLoose(data?['advanceAmount']) ??
      _readOptionalNumberLoose(data?['advance_amount']) ??
      _readOptionalNumberLoose(response['advanceAmount']) ??
      _readOptionalNumberLoose(response['advance_amount']);
}

class _BookingLocationScreenState extends ConsumerState<BookingLocationScreen> {
  static const LatLng _fallbackMapCenter = LatLng(19.0760, 72.8777);

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _weightController;
  late final TextEditingController _amountController;
  late VehicleOption _vehicle;
  GoogleMapController? _brokerMapController;
  CameraPosition? _brokerMapCameraPosition;
  late final StateController<bool> _bottomNavVisibleController;
  BitmapDescriptor? _truckMarkerIcon;
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropMarkerIcon;
  List<LatLng> _brokerRoutePoints = const [];
  int _brokerRouteRequestToken = 0;
  String? _brokerRouteKey;

  _BookingFlowStep _step = _BookingFlowStep.location;
  NearbyTruck? _selectedTruck;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.googlePay;
  bool _submitting = false;
  bool _resolvingDistance = false;
  bool _resolvingCurrentLocation = false;
  bool _bookingCreated = false;
  String? _bookingReference;
  ClientBookingOffer? _driverRequest;
  String? _activeBookingId;
  List<ClientBookingOffer> _findTruckRequests = const [];
  int _findTruckRequestCount = 0;
  int _findTruckDeclinedCount = 0;
  bool _findTruckNegotiationOpen = false;
  bool _cancellingFindTruckSearch = false;
  String? _findTruckActingId;
  bool _searchingFindTruckAgain = false;
  bool _findTruckOffersError = false;
  final DraggableScrollableController _truckSearchSheetController =
      DraggableScrollableController();
  double _truckSearchSheetExtent = 0.44;
  bool _postNegotiationPayment = false;
  bool _paymentCompletionVisible = false;
  bool _loadingAdvanceAmount = false;
  bool _loadingExpressQuote = false;
  double? _advanceAmount;
  bool _loadingEligibleBrokers = false;
  String? _eligibleBrokersError;
  List<_EligibleBroker> _eligibleBrokers = const [];
  String? _haltingNote;
  bool _weightUnknown = false;
  String? _weightError;
  late BookingData _draft;
  late int _vehicleIndex;
  bool _autoLocationFlowStarted = false;
  _MapPinTarget _mapPinTarget = _MapPinTarget.pickup;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSubscription;
  Timer? _findTruckPollTimer;
  Timer? _findTruckZoomTimer;
  StreamSubscription<Map<String, dynamic>>? _findTruckRequestSubscription;
  bool _locationStreamStarted = false;
  // Broker-mode negotiation (jobs/requests offers family, like the web
  // BrokerNegotiation flow). Separate from the driver-requests polling above
  // because broker counters live in offers, never in driver-requests.
  List<ClientBrokerOffer> _brokerOffers = const [];
  String? _brokerBookingStatus;
  String? _primaryBrokerOfferId;
  bool _brokerNegotiationOpen = false;
  Timer? _brokerOffersPollTimer;
  StreamSubscription<Map<String, dynamic>>? _brokerOfferSubscription;

  BookingData _freshBookingDraft() {
    return BookingData(
      from: '',
      to: '',
      tripType: widget.tripType,
      city: '',
      vehicle: _vehicle,
      scheduledDate: DateTime.now().add(const Duration(hours: 3)),
      amount: _priceValue(_vehicle.price),
      truckCategory: _truckCategoryForVehicle(_vehicle.label),
      searchMode: BookingSearchMode.truck,
    );
  }

  @override
  void initState() {
    super.initState();
    _bottomNavVisibleController = ref.read(bottomNavVisibleProvider.notifier);
    _bottomNavVisibleController.state = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadTruckMarkerIcon();
      }
    });
    _vehicleIndex = widget.initialVehicleIndex;
    final initialPricingState = ref.read(clientPricingProvider);
    final vehicles = resolveVehicleOptions(
      tripType: widget.tripType,
      pricing: initialPricingState.valueOrNull,
      isLoading: initialPricingState.isLoading,
    );
    _vehicleIndex = _vehicleIndex.clamp(0, vehicles.length - 1).toInt();
    _vehicle = vehicles[_vehicleIndex];
    final initialDraft = widget.initialBookingData;
    _draft = (initialDraft ?? _freshBookingDraft()).copyWith(
      tripType: initialDraft?.tripType ?? widget.tripType,
      vehicle: initialDraft?.vehicle ?? _vehicle,
      truckCategory: initialDraft?.truckCategory.isNotEmpty == true
          ? initialDraft!.truckCategory
          : _truckCategoryForVehicle(_vehicle.label),
      amount: initialDraft?.amount ?? _priceValue(_vehicle.price),
    );
    _fromController = TextEditingController(text: _draft.from);
    _toController = TextEditingController(text: _draft.to);
    _weightController = TextEditingController(
      text: _draft.weight > 0 ? _draft.weight.toString() : '',
    );
    _amountController = TextEditingController(
      text: _draft.amount > 0
          ? _priceInputText(_draft.amount.toString())
          : _priceInputText(_vehicle.price),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _step == _BookingFlowStep.location) {
        unawaited(_startLocationStream());
      }
    });
    if (widget.skipLocationStep) {
      _step = _BookingFlowStep.itemDetails;
    }

    if (widget.autoOpenLocationFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _runAutoLocationFlow();
        }
      });
    }
  }

  @override
  void dispose() {
    _bottomNavVisibleController.state = true;
    _positionSubscription?.cancel();
    _findTruckPollTimer?.cancel();
    _findTruckZoomTimer?.cancel();
    _findTruckRequestSubscription?.cancel();
    _brokerOffersPollTimer?.cancel();
    _brokerOfferSubscription?.cancel();
    _brokerMapController?.dispose();
    _truckSearchSheetController.dispose();
    _fromController.dispose();
    _toController.dispose();
    _weightController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _startLocationStream() async {
    if (_locationStreamStarted || !mounted) {
      return;
    }

    // Fast path: seed the map instantly from the login-prefetched fix so
    // the user never stares at a loading state.
    final cached = ref.read(userLocationProvider).valueOrNull;
    if (cached != null &&
        cached.isFresh &&
        mounted &&
        _step == _BookingFlowStep.location &&
        _currentPosition == null) {
      setState(() {
        _currentPosition = Position(
          latitude: cached.latitude,
          longitude: cached.longitude,
          timestamp: cached.fetchedAt,
          accuracy: cached.accuracy ?? 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        !mounted) {
      return;
    }

    _locationStreamStarted = true;
    _positionSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((position) {
          if (!mounted || _step != _BookingFlowStep.location) {
            return;
          }
          setState(() {
            _currentPosition = position;
          });
        });

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted && _step == _BookingFlowStep.location) {
        setState(() {
          _currentPosition = position;
        });
      }
      final previousAddress =
          ref.read(userLocationProvider).valueOrNull?.address ?? '';
      ref
          .read(userLocationProvider.notifier)
          .cache(
            latitude: position.latitude,
            longitude: position.longitude,
            address: previousAddress,
            accuracy: position.accuracy,
          );
    } catch (_) {
      // The stream can still provide a position after the initial lookup fails.
    }
  }

  void _stopLocationStream() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _locationStreamStarted = false;
  }

  Future<void> _handleBookingMapTap(LatLng point) async {
    if (_resolvingCurrentLocation) {
      return;
    }

    setState(() {
      _resolvingCurrentLocation = true;
    });
    try {
      final address = await ref
          .read(googlePlacesServiceProvider)
          .reverseGeocode(latitude: point.latitude, longitude: point.longitude);
      if (!mounted) return;
      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resolve this map point.')),
        );
        return;
      }

      setState(() {
        if (_mapPinTarget == _MapPinTarget.pickup) {
          _draft = _draft.copyWith(
            from: address,
            pickupLat: point.latitude,
            pickupLng: point.longitude,
            city: _deriveCityFromLocation(address, ''),
          );
          _fromController.text = address;
          _mapPinTarget = _MapPinTarget.drop;
        } else {
          _draft = _draft.copyWith(
            to: address,
            dropLat: point.latitude,
            dropLng: point.longitude,
          );
          _toController.text = address;
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingCurrentLocation = false;
        });
      }
    }
  }

  Set<Marker> _buildLocationMapMarkers() {
    final markers = <Marker>{};
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final current = _currentPosition;
    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('booking-pickup'),
          position: pickup,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }
    for (var index = 0; index < _draft.loadingStops.length; index++) {
      final stop = _draft.loadingStops[index];
      markers.add(
        Marker(
          markerId: MarkerId('booking-loading-$index'),
          position: stop.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueYellow,
          ),
          infoWindow: InfoWindow(title: 'Loading point ${index + 1}'),
        ),
      );
    }
    for (var index = 0; index < _draft.unloadingStops.length; index++) {
      final stop = _draft.unloadingStops[index];
      markers.add(
        Marker(
          markerId: MarkerId('booking-unloading-$index'),
          position: stop.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: 'Unloading point ${index + 1}'),
        ),
      );
    }
    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('booking-drop'),
          position: drop,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Drop-off'),
        ),
      );
    }
    if (current != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('booking-current-location'),
          position: LatLng(current.latitude, current.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    }
    return markers;
  }

  Widget _buildLocationMap(BuildContext context) {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final current = _currentPosition;
    final target =
        pickup ??
        drop ??
        (current == null
            ? _fallbackMapCenter
            : LatLng(current.latitude, current.longitude));
    final distance = _routeDistanceKm(_bookingRoutePoints());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Tap map to set'),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Pickup'),
              selected: _mapPinTarget == _MapPinTarget.pickup,
              onSelected: (_) => setState(() {
                _mapPinTarget = _MapPinTarget.pickup;
              }),
            ),
            const SizedBox(width: 6),
            ChoiceChip(
              label: const Text('Drop-off'),
              selected: _mapPinTarget == _MapPinTarget.drop,
              onSelected: (_) => setState(() {
                _mapPinTarget = _MapPinTarget.drop;
              }),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 220,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: GoogleMap(
              style: ClientMapTheme.styleFor(context),
              initialCameraPosition: CameraPosition(target: target, zoom: 10.5),
              markers: _buildLocationMapMarkers(),
              myLocationEnabled: _locationStreamStarted,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onTap: _handleBookingMapTap,
            ),
          ),
        ),
        if (distance != null) ...[
          const SizedBox(height: 8),
          Text(
            'Estimated route distance: ${distance.toStringAsFixed(distance < 10 ? 1 : 0)} km',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _loadTruckMarkerIcon() async {
    try {
      final truck = await loadTruckMarkerIcon();
      final pickup = await _buildDotMarkerIcon(const Color(0xFF22C55E));
      final drop = await _buildDotMarkerIcon(const Color(0xFFEF4444));
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = truck;
        _pickupMarkerIcon = pickup;
        _dropMarkerIcon = drop;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
        _pickupMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        );
        _dropMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        );
      });
    }
  }

  Future<void> _refreshBrokerRoute() async {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final token = ++_brokerRouteRequestToken;
    if (pickup == null || drop == null) {
      if (mounted) {
        setState(() {
          _brokerRoutePoints = const [];
        });
      }
      return;
    }
    try {
      final service = ref.read(googlePlacesServiceProvider);
      final route = await service.fetchDrivingRoute(
        originLatitude: pickup.latitude,
        originLongitude: pickup.longitude,
        destinationLatitude: drop.latitude,
        destinationLongitude: drop.longitude,
        waypoints: [
          ..._draft.loadingStops.map((stop) => stop.latLng),
          ..._draft.unloadingStops.map((stop) => stop.latLng),
        ],
      );
      if (!mounted || token != _brokerRouteRequestToken) {
        return;
      }
      setState(() {
        _brokerRoutePoints = route;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBrokerCamera());
    } catch (_) {
      if (!mounted || token != _brokerRouteRequestToken) {
        return;
      }
      setState(() {
        _brokerRoutePoints = const [];
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitBrokerCamera());
    }
  }

  void _scheduleBrokerRouteRefresh() {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    if (pickup == null || drop == null) {
      return;
    }

    final routeKey = _bookingRoutePoints()
        .map((point) => '${point.latitude},${point.longitude}')
        .join('|');
    if (_brokerRouteKey == routeKey) {
      return;
    }

    _brokerRouteKey = routeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshBrokerRoute();
      }
    });
  }

  Future<GooglePlaceSelection?> _openLocationDetailsScreen(
    _LocationFieldKind kind,
  ) async {
    final initialValue = kind == _LocationFieldKind.pickup
        ? _fromController.text
        : _toController.text;

    return Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        builder: (context) =>
            _LocationDetailsScreen(kind: kind, initialValue: initialValue),
      ),
    );
  }

  Future<void> _addIntermediateStop({required bool loading}) async {
    final selection = await Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        builder: (context) => _IntermediateStopDetailsScreen(loading: loading),
      ),
    );
    if (selection == null || !mounted) {
      return;
    }
    final lat = selection.latitude;
    final lng = selection.longitude;
    if (lat == null || lng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loading
                ? 'Choose a loading point from suggestions so we can pin it.'
                : 'Choose an unloading point from suggestions so we can pin it.',
          ),
        ),
      );
      return;
    }

    final stop = BookingStop(
      location: selection.formattedAddress,
      lat: lat,
      lng: lng,
    );
    setState(() {
      _draft = loading
          ? _draft.copyWith(loadingStops: [..._draft.loadingStops, stop])
          : _draft.copyWith(unloadingStops: [..._draft.unloadingStops, stop]);
    });
    _scheduleBrokerRouteRefresh();
  }

  void _removeIntermediateStop({required bool loading, required int index}) {
    setState(() {
      final updated = [
        ...(loading ? _draft.loadingStops : _draft.unloadingStops),
      ]..removeAt(index);
      _draft = loading
          ? _draft.copyWith(loadingStops: updated)
          : _draft.copyWith(unloadingStops: updated);
    });
    _scheduleBrokerRouteRefresh();
  }

  Future<void> _runAutoLocationFlow() async {
    if (_autoLocationFlowStarted || !mounted) {
      return;
    }
    _autoLocationFlowStarted = true;

    final pickup = await _openLocationDetailsScreen(_LocationFieldKind.pickup);
    if (pickup == null || !mounted) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        from: pickup.formattedAddress,
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        city: pickup.city.isNotEmpty ? pickup.city : _draft.city,
      );
      _fromController.text = pickup.formattedAddress;
    });

    final drop = await _openLocationDetailsScreen(_LocationFieldKind.drop);
    if (drop == null || !mounted) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        to: drop.formattedAddress,
        dropLat: drop.latitude,
        dropLng: drop.longitude,
      );
      _toController.text = drop.formattedAddress;
    });

    if (mounted) {
      await _resolveDistanceAndContinue();
    }
  }

  Future<BitmapDescriptor> _buildDotMarkerIcon(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 56.0;
    final center = const Offset(size / 2, size / 2);
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 2), 13, shadowPaint);

    final outer = Paint()..color = Colors.white;
    final inner = Paint()..color = color;
    canvas.drawCircle(center, 13, outer);
    canvas.drawCircle(center, 8.5, inner);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to build marker icon');
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<void> _advanceFromWeightStep({required bool unknown}) async {
    final rawWeight = _weightController.text.trim();
    final parsedWeight = double.tryParse(rawWeight);

    if (!unknown && (parsedWeight == null || parsedWeight <= 0)) {
      setState(() {
        _weightUnknown = false;
        _weightError = 'Enter weight';
      });
      return;
    }

    setState(() {
      _weightUnknown = unknown;
      _weightError = null;
      _draft = _draft.copyWith(
        weight: unknown ? 0 : parsedWeight ?? 0,
        quantity: 1,
        material: '',
        additionalNotes: '',
      );
      _selectedTruck = null;
      _step = _BookingFlowStep.brokerSelection;
    });
    unawaited(_loadEligibleBrokers());
  }

  Future<void> _pickScheduledDateTime() async {
    final now = DateTime.now();
    final current =
        _draft.scheduledDate != null && _draft.scheduledDate!.isAfter(now)
        ? _draft.scheduledDate!
        : now.add(const Duration(hours: 3));
    final scheduled = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => _SchedulePickerSheet(
        initialDateTime: current,
        firstDateTime: now,
        lastDateTime: now.add(const Duration(days: 180)),
      ),
    );
    if (scheduled == null || !mounted) return;

    if (!scheduled.isAfter(now)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future pickup time.')),
      );
      return;
    }
    setState(() {
      _draft = _draft.copyWith(isScheduled: true, scheduledDate: scheduled);
    });
  }

  Future<void> _loadEligibleBrokers() async {
    if (_loadingEligibleBrokers) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() {
      _loadingEligibleBrokers = true;
      _eligibleBrokersError = null;
    });
    try {
      final response = await ref
          .read(apiClientProvider)
          .getEligibleBrokers(
            accessToken: session.tokens.accessToken,
            city: _draft.city,
          );
      final brokers = _eligibleBrokersFromResponse(response);
      if (!mounted) return;
      setState(() {
        _eligibleBrokers = brokers;
        _loadingEligibleBrokers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadingEligibleBrokers = false;
        _eligibleBrokersError = error.toString().replaceFirst(
          'ApiException: ',
          '',
        );
      });
    }
  }

  List<_EligibleBroker> _eligibleBrokersFromResponse(
    Map<String, dynamic> response,
  ) {
    Object? source = response['brokers'];
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      source = data['brokers'] ?? data['items'] ?? data['data'] ?? source;
    }
    if (source is! List) return const [];
    return source
        .whereType<Map<String, dynamic>>()
        .map(_EligibleBroker.fromJson)
        .where((broker) => broker.id.isNotEmpty)
        .toList(growable: false);
  }

  void _selectVehicleForSearchStep(int index) {
    final vehicles = resolveVehicleOptions(
      tripType: widget.tripType,
      pricing: ref.read(clientPricingProvider).valueOrNull,
      isLoading: ref.read(clientPricingProvider).isLoading,
    );
    if (vehicles.isEmpty) return;
    final safeIndex = index.clamp(0, vehicles.length - 1).toInt();
    final vehicle = vehicles[safeIndex];
    setState(() {
      _vehicleIndex = safeIndex;
      _vehicle = vehicle;
      _draft = _draft.copyWith(
        vehicle: vehicle,
        truckCategory: _truckCategoryForVehicle(vehicle.label),
        amount: _priceValue(vehicle.price),
        expressSurcharge: 0,
        expressInsuranceIncluded: false,
      );
      _amountController.text = _priceInputText(vehicle.price);
      _selectedTruck = null;
    });
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session != null && _draft.distance > 0) {
      unawaited(
        _estimateBookingAmount(
          accessToken: session.tokens.accessToken,
          distance: _draft.distance,
          durationMin: _draft.durationMin,
          durationInTrafficMin: _draft.durationInTrafficMin,
        ).then((amount) {
          if (!mounted || amount == null || amount <= 0) return;
          _amountController.text = _priceInputText(amount.toString());
        }),
      );
    }
  }

  void _animateTruckSearchSheetTo(double extent) {
    if (!_truckSearchSheetController.isAttached) {
      return;
    }
    unawaited(
      _truckSearchSheetController.animateTo(
        extent,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  void _continueWithSearchMode() {
    final mode = _draft.searchMode ?? BookingSearchMode.truck;
    if (mode == BookingSearchMode.broker &&
        _draft.selectedBrokerId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a broker to continue.')),
      );
      return;
    }
    if (mode == BookingSearchMode.broker) {
      // Like the web app: choosing a broker only targets the negotiation.
      // Create the booking for that broker and negotiate first — payment
      // comes only after mutual confirmation, never straight from here.
      unawaited(_startBrokerSearch());
      return;
    }
    setState(() {
      _draft = _draft.copyWith(searchMode: mode);
      _step = _BookingFlowStep.payment;
    });
  }

  /// Broker-mode counterpart of [_startFindTruckSearch]: creates the booking
  /// targeted at the selected broker, then enters the same live-update /
  /// offer-poll / negotiation loop. Payment happens only when negotiation
  /// resolves with the payment outcome.
  Future<void> _startBrokerSearch() async {
    if (_submitting) {
      return;
    }
    if (_bookingCreated) {
      if (!_postNegotiationPayment) {
        return;
      }
      _resetUnpaidPaymentBookingForRetry(searchMode: BookingSearchMode.broker);
    }
    if (!_validateScheduledDate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to create a booking.'),
        ),
      );
      return;
    }
    if (_draft.selectedBrokerId.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a broker to continue.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _driverRequest = null;
      _findTruckRequests = const [];
      _findTruckRequestCount = 0;
      _findTruckDeclinedCount = 0;
      _paymentCompletionVisible = false;
      _draft = _draft.copyWith(searchMode: BookingSearchMode.broker);
    });
    _startFindTruckZoomOutLoop();

    try {
      final hasCoordinates = await _ensureFindTruckCoordinates();
      if (!hasCoordinates) {
        if (!mounted) {
          return;
        }
        setState(() {
          _submitting = false;
        });
        return;
      }

      final bookingPayload = _bookingPayload();
      debugPrint(
        'SSK.ClientBooking BrokerSearch payload '
        'search_mode=${bookingPayload['search_mode']} '
        'broker_id=${bookingPayload['broker_id']} '
        'pickup_lat=${bookingPayload['pickup_lat']} '
        'pickup_lng=${bookingPayload['pickup_lng']} '
        'drop_lat=${bookingPayload['drop_lat']} '
        'drop_lng=${bookingPayload['drop_lng']}',
      );

      final response = await ref
          .read(apiClientProvider)
          .createBooking(
            accessToken: session.tokens.accessToken,
            booking: bookingPayload,
            idempotencyKey: _buildIdempotencyKey(),
          );
      final bookingNumber = _extractBookingNumber(response);
      final bookingId = _extractBookingId(response);
      final resolvedBookingNumber = bookingNumber.isNotEmpty
          ? bookingNumber
          : await _fetchLatestBookingNumber(session.tokens.accessToken);

      if (!mounted) {
        return;
      }

      setState(() {
        _submitting = false;
        _bookingCreated = true;
        _bookingReference = resolvedBookingNumber;
        _activeBookingId = bookingId.isNotEmpty ? bookingId : _activeBookingId;
        _postNegotiationPayment = false;
        _brokerOffers = const [];
        _brokerBookingStatus = null;
        _primaryBrokerOfferId = null;
        _brokerNegotiationOpen = false;
        _step = _BookingFlowStep.brokerSelection;
      });
      _startFindTruckZoomOutLoop();

      await _startFindTruckLiveUpdates(session.tokens.accessToken);
      await _startBrokerOfferUpdates(session.tokens.accessToken);
      await _loadBrokerOffers(silent: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _stopFindTruckZoomOutLoop();
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  Future<void> _startFindTruckSearch() async {
    if (_submitting) {
      return;
    }
    if (_bookingCreated) {
      if (!_postNegotiationPayment) {
        return;
      }
      _resetUnpaidPaymentBookingForRetry(searchMode: BookingSearchMode.truck);
    }
    if (!_validateScheduledDate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to create a booking.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
      _driverRequest = null;
      _findTruckRequests = const [];
      _findTruckRequestCount = 0;
      _findTruckDeclinedCount = 0;
      _paymentCompletionVisible = false;
      _draft = _draft.copyWith(
        searchMode: BookingSearchMode.truck,
        selectedBrokerId: '',
      );
    });
    _startFindTruckZoomOutLoop();

    try {
      final hasCoordinates = await _ensureFindTruckCoordinates();
      if (!hasCoordinates) {
        if (!mounted) {
          return;
        }
        setState(() {
          _submitting = false;
        });
        return;
      }

      final bookingPayload = _bookingPayload();
      debugPrint(
        'SSK.ClientBooking FindTruck payload '
        'search_mode=${bookingPayload['search_mode']} '
        'broker_id=${bookingPayload['broker_id']} '
        'search_radius_km=${bookingPayload['search_radius_km']} '
        'pickup_lat=${bookingPayload['pickup_lat']} '
        'pickup_lng=${bookingPayload['pickup_lng']} '
        'drop_lat=${bookingPayload['drop_lat']} '
        'drop_lng=${bookingPayload['drop_lng']}',
      );

      final response = await ref
          .read(apiClientProvider)
          .createBooking(
            accessToken: session.tokens.accessToken,
            booking: bookingPayload,
            idempotencyKey: _buildIdempotencyKey(),
          );
      final bookingNumber = _extractBookingNumber(response);
      final bookingId = _extractBookingId(response);
      final resolvedBookingNumber = bookingNumber.isNotEmpty
          ? bookingNumber
          : await _fetchLatestBookingNumber(session.tokens.accessToken);

      if (!mounted) {
        return;
      }

      setState(() {
        _submitting = false;
        _bookingCreated = true;
        _bookingReference = resolvedBookingNumber;
        _activeBookingId = bookingId.isNotEmpty ? bookingId : _activeBookingId;
        _postNegotiationPayment = false;
        _step = _BookingFlowStep.brokerSelection;
      });
      _startFindTruckZoomOutLoop();

      await _startFindTruckLiveUpdates(session.tokens.accessToken);
      await _loadFindTruckDriverRequests(silent: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _stopFindTruckZoomOutLoop();
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  bool get _isFindTruckSearchActive =>
      _bookingCreated &&
      !_postNegotiationPayment;

  void _resetUnpaidPaymentBookingForRetry({
    BookingSearchMode? searchMode,
    _BookingFlowStep? step,
  }) {
    _findTruckPollTimer?.cancel();
    _findTruckPollTimer = null;
    _stopFindTruckZoomOutLoop();
    unawaited(_findTruckRequestSubscription?.cancel() ?? Future<void>.value());
    _findTruckRequestSubscription = null;
    _stopBrokerOfferUpdates();

    setState(() {
      _bookingCreated = false;
      _bookingReference = null;
      _activeBookingId = null;
      _driverRequest = null;
      _findTruckRequests = const [];
      _findTruckRequestCount = 0;
      _findTruckDeclinedCount = 0;
      _findTruckNegotiationOpen = false;
      _brokerOffers = const [];
      _brokerBookingStatus = null;
      _primaryBrokerOfferId = null;
      _brokerNegotiationOpen = false;
      _postNegotiationPayment = false;
      _paymentCompletionVisible = false;
      _cancellingFindTruckSearch = false;
      _selectedTruck = null;
      _draft = _draft.copyWith(
        searchMode: searchMode ?? _draft.searchMode,
        selectedBrokerId: searchMode == BookingSearchMode.truck
            ? ''
            : _draft.selectedBrokerId,
      );
      if (step != null) {
        _step = step;
      }
    });
  }

  void _startFindTruckZoomOutLoop({bool initialFit = true}) {
    _findTruckZoomTimer?.cancel();
    unawaited(_zoomOutForFindTruckSearch(initialFit: initialFit));
    _findTruckZoomTimer = Timer.periodic(const Duration(milliseconds: 1800), (
      _,
    ) {
      if (mounted) {
        unawaited(_zoomOutForFindTruckSearch());
      }
    });
  }

  void _stopFindTruckZoomOutLoop() {
    _findTruckZoomTimer?.cancel();
    _findTruckZoomTimer = null;
  }

  Future<void> _zoomOutForFindTruckSearch({bool initialFit = false}) async {
    if (_step == _BookingFlowStep.payment) {
      return;
    }
    final controller = _brokerMapController;
    if (controller == null) {
      return;
    }

    final bounds = _brokerRouteBounds();
    try {
      if (initialFit && bounds != null) {
        await controller.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 90),
        );
        await Future<void>.delayed(const Duration(milliseconds: 220));
      }
      await controller.animateCamera(CameraUpdate.zoomBy(-0.28));
    } catch (_) {
      // GoogleMap can reject camera updates while the platform view settles.
    }
  }

  Future<bool> _ensureFindTruckCoordinates() async {
    final hasPickup = _draft.pickupLat != null && _draft.pickupLng != null;
    final hasDrop = _draft.dropLat != null && _draft.dropLng != null;
    if (hasPickup && hasDrop) {
      return true;
    }

    final pickup = _fromController.text.trim();
    final drop = _toController.text.trim();
    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select pickup and drop locations on the map.'),
        ),
      );
      return false;
    }

    await _resolveTypedCoordinates(pickup: pickup, drop: drop);
    if (!mounted) {
      return false;
    }

    final resolvedPickup = _draft.pickupLat != null && _draft.pickupLng != null;
    final resolvedDrop = _draft.dropLat != null && _draft.dropLng != null;
    if (resolvedPickup && resolvedDrop) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not resolve exact pickup/drop coordinates. Please choose them from suggestions or the map.',
        ),
      ),
    );
    return false;
  }

  Future<void> _startFindTruckLiveUpdates(String accessToken) async {
    final bookingId = _activeBookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(accessToken: accessToken);

    await _findTruckRequestSubscription?.cancel();
    _findTruckRequestSubscription = socketService.driverRequestStream.listen((
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
      if (payloadBookingId == bookingId || payloadBookingId.isEmpty) {
        unawaited(_loadFindTruckDriverRequests(silent: true));
      }
    });

    _findTruckPollTimer?.cancel();
    _findTruckPollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        unawaited(_loadFindTruckDriverRequests(silent: true));
      }
    });
  }

  Future<void> _loadFindTruckDriverRequests({required bool silent}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getDriverRequestsForBooking(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );
      final requests = _driverRequestsFromResponse(response);
      // Web parity: only a fully accepted row promotes to the single-target
      // sheet. Everything else stays in the inline fan-out list.
      ClientBookingOffer? accepted;
      for (final request in requests) {
        if (request.normalizedStatus == 'accepted') {
          accepted = request;
          break;
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _findTruckRequestCount = requests.length;
        _findTruckRequests = requests;
        _findTruckOffersError = false;
        _findTruckDeclinedCount = requests
            .where((request) => request.normalizedStatus == 'declined')
            .length;
        if (accepted != null) {
          _driverRequest = accepted;
        }
      });

      if (accepted != null && _shouldOpenFindTruckNegotiation(accepted)) {
        _stopFindTruckZoomOutLoop();
        unawaited(_openFindTruckNegotiation(accepted));
      } else if (_isFindTruckSearchActive && _findTruckZoomTimer == null) {
        _startFindTruckZoomOutLoop(initialFit: false);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _findTruckOffersError = true);
      }
      if (!mounted || silent) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  /// Web parity (FindTruckSearch.jsx "Search Again"): re-notifies nearby
  /// drivers server-side, then refreshes so fresh 'pending' rows show up
  /// immediately instead of waiting for the next poll.
  Future<void> _rebroadcastFindTruckSearch() async {
    if (_searchingFindTruckAgain) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) return;
    setState(() {
      _searchingFindTruckAgain = true;
      _findTruckOffersError = false;
    });
    try {
      await ref
          .read(apiClientProvider)
          .rebroadcastBooking(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );
      await _loadFindTruckDriverRequests(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => _searchingFindTruckAgain = false);
    }
  }

  /// Broker-mode offer loop — mirrors the web BrokerNegotiation flow step by
  /// step: poll `GET /api/bookings/{id}/offers` every 4s plus live
  /// `job-request-updated` pushes, keep one sticky primary offer by rank,
  /// and open negotiation as soon as it is actionable by the client.
  /// Broker counters live in offers, never in driver-requests, which is why
  /// the driver-requests polling above can never see them.
  Future<void> _startBrokerOfferUpdates(String accessToken) async {
    final bookingId = _activeBookingId;
    if (bookingId == null || bookingId.isEmpty) {
      return;
    }

    final socketService = ref.read(appSocketServiceProvider);
    await socketService.ensureConnected(accessToken: accessToken);

    await _brokerOfferSubscription?.cancel();
    _brokerOfferSubscription = socketService.jobRequestStream.listen((payload) {
      final payloadMap = _payloadAsMapLoose(payload);
      if (payloadMap == null) {
        return;
      }
      final payloadBookingId = _readString(payloadMap, const [
        'bookingId',
        'booking_id',
      ]);
      final payloadOfferId = _readString(payloadMap, const [
        'id',
        'request_id',
      ]);
      if (payloadBookingId == bookingId ||
          payloadBookingId.isEmpty ||
          _brokerOffers.any((offer) => offer.id == payloadOfferId)) {
        unawaited(_loadBrokerOffers(silent: true));
      }
    });

    _brokerOffersPollTimer?.cancel();
    _brokerOffersPollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) {
        unawaited(_loadBrokerOffers(silent: true));
      }
    });
  }

  void _stopBrokerOfferUpdates() {
    _brokerOffersPollTimer?.cancel();
    _brokerOffersPollTimer = null;
    unawaited(_brokerOfferSubscription?.cancel() ?? Future<void>.value());
    _brokerOfferSubscription = null;
  }

  List<ClientBrokerOffer> _brokerOffersFromResponse(
    Map<String, dynamic> response,
  ) {
    final data = response['data'];
    final payload = data is Map<String, dynamic> ? data : response;
    final items =
        payload['offers'] ??
        payload['items'] ??
        payload['results'] ??
        payload['data'];
    final list = items is List ? items : const <dynamic>[];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClientBrokerOffer.fromJson)
        .where((offer) => offer.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadBrokerOffers({required bool silent}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getBookingOffers(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );
      final data = response['data'];
      final payload = data is Map<String, dynamic> ? data : response;
      final offers = _brokerOffersFromResponse(response);
      final bookingStatus = _readString(payload, const [
        'bookingStatus',
        'booking_status',
        'status',
      ]).trim().toLowerCase();

      if (!mounted) {
        return;
      }

      final primary = pickPrimaryBrokerOffer(offers, _primaryBrokerOfferId);
      setState(() {
        _brokerOffers = offers;
        if (bookingStatus.isNotEmpty) {
          _brokerBookingStatus = bookingStatus;
        }
        if (primary != null) {
          _primaryBrokerOfferId = primary.id;
        }
      });

      // Web parity: booking confirmed means a broker locked in — stop
      // watching and move to payment.
      if (_brokerBookingStatus == 'confirmed') {
        _stopBrokerOfferUpdates();
        _stopFindTruckZoomOutLoop();
        if (mounted && !_postNegotiationPayment) {
          setState(() {
            _postNegotiationPayment = true;
            _brokerOffers = const [];
          });
          unawaited(_loadAdvanceAmount());
          _goToPaymentAfterBrokerConfirm();
        }
        return;
      }

      if (primary != null &&
          !_brokerNegotiationOpen &&
          (primary.isCountered || primary.isYourTurnToConfirm)) {
        // Web parity: the sheet opens on broker action (counter / awaiting
        // your confirm) or your own tap — never on a plain pending offer
        // the broker hasn't touched yet.
        unawaited(_openBrokerOfferNegotiation(primary));
      }
    } catch (_) {
      // Silent polls stay silent; the loader keeps waiting for offers.
      if (!mounted || silent) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not load broker offers.')),
      );
    }
  }

  void _goToPaymentAfterBrokerConfirm() {
    if (!mounted || _step == _BookingFlowStep.payment) {
      return;
    }
    setState(() {
      _step = _BookingFlowStep.payment;
    });
  }

  Future<void> _openBrokerOfferNegotiation(ClientBrokerOffer offer) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }
    if (_brokerNegotiationOpen) {
      return;
    }
    _brokerNegotiationOpen = true;
    final outcome = await showDialog<_FindTruckNegotiationResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) => _BrokerOfferNegotiationSheet(
        bookingId: bookingId,
        bookingNumber: _bookingReference,
        accessToken: session.tokens.accessToken,
        initialOffer: offer,
        askingPrice: _draft.amount,
      ),
    );
    if (!mounted) {
      return;
    }
    _brokerNegotiationOpen = false;

    if (outcome == _FindTruckNegotiationResult.payment) {
      _stopBrokerOfferUpdates();
      _stopFindTruckZoomOutLoop();
      await _findTruckRequestSubscription?.cancel();
      setState(() {
        _postNegotiationPayment = true;
        _brokerOffers = const [];
        _step = _BookingFlowStep.payment;
      });
      unawaited(_loadAdvanceAmount());
      return;
    }

    // Dismissed: keep polling so a broker counter reopens negotiation.
    if (_bookingCreated && !_postNegotiationPayment) {
      unawaited(_loadBrokerOffers(silent: true));
    }
  }

  Future<void> _cancelFindTruckSearch() async {
    if (_cancellingFindTruckSearch) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;

    setState(() {
      _cancellingFindTruckSearch = true;
    });

    try {
      _findTruckPollTimer?.cancel();
      _stopFindTruckZoomOutLoop();
      await _findTruckRequestSubscription?.cancel();
      _findTruckRequestSubscription = null;
      _stopBrokerOfferUpdates();

      if (session != null && bookingId != null && bookingId.isNotEmpty) {
        final brokerMode =
            (_draft.searchMode ?? BookingSearchMode.truck) ==
            BookingSearchMode.broker;
        await ref
            .read(apiClientProvider)
            .cancelBooking(
              accessToken: session.tokens.accessToken,
              id: bookingId,
              reason: brokerMode
                  ? 'Broker search cancelled by client'
                  : 'No driver found within the search window',
            );
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _bookingCreated = false;
        _bookingReference = null;
        _activeBookingId = null;
        _driverRequest = null;
        _findTruckRequests = const [];
        _findTruckRequestCount = 0;
        _findTruckDeclinedCount = 0;
        _findTruckOffersError = false;
        _searchingFindTruckAgain = false;
        _findTruckNegotiationOpen = false;
        _postNegotiationPayment = false;
        _cancellingFindTruckSearch = false;
        _selectedTruck = null;
        _step = _BookingFlowStep.brokerSelection;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _animateTruckSearchSheetTo(0.58);
        }
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingFindTruckSearch = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _cancellingFindTruckSearch = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  /// Web parity (FindTruckSearch.jsx): the fan-out list stays on screen and
  /// each card negotiates inline. Only a fully `accepted` row promotes to the
  /// single-target sheet (which owns the confirmed/payment flow) — a mere
  /// counter/actionable row must NOT pop the dialog over the list.
  bool _shouldOpenFindTruckNegotiation(ClientBookingOffer request) {
    if (_findTruckNegotiationOpen) {
      return false;
    }
    return request.normalizedStatus == 'accepted';
  }

  Future<void> _openFindTruckNegotiation(ClientBookingOffer request) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    _findTruckNegotiationOpen = true;
    final outcome = await showDialog<_FindTruckNegotiationResult>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.46),
      builder: (context) => _FindTruckNegotiationSheet(
        bookingId: bookingId,
        bookingNumber: _bookingReference,
        accessToken: session.tokens.accessToken,
        initialRequest: request,
        askingPrice: _draft.amount,
      ),
    );
    if (!mounted) {
      return;
    }
    _findTruckNegotiationOpen = false;

    if (outcome == _FindTruckNegotiationResult.payment) {
      _findTruckPollTimer?.cancel();
      await _findTruckRequestSubscription?.cancel();
      setState(() {
        _postNegotiationPayment = true;
        _findTruckRequests = const [];
        _step = _BookingFlowStep.payment;
      });
      unawaited(_loadAdvanceAmount());
      return;
    }

    if (_isFindTruckSearchActive) {
      _startFindTruckZoomOutLoop(initialFit: false);
    }
    await _loadFindTruckDriverRequests(silent: true);
  }

  /// Inline fan-out card actions (web parity with DriverOfferCard): each live
  /// driver_requests row negotiates independently from the search overlay.
  Future<void> _acceptFindTruckRequest(ClientBookingOffer request) async {
    if (_findTruckActingId != null || !request.isActionableByClient) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _findTruckActingId = request.id);
    try {
      await ref
          .read(apiClientProvider)
          .acceptDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Accepted - waiting for the driver to confirm.'),
        ),
      );
      await _loadFindTruckDriverRequests(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _findTruckActingId = null);
    }
  }

  Future<void> _rejectFindTruckRequest(ClientBookingOffer request) async {
    if (_findTruckActingId != null || !request.isActionableByClient) {
      // Declining a pending (non-actionable) card is still valid — the web
      // card always offers Decline. Only gate on busy.
      if (_findTruckActingId != null) return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _findTruckActingId = request.id);
    try {
      await ref
          .read(apiClientProvider)
          .rejectDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Declined ${request.brokerName.isNotEmpty ? request.brokerName : 'driver'} — still waiting on the rest.',
          ),
        ),
      );
      await _loadFindTruckDriverRequests(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _findTruckActingId = null);
    }
  }

  Future<void> _counterFindTruckRequest(
    ClientBookingOffer request,
    double amount,
  ) async {
    if (_findTruckActingId != null) return;
    if (amount <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a valid amount.')));
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() => _findTruckActingId = request.id);
    try {
      await ref
          .read(apiClientProvider)
          .counterDriverRequest(
            accessToken: session.tokens.accessToken,
            id: request.id,
            amount: amount,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Counter sent.')));
      await _loadFindTruckDriverRequests(silent: true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) setState(() => _findTruckActingId = null);
    }
  }

  Future<void> _next() async {
    switch (_step) {
      case _BookingFlowStep.location:
        if (_toController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the drop location.')),
          );
          return;
        }
        await _resolveDistanceAndContinue();
        return;
      case _BookingFlowStep.itemDetails:
        await _advanceFromWeightStep(unknown: _weightUnknown);
        return;
      case _BookingFlowStep.brokerSelection:
        return;
      case _BookingFlowStep.payment:
        setState(() {
          _draft = _draft.copyWith(
            selectedPaymentLabel: _selectedPaymentMethod.label,
          );
        });
        if (_postNegotiationPayment) {
          await _payExistingBooking();
        } else {
          await _submitBooking();
        }
        return;
      case _BookingFlowStep.waiting:
        return;
    }
  }

  void _acceptSelectedBroker(NearbyTruck truck) {
    setState(() {
      _selectedTruck = truck;
      _draft = _draft.copyWith(
        brokerId: truck.id,
        amount: _draft.amount > 0 ? _draft.amount : _priceValue(_vehicle.price),
      );
    });
    unawaited(_openNegotiationSheet(truck));
  }

  Future<void> _openNegotiationSheet(NearbyTruck truck) async {
    final basePrice = _draft.amount > 0
        ? _draft.amount
        : _priceValue(_vehicle.price);
    final lower = basePrice * 0.84;
    final upper = basePrice * 1.08;
    final initial = _draft.amount > 0
        ? _draft.amount.clamp(lower, upper).toDouble()
        : basePrice.clamp(lower, upper).toDouble();

    final outcome = await showModalBottomSheet<_DirectNegotiationOutcome?>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BrokerNegotiationSheet(
        truck: truck,
        minPrice: lower,
        maxPrice: upper,
        initialPrice: initial,
        onTrack: () => _navigateAfterNegotiation('/client/tracking'),
        onHome: _navigateHomeAfterNegotiation,
        onCreateRequest: (amount) =>
            _createDirectTruckRequestSession(truckId: truck.id, amount: amount),
      ),
    );

    if (!mounted || outcome == null) {
      return;
    }

    if (!outcome.accepted) {
      _goToClientHome();
      return;
    }

    setState(() {
      _bookingReference = outcome.bookingNumber;
      _activeBookingId = outcome.bookingId.isNotEmpty
          ? outcome.bookingId
          : _activeBookingId;
      _bookingCreated = true;
      _postNegotiationPayment = true;
      if (outcome.amount != null && outcome.amount! > 0) {
        _draft = _draft.copyWith(amount: outcome.amount!);
      }
      _step = _BookingFlowStep.payment;
    });
  }

  void _navigateAfterNegotiation(String location) {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go(location);
      });
      return;
    }
    router.go(location);
  }

  void _navigateHomeAfterNegotiation() {
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      router.go('/client/home');
      return;
    }

    // Negotiation is opened above the booking sheet, so close both layers.
    navigator.pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigator.mounted && navigator.canPop()) {
        navigator.pop();
      }
      router.go('/client/home');
    });
  }

  Future<void> _handleTruckTap(NearbyTruck truck) async {
    if (_submitting || _bookingCreated) {
      return;
    }
    setState(() {
      _selectedTruck = truck;
    });

    final action = await _showTruckActionDialog(truck);
    if (!mounted || action == null) {
      return;
    }

    if (action == _TruckAction.continueBooking) {
      _acceptSelectedBroker(truck);
      return;
    }

    await _openNegotiationSheet(truck);
  }

  Future<_TruckAction?> _showTruckActionDialog(NearbyTruck truck) {
    return showDialog<_TruckAction>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  truck.displayTitle,
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: dialogContext.colors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(AppIcons.close_rounded),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                truck.displaySubtitle,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: dialogContext.colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _buildTruckCategoryPicker(context),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    AppIcons.local_shipping_rounded,
                    color: Color(0xFF2FA56E),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      truck.capacity.isNotEmpty
                          ? truck.capacity
                          : 'Available truck',
                      style: Theme.of(dialogContext).textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: dialogContext.colors.textPrimary,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(_TruckAction.continueBooking),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(_TruckAction.negotiate),
                    child: const Text('Negotiate'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _resolveDistanceAndContinue() async {
    if (_resolvingDistance) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }

    final pickup = _fromController.text.trim();
    final drop = _toController.text.trim();
    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and drop locations.'),
        ),
      );
      return;
    }

    setState(() {
      _resolvingDistance = true;
    });

    try {
      await _resolveTypedCoordinates(pickup: pickup, drop: drop);
      await _refreshBrokerRoute();
      final resolvedTripType = _resolveTripTypeFromLocations(pickup, drop);
      final city = resolvedTripType == TripType.intraCity
          ? (_draft.city.isNotEmpty
                ? _draft.city
                : _deriveCityFromLocation(pickup, drop))
          : '';
      if (city.isNotEmpty || _draft.city.isNotEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _draft = _draft.copyWith(city: city, tripType: resolvedTripType);
        });
      } else {
        setState(() {
          _draft = _draft.copyWith(tripType: resolvedTripType);
        });
      }

      final validation = await ref
          .read(apiClientProvider)
          .validateBookingLocation(
            accessToken: session.tokens.accessToken,
            pickupLocation: pickup,
            dropLocation: drop,
            transportType: resolvedTripType == TripType.intraCity
                ? 'intra'
                : 'inter',
            city: resolvedTripType == TripType.intraCity
                ? (city.isNotEmpty ? city : _draft.city)
                : null,
          );
      if (validation['success'] == false) {
        throw ApiException(
          (validation['message'] ??
                  'These pickup/drop locations are not valid for this trip')
              .toString(),
        );
      }

      final response = await ref
          .read(apiClientProvider)
          .getDistanceEstimate(
            accessToken: session.tokens.accessToken,
            pickup: pickup,
            drop: drop,
          );
      final data = response['data'];
      final directDistance = _readDistanceValue(data, response);
      final stopChainDistance = _routeDistanceKm(_bookingRoutePoints());
      final distance =
          (_draft.loadingStops.isNotEmpty || _draft.unloadingStops.isNotEmpty)
          ? (stopChainDistance ?? directDistance)
          : directDistance;
      final durationMin = _readIntValue(data, response, const [
        'durationMin',
        'duration_min',
      ]);
      final durationInTrafficMin = _readIntValue(data, response, const [
        'durationInTrafficMin',
        'duration_in_traffic_min',
      ]);
      final estimatedAmount = await _estimateBookingAmount(
        accessToken: session.tokens.accessToken,
        distance: distance,
        durationMin: durationMin,
        durationInTrafficMin: durationInTrafficMin,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _draft = _draft.copyWith(
          to: drop,
          from: pickup,
          city: city,
          tripType: resolvedTripType,
          vehicle: _vehicle,
          truckCategory: _truckCategoryForVehicle(_vehicle.label),
          isExpress: resolvedTripType == TripType.intraCity
              ? _draft.isExpress
              : false,
          expressSurcharge: resolvedTripType == TripType.intraCity
              ? _draft.expressSurcharge
              : 0,
          expressInsuranceIncluded: resolvedTripType == TripType.intraCity
              ? _draft.expressInsuranceIncluded
              : false,
          distance: distance,
          durationMin: durationMin,
          durationInTrafficMin: durationInTrafficMin,
          amount: estimatedAmount ?? _draft.amount,
        );
        _amountController.text = estimatedAmount == null
            ? _amountController.text
            : _priceInputText(estimatedAmount.toString());
        _step = _BookingFlowStep.itemDetails;
      });
      _stopLocationStream();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingDistance = false;
        });
      }
    }
  }

  Future<void> _resolveTypedCoordinates({
    required String pickup,
    required String drop,
  }) async {
    final service = ref.read(googlePlacesServiceProvider);
    final pickupNeedsResolution =
        _draft.pickupLat == null || _draft.pickupLng == null;
    final dropNeedsResolution =
        _draft.dropLat == null || _draft.dropLng == null;

    GooglePlaceSelection? pickupSelection;
    if (pickupNeedsResolution) {
      pickupSelection = await service.geocodeAddress(address: pickup);
    }

    GooglePlaceSelection? dropSelection;
    if (dropNeedsResolution) {
      dropSelection = await service.geocodeAddress(address: drop);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (pickupSelection != null &&
          pickupSelection.latitude != null &&
          pickupSelection.longitude != null) {
        _draft = _draft.copyWith(
          from: pickupSelection.formattedAddress.isNotEmpty
              ? pickupSelection.formattedAddress
              : pickup,
          pickupLat: pickupSelection.latitude,
          pickupLng: pickupSelection.longitude,
          city: pickupSelection.city.isNotEmpty
              ? pickupSelection.city
              : _draft.city,
        );
        if (pickupSelection.formattedAddress.isNotEmpty) {
          _fromController.text = pickupSelection.formattedAddress;
        }
      }

      if (dropSelection != null &&
          dropSelection.latitude != null &&
          dropSelection.longitude != null) {
        _draft = _draft.copyWith(
          to: dropSelection.formattedAddress.isNotEmpty
              ? dropSelection.formattedAddress
              : drop,
          dropLat: dropSelection.latitude,
          dropLng: dropSelection.longitude,
        );
        if (dropSelection.formattedAddress.isNotEmpty) {
          _toController.text = dropSelection.formattedAddress;
        }
      }
    });
  }

  Future<void> _useCurrentLocationForPickup() async {
    if (_resolvingCurrentLocation) {
      return;
    }

    // Fast path: reuse the login-prefetched fix — no "Locating..." wait.
    final cached = ref.read(userLocationProvider).valueOrNull;
    if (cached != null && cached.isFresh && cached.address.isNotEmpty) {
      setState(() {
        final city = _deriveCityFromLocation(cached.address, '');
        _draft = _draft.copyWith(
          from: cached.address,
          pickupLat: cached.latitude,
          pickupLng: cached.longitude,
          city: city.isNotEmpty ? city : _draft.city,
        );
        _fromController.text = cached.address;
      });
      ref.read(userLocationProvider.notifier).refreshInBackground();
      return;
    }

    setState(() {
      _resolvingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on location services to autofill pickup.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is needed to autofill pickup.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final service = ref.read(googlePlacesServiceProvider);
      final address = await service.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;

      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resolve your current address yet.'),
          ),
        );
        return;
      }

      setState(() {
        final city = _deriveCityFromLocation(address, '');
        _draft = _draft.copyWith(
          from: address,
          pickupLat: position.latitude,
          pickupLng: position.longitude,
          city: city.isNotEmpty ? city : _draft.city,
        );
        _fromController.text = address;
      });
      ref
          .read(userLocationProvider.notifier)
          .cache(
            latitude: position.latitude,
            longitude: position.longitude,
            address: address,
            accuracy: position.accuracy,
          );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingCurrentLocation = false;
        });
      }
    }
  }

  Future<double?> _estimateBookingAmount({
    required String accessToken,
    required double distance,
    required int? durationMin,
    required int? durationInTrafficMin,
  }) async {
    try {
      final payload = <String, dynamic>{
        'distance': distance,
        'truck_category': _truckCategoryForVehicle(_vehicle.label),
        'transport_type': _draft.transportType,
        'truck_type': _vehicle.label,
        'is_express': _draft.transportType == 'intra'
            ? _draft.isExpress
            : false,
        if (_draft.pickupLat != null) 'pickup_lat': _draft.pickupLat,
        if (_draft.pickupLng != null) 'pickup_lng': _draft.pickupLng,
      };
      if (durationMin != null) {
        payload['duration_min'] = durationMin;
      }
      if (durationInTrafficMin != null) {
        payload['duration_in_traffic_min'] = durationInTrafficMin;
      }
      final response = await ref
          .read(apiClientProvider)
          .estimatePricing(accessToken: accessToken, payload: payload);
      if (mounted) {
        final data = response['data'];
        final amount = _readMoneyValue(data, response);
        setState(() {
          _haltingNote = _haltingNoteFromQuote(response);
          _draft = _draft.copyWith(
            amount: amount > 0 ? amount : _draft.amount,
            isExpress: _draft.transportType == 'intra' && _draft.isExpress,
            expressSurcharge:
                _readDoubleValue(data, response, const [
                  'expressSurcharge',
                  'express_surcharge',
                ]) ??
                0,
            expectedDeliveryHours: _readDoubleValue(data, response, const [
              'expectedDeliveryHours',
              'expected_delivery_hours',
            ]),
            estimatedDeliveryDate: _readDateTimeValue(data, response, const [
              'estimatedDeliveryDate',
              'estimated_delivery_date',
            ]),
            estimatedDeliveryDays: _readIntValue(data, response, const [
              'estimatedDeliveryDays',
              'estimated_delivery_days',
            ]),
            expressInsuranceIncluded: _readBool(
              data is Map<String, dynamic>
                  ? (data['expressInsuranceIncluded'] ??
                        data['express_insurance_included'])
                  : (response['expressInsuranceIncluded'] ??
                        response['express_insurance_included']),
            ),
          );
        });
      }
      return _readMoneyValue(response['data'], response);
    } catch (_) {
      if (mounted) {
        setState(() {
          _haltingNote = null;
        });
      }
      return null;
    }
  }

  String? _haltingNoteFromQuote(Map<String, dynamic> response) {
    final data = response['data'];
    final halting = data is Map<String, dynamic>
        ? data['halting']
        : response['halting'];
    if (halting is! Map<String, dynamic>) {
      return null;
    }
    final graceHours = _readNumberLoose(
      halting['graceHours'] ?? halting['grace_hours'],
    );
    final rate = _readNumberLoose(
      halting['ratePerHour'] ?? halting['rate_per_hour'],
    );
    if (graceHours <= 0 || rate <= 0) {
      return null;
    }
    return 'Free halting: ${graceHours.toStringAsFixed(graceHours % 1 == 0 ? 0 : 1)}h, then ${_formatRupees(rate)}/hr.';
  }

  Future<void> _setExpressDelivery(bool enabled) async {
    if (!enabled) {
      setState(() {
        _draft = _draft.copyWith(
          isExpress: false,
          expressSurcharge: 0,
          expressInsuranceIncluded: false,
        );
      });
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }

    final canUseExpress = await _ensureExpressEligible(
      accessToken: session.tokens.accessToken,
    );
    if (!canUseExpress) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Express delivery is available for intra-city bookings.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _loadingExpressQuote = true;
      _draft = _draft.copyWith(
        isExpress: enabled,
        expressSurcharge: _draft.expressSurcharge,
        expressInsuranceIncluded: _draft.expressInsuranceIncluded,
      );
    });

    if (_draft.distance <= 0) {
      if (mounted) {
        setState(() {
          _loadingExpressQuote = false;
        });
      }
      return;
    }

    final estimatedAmount = await _estimateBookingAmount(
      accessToken: session.tokens.accessToken,
      distance: _draft.distance,
      durationMin: _draft.durationMin,
      durationInTrafficMin: _draft.durationInTrafficMin,
    );
    if (!mounted) return;
    setState(() {
      _loadingExpressQuote = false;
      if (estimatedAmount != null && estimatedAmount > 0) {
        _amountController.text = _priceInputText(estimatedAmount.toString());
      }
    });
  }

  Future<bool> _ensureExpressEligible({required String accessToken}) async {
    if (_draft.transportType == 'intra') {
      return true;
    }

    final pickup = _draft.from.isNotEmpty
        ? _draft.from
        : _fromController.text.trim();
    final drop = _draft.to.isNotEmpty ? _draft.to : _toController.text.trim();
    if (pickup.isEmpty || drop.isEmpty) {
      return false;
    }

    final city = _draft.city.isNotEmpty
        ? _draft.city
        : _deriveCityFromLocation(pickup, drop);
    try {
      final validation = await ref
          .read(apiClientProvider)
          .validateBookingLocation(
            accessToken: accessToken,
            pickupLocation: pickup,
            dropLocation: drop,
            transportType: 'intra',
            city: city.isNotEmpty ? city : null,
          );
      if (validation['success'] == false) {
        return false;
      }
      if (mounted) {
        setState(() {
          _draft = _draft.copyWith(
            tripType: TripType.intraCity,
            city: city.isNotEmpty ? city : _draft.city,
          );
        });
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _submitBooking() async {
    if (_submitting || _bookingCreated) {
      return;
    }
    if (!_validateScheduledDate()) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to create a booking.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .createBooking(
            accessToken: session.tokens.accessToken,
            booking: _bookingPayload(),
            idempotencyKey: _buildIdempotencyKey(),
          );
      final bookingNumber = _extractBookingNumber(response);
      final bookingId = _extractBookingId(response);
      final resolvedBookingNumber = bookingNumber.isNotEmpty
          ? bookingNumber
          : await _fetchLatestBookingNumber(session.tokens.accessToken);

      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _bookingCreated = true;
        _bookingReference = resolvedBookingNumber;
        _activeBookingId = bookingId.isNotEmpty ? bookingId : _activeBookingId;
      });
      await _showBookingCompleteAndRedirect();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  Future<void> _payExistingBooking() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    final selectedMethod = _selectedPaymentMethod;
    setState(() {
      _submitting = true;
    });
    if (selectedMethod == PaymentMethod.payLater) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _bookingCreated = true;
      });
      await _showBookingCompleteAndRedirect();
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
          _submitting = false;
          _bookingCreated = true;
        });
        await _showBookingCompleteAndRedirect();
      } on ApiException catch (error) {
        if (!mounted) return;
        setState(() {
          _submitting = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
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
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _bookingCreated = true;
      });
      await _showBookingCompleteAndRedirect();
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
  }

  Future<void> _showBookingCompleteAndRedirect() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _submitting = false;
      _paymentCompletionVisible = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 1450));
    if (!mounted) {
      return;
    }

    _bottomNavVisibleController.state = true;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('/client/delivery');
      });
      return;
    }
    router.go('/client/delivery');
  }

  Future<_DirectRequestSession?> _createDirectTruckRequestSession({
    required String truckId,
    required double amount,
  }) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      throw StateError('Please sign in again to create a booking.');
    }
    if (!_validateScheduledDate()) {
      throw StateError('Choose a future pickup time.');
    }

    setState(() {
      _draft = _draft.copyWith(brokerId: truckId, amount: amount);
    });

    final response = await ref
        .read(apiClientProvider)
        .createBooking(
          accessToken: session.tokens.accessToken,
          booking: _bookingPayload(),
          idempotencyKey: _buildIdempotencyKey(),
        );
    final bookingNumber = _extractBookingNumber(response);
    final bookingId = _extractBookingId(response);
    final resolvedBookingNumber = bookingNumber.isNotEmpty
        ? bookingNumber
        : await _fetchLatestBookingNumber(session.tokens.accessToken);

    ClientBookingOffer? driverRequest;
    if (bookingId.isNotEmpty && truckId.trim().isNotEmpty) {
      try {
        final requestResponse = await ref
            .read(apiClientProvider)
            .requestTruckForBooking(
              accessToken: session.tokens.accessToken,
              bookingId: bookingId,
              truckId: truckId,
            );
        driverRequest = _extractDriverRequest(requestResponse);
      } catch (_) {
        driverRequest = null;
      }
    }

    if (mounted) {
      setState(() {
        _bookingReference = resolvedBookingNumber;
        _activeBookingId = bookingId.isNotEmpty ? bookingId : _activeBookingId;
      });
    }

    return _DirectRequestSession(
      bookingId: bookingId,
      bookingNumber: resolvedBookingNumber,
      request: driverRequest,
    );
  }

  Map<String, dynamic> _bookingPayload() {
    final scheduled = _draft.isScheduled
        ? (_draft.scheduledDate ?? DateTime.now().add(const Duration(hours: 3)))
        : DateTime.now();
    final mode = _draft.searchMode;
    return <String, dynamic>{
      'pickup_location': _draft.from,
      'pickup_lat': _draft.pickupLat ?? 0,
      'pickup_lng': _draft.pickupLng ?? 0,
      'drop_location': _draft.to,
      'drop_lat': _draft.dropLat ?? 0,
      'drop_lng': _draft.dropLng ?? 0,
      if (_draft.loadingStops.isNotEmpty)
        'add_loading_location': _draft.loadingStops
            .map((stop) => stop.toPayload())
            .toList(growable: false),
      if (_draft.unloadingStops.isNotEmpty)
        'add_unloading_location': _draft.unloadingStops
            .map((stop) => stop.toPayload())
            .toList(growable: false),
      'truck_type': _draft.truckType,
      'truck_category': _draft.truckCategory.isEmpty
          ? _truckCategoryForVehicle(_vehicle.label)
          : _draft.truckCategory,
      'city': _draft.transportType == 'intra'
          ? _draft.city.isNotEmpty
                ? _draft.city
                : _deriveCityFromLocation(_draft.from, _draft.to)
          : _draft.city,
      'weight': _draft.weight,
      'weight_unit': _draft.weightUnit,
      'quantity': _draft.quantity,
      'material': _draft.material,
      if (_draft.additionalNotes.trim().isNotEmpty)
        'notes': _draft.additionalNotes.trim(),
      'transport_type': _draft.transportType,
      'scheduled_date': scheduled.toUtc().toIso8601String(),
      if (_draft.isScheduled) 'is_scheduled': true,
      if (mode == BookingSearchMode.truck) ...{
        'search_mode': 'truck',
        'search_radius_km': _draft.searchRadiusKm.clamp(0.5, 200).toDouble(),
      },
      if (mode == BookingSearchMode.broker) ...{
        'search_mode': 'broker',
        'broker_id': _draft.selectedBrokerId,
      },
      'distance': _draft.distance,
      if (_draft.durationMin != null) 'duration_min': _draft.durationMin,
      if (_draft.durationInTrafficMin != null)
        'duration_in_traffic_min': _draft.durationInTrafficMin,
      'is_express': _draft.transportType == 'intra' ? _draft.isExpress : false,
      'amount': _draft.amount,
      'payment_status': 'pending',
    };
  }

  bool _validateScheduledDate() {
    if (!_draft.isScheduled) {
      return true;
    }
    final scheduled = _draft.scheduledDate;
    if (scheduled == null || !scheduled.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future pickup time.')),
      );
      return false;
    }
    return true;
  }

  String _buildIdempotencyKey() {
    final payload = <String, dynamic>{
      ..._bookingPayload(),
      'attempted_at': DateTime.now().microsecondsSinceEpoch,
    };
    final normalized = payload.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('|');
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final hash = normalized.hashCode.abs().toRadixString(36);
    final random = Random().nextInt(1 << 32).toRadixString(36);
    return '$timestamp-$hash-$random';
  }

  String _deriveCityFromLocation(String pickup, String drop) {
    String cityFromAddress(String value) {
      final segments = value
          .split(',')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.length >= 2) {
        return segments[1];
      }
      if (segments.isNotEmpty) {
        return segments.first;
      }
      return '';
    }

    final pickupCity = cityFromAddress(pickup);
    if (pickupCity.isNotEmpty) {
      return pickupCity;
    }
    return cityFromAddress(drop);
  }

  TripType _resolveTripTypeFromLocations(String pickup, String drop) {
    String cityFromAddress(String value) {
      final segments = value
          .split(',')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.length >= 2) {
        return segments[1].toLowerCase();
      }
      if (segments.isNotEmpty) {
        return segments.first.toLowerCase();
      }
      return '';
    }

    final pickupCity = cityFromAddress(pickup);
    final dropCity = cityFromAddress(drop);
    if (pickupCity.isEmpty || dropCity.isEmpty) {
      return _draft.tripType;
    }
    return pickupCity == dropCity ? TripType.intraCity : TripType.interCity;
  }

  Future<String> _fetchLatestBookingNumber(String accessToken) async {
    final response = await ref
        .read(apiClientProvider)
        .getBookings(accessToken: accessToken, page: 1, limit: 20);
    final bookingsPage = ClientBookingPage.fromJson(response);
    if (bookingsPage.bookings.isEmpty) {
      return '';
    }

    final candidates = bookingsPage.bookings
        .where(_matchesDraftBooking)
        .toList();
    final booking = candidates.isNotEmpty
        ? candidates.first
        : bookingsPage.bookings.first;
    return booking.bookingNumber.isNotEmpty
        ? booking.bookingNumber
        : (booking.bookingRef.isNotEmpty ? booking.bookingRef : booking.id);
  }

  bool _matchesDraftBooking(ClientBooking booking) {
    final draftPickup = _draft.from.trim().toLowerCase();
    final draftDrop = _draft.to.trim().toLowerCase();
    final draftMaterial = _draft.material.trim().toLowerCase();
    final draftAmount = _draft.amount.toStringAsFixed(2);
    final bookingAmount = booking.amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    return booking.pickupLocation.trim().toLowerCase() == draftPickup &&
        booking.dropoffLocation.trim().toLowerCase() == draftDrop &&
        (draftMaterial.isEmpty ||
            booking.packageName.trim().toLowerCase().contains(draftMaterial) ||
            booking.raw['material']?.toString().trim().toLowerCase() ==
                draftMaterial) &&
        (bookingAmount.isEmpty ||
            bookingAmount == draftAmount ||
            bookingAmount == _draft.amount.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(clientPricingProvider, (previous, next) {
      final pricing = next.valueOrNull;
      if (pricing == null || !mounted) {
        return;
      }
      final vehicles = resolveVehicleOptions(
        tripType: widget.tripType,
        pricing: pricing,
        isLoading: false,
      );
      if (vehicles.isEmpty) return;
      final safeIndex = _vehicleIndex.clamp(0, vehicles.length - 1).toInt();
      final updatedVehicle = vehicles[safeIndex];
      setState(() {
        _vehicle = updatedVehicle;
        _draft = _draft.copyWith(
          vehicle: updatedVehicle,
          truckCategory: _truckCategoryForVehicle(updatedVehicle.label),
          amount: _priceValue(updatedVehicle.price),
        );
        _amountController.text = _priceInputText(updatedVehicle.price);
      });
    });

    final hideInitialAutoLocationFrame =
        widget.autoOpenLocationFlow &&
        !_autoLocationFlowStarted &&
        _step == _BookingFlowStep.location;

    if (hideInitialAutoLocationFrame) {
      return Scaffold(
        backgroundColor: context.colors.canvas,
        body: SizedBox.shrink(),
      );
    }

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final showBottomButton = switch (_step) {
      _BookingFlowStep.location => true,
      _BookingFlowStep.payment => false,
      _BookingFlowStep.waiting => false,
      _BookingFlowStep.brokerSelection => false,
      _BookingFlowStep.itemDetails => false,
    };
    final bodyPadding = _step == _BookingFlowStep.brokerSelection
        ? EdgeInsets.zero
        : EdgeInsets.fromLTRB(
            18,
            12,
            18,
            _step == _BookingFlowStep.itemDetails ? 154 : 18,
          );

    return Scaffold(
      backgroundColor: context.colors.canvas,
      bottomNavigationBar:
          (_bookingCreated && !_postNegotiationPayment) || !showBottomButton
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 44),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _next,
                  child: (_submitting || _resolvingDistance)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(switch (_step) {
                          _BookingFlowStep.location => 'Next',
                          _BookingFlowStep.payment => 'Continue',
                          _BookingFlowStep.brokerSelection => 'Continue',
                          _BookingFlowStep.itemDetails => 'Next',
                          _BookingFlowStep.waiting => 'Continue',
                        }),
                ),
              ),
            ),
      body: _step == _BookingFlowStep.brokerSelection
          ? _buildBrokerSelectionMapSheetStep(context)
          : _step == _BookingFlowStep.payment &&
                (_paymentCompletionVisible ||
                    !(_bookingCreated && !_postNegotiationPayment))
          ? _buildPaymentMapSheetStep(context)
          : SafeArea(
              child: _step == _BookingFlowStep.itemDetails
                  ? Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                padding: bodyPadding,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            if (_step ==
                                                    _BookingFlowStep.location ||
                                                (_step ==
                                                        _BookingFlowStep
                                                            .itemDetails &&
                                                    widget.skipLocationStep)) {
                                              Navigator.of(context).pop();
                                              return;
                                            }
                                            setState(() {
                                              _step = switch (_step) {
                                                _BookingFlowStep.location =>
                                                  _BookingFlowStep.location,
                                                _BookingFlowStep.itemDetails =>
                                                  _BookingFlowStep.location,
                                                _BookingFlowStep
                                                    .brokerSelection =>
                                                  _BookingFlowStep.itemDetails,
                                                _BookingFlowStep.payment =>
                                                  _BookingFlowStep
                                                      .brokerSelection,
                                                _BookingFlowStep.waiting =>
                                                  _BookingFlowStep.payment,
                                              };
                                            });
                                          },
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          child: const SizedBox(
                                            width: 28,
                                            height: 28,
                                            child: Icon(
                                              AppIcons.arrow_back_rounded,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        _buildScheduleHeaderActions(context),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _buildCurrentStep(context),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildWeightBottomActions(context),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: bodyPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_step !=
                                    _BookingFlowStep.brokerSelection) ...[
                                  Row(
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          if (_step ==
                                                  _BookingFlowStep.location ||
                                              (_step ==
                                                      _BookingFlowStep
                                                          .itemDetails &&
                                                  widget.skipLocationStep)) {
                                            Navigator.of(context).pop();
                                            return;
                                          }
                                          setState(() {
                                            _step = switch (_step) {
                                              _BookingFlowStep.location =>
                                                _BookingFlowStep.location,
                                              _BookingFlowStep.itemDetails =>
                                                _BookingFlowStep.location,
                                              _BookingFlowStep
                                                  .brokerSelection =>
                                                _BookingFlowStep.itemDetails,
                                              _BookingFlowStep.payment =>
                                                _BookingFlowStep
                                                    .brokerSelection,
                                              _BookingFlowStep.waiting =>
                                                _BookingFlowStep.payment,
                                            };
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: const SizedBox(
                                          width: 28,
                                          height: 28,
                                          child: Icon(
                                            AppIcons.arrow_back_rounded,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        switch (_step) {
                                          _BookingFlowStep.location =>
                                            'Location',
                                          _BookingFlowStep.itemDetails =>
                                            'Weight',
                                          _BookingFlowStep.brokerSelection =>
                                            'Choose trucks',
                                          _BookingFlowStep.payment => 'Payment',
                                          _BookingFlowStep.waiting => 'Waiting',
                                        },
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              color: context.colors.textSecondary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                _buildCurrentStep(context),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    return switch (_step) {
      _BookingFlowStep.location => _buildLocationStep(context),
      _BookingFlowStep.itemDetails => _buildItemDetailsStep(context),
      _BookingFlowStep.brokerSelection => _buildBrokerSelectionMapSheetStep(
        context,
      ),
      _BookingFlowStep.payment =>
        _bookingCreated && !_postNegotiationPayment
            ? _buildSuccessStep(context)
            : _buildPaymentStep(context),
      _BookingFlowStep.waiting => _buildWaitingStep(context),
    };
  }

  Widget _buildBrokerSelectionMapSheetStep(BuildContext context) {
    final mode = _draft.searchMode ?? BookingSearchMode.truck;
    final isFindTruckSearching =
        _bookingCreated && !_postNegotiationPayment;
    final hideSearchPanel = _submitting || isFindTruckSearching;
    final dimFindTruckMap = isFindTruckSearching && _findTruckRequestCount > 0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final brokerMode = mode == BookingSearchMode.broker;
        final mediaQuery = MediaQuery.of(context);
        final view = View.of(context);
        final viewBottomInset =
            max(view.padding.bottom, view.viewPadding.bottom) /
            view.devicePixelRatio;
        final bottomSystemInset = max(
          max(mediaQuery.viewPadding.bottom, mediaQuery.padding.bottom),
          viewBottomInset,
        );
        final isAndroid = Theme.of(context).platform == TargetPlatform.android;
        final contentBottomPadding = isAndroid
            ? max(bottomSystemInset, 56.0)
            : bottomSystemInset;
        final sheetBottomPadding = contentBottomPadding + 18;
        const collapsedSheetExtent = 0.16;
        const normalSheetExtent = 0.58;
        final maxSheetExtent = brokerMode ? 0.82 : normalSheetExtent;
        final snapSizes = brokerMode
            ? const [collapsedSheetExtent, normalSheetExtent, 0.82]
            : const [collapsedSheetExtent, normalSheetExtent];

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBrokerMap(
              context,
              const <NearbyTruck>[],
              findTruckRequests: isFindTruckSearching
                  ? _findTruckRequests
                  : const <ClientBookingOffer>[],
              searchRadiusKm: isFindTruckSearching
                  ? _draft.searchRadiusKm
                  : null,
            ),
            if (dimFindTruckMap)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    color: const Color(0xFF111827).withValues(alpha: 0.34),
                  ),
                ),
              ),
            if (isFindTruckSearching)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: Builder(
                  builder: (context) {
                    final negotiableOffer = brokerMode
                        ? pickPrimaryBrokerOffer(
                            _brokerOffers,
                            _primaryBrokerOfferId,
                          )
                        : null;
                    final showNegotiate =
                        negotiableOffer != null &&
                        !_brokerNegotiationOpen &&
                        !negotiableOffer.isCountered &&
                        !negotiableOffer.isYourTurnToConfirm;
                    // Name the broker you actually chose — the offer row
                    // itself often carries no name.
                    String chosenBrokerName = negotiableOffer?.brokerName
                        .trim() ??
                        '';
                    if (chosenBrokerName.isEmpty) {
                      final selectedId = _draft.selectedBrokerId.trim();
                      for (final broker in _eligibleBrokers) {
                        if (broker.id == selectedId &&
                            broker.name.trim().isNotEmpty) {
                          chosenBrokerName = broker.name.trim();
                          break;
                        }
                      }
                    }
                    return _FindTruckScreenLoader(
                      bookingReference: _bookingReference,
                      requestCount: _findTruckRequestCount,
                      declinedCount: _findTruckDeclinedCount,
                      searchRadiusKm: _draft.searchRadiusKm,
                      isCancelling: _cancellingFindTruckSearch,
                      onCancel: _cancelFindTruckSearch,
                      pickup: _draft.from,
                      drop: _draft.to,
                      amountText: _draft.amountText,
                      requests: _findTruckRequests,
                      actingId: _findTruckActingId,
                      onAccept: _acceptFindTruckRequest,
                      onReject: _rejectFindTruckRequest,
                      onCounter: _counterFindTruckRequest,
                      searchingAgain: _searchingFindTruckAgain,
                      onSearchAgain: _rebroadcastFindTruckSearch,
                      offersError: _findTruckOffersError,
                      onRetryOffers: () =>
                          _loadFindTruckDriverRequests(silent: false),
                      negotiateLabel: showNegotiate
                          ? 'Negotiate${chosenBrokerName.isNotEmpty ? ' with $chosenBrokerName' : ''}'
                          : null,
                      onNegotiate: showNegotiate
                          ? () => _openBrokerOfferNegotiation(negotiableOffer)
                          : null,
                    );
                  },
                ),
              ),
            if (!hideSearchPanel)
              Positioned.fill(
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    final collapsedChanged =
                        (_truckSearchSheetExtent <= 0.20) !=
                        (notification.extent <= 0.20);
                    if (collapsedChanged && mounted) {
                      setState(() {
                        _truckSearchSheetExtent = notification.extent;
                      });
                    } else {
                      _truckSearchSheetExtent = notification.extent;
                    }
                    return false;
                  },
                  child: DraggableScrollableSheet(
                    controller: _truckSearchSheetController,
                    initialChildSize: normalSheetExtent,
                    minChildSize: collapsedSheetExtent,
                    maxChildSize: maxSheetExtent,
                    snap: true,
                    snapAnimationDuration: const Duration(milliseconds: 220),
                    snapSizes: snapSizes,
                    shouldCloseOnMinExtent: false,
                    builder: (context, scrollController) {
                      final isCollapsed = _truckSearchSheetExtent <= 0.20;
                      return _SearchMethodSheet(
                        child: AbsorbPointer(
                          absorbing: isFindTruckSearching,
                          child: Opacity(
                            opacity: isFindTruckSearching ? 0.58 : 1,
                            child: SingleChildScrollView(
                              controller: scrollController,
                              physics: const ClampingScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(
                                16,
                                8,
                                16,
                                sheetBottomPadding,
                              ),
                              child: _buildTruckSearchSheetContent(
                                context,
                                mode: mode,
                                brokerMode: brokerMode,
                                isCollapsed: isCollapsed,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            if (!isFindTruckSearching)
              Positioned(
                left: 16,
                top: 0,
                child: SafeArea(
                  child: Material(
                    color: context.colors.surface,
                    shape: const CircleBorder(),
                    elevation: 5,
                    shadowColor: Colors.black.withValues(alpha: 0.18),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => setState(() {
                        _step = _BookingFlowStep.itemDetails;
                      }),
                      child: SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          AppIcons.arrow_back_rounded,
                          color: context.colors.textPrimary,
                          size: 23,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTruckSearchSheetContent(
    BuildContext context, {
    required BookingSearchMode mode,
    required bool brokerMode,
    required bool isCollapsed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SheetGrabber(),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeOutCubic,
          child: isCollapsed
              ? const _CollapsedTruckSearchBar(
                  key: ValueKey('truck-sheet-collapsed'),
                )
              : Column(
                  key: const ValueKey('truck-sheet-expanded'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 14),
                    Text(
                      'Choose Trucks',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      brokerMode
                          ? 'Pick a broker for this route'
                          : 'Select truck type and search radius',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.colors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTruckCategoryPicker(context),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _SearchModeCard(
                            selected: mode == BookingSearchMode.truck,
                            icon: AppIcons.local_shipping_rounded,
                            title: 'Find Truck',
                            onTap: () {
                              setState(() {
                                _draft = _draft.copyWith(
                                  searchMode: BookingSearchMode.truck,
                                  selectedBrokerId: '',
                                );
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _animateTruckSearchSheetTo(0.58);
                                }
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SearchModeCard(
                            selected: mode == BookingSearchMode.broker,
                            icon: AppIcons.person_rounded,
                            title: 'Brokers',
                            onTap: () {
                              setState(() {
                                _draft = _draft.copyWith(
                                  searchMode: BookingSearchMode.broker,
                                );
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (mounted) {
                                  _animateTruckSearchSheetTo(0.82);
                                }
                              });
                              unawaited(_loadEligibleBrokers());
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: brokerMode
                          ? Column(
                              key: const ValueKey('broker-mode-content'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildBrokerListOptions(context),
                                const SizedBox(height: 12),
                                FilledButton(
                                  onPressed:
                                      _draft.selectedBrokerId.trim().isEmpty
                                      ? null
                                      : _continueWithSearchMode,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2FA56E),
                                    disabledBackgroundColor: const Color(
                                      0xFFD8E1ED,
                                    ),
                                    foregroundColor: Colors.white,
                                    disabledForegroundColor:
                                        context.colors.textSecondary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text('Continue'),
                                ),
                              ],
                            )
                          : Column(
                              key: const ValueKey('truck-mode-content'),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildFindTruckOptions(context),
                                const SizedBox(height: 12),
                                FilledButton.icon(
                                  onPressed: _startFindTruckSearch,
                                  icon: const Icon(
                                    AppIcons.search_rounded,
                                    size: 19,
                                  ),
                                  label: const Text('Find Truck'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2FA56E),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildBrokerSelectionStep(BuildContext context) {
    final mode = _draft.searchMode ?? BookingSearchMode.truck;
    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetWidth = min(constraints.maxWidth, 680.0);
        return Center(
          child: SizedBox(
            width: sheetWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 300,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: _buildBrokerMap(context, const <NearbyTruck>[]),
                      ),
                      Container(
                        color: const Color(0xFF0B2545).withValues(alpha: 0.18),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -22),
                  child: _SearchMethodSheet(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 54,
                            height: 5,
                            decoration: BoxDecoration(
                              color: context.colors.line,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Choose Trucks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: context.colors.textPrimary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                        ),
                        const SizedBox(height: 14),
                        _buildTruckCategoryPicker(context),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _SearchModeCard(
                                selected: mode == BookingSearchMode.truck,
                                icon: AppIcons.local_shipping_rounded,
                                title: 'Find Truck',
                                onTap: () {
                                  setState(() {
                                    _draft = _draft.copyWith(
                                      searchMode: BookingSearchMode.truck,
                                      selectedBrokerId: '',
                                    );
                                  });
                                  _continueWithSearchMode();
                                },
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: _SearchModeCard(
                                selected: mode == BookingSearchMode.broker,
                                icon: AppIcons.person_rounded,
                                title: 'Brokers',
                                onTap: () {
                                  setState(() {
                                    _draft = _draft.copyWith(
                                      searchMode: BookingSearchMode.broker,
                                    );
                                  });
                                  unawaited(_loadEligibleBrokers());
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Divider(height: 1, color: context.colors.line),
                        const SizedBox(height: 14),
                        if (mode == BookingSearchMode.truck)
                          _buildFindTruckOptions(context)
                        else
                          _buildBrokerListOptions(context),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFindTruckOptions(BuildContext context) {
    final radius = _draft.searchRadiusKm.clamp(0.5, 200).toDouble();
    final radiusText = radius.toStringAsFixed(radius % 1 == 0 ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              AppIcons.my_location_rounded,
              color: context.colors.textPrimary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search Radius',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: context.colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.colors.brandFill,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$radiusText km',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF2FA56E),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2FA56E),
            inactiveTrackColor: context.colors.line,
            thumbColor: const Color(0xFF2FA56E),
            overlayColor: const Color(0xFF2FA56E).withValues(alpha: 0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: radius,
            min: 0.5,
            max: 200,
            divisions: 399,
            label: '$radiusText km',
            onChanged: (value) {
              setState(() {
                _draft = _draft.copyWith(searchRadiusKm: value);
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTruckCategoryPicker(BuildContext context) {
    final pricingState = ref.watch(clientPricingProvider);
    final vehicles = resolveVehicleOptions(
      tripType: widget.tripType,
      pricing: pricingState.valueOrNull,
      isLoading: pricingState.isLoading,
    );
    final selectedIndex = vehicles.isEmpty
        ? 0
        : _vehicleIndex.clamp(0, vehicles.length - 1).toInt();

    return SizedBox(
      height: 68,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = min(190.0, constraints.maxWidth * 0.58);
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 1),
            itemCount: vehicles.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              return SizedBox(
                width: cardWidth,
                child: _ChooseTruckCard(
                  vehicle: vehicles[index],
                  selected: selectedIndex == index,
                  onTap: () => _selectVehicleForSearchStep(index),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBrokerListOptions(BuildContext context) {
    if (_loadingEligibleBrokers) {
      return const _BrokerLoadingCard();
    }
    if (_eligibleBrokersError != null) {
      return _BrokerEmptyCard(
        icon: AppIcons.wifi_off_rounded,
        title: 'Could not load brokers',
        message: _eligibleBrokersError!,
        onRetry: _loadEligibleBrokers,
      );
    }
    if (_eligibleBrokers.isEmpty) {
      return _BrokerEmptyCard(
        icon: AppIcons.manage_search_rounded,
        title: 'No broker nearby',
        message: 'No eligible brokers found for this route yet.',
        onRetry: _loadEligibleBrokers,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BrokerListHeader(count: _eligibleBrokers.length),
        const SizedBox(height: 10),
        ..._eligibleBrokers.map(
          (broker) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _EligibleBrokerTile(
              broker: broker,
              selected: _draft.selectedBrokerId == broker.id,
              onTap: () {
                setState(() {
                  _draft = _draft.copyWith(
                    searchMode: BookingSearchMode.broker,
                    selectedBrokerId: broker.id,
                  );
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildBrokerMap(
    BuildContext context,
    List<NearbyTruck> trucks, {
    List<ClientBookingOffer> findTruckRequests = const [],
    double? searchRadiusKm,
  }) {
    final cameraTarget = _brokerMapCenter();
    final markers = _buildBrokerMarkers(
      trucks,
      findTruckRequests: findTruckRequests,
    );
    final polylines = _buildBrokerPolylines();
    final circles = _buildFindTruckSearchCircles(searchRadiusKm);
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final shouldAutoFitCamera = _step != _BookingFlowStep.payment;

    _scheduleBrokerRouteRefresh();

    return GoogleMap(
      style: ClientMapTheme.styleFor(context),
      initialCameraPosition:
          _brokerMapCameraPosition ??
          CameraPosition(
            target: cameraTarget,
            zoom: pickup != null && drop != null ? 8.4 : 10.2,
          ),
      mapType: MapType.normal,
      markers: markers,
      circles: circles,
      polylines: polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trafficEnabled: true,
      onCameraMove: (position) {
        _brokerMapCameraPosition = position;
      },
      onMapCreated: (controller) {
        _brokerMapController = controller;
        _scheduleBrokerRouteRefresh();
        if (shouldAutoFitCamera) {
          WidgetsBinding.instance.addPostFrameCallback(
            (_) => _fitBrokerCamera(),
          );
        }
      },
    );
  }

  Set<Marker> _buildBrokerMarkers(
    List<NearbyTruck> trucks, {
    List<ClientBookingOffer> findTruckRequests = const [],
  }) {
    final icon =
        _truckMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    final markers = <Marker>{};

    for (final truck in trucks) {
      final latitude = truck.currentLat;
      final longitude = truck.currentLng;
      if (latitude == 0 && longitude == 0) {
        continue;
      }
      markers.add(
        Marker(
          markerId: MarkerId(truck.id),
          position: LatLng(latitude, longitude),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: _selectedTruck?.id == truck.id ? 2 : 1,
          infoWindow: InfoWindow(
            title: truck.displayTitle,
            snippet: truck.displaySubtitle,
          ),
          onTap: () => _handleTruckTap(truck),
        ),
      );
    }

    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final pickupIcon =
        _pickupMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    final dropIcon =
        _dropMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup-point'),
          position: pickup,
          icon: pickupIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    for (final entry in findTruckRequests.asMap().entries) {
      final request = entry.value;
      if (request.normalizedStatus == 'declined') {
        continue;
      }
      final latitude = request.driverLat;
      final longitude = request.driverLng;
      if (latitude == null ||
          longitude == null ||
          !latitude.isFinite ||
          !longitude.isFinite) {
        continue;
      }
      final markerKey = request.id.isEmpty ? entry.key.toString() : request.id;
      markers.add(
        Marker(
          markerId: MarkerId('find-truck-driver-$markerKey'),
          position: LatLng(latitude, longitude),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          rotation: request.driverHeading?.isFinite == true
              ? request.driverHeading!
              : 0,
          flat: true,
          zIndexInt: 2,
          infoWindow: InfoWindow(
            title: request.brokerName.isEmpty ? 'Driver' : request.brokerName,
            snippet: request.displayStatusLabel,
          ),
        ),
      );
    }

    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop-point'),
          position: drop,
          icon: dropIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          infoWindow: const InfoWindow(title: 'Drop'),
        ),
      );
    }

    return markers;
  }

  Set<Circle> _buildFindTruckSearchCircles(double? searchRadiusKm) {
    final pickup = _pickupLatLng;
    if (pickup == null ||
        searchRadiusKm == null ||
        !searchRadiusKm.isFinite ||
        searchRadiusKm <= 0) {
      return const {};
    }
    return {
      Circle(
        circleId: const CircleId('find-truck-search-radius'),
        center: pickup,
        radius: searchRadiusKm * 1000,
        strokeWidth: 2,
        strokeColor: const Color(0xFF2FA56E).withValues(alpha: 0.55),
        fillColor: const Color(0xFF2FA56E).withValues(alpha: 0.10),
        zIndex: 1,
      ),
    };
  }

  Set<Polyline> _buildBrokerPolylines() {
    final path = _brokerRoutePath();
    if (path.length < 2) {
      return const {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('booking-route'),
        points: path,
        color: const Color(0xFF1A73E8),
        width: 7,
        geodesic: false,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  Future<void> _fitBrokerCamera() async {
    if (_step == _BookingFlowStep.payment) {
      return;
    }
    final controller = _brokerMapController;
    final bounds = _brokerRouteBounds();
    if (controller == null || bounds == null) {
      return;
    }

    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 34));
    } catch (_) {
      // The map can briefly reject bounds updates while the surface is still
      // settling. The next rebuild or route refresh will retry automatically.
    }
  }

  LatLng? get _pickupLatLng {
    final lat = _draft.pickupLat;
    final lng = _draft.pickupLng;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng? get _dropLatLng {
    final lat = _draft.dropLat;
    final lng = _draft.dropLng;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  List<LatLng> _bookingRoutePoints() {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    return [
      ?pickup,
      ..._draft.loadingStops.map((stop) => stop.latLng),
      ..._draft.unloadingStops.map((stop) => stop.latLng),
      ?drop,
    ];
  }

  LatLng _brokerMapCenter() {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    if (pickup != null && drop != null) {
      return LatLng(
        (pickup.latitude + drop.latitude) / 2,
        (pickup.longitude + drop.longitude) / 2,
      );
    }
    return pickup ?? drop ?? _fallbackMapCenter;
  }

  List<LatLng> _brokerRoutePath() {
    if (_brokerRoutePoints.length >= 2) {
      return _brokerRoutePoints;
    }
    return _bookingRoutePoints();
  }

  LatLngBounds? _brokerRouteBounds() {
    final points = _brokerRoutePath();
    if (points.isEmpty) {
      return null;
    }
    if (points.length == 1) {
      final point = points.first;
      return LatLngBounds(southwest: point, northeast: point);
    }

    double? minLat;
    double? maxLat;
    double? minLng;
    double? maxLng;
    for (final point in points) {
      minLat = minLat == null ? point.latitude : min(minLat, point.latitude);
      maxLat = maxLat == null ? point.latitude : max(maxLat, point.latitude);
      minLng = minLng == null ? point.longitude : min(minLng, point.longitude);
      maxLng = maxLng == null ? point.longitude : max(maxLng, point.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  Widget _buildLocationStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.colors.textPrimary,
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resolvingCurrentLocation
                  ? null
                  : _useCurrentLocationForPickup,
              icon: _resolvingCurrentLocation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(AppIcons.gps_fixed_rounded, size: 14),
              label: Text(
                _resolvingCurrentLocation
                    ? 'Locating...'
                    : 'Use current location',
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: context.colors.infoEmphasis,
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LocationLaunchCard(
          pickupValue: _fromController.text.isEmpty
              ? 'Enter loading location'
              : _fromController.text,
          dropValue: _toController.text.isEmpty
              ? 'Enter unloading location'
              : _toController.text,
          onPickupTap: () async {
            final selection = await _openLocationDetailsScreen(
              _LocationFieldKind.pickup,
            );
            if (selection == null || !mounted) {
              return;
            }
            setState(() {
              _draft = _draft.copyWith(
                from: selection.formattedAddress,
                pickupLat: selection.latitude,
                pickupLng: selection.longitude,
                city: selection.city.isNotEmpty ? selection.city : _draft.city,
              );
              _fromController.text = selection.formattedAddress;
            });
          },
          onDropTap: () async {
            final selection = await _openLocationDetailsScreen(
              _LocationFieldKind.drop,
            );
            if (selection == null || !mounted) {
              return;
            }
            setState(() {
              _draft = _draft.copyWith(
                to: selection.formattedAddress,
                dropLat: selection.latitude,
                dropLng: selection.longitude,
              );
              _toController.text = selection.formattedAddress;
            });
          },
        ),
        const SizedBox(height: 14),
        _buildLocationMap(context),
      ],
    );
  }

  Widget _buildItemDetailsStep(BuildContext context) {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;
    final quickWeights = [1.0, 4.5, 7.0, 12.0, 15.0, 18.0, 25.0];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _WeightStepRouteSummary(
          pickupAddress: _draft.from,
          dropAddress: _draft.to,
          onEditTap: () async {
            final selection = await _openLocationDetailsScreen(
              _LocationFieldKind.pickup,
            );
            if (selection == null || !mounted) {
              return;
            }
            setState(() {
              _draft = _draft.copyWith(
                from: selection.formattedAddress,
                pickupLat: selection.latitude,
                pickupLng: selection.longitude,
                city: selection.city.isNotEmpty ? selection.city : _draft.city,
              );
              _fromController.text = selection.formattedAddress;
            });
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _WeightStepActionChip(
                label: 'Loading point',
                icon: AppIcons.add_location_alt_rounded,
                onPressed: () async {
                  await _addIntermediateStop(loading: true);
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _WeightStepActionChip(
                label: 'Unloading point',
                icon: AppIcons.add_road_rounded,
                onPressed: () async {
                  await _addIntermediateStop(loading: false);
                },
              ),
            ),
          ],
        ),
        if (_draft.loadingStops.isNotEmpty ||
            _draft.unloadingStops.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IntermediateStopsList(
            loadingStops: _draft.loadingStops,
            unloadingStops: _draft.unloadingStops,
            onRemoveLoading: (index) =>
                _removeIntermediateStop(loading: true, index: index),
            onRemoveUnloading: (index) =>
                _removeIntermediateStop(loading: false, index: index),
          ),
        ],
        if (_draft.transportType == 'intra') ...[
          const SizedBox(height: 12),
          _ExpressDeliveryOptionCard(
            selected: _draft.isExpress,
            loading: _loadingExpressQuote,
            surcharge: _draft.expressSurcharge,
            expectedDeliveryHours: _draft.expectedDeliveryHours,
            insuranceIncluded: _draft.expressInsuranceIncluded,
            onChanged: (value) => unawaited(_setExpressDelivery(value)),
          ),
        ],
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
          decoration: BoxDecoration(
            color: context.colors.brandFill,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: _weightError != null
                  ? const Color(0xFFE23A4B)
                  : context.colors.brandBorder,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0B1F3A).withValues(alpha: 0.06),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA56E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      AppIcons.scale_rounded,
                      color: Color(0xFF2FA56E),
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Material weight',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 7, 14, 7),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _weightController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: context.colors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w500,
                              height: 1.12,
                            ),
                        onSubmitted: (_) {
                          FocusScope.of(context).unfocus();
                        },
                        onChanged: (_) {
                          if (_weightUnknown || _weightError != null) {
                            setState(() {
                              _weightUnknown = false;
                              _weightError = null;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          hintText: '0.0',
                          filled: false,
                          fillColor: Colors.transparent,
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'ton',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_weightError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _weightError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFFE23A4B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickWeights
                    .map(
                      (value) => _WeightChip(
                        label:
                            '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}t',
                        selected:
                            !_weightUnknown && (weight - value).abs() < 0.001,
                        onTap: () {
                          setState(() {
                            _weightUnknown = false;
                            _weightError = null;
                            _weightController.text = value.toStringAsFixed(
                              value % 1 == 0 ? 0 : 1,
                            );
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleHeaderActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HeaderScheduleIconButton(
          icon: AppIcons.flash_on_rounded,
          tooltip: 'Book now',
          selected: !_draft.isScheduled,
          onTap: () {
            setState(() {
              _draft = _draft.copyWith(isScheduled: false);
            });
          },
        ),
        const SizedBox(width: 8),
        _HeaderScheduleIconButton(
          icon: AppIcons.event_available_rounded,
          tooltip: _draft.scheduledDate == null
              ? 'Book later'
              : 'Book later: ${_formatDateTime(_draft.scheduledDate!)}',
          selected: _draft.isScheduled,
          onTap: _pickScheduledDateTime,
        ),
      ],
    );
  }

  Widget _buildWeightBottomActions(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 12, 18, bottomInset + 12),
      decoration: BoxDecoration(
        color: context.colors.surface,
        border: Border(top: BorderSide(color: context.colors.line)),
      ),
      child: Row(
        children: [
          Expanded(
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _advanceFromWeightStep(unknown: true),
              style: FilledButton.styleFrom(
                backgroundColor: context.colors.fillSubtle,
                foregroundColor: context.colors.textSecondary,
                minimumSize: const Size.fromHeight(54),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _submitting
                  ? null
                  : () => _advanceFromWeightStep(unknown: _weightUnknown),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              icon: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              label: const Icon(AppIcons.chevron_right_rounded, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_draft.isExpress) ...[
          _ExpressBookingSummaryCard(
            surcharge: _draft.expressSurcharge,
            expectedDeliveryHours: _draft.expectedDeliveryHours,
            insuranceIncluded: _draft.expressInsuranceIncluded,
          ),
          const SizedBox(height: 12),
        ],
        if (_draft.estimatedDeliveryDate != null ||
            _draft.expectedDeliveryHours != null) ...[
          _DeliveryEstimateCard(
            estimatedDeliveryDate: _draft.estimatedDeliveryDate,
            estimatedDeliveryDays: _draft.estimatedDeliveryDays,
            expectedDeliveryHours: _draft.expectedDeliveryHours,
            isExpress: _draft.isExpress,
          ),
          const SizedBox(height: 12),
        ],
        if (_haltingNote != null) ...[
          _HaltingInfoCard(message: _haltingNote!),
          const SizedBox(height: 12),
        ],
        _CheckoutChoiceCard(
          selectedMethod: _selectedPaymentMethod,
          advanceAmount: _advanceAmount,
          loadingAdvanceAmount: _loadingAdvanceAmount,
          allowToBeBilled:
              _postNegotiationPayment && _activeBookingId?.isNotEmpty == true,
          onSelect: (method) {
            setState(() => _selectedPaymentMethod = method);
          },
        ),
      ],
    );
  }

  Widget _buildPaymentMapSheetStep(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final view = View.of(context);
    final viewBottomInset =
        max(view.padding.bottom, view.viewPadding.bottom) /
        view.devicePixelRatio;
    final bottomSystemInset = max(
      max(mediaQuery.viewPadding.bottom, mediaQuery.padding.bottom),
      viewBottomInset,
    );
    final isAndroid = Theme.of(context).platform == TargetPlatform.android;
    final contentBottomPadding = isAndroid
        ? max(bottomSystemInset, 28.0)
        : bottomSystemInset;
    final selectedMethod = _selectedPaymentMethod;
    final amount = _draft.amount > 0
        ? _draft.amount
        : _priceValue(_vehicle.price);
    final allowToBeBilled =
        _postNegotiationPayment && _activeBookingId?.isNotEmpty == true;
    final advanceSubtitle = _loadingAdvanceAmount
        ? 'Fetching advance'
        : _advanceAmount == null
        ? 'Advance unavailable'
        : '${_formatRupees(_advanceAmount!)} now';
    final fullSelected =
        selectedMethod != PaymentMethod.advance &&
        selectedMethod != PaymentMethod.payLater &&
        selectedMethod != PaymentMethod.toBeBilled;
    final ctaLabel = selectedMethod == PaymentMethod.payLater
        ? 'Confirm To Pay'
        : selectedMethod == PaymentMethod.toBeBilled
        ? 'Confirm Billing'
        : selectedMethod == PaymentMethod.advance
        ? 'Pay Advance'
        : 'Pay Securely';

    return LayoutBuilder(
      builder: (context, constraints) {
        final sheetHeight = min(constraints.maxHeight * 0.48, 350.0);
        final paymentBottomPadding = contentBottomPadding + 10;
        return Stack(
          fit: StackFit.expand,
          children: [
            _buildBrokerMap(context, const <NearbyTruck>[]),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.10),
                        Colors.black.withValues(alpha: 0.34),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: IconButton(
                    onPressed: () {
                      if (_bookingCreated && _postNegotiationPayment) {
                        _resetUnpaidPaymentBookingForRetry(
                          step: _BookingFlowStep.brokerSelection,
                        );
                        return;
                      }
                      setState(() => _step = _BookingFlowStep.brokerSelection);
                    },
                    icon: Icon(AppIcons.arrow_back_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: context.colors.surface.withValues(alpha: 0.94),
                      foregroundColor: context.colors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                ignoring: _paymentCompletionVisible,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOutCubic,
                  offset: _paymentCompletionVisible
                      ? const Offset(0, 1.08)
                      : Offset.zero,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 240),
                    opacity: _paymentCompletionVisible ? 0 : 1,
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: sheetHeight + paymentBottomPadding,
                      ),
                      padding: EdgeInsets.fromLTRB(
                        0,
                        16,
                        0,
                        paymentBottomPadding,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceElevated,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(30),
                        ),
                        border: Border.all(color: context.colors.line),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 30,
                            offset: const Offset(0, -12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Choose payment',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              color: context.colors.textPrimary,
                                              fontWeight: FontWeight.w900,
                                            ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'Map stays live while you finish checkout.',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: context.colors.textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: context.colors.brandFill,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    _formatRupees(amount),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: context.colors.brandEmphasis,
                                          fontWeight: FontWeight.w900,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: 112,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.zero,
                              children: [
                                _CheckoutMethodCard(
                                  title: 'Pay Now',
                                  subtitle: 'Secure checkout',
                                  icon: AppIcons.lock_outline_rounded,
                                  selected: fullSelected,
                                  enabled: true,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod =
                                        PaymentMethod.googlePay,
                                  ),
                                ),
                                _CheckoutMethodCard(
                                  title: 'Advance',
                                  subtitle: advanceSubtitle,
                                  icon: _loadingAdvanceAmount
                                      ? AppIcons.hourglass_top_rounded
                                      : AppIcons.payments_outlined,
                                  selected:
                                      selectedMethod == PaymentMethod.advance,
                                  enabled:
                                      _advanceAmount != null &&
                                      !_loadingAdvanceAmount,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod =
                                        PaymentMethod.advance,
                                  ),
                                ),
                                _CheckoutMethodCard(
                                  title: 'To Pay',
                                  subtitle: 'Pay on delivery',
                                  icon: AppIcons.local_shipping_outlined,
                                  selected:
                                      selectedMethod == PaymentMethod.payLater,
                                  enabled: true,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod =
                                        PaymentMethod.payLater,
                                  ),
                                ),
                                _CheckoutMethodCard(
                                  title: 'To Be Billed',
                                  subtitle: allowToBeBilled
                                      ? 'No collection now'
                                      : 'After driver confirm',
                                  icon: AppIcons.receipt_long_outlined,
                                  selected:
                                      selectedMethod ==
                                      PaymentMethod.toBeBilled,
                                  enabled: allowToBeBilled,
                                  onTap: () => setState(
                                    () => _selectedPaymentMethod =
                                        PaymentMethod.toBeBilled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _submitting ? null : _next,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF2FA56E),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size.fromHeight(52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: _submitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(ctaLabel),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_paymentCompletionVisible)
              const Positioned.fill(child: _BookingCompleteOverlay()),
          ],
        );
      },
    );
  }

  Future<void> _loadAdvanceAmount() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
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

  Widget _buildSuccessStep(BuildContext context) {
    return _BookingSuccessCard(
      bookingReference: _bookingReference,
      title: _draft.isScheduled ? 'Booking scheduled' : 'Booking confirmed',
      message: _draft.isScheduled
          ? 'We will notify drivers or brokers closer to your pickup time.'
          : 'Your booking has been successfully placed.',
      onTrack: () => context.go('/client/tracking'),
      onHome: _goToClientHome,
    );
  }

  Widget _buildWaitingStep(BuildContext context) {
    return _BookingWaitingCard(
      bookingReference: _bookingReference,
      driverRequest: _driverRequest,
      requestCount: _findTruckRequestCount,
      declinedCount: _findTruckDeclinedCount,
      searchRadiusKm: _draft.searchRadiusKm,
      showActions: true,
      onTrack: () => context.go('/client/tracking'),
      onHome: _goToClientHome,
    );
  }

  void _goToClientHome() {
    _bottomNavVisibleController.state = true;
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        router.go('/client/home');
      });
      return;
    }
    router.go('/client/home');
  }
}
