part of '../client_flow_widgets.dart';

enum TripType { interCity, intraCity }

enum _LocationFieldKind { pickup, drop }

enum _MapPinTarget { pickup, drop }

class BookingStop {
  const BookingStop({
    required this.location,
    required this.lat,
    required this.lng,
  });

  final String location;
  final double lat;
  final double lng;

  LatLng get latLng => LatLng(lat, lng);

  Map<String, dynamic> toPayload() => <String, dynamic>{
    'location': location,
    'lat': lat,
    'lng': lng,
  };
}

class _SavedLocationShortcut {
  const _SavedLocationShortcut({
    required this.id,
    required this.label,
    required this.address,
    this.latitude,
    this.longitude,
    this.city = '',
    this.addressType = 'pickup',
  });

  final String id;
  final String label;
  final String address;
  final double? latitude;
  final double? longitude;
  final String city;
  final String addressType;

  factory _SavedLocationShortcut.fromJson(Map<String, dynamic> json) {
    return _SavedLocationShortcut(
      id: _locationString(json, const ['id']),
      label: _locationString(json, const ['label']).isEmpty
          ? 'Saved address'
          : _locationString(json, const ['label']),
      address: _locationString(json, const ['address']),
      latitude: _locationDouble(json, const ['lat', 'latitude']),
      longitude: _locationDouble(json, const ['lng', 'longitude']),
      city: _locationString(json, const ['city']),
      addressType: _locationString(json, const [
        'addressType',
        'address_type',
      ]).toLowerCase(),
    );
  }
}

String _locationString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

double? _locationDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

class _LocationDetailsScreen extends ConsumerStatefulWidget {
  const _LocationDetailsScreen({
    required this.kind,
    required this.initialValue,
    this.title,
    this.subtitle,
    this.mapButtonLabel = 'Select on map',
    this.showCurrentLocation,
  });

  final _LocationFieldKind kind;
  final String initialValue;
  final String? title;
  final String? subtitle;
  final String mapButtonLabel;
  final bool? showCurrentLocation;

  @override
  ConsumerState<_LocationDetailsScreen> createState() =>
      _LocationDetailsScreenState();
}

class _LocationDetailsScreenState
    extends ConsumerState<_LocationDetailsScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final Random _random = Random();
  Timer? _debounce;
  String _sessionToken = '';
  bool _loadingSuggestions = false;
  bool _selectingSuggestion = false;
  String? _errorMessage;
  List<GooglePlaceSuggestion> _suggestions = const [];
  List<_SavedLocationShortcut> _savedAddresses = const [];
  bool _resolvingCurrentLocation = false;
  bool _applyingLocationSelection = false;
  GooglePlaceSelection? _pendingLocationSelection;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    _sessionToken = _newSessionToken();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    unawaited(_loadSavedAddresses());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final shouldAutofillCurrentLocation =
          _showCurrentLocation &&
          widget.kind == _LocationFieldKind.pickup &&
          _controller.text.trim().isEmpty;
      if (shouldAutofillCurrentLocation) {
        unawaited(
          Future<void>.delayed(const Duration(milliseconds: 350), () {
            if (mounted && _controller.text.trim().isEmpty) {
              return _useCurrentLocation();
            }
          }),
        );
      } else {
        _focusNode.requestFocus();
      }
    });
  }

  Future<void> _loadSavedAddresses() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    try {
      final response = await ref
          .read(apiClientProvider)
          .getSavedAddresses(accessToken: session.tokens.accessToken);
      if (!mounted) return;
      final payload = response['data'];
      final data = payload is Map<String, dynamic> ? payload : response;
      final raw =
          data['addresses'] ??
          data['items'] ??
          data['results'] ??
          data['rows'] ??
          data['data'];
      if (raw is! List) return;
      setState(() {
        _savedAddresses = raw
            .whereType<Map>()
            .map(
              (item) =>
                  _SavedLocationShortcut.fromJson(item.cast<String, dynamic>()),
            )
            .where(
              (address) => address.id.isNotEmpty && address.address.isNotEmpty,
            )
            .toList(growable: false);
      });
    } catch (_) {
      // Saved addresses are a convenience; autocomplete remains available.
    }
  }

  List<_SavedLocationShortcut> get _matchingSavedAddresses {
    final isDropoff = widget.kind == _LocationFieldKind.drop;
    return _savedAddresses
        .where(
          (address) => isDropoff
              ? address.addressType == 'dropoff'
              : address.addressType != 'dropoff',
        )
        .take(8)
        .toList(growable: false);
  }

  void _selectSavedAddress(_SavedLocationShortcut address) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(
      GooglePlaceSelection(
        placeId: '',
        formattedAddress: address.address,
        latitude: address.latitude,
        longitude: address.longitude,
        city: address.city,
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_selectingSuggestion) {
      return;
    }
    if (_focusNode.hasFocus && _controller.text.trim().isNotEmpty) {
      _scheduleSearch();
      return;
    }
    if (!_focusNode.hasFocus) {
      setState(() {
        _suggestions = const [];
      });
    }
  }

  void _onTextChanged() {
    if (_applyingLocationSelection) {
      return;
    }
    if (_selectingSuggestion) {
      return;
    }
    _pendingLocationSelection = null;
    if (!_focusNode.hasFocus) {
      return;
    }
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() {
        _suggestions = const [];
        _errorMessage = null;
      });
      _sessionToken = _newSessionToken();
      return;
    }
    _scheduleSearch();
    setState(() {});
  }

  void _applyLocationSelection(GooglePlaceSelection selection) {
    _applyingLocationSelection = true;
    _controller
      ..text = selection.formattedAddress
      ..selection = TextSelection.collapsed(offset: _controller.text.length);
    _applyingLocationSelection = false;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _pendingLocationSelection = selection;
      _suggestions = const [];
      _errorMessage = null;
      _sessionToken = _newSessionToken();
    });
  }

  void _submitLocation() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }
    final pending = _pendingLocationSelection;
    Navigator.of(context).pop(
      pending != null && pending.formattedAddress.trim() == text
          ? pending
          : GooglePlaceSelection(
              placeId: '',
              formattedAddress: text,
              latitude: null,
              longitude: null,
              city: '',
            ),
    );
  }

  void _scheduleSearch() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), _search);
  }

  Future<void> _search() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _loadingSuggestions = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(googlePlacesServiceProvider);
      final suggestions = await service.autocomplete(
        input: text,
        sessionToken: _sessionToken,
      );
      if (!mounted) return;
      setState(() {
        _suggestions = suggestions;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _suggestions = const [];
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
        });
      }
    }
  }

  Future<void> _selectSuggestion(GooglePlaceSuggestion suggestion) async {
    setState(() {
      _loadingSuggestions = true;
      _errorMessage = null;
      _selectingSuggestion = true;
      _suggestions = const [];
    });

    try {
      FocusManager.instance.primaryFocus?.unfocus();
      final service = ref.read(googlePlacesServiceProvider);
      final selection = await service.fetchPlaceSelection(
        placeId: suggestion.placeId,
      );
      if (!mounted) return;
      _controller
        ..text = selection.formattedAddress.isNotEmpty
            ? selection.formattedAddress
            : suggestion.description
        ..selection = TextSelection.collapsed(offset: _controller.text.length);
      Navigator.of(context).pop(
        GooglePlaceSelection(
          placeId: selection.placeId,
          formattedAddress: _controller.text,
          latitude: selection.latitude,
          longitude: selection.longitude,
          city: selection.city,
        ),
      );
      setState(() {
        _sessionToken = _newSessionToken();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingSuggestions = false;
          _selectingSuggestion = false;
        });
      }
    }
  }

  String _newSessionToken() {
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final randomPart = _random.nextInt(1 << 32).toRadixString(36);
    return '$timestamp$randomPart'.substring(
      0,
      min(36, timestamp.length + randomPart.length),
    );
  }

  String get _hintText => widget.kind == _LocationFieldKind.pickup
      ? 'Enter your loading address'
      : 'Enter your unloading address';

  String get _title =>
      widget.title ??
      (widget.kind == _LocationFieldKind.pickup
          ? 'Loading location'
          : 'Unloading location');

  String get _subtitle =>
      widget.subtitle ??
      (widget.kind == _LocationFieldKind.pickup
          ? 'Search, use current location, or select the pickup point on map.'
          : 'Search or select the drop point on map.');

  String get _useCurrentLocationLabel =>
      widget.kind == _LocationFieldKind.pickup
      ? 'Use your current location'
      : 'Use current location';

  IconData get _fieldIcon => widget.kind == _LocationFieldKind.pickup
      ? AppIcons.arrow_upward_rounded
      : AppIcons.arrow_downward_rounded;

  Color get _fieldIconColor => widget.kind == _LocationFieldKind.pickup
      ? const Color(0xFF38B47A)
      : const Color(0xFFF05252);

  bool get _showCurrentLocation =>
      widget.showCurrentLocation ?? widget.kind == _LocationFieldKind.pickup;

  Future<void> _useCurrentLocation() async {
    if (!_showCurrentLocation || _resolvingCurrentLocation) {
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

      _applyLocationSelection(
        GooglePlaceSelection(
          placeId: '',
          formattedAddress: address,
          latitude: position.latitude,
          longitude: position.longitude,
          city: '',
        ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 36,
                            height: 36,
                            child: Icon(AppIcons.arrow_back_rounded, size: 24),
                          ),
                        ),
                        const Spacer(),
                        OutlinedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(AppIcons.map_outlined, size: 17),
                          label: Text(widget.mapButtonLabel),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.colors.infoEmphasis,
                            side: const BorderSide(color: Color(0xFFD7E7F4)),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: context.colors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: context.colors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          margin: const EdgeInsets.only(top: 10),
                          decoration: BoxDecoration(
                            color: _fieldIconColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _fieldIcon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: context.colors.surface,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: context.colors.line,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 12,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    focusNode: _focusNode,
                                    textInputAction: TextInputAction.search,
                                    cursorColor: const Color(0xFF2D8EDB),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: context.colors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: _hintText,
                                      hintStyle: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            color: context.colors.textTertiary,
                                            fontWeight: FontWeight.w400,
                                            fontSize: 15,
                                          ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: Center(
                                    child: _loadingSuggestions
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : (_controller.text.isEmpty
                                              ? const SizedBox.shrink()
                                              : InkWell(
                                                  onTap: () {
                                                    _controller.clear();
                                                    _focusNode.requestFocus();
                                                  },
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        999,
                                                      ),
                                                  child: Padding(
                                                    padding: EdgeInsets.all(2),
                                                    child: Icon(
                                                      AppIcons.close_rounded,
                                                      size: 18,
                                                      color: context
                                                          .colors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_showCurrentLocation) ...[
                      const SizedBox(height: 18),
                      InkWell(
                        onTap: _resolvingCurrentLocation
                            ? null
                            : _useCurrentLocation,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Row(
                            children: [
                              _resolvingCurrentLocation
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      AppIcons.my_location_rounded,
                                      color: Color(0xFF2D8EDB),
                                      size: 24,
                                    ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _useCurrentLocationLabel,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: const Color(0xFF2D8EDB),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_resolvingCurrentLocation) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Fetching your current location...',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: context.colors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Container(height: 1, color: context.colors.divider),
                    ],
                    if (_matchingSavedAddresses.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Saved addresses',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: context.colors.textTertiary,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final address in _matchingSavedAddresses) ...[
                              ActionChip(
                                avatar: Icon(
                                  widget.kind == _LocationFieldKind.pickup
                                      ? AppIcons.upload_rounded
                                      : AppIcons.download_rounded,
                                  size: 16,
                                  color:
                                      widget.kind == _LocationFieldKind.pickup
                                      ? const Color(0xFF2FA56E)
                                      : const Color(0xFFE05252),
                                ),
                                label: Text(address.label),
                                onPressed: () => _selectSavedAddress(address),
                                backgroundColor: context.colors.brandFill,
                                side: BorderSide(
                                  color: context.colors.brandBorder,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ],
                        ),
                      ),
                    ],
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Could not load suggestions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.colors.dangerEmphasis,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_suggestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ..._suggestions.asMap().entries.map(
                        (entry) => Column(
                          children: [
                            _LocationSuggestionTile(
                              suggestion: entry.value,
                              onTap: () => _selectSuggestion(entry.value),
                            ),
                            if (entry.key != _suggestions.length - 1)
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 2),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: context.colors.divider,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              child: Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed:
                      _controller.text.trim().isEmpty ||
                          _resolvingCurrentLocation
                      ? null
                      : _submitLocation,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2FA56E),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(58, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Icon(AppIcons.arrow_forward_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openMapPicker() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final selection = await Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        builder: (context) => _MapLocationPickerScreen(kind: widget.kind),
      ),
    );
    if (selection == null || !mounted) {
      return;
    }

    _controller
      ..text = selection.formattedAddress
      ..selection = TextSelection.collapsed(offset: _controller.text.length);
    Navigator.of(context).pop(selection);
  }
}

class _IntermediateStopDetailsScreen extends StatelessWidget {
  const _IntermediateStopDetailsScreen({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return _LocationDetailsScreen(
      kind: loading ? _LocationFieldKind.pickup : _LocationFieldKind.drop,
      initialValue: '',
      title: loading ? 'Add loading point' : 'Add unloading point',
      subtitle: loading
          ? 'Add another pickup stop before the main route continues.'
          : 'Add another drop stop before the final delivery.',
      mapButtonLabel: loading ? 'Pin loading point' : 'Pin unloading point',
      showCurrentLocation: loading,
    );
  }
}

class _MapLocationPickerScreen extends ConsumerStatefulWidget {
  const _MapLocationPickerScreen({required this.kind});

  final _LocationFieldKind kind;

  @override
  ConsumerState<_MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState
    extends ConsumerState<_MapLocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(19.0760, 72.8777);

  GoogleMapController? _mapController;
  LatLng _center = _defaultCenter;
  LatLng? _ownLocation;
  bool _locationPermissionGranted = false;
  bool _locatingOwnLocation = false;
  bool _resolving = false;
  bool _dragging = false;

  String get _locationLabel =>
      widget.kind == _LocationFieldKind.pickup ? 'pickup' : 'drop-off';

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentPosition());
  }

  Future<LatLng?> _loadCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      if (mounted) {
        setState(() {
          _locationPermissionGranted = true;
        });
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return null;
      final center = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = center;
        _ownLocation = center;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(center, 15),
      );
      return center;
    } catch (_) {
      // The picker remains usable from the default map center.
      return null;
    }
  }

  Future<void> _returnToOwnLocation() async {
    if (_locatingOwnLocation) {
      return;
    }
    setState(() {
      _locatingOwnLocation = true;
    });
    try {
      if (_ownLocation == null) {
        await _loadCurrentPosition();
      }
      final ownLocation = _ownLocation;
      if (ownLocation == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your location is not available yet.')),
        );
        return;
      }
      setState(() {
        _center = ownLocation;
      });
      await _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(ownLocation, 15),
      );
    } finally {
      if (mounted) {
        setState(() {
          _locatingOwnLocation = false;
        });
      }
    }
  }

  Future<void> _confirmLocation() async {
    if (_resolving) {
      return;
    }
    setState(() {
      _resolving = true;
    });
    try {
      final address = await ref
          .read(googlePlacesServiceProvider)
          .reverseGeocode(
            latitude: _center.latitude,
            longitude: _center.longitude,
          );
      if (!mounted) return;
      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not resolve this map point.')),
        );
        return;
      }
      Navigator.of(context).pop(
        GooglePlaceSelection(
          placeId: '',
          formattedAddress: address,
          latitude: _center.latitude,
          longitude: _center.longitude,
        ),
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
          _resolving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            style: ClientMapTheme.styleFor(context),
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              final ownLocation = _ownLocation;
              if (ownLocation != null) {
                unawaited(
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(ownLocation, 15),
                  ),
                );
              }
            },
            onCameraMove: (position) {
              _center = position.target;
            },
            onCameraMoveStarted: () {
              if (!_dragging && mounted) {
                setState(() {
                  _dragging = true;
                });
              }
            },
            onCameraIdle: () {
              if (_dragging && mounted) {
                setState(() {
                  _dragging = false;
                });
              }
            },
          ),
          Center(child: _CenterPin(lifted: _dragging)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(6, 6, 18, 6),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: context.colors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.10),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MapCircleButton(
                          icon: AppIcons.arrow_back_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Set $_locationLabel location',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: context.colors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _MapCircleButton(
                    icon: AppIcons.my_location_rounded,
                    loading: _locatingOwnLocation,
                    onTap: _locatingOwnLocation ? () {} : _returnToOwnLocation,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: context.colors.line),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 28,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: context.colors.line,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: context.colors.fillSubtle,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: context.colors.brandFill,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  AppIcons.location_on_rounded,
                                  color: context.colors.brandEmphasis,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Move the map to position the pin',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color:
                                                context.colors.textPrimary,
                                          ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'The exact address will be detected after you confirm.',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color:
                                                context.colors.textSecondary,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _resolving ? null : _confirmLocation,
                          icon: _resolving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(AppIcons.check_rounded),
                          label: Text(
                            _resolving
                                ? 'Finding address...'
                                : 'Use this $_locationLabel',
                          ),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
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
        ],
      ),
    );
  }
}

class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      shape: CircleBorder(
        side: BorderSide(color: context.colors.line),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: loading
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context.colors.textSecondary,
                    ),
                  ),
                )
              : Icon(icon, color: context.colors.textPrimary),
        ),
      ),
    );
  }
}

/// Brand center pin with a ground shadow. Lifts while the camera moves,
/// Uber-style, so the user feels the pin detach from the map.
class _CenterPin extends StatelessWidget {
  const _CenterPin({required this.lifted});

  final bool lifted;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        width: 76,
        height: 76,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 9,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                width: lifted ? 24 : 34,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(
                    alpha: lifted ? 0.16 : 0.28,
                  ),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            AnimatedSlide(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              offset: lifted ? const Offset(0, -0.22) : Offset.zero,
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(
                        0xFF2FA56E,
                      ).withValues(alpha: lifted ? 0.55 : 0.40),
                      blurRadius: lifted ? 22 : 14,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: const Icon(
                  AppIcons.location_on_rounded,
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

class _LocationSuggestionTile extends StatelessWidget {
  const _LocationSuggestionTile({
    required this.suggestion,
    required this.onTap,
  });

  final GooglePlaceSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.colors.fillSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  AppIcons.location_on_outlined,
                  size: 18,
                  color: context.colors.textTertiary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suggestion.mainText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (suggestion.secondaryText.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        suggestion.secondaryText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colors.textTertiary,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (suggestion.distanceMeters != null) ...[
                const SizedBox(width: 10),
                Text(
                  '${(suggestion.distanceMeters! / 1000).toStringAsFixed(suggestion.distanceMeters! >= 1000 ? 1 : 0)} km',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colors.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension TripTypeDisplayLabel on TripType {
  String get displayLabel => switch (this) {
    TripType.interCity => 'Full truck',
    TripType.intraCity => 'Part truck',
  };

  String get helperText => switch (this) {
    TripType.interCity => 'Dedicated truck for one shipment',
    TripType.intraCity => 'Share capacity and optimize cost',
  };
}
