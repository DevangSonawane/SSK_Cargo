import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/services/booking_payment_gateway.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../../core/widgets/truck_marker_icon.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';

enum TripType { interCity, intraCity }

enum _LocationFieldKind { pickup, drop }

enum _MapPinTarget { pickup, drop }

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
  });

  final _LocationFieldKind kind;
  final String initialValue;

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
      if (mounted) {
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
    if (_selectingSuggestion) {
      return;
    }
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

  String get _useCurrentLocationLabel =>
      widget.kind == _LocationFieldKind.pickup
      ? 'Use your current location'
      : 'Use current location';

  IconData get _fieldIcon => widget.kind == _LocationFieldKind.pickup
      ? Icons.arrow_upward_rounded
      : Icons.arrow_downward_rounded;

  Color get _fieldIconColor => widget.kind == _LocationFieldKind.pickup
      ? const Color(0xFF38B47A)
      : const Color(0xFFF05252);

  Future<void> _useCurrentLocation() async {
    if (widget.kind != _LocationFieldKind.pickup || _resolvingCurrentLocation) {
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

      Navigator.of(context).pop(
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
                      child: Icon(Icons.arrow_back_rounded, size: 24),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: _openMapPicker,
                    icon: const Icon(Icons.map_outlined, size: 17),
                    label: const Text('Select on map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1F88C9),
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
              const SizedBox(height: 22),
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
                    child: Icon(_fieldIcon, color: Colors.white, size: 18),
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE7EEF6)),
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
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: const Color(0xFF101828),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                              decoration: InputDecoration(
                                hintText: _hintText,
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: const Color(0xFF98A2B3),
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
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(2),
                                              child: Icon(
                                                Icons.close_rounded,
                                                size: 18,
                                                color: Color(0xFF667085),
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
              if (widget.kind == _LocationFieldKind.pickup) ...[
                const SizedBox(height: 18),
                InkWell(
                  onTap: _resolvingCurrentLocation ? null : _useCurrentLocation,
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
                                Icons.my_location_rounded,
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
                const SizedBox(height: 18),
                Container(height: 1, color: const Color(0xFFE6EAF0)),
              ],
              if (_matchingSavedAddresses.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  'Saved addresses',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF98A2B3),
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
                                ? Icons.upload_rounded
                                : Icons.download_rounded,
                            size: 16,
                            color: widget.kind == _LocationFieldKind.pickup
                                ? const Color(0xFF2FA56E)
                                : const Color(0xFFE05252),
                          ),
                          label: Text(address.label),
                          onPressed: () => _selectSavedAddress(address),
                          backgroundColor: const Color(0xFFF0F7F3),
                          side: const BorderSide(color: Color(0xFFD7EBDD)),
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
                    color: const Color(0xFFB42318),
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
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 2),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: Color(0xFFE6EAF0),
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
  bool _resolving = false;
  String? _address;

  String get _locationLabel =>
      widget.kind == _LocationFieldKind.pickup ? 'pickup' : 'drop-off';

  @override
  void initState() {
    super.initState();
    _loadCurrentPosition();
  }

  Future<void> _loadCurrentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
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
      if (!mounted) return;
      final center = LatLng(position.latitude, position.longitude);
      setState(() {
        _center = center;
        _ownLocation = center;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLng(center));
    } catch (_) {
      // The picker remains usable from the default map center.
    }
  }

  Future<void> _returnToOwnLocation() async {
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
            initialCameraPosition: CameraPosition(target: _center, zoom: 15),
            myLocationEnabled: _locationPermissionGranted,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            compassEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: (position) {
              _center = position.target;
              _address = null;
            },
          ),
          const IgnorePointer(
            child: Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 48,
                color: Color(0xFFE53935),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  _MapCircleButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Set $_locationLabel location',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
                      ),
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
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Move the map to position the pin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _address ??
                          'The exact address will be detected after you confirm.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _returnToOwnLocation,
                        icon: const Icon(Icons.my_location_rounded, size: 18),
                        label: const Text('Use my location'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F88C9),
                          side: const BorderSide(color: Color(0xFFD7E7F4)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
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
                            : const Icon(Icons.check_rounded),
                        label: Text(
                          _resolving
                              ? 'Finding address...'
                              : 'Use this $_locationLabel',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE53935),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
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

class _MapCircleButton extends StatelessWidget {
  const _MapCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: const Color(0xFF101828)),
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
                decoration: const BoxDecoration(
                  color: Color(0xFFF2F4F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                  color: Color(0xFF98A2B3),
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
                        color: const Color(0xFF101828),
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
                          color: const Color(0xFF98A2B3),
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
                    color: const Color(0xFF98A2B3),
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

class BookingData {
  const BookingData({
    required this.from,
    required this.to,
    required this.tripType,
    this.city = '',
    this.vehicle,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.material = '',
    this.additionalNotes = '',
    this.weight = 0,
    this.quantity = 1,
    this.weightUnit = 'tons',
    this.truckCategory = '',
    this.scheduledDate,
    this.distance = 0,
    this.durationMin,
    this.durationInTrafficMin,
    this.amount = 0,
    this.brokerId = '',
    this.truckId = '',
    this.isScheduled = false,
    this.searchMode,
    this.searchRadiusKm = 15,
    this.selectedBrokerId = '',
    this.paymentMode = PaymentMode.payLater,
    this.selectedPaymentLabel = '',
  });

  final String from;
  final String to;
  final TripType tripType;
  final String city;
  final VehicleOption? vehicle;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String material;
  final String additionalNotes;
  final double weight;
  final int quantity;
  final String weightUnit;
  final String truckCategory;
  final DateTime? scheduledDate;
  final double distance;
  final int? durationMin;
  final int? durationInTrafficMin;
  final double amount;
  final String brokerId;
  final String truckId;
  final bool isScheduled;
  final BookingSearchMode? searchMode;
  final double searchRadiusKm;
  final String selectedBrokerId;
  final PaymentMode paymentMode;
  final String selectedPaymentLabel;

  String get transportType =>
      tripType == TripType.interCity ? 'inter' : 'intra';
  String get truckType => vehicle?.label ?? '';
  String get weightText => weight > 0 ? '$weight $weightUnit' : '';
  String get distanceText => distance > 0
      ? '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km'
      : '';
  String get amountText =>
      amount > 0 ? '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}' : '';

  BookingData copyWith({
    String? from,
    String? to,
    TripType? tripType,
    String? city,
    VehicleOption? vehicle,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? material,
    String? additionalNotes,
    double? weight,
    int? quantity,
    String? weightUnit,
    String? truckCategory,
    DateTime? scheduledDate,
    double? distance,
    int? durationMin,
    int? durationInTrafficMin,
    double? amount,
    String? brokerId,
    String? truckId,
    bool? isScheduled,
    BookingSearchMode? searchMode,
    double? searchRadiusKm,
    String? selectedBrokerId,
    PaymentMode? paymentMode,
    String? selectedPaymentLabel,
  }) {
    return BookingData(
      from: from ?? this.from,
      to: to ?? this.to,
      tripType: tripType ?? this.tripType,
      city: city ?? this.city,
      vehicle: vehicle ?? this.vehicle,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      material: material ?? this.material,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      weightUnit: weightUnit ?? this.weightUnit,
      truckCategory: truckCategory ?? this.truckCategory,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      distance: distance ?? this.distance,
      durationMin: durationMin ?? this.durationMin,
      durationInTrafficMin: durationInTrafficMin ?? this.durationInTrafficMin,
      amount: amount ?? this.amount,
      brokerId: brokerId ?? this.brokerId,
      truckId: truckId ?? this.truckId,
      isScheduled: isScheduled ?? this.isScheduled,
      searchMode: searchMode ?? this.searchMode,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      selectedBrokerId: selectedBrokerId ?? this.selectedBrokerId,
      paymentMode: paymentMode ?? this.paymentMode,
      selectedPaymentLabel: selectedPaymentLabel ?? this.selectedPaymentLabel,
    );
  }
}

double? _routeDistanceKm(Iterable<LatLng> points) {
  final values = points.toList(growable: false);
  if (values.length < 2) {
    return null;
  }

  var meters = 0.0;
  for (var index = 1; index < values.length; index++) {
    final previous = values[index - 1];
    final current = values[index];
    meters += Geolocator.distanceBetween(
      previous.latitude,
      previous.longitude,
      current.latitude,
      current.longitude,
    );
  }
  return meters / 1000;
}

enum PaymentMode { payNow, payLater }

enum PaymentMethod {
  googlePay,
  phonePe,
  paytm,
  otherUpi,
  card,
  cashOnDelivery,
  netBanking,
  emi,
  payLater,
  advance,
}

const double _advancePaymentThreshold = 5000.0;
const double _advancePaymentPct = 0.2;

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    return switch (this) {
      PaymentMethod.googlePay => 'Google Pay',
      PaymentMethod.phonePe => 'PhonePe',
      PaymentMethod.paytm => 'PayTM',
      PaymentMethod.otherUpi => 'Other UPI',
      PaymentMethod.card => 'Card',
      PaymentMethod.cashOnDelivery => 'Cash On Delivery',
      PaymentMethod.netBanking => 'Net Banking',
      PaymentMethod.emi => 'EMI',
      PaymentMethod.payLater => 'Pay later',
      PaymentMethod.advance => 'Pay 20% Advance',
    };
  }
}

class TruckSize {
  const TruckSize({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class VehicleOption {
  const VehicleOption({
    required this.label,
    required this.capacity,
    required this.price,
    required this.accentColor,
    required this.assetPath,
  });

  final String label;
  final String capacity;
  final String price;
  final Color accentColor;
  final String assetPath;
}

const vehicleOptions = <VehicleOption>[
  VehicleOption(
    label: 'Small truck',
    capacity: 'Up to 1 Ton',
    price: '₹899',
    accentColor: Color(0xFF2FA56E),
    assetPath: 'assets/trucks/small truck.png',
  ),
  VehicleOption(
    label: 'Medium truck',
    capacity: '1 - 5 Tons',
    price: '₹1,499',
    accentColor: Color(0xFF1F88C9),
    assetPath: 'assets/trucks/medium truck.png',
  ),
  VehicleOption(
    label: 'Big truck',
    capacity: '5 - 15 Tons',
    price: '₹2,299',
    accentColor: Color(0xFF7A5AF8),
    assetPath: 'assets/trucks/big truck.png',
  ),
  VehicleOption(
    label: 'Truck pooling',
    capacity: 'Shared Space',
    price: '₹499',
    accentColor: Color(0xFFF59E0B),
    assetPath: 'assets/trucks/truck pooling.png',
  ),
];

List<VehicleOption> resolveVehicleOptions({
  required TripType tripType,
  ClientPricingConfig? pricing,
  required bool isLoading,
}) {
  if (isLoading) {
    return vehicleOptions
        .map(
          (vehicle) => VehicleOption(
            label: vehicle.label,
            capacity: vehicle.capacity,
            price: 'Loading...',
            accentColor: vehicle.accentColor,
            assetPath: vehicle.assetPath,
          ),
        )
        .toList(growable: false);
  }

  if (pricing == null) {
    return vehicleOptions;
  }

  return vehicleOptions
      .map(
        (vehicle) => VehicleOption(
          label: vehicle.label,
          capacity: vehicle.capacity,
          price: _vehiclePriceLabel(
            label: vehicle.label,
            tripType: tripType,
            pricing: pricing,
            fallback: vehicle.price,
          ),
          accentColor: vehicle.accentColor,
          assetPath: vehicle.assetPath,
        ),
      )
      .toList(growable: false);
}

String _vehiclePriceLabel({
  required String label,
  required TripType tripType,
  required ClientPricingConfig pricing,
  required String fallback,
}) {
  if (tripType == TripType.intraCity) {
    final tier = _intraCityTierForVehicle(pricing, label);
    final baseFare = tier?.baseFare ?? 0;
    if (baseFare > 0) {
      final toll = tier?.tollFixedAmount ?? 0;
      if (toll > 0) {
        return '${_formatRupees(baseFare)} + toll ${_formatRupees(toll)}';
      }
      return _formatRupees(baseFare);
    }
    return fallback;
  }

  final interCityRate = pricing.interCity.baseRatePerKm;
  if (interCityRate > 0) {
    return '${_formatRupees(interCityRate)}/km';
  }

  return fallback;
}

String _formatRupees(double amount) {
  return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
}

String _formatDateTime(DateTime value) {
  final hour12 = value.hour == 0
      ? 12
      : value.hour > 12
      ? value.hour - 12
      : value.hour;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.day}/${value.month}/${value.year} at $hour12:$minute $period';
}

ClientTruckPricingTier? _intraCityTierForVehicle(
  ClientPricingConfig pricing,
  String label,
) {
  final text = label.toLowerCase();
  if (text.contains('small')) return pricing.intraCity.small;
  if (text.contains('medium')) return pricing.intraCity.medium;
  if (text.contains('big') || text.contains('large')) {
    return pricing.intraCity.large;
  }
  return pricing.intraCity.small;
}

class TrackingDemoShipment {
  const TrackingDemoShipment({
    required this.packageName,
    required this.trackingId,
    required this.fromLocation,
    required this.toLocation,
    required this.status,
    required this.customerName,
    required this.weight,
    required this.timeline,
    this.amount = 0,
    this.amountPaid = 0,
    this.paymentStatus = 'pending',
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.liveLat,
    this.liveLng,
    this.podUrl,
    this.ratingStars,
    this.tripId,
    this.bookingId,
    this.bookingStatus,
    this.assignedDriverName,
    this.assignedDriverPhone,
    this.assignedTruckName,
    this.pickupOtp,
    this.pickupOtpVerified = false,
  });

  TrackingDemoShipment copyWith({
    String? packageName,
    String? trackingId,
    String? fromLocation,
    String? toLocation,
    String? status,
    String? customerName,
    String? weight,
    List<TrackingTimelineStep>? timeline,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    double? liveLat,
    double? liveLng,
    String? bookingId,
    String? bookingStatus,
    String? assignedDriverName,
    String? assignedDriverPhone,
    String? assignedTruckName,
    String? tripId,
    double? amount,
    double? amountPaid,
    String? paymentStatus,
    String? podUrl,
    int? ratingStars,
    String? pickupOtp,
    bool? pickupOtpVerified,
    bool clearPickupLat = false,
    bool clearPickupLng = false,
    bool clearDropLat = false,
    bool clearDropLng = false,
    bool clearLiveLat = false,
    bool clearLiveLng = false,
  }) {
    return TrackingDemoShipment(
      packageName: packageName ?? this.packageName,
      trackingId: trackingId ?? this.trackingId,
      fromLocation: fromLocation ?? this.fromLocation,
      toLocation: toLocation ?? this.toLocation,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
      weight: weight ?? this.weight,
      timeline: timeline ?? this.timeline,
      pickupLat: clearPickupLat ? null : (pickupLat ?? this.pickupLat),
      pickupLng: clearPickupLng ? null : (pickupLng ?? this.pickupLng),
      dropLat: clearDropLat ? null : (dropLat ?? this.dropLat),
      dropLng: clearDropLng ? null : (dropLng ?? this.dropLng),
      liveLat: clearLiveLat ? null : (liveLat ?? this.liveLat),
      liveLng: clearLiveLng ? null : (liveLng ?? this.liveLng),
      podUrl: podUrl ?? this.podUrl,
      ratingStars: ratingStars ?? this.ratingStars,
      tripId: tripId ?? this.tripId,
      bookingId: bookingId ?? this.bookingId,
      bookingStatus: bookingStatus ?? this.bookingStatus,
      assignedDriverName: assignedDriverName ?? this.assignedDriverName,
      assignedDriverPhone: assignedDriverPhone ?? this.assignedDriverPhone,
      assignedTruckName: assignedTruckName ?? this.assignedTruckName,
      pickupOtp: pickupOtp ?? this.pickupOtp,
      pickupOtpVerified: pickupOtpVerified ?? this.pickupOtpVerified,
      amount: amount ?? this.amount,
      amountPaid: amountPaid ?? this.amountPaid,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  final String packageName;
  final String trackingId;
  final String fromLocation;
  final String toLocation;
  final String status;
  final String customerName;
  final String weight;
  final List<TrackingTimelineStep> timeline;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? liveLat;
  final double? liveLng;
  final double amount;
  final double amountPaid;
  final String paymentStatus;
  final String? podUrl;
  final int? ratingStars;
  final String? tripId;
  final String? bookingId;
  final String? bookingStatus;
  final String? assignedDriverName;
  final String? assignedDriverPhone;
  final String? assignedTruckName;
  final String? pickupOtp;
  final bool pickupOtpVerified;
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
      return value;
    }
  }
  return '';
}

String formatPaymentStatus(String status) {
  final normalized = status.trim().toLowerCase();
  if (normalized.isEmpty) {
    return 'Pending';
  }
  switch (normalized) {
    case 'paid':
      return 'Paid';
    case 'pending':
      return 'Pending';
    case 'failed':
      return 'Failed';
    case 'refunded':
      return 'Refunded';
    case 'partial':
    case 'partially_paid':
      return 'Partially paid';
    default:
      return normalized
          .split(RegExp(r'[_\s-]+'))
          .where((part) => part.isNotEmpty)
          .map((part) => part[0].toUpperCase() + part.substring(1))
          .join(' ');
  }
}

class TrackingTimelineStep {
  const TrackingTimelineStep({
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  final String title;
  final String subtitle;
  final bool completed;
}

class PickupOtpBanner extends StatelessWidget {
  const PickupOtpBanner({
    super.key,
    required this.pickupOtp,
    required this.pickupOtpVerified,
  });

  final String? pickupOtp;
  final bool pickupOtpVerified;

  @override
  Widget build(BuildContext context) {
    final otp = pickupOtp?.trim();
    if (otp == null || otp.isEmpty) {
      return const SizedBox.shrink();
    }

    final isVerified = pickupOtpVerified;
    final backgroundColor = isVerified
        ? const Color(0xFFEAF7EF)
        : const Color(0xFFFFF6DB);
    final borderColor = isVerified
        ? const Color(0xFFCDEFD9)
        : const Color(0xFFF3DC8C);
    final accentColor = isVerified
        ? const Color(0xFF2FA56E)
        : const Color(0xFFB88900);
    final title = isVerified ? 'Pickup verified' : 'Pickup code';
    final message = isVerified
        ? 'Pickup verified with your code'
        : 'Share this code with your driver when they arrive to confirm pickup';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isVerified ? Icons.verified_rounded : Icons.key_rounded,
                size: 18,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF101828),
                ),
              ),
              const Spacer(),
              if (isVerified)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Done',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF475467),
              height: 1.35,
            ),
          ),
          if (!isVerified) ...[
            const SizedBox(height: 12),
            Center(
              child: Text(
                otp,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 3,
                  color: const Color(0xFF101828),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

TrackingDemoShipment trackingShipmentFromBooking(ClientBooking booking) {
  final status = booking.status.toLowerCase();
  final raw = booking.raw;
  debugPrint(
    '[TrackingShipment] bookingId=${booking.id} '
    'pickup=${_readBookingCoordinate(raw, const ['pickup_lat', 'pickupLat'])},'
    '${_readBookingCoordinate(raw, const ['pickup_lng', 'pickupLng'])} '
    'drop=${_readBookingCoordinate(raw, const ['drop_lat', 'dropLat'])},'
    '${_readBookingCoordinate(raw, const ['drop_lng', 'dropLng'])} '
    'live=${_readBookingCoordinate(raw, const ['current_lat', 'currentLat', 'truck_lat', 'truckLat'])},'
    '${_readBookingCoordinate(raw, const ['current_lng', 'currentLng', 'truck_lng', 'truckLng'])}',
  );
  return TrackingDemoShipment(
    packageName: booking.displayTitle,
    trackingId: booking.bookingRef.isEmpty ? booking.id : booking.bookingRef,
    fromLocation: booking.pickupLocation.isEmpty
        ? 'Pickup location not provided'
        : booking.pickupLocation,
    toLocation: booking.dropoffLocation.isEmpty
        ? 'Drop-off location not provided'
        : booking.dropoffLocation,
    status: booking.displayStatusLabel,
    customerName: booking.clientName,
    weight: booking.weight.isEmpty ? booking.vehicleType : booking.weight,
    pickupLat: _readBookingCoordinate(raw, const ['pickup_lat', 'pickupLat']),
    pickupLng: _readBookingCoordinate(raw, const ['pickup_lng', 'pickupLng']),
    dropLat: _readBookingCoordinate(raw, const ['drop_lat', 'dropLat']),
    dropLng: _readBookingCoordinate(raw, const ['drop_lng', 'dropLng']),
    liveLat: _readBookingCoordinate(raw, const [
      'current_lat',
      'currentLat',
      'truck_lat',
      'truckLat',
    ]),
    liveLng: _readBookingCoordinate(raw, const [
      'current_lng',
      'currentLng',
      'truck_lng',
      'truckLng',
    ]),
    pickupOtp: booking.pickupOtp,
    pickupOtpVerified: booking.pickupOtpVerified,
    amount: _readMoneyValue(raw, raw),
    amountPaid:
        _readDoubleValue(raw, raw, const [
          'amount_paid',
          'amountPaid',
          'paid_amount',
          'paidAmount',
        ]) ??
        0,
    paymentStatus: formatPaymentStatus(
      _readString(raw, const ['payment_status', 'paymentStatus']).isEmpty
          ? 'pending'
          : _readString(raw, const ['payment_status', 'paymentStatus']),
    ),
    podUrl: _readString(raw, const ['podUrl', 'pod_url']),
    ratingStars: _readIntValue(raw, raw, const ['rating_stars', 'stars']),
    tripId: '',
    bookingId: booking.id,
    bookingStatus: status,
    assignedDriverName: booking.raw['driver'] is Map
        ? _readString(
            (booking.raw['driver'] as Map).cast<String, dynamic>(),
            const ['name'],
          )
        : _readString(raw, const ['driverName', 'driver_name']),
    assignedDriverPhone: booking.raw['driver'] is Map
        ? _readString(
            (booking.raw['driver'] as Map).cast<String, dynamic>(),
            const ['phone', 'phoneNumber', 'phone_number'],
          )
        : _readString(raw, const ['driverPhone', 'driver_phone']),
    timeline: _timelineForStatus(status, booking),
  );
}

List<TrackingTimelineStep> _timelineForStatus(
  String status,
  ClientBooking booking,
) {
  final origin = booking.pickupLocation.isEmpty
      ? 'Pickup location not provided'
      : booking.pickupLocation;
  final destination = booking.dropoffLocation.isEmpty
      ? 'Drop-off location not provided'
      : booking.dropoffLocation;

  switch (status) {
    case 'completed':
    case 'delivered':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Assigned',
          subtitle: 'Vehicle assigned',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Completed successfully',
          completed: true,
        ),
      ];
    case 'assigned':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Assigned',
          subtitle: 'Driver assigned',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
    case 'en_route_pickup':
    case 'picked_up':
    case 'in_transit':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Assigned',
          subtitle: 'Driver assigned',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
    case 'confirmed':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Confirmed',
          subtitle: 'Waiting for assignment',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
    case 'cancelled':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Cancelled',
          subtitle: 'Booking was cancelled',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Cancelled',
          completed: false,
        ),
      ];
    case 'pending':
    default:
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Pending',
          subtitle: 'Waiting for confirmation',
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
  }
}

const trackingDemoShipments = <TrackingDemoShipment>[
  TrackingDemoShipment(
    packageName: 'MacBook Air M3',
    trackingId: 'TRK-SSK-20489',
    fromLocation: 'Mumbai Warehouse',
    toLocation: 'Pune Distribution Center',
    status: 'Your package is in transit',
    customerName: 'Aarav Mehta',
    weight: '2.40 KG',
    pickupLat: 19.0760,
    pickupLng: 72.8777,
    dropLat: 18.5204,
    dropLng: 73.8567,
    liveLat: 18.7640,
    liveLng: 73.4100,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Mumbai Warehouse',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Pune Gateway Hub',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Pune Distribution Center',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Awaiting final handoff',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Apple iPhone 15 Pro',
    trackingId: 'TRK-SSK-20841',
    fromLocation: 'Navi Mumbai Hub',
    toLocation: 'Bangalore Tech Park',
    status: 'Arriving at next checkpoint',
    customerName: 'Karan Shah',
    weight: '1.15 KG',
    pickupLat: 19.0330,
    pickupLng: 73.0297,
    dropLat: 12.9716,
    dropLng: 77.5946,
    liveLat: 16.0800,
    liveLng: 75.3500,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Navi Mumbai Hub',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Kolhapur Sorting Center',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Bangalore Tech Park',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Final confirmation pending',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Office Chair Set',
    trackingId: 'TRK-SSK-21077',
    fromLocation: 'Delhi DC-3',
    toLocation: 'Jaipur Office',
    status: 'Awaiting dispatch',
    customerName: 'Neha Kapoor',
    weight: '8.60 KG',
    pickupLat: 28.7041,
    pickupLng: 77.1025,
    dropLat: 26.9124,
    dropLng: 75.7873,
    liveLat: 27.5400,
    liveLng: 76.4200,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Delhi DC-3',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Load assigned',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Queue for pickup',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Not started yet',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Printer Cartridge Box',
    trackingId: 'TRK-SSK-21330',
    fromLocation: 'Pune Cargo Yard',
    toLocation: 'Hyderabad Retail Store',
    status: 'Out for pickup',
    customerName: 'Rohan Kulkarni',
    weight: '4.05 KG',
    pickupLat: 18.5204,
    pickupLng: 73.8567,
    dropLat: 17.3850,
    dropLng: 78.4867,
    liveLat: 17.9400,
    liveLng: 76.9900,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Pune Cargo Yard',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Pickup scheduled',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Not started',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Pending',
        completed: false,
      ),
    ],
  ),
];

class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationArc extends StatelessWidget {
  const LocationArc({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EDF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: scheme.primary, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick up from',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mumbai, Maharashtra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF17324D),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: const AspectRatio(
        aspectRatio: 2,
        child: Image(
          image: AssetImage('assets/client/test.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

Future<void> showTripTypeSheet(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  onOpen?.call();
  try {
    final tripType =
        initialTripType ??
        await showModalBottomSheet<TripType>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TripTypeSheet(),
        );
    if (tripType == null || !context.mounted) return;

    final bookingData = await Navigator.of(context).push<BookingData>(
      MaterialPageRoute(
        builder: (context) => BookingLocationScreen(
          tripType: tripType,
          initialVehicleIndex: initialVehicleIndex ?? 0,
        ),
      ),
    );
    if (bookingData == null || !context.mounted) return;

    final vehicle = await Navigator.of(context).push<VehicleOption>(
      MaterialPageRoute(
        builder: (context) => SelectVehicleScreen(
          bookingData: bookingData,
          initialIndex: initialVehicleIndex ?? 0,
        ),
      ),
    );
    if (vehicle == null || !context.mounted) return;
  } finally {
    onClose?.call();
  }
}

Future<void> showQuickBookingFlow(
  BuildContext context, {
  required TripType tripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  onOpen?.call();
  try {
    final pickup = await Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        builder: (context) => _LocationDetailsScreen(
          kind: _LocationFieldKind.pickup,
          initialValue: '',
        ),
      ),
    );
    if (pickup == null || !context.mounted) {
      return;
    }

    final drop = await Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        builder: (context) => _LocationDetailsScreen(
          kind: _LocationFieldKind.drop,
          initialValue: '',
        ),
      ),
    );
    if (drop == null || !context.mounted) {
      return;
    }

    final bookingData = BookingData(
      from: pickup.formattedAddress,
      to: drop.formattedAddress,
      tripType: tripType,
      city: pickup.city.isNotEmpty ? pickup.city : drop.city,
      pickupLat: pickup.latitude,
      pickupLng: pickup.longitude,
      dropLat: drop.latitude,
      dropLng: drop.longitude,
      scheduledDate: DateTime.now().add(const Duration(hours: 3)),
    );

    if (!context.mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BookingLocationScreen(
          tripType: tripType,
          initialVehicleIndex: initialVehicleIndex ?? 0,
          initialBookingData: bookingData,
          skipLocationStep: true,
        ),
      ),
    );
  } finally {
    onClose?.call();
  }
}

Future<void> showBookingFlow(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  await showTripTypeSheet(
    context,
    initialTripType: initialTripType,
    initialVehicleIndex: initialVehicleIndex,
    onOpen: onOpen,
    onClose: onClose,
  );
}

class TrackingMockCard extends StatelessWidget {
  const TrackingMockCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEAF2F8),
                    valueColor: AlwaysStoppedAnimation(accent),
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

class PackageTrackingCard extends StatelessWidget {
  const PackageTrackingCard({super.key, required this.shipment, this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F3F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset('assets/package.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.packageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121826),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#Tracking ID: ${shipment.trackingId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: const Icon(Icons.more_horiz_rounded, size: 22),
                color: Colors.black45,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 14,
                child: Column(
                  children: [
                    const SizedBox(height: 3),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      shipment.fromLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Shipping to:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      shipment.toLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFECEFF3)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Status:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1C2430),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shipment.status,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF1C2430),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }
}

class TruckIllustration extends StatelessWidget {
  const TruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            left: 4,
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 16,
            child: Container(
              width: 20,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1F88C9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
          const Positioned(bottom: 10, left: 10, child: Wheel()),
          const Positioned(bottom: 10, right: 10, child: Wheel()),
        ],
      ),
    );
  }
}

class Wheel extends StatelessWidget {
  const Wheel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF17324D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7EEF5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF2FA56E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.46,
        minChildSize: 0.36,
        maxChildSize: 0.86,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE7EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TripTypeSheet extends StatelessWidget {
  const TripTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose trip type',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _TripTypeRow(
              imagePath: 'assets/trucks/inter-city.png',
              label: TripType.interCity.displayLabel,
              helperText: TripType.interCity.helperText,
              onTap: () => Navigator.of(context).pop(TripType.interCity),
            ),
            const SizedBox(height: 10),
            _TripTypeRow(
              imagePath: 'assets/trucks/intra-city.png',
              label: TripType.intraCity.displayLabel,
              helperText: TripType.intraCity.helperText,
              onTap: () => Navigator.of(context).pop(TripType.intraCity),
            ),
          ],
        ),
      ),
    );
  }
}

double _sheetBottomInset(BuildContext context) {
  final viewPadding = MediaQuery.of(context).viewPadding.bottom;
  return viewPadding > 0 ? viewPadding + 28 : 28;
}

class _TripTypeRow extends StatelessWidget {
  const _TripTypeRow({
    required this.imagePath,
    required this.label,
    required this.helperText,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 54, height: 54, fit: BoxFit.contain),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
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

class _BookingLocationScreenState extends ConsumerState<BookingLocationScreen> {
  static const LatLng _fallbackMapCenter = LatLng(19.0760, 72.8777);

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _weightController;
  late final TextEditingController _amountController;
  late VehicleOption _vehicle;
  GoogleMapController? _brokerMapController;
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
  int _findTruckRequestCount = 0;
  int _findTruckDeclinedCount = 0;
  bool _findTruckNegotiationOpen = false;
  bool _postNegotiationPayment = false;
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
  StreamSubscription<Map<String, dynamic>>? _findTruckRequestSubscription;
  bool _locationStreamStarted = false;

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
    _draft =
        (initialDraft ??
                BookingData(
                  from: '',
                  to: '',
                  tripType: widget.tripType,
                  city: '',
                  scheduledDate: DateTime.now().add(const Duration(hours: 3)),
                  amount: _priceValue(_vehicle.price),
                ))
            .copyWith(
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
    _positionSubscription?.cancel();
    _findTruckPollTimer?.cancel();
    _findTruckRequestSubscription?.cancel();
    _brokerMapController?.dispose();
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
    final distance = _routeDistanceKm([?pickup, ?drop]);

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
              color: const Color(0xFF667085),
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

    final routeKey =
        '${pickup.latitude},${pickup.longitude}|${drop.latitude},${drop.longitude}';
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
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;

    final scheduled = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
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
      );
      _amountController.text = _priceInputText(vehicle.price);
      _selectedTruck = null;
    });
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
    setState(() {
      _draft = _draft.copyWith(searchMode: mode);
      _step = _BookingFlowStep.payment;
    });
  }

  Future<void> _startFindTruckSearch() async {
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
      _driverRequest = null;
      _findTruckRequestCount = 0;
      _findTruckDeclinedCount = 0;
      _draft = _draft.copyWith(
        searchMode: BookingSearchMode.truck,
        selectedBrokerId: '',
      );
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
        _postNegotiationPayment = false;
        _step = _BookingFlowStep.waiting;
      });

      await _startFindTruckLiveUpdates(session.tokens.accessToken);
      await _loadFindTruckDriverRequests(silent: false);
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
      final best = _bestFindTruckDriverRequest(requests);

      if (!mounted) {
        return;
      }

      setState(() {
        _findTruckRequestCount = requests.length;
        _findTruckDeclinedCount = requests
            .where((request) => request.normalizedStatus == 'declined')
            .length;
        if (best != null) {
          _driverRequest = best;
        }
      });

      if (best != null && _shouldOpenFindTruckNegotiation(best)) {
        unawaited(_openFindTruckNegotiation(best));
      }
    } catch (error) {
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

  bool _shouldOpenFindTruckNegotiation(ClientBookingOffer request) {
    if (_findTruckNegotiationOpen) {
      return false;
    }
    if (request.normalizedStatus == 'declined' ||
        request.normalizedStatus == 'expired') {
      return false;
    }
    return request.isActionableByClient ||
        request.normalizedStatus == 'accepted';
  }

  Future<void> _openFindTruckNegotiation(ClientBookingOffer request) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final bookingId = _activeBookingId;
    if (session == null || bookingId == null || bookingId.isEmpty) {
      return;
    }

    _findTruckNegotiationOpen = true;
    final outcome = await showModalBottomSheet<_FindTruckNegotiationResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
        _step = _BookingFlowStep.payment;
      });
      return;
    }

    await _loadFindTruckDriverRequests(silent: true);
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
                    color: const Color(0xFF101828),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded),
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
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              _buildTruckCategoryPicker(context),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_rounded,
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
                            color: const Color(0xFF101828),
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
      final distance = _readDistanceValue(data, response);
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
        setState(() {
          _haltingNote = _haltingNoteFromQuote(response);
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
        _postNegotiationPayment = false;
      });
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
    if (selectedMethod == PaymentMethod.payLater) {
      if (!mounted) return;
      setState(() {
        _postNegotiationPayment = false;
        _bookingCreated = true;
      });
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
            ? '20% advance payment'
            : 'Booking payment',
        context: context,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _postNegotiationPayment = false;
        _bookingCreated = true;
      });
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
    }
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
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final showBottomButton = switch (_step) {
      _BookingFlowStep.location || _BookingFlowStep.payment => true,
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
      backgroundColor: Colors.white,
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
                                              Icons.arrow_back_rounded,
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
                                            _BookingFlowStep.payment =>
                                              'Payment',
                                            _BookingFlowStep.waiting =>
                                              'Waiting',
                                          },
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                color: const Color(0xFF667085),
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
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
                          bottom: 44,
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
                                            Icons.arrow_back_rounded,
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
                                              color: const Color(0xFF667085),
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
    final openSheetSize = mode == BookingSearchMode.broker ? 0.62 : 0.46;
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildBrokerMap(context, const <NearbyTruck>[]),
        Positioned(
          left: 16,
          top: 0,
          child: SafeArea(
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 5,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() {
                  _step = _BookingFlowStep.itemDetails;
                }),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF0B1F3A),
                    size: 23,
                  ),
                ),
              ),
            ),
          ),
        ),
        DraggableScrollableSheet(
          initialChildSize: openSheetSize,
          minChildSize: 0.15,
          maxChildSize: openSheetSize,
          snap: true,
          snapSizes: [0.15, openSheetSize],
          builder: (context, scrollController) {
            return _SearchMethodSheet(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(
                  14,
                  0,
                  14,
                  MediaQuery.of(context).viewPadding.bottom + 10,
                ),
                children: [
                  const _SheetDragHandle(),
                  Text(
                    'Choose Trucks',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF0B1F3A),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildTruckCategoryPicker(context),
                  const SizedBox(height: 10),
                  if (mode == BookingSearchMode.truck) ...[
                    _buildFindTruckOptions(context),
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE1E8F2)),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: _SearchModeCard(
                          selected: mode == BookingSearchMode.truck,
                          icon: Icons.local_shipping_rounded,
                          title: 'Find Truck',
                          onTap: () {
                            setState(() {
                              _draft = _draft.copyWith(
                                searchMode: BookingSearchMode.truck,
                                selectedBrokerId: '',
                              );
                            });
                            unawaited(_startFindTruckSearch());
                          },
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _SearchModeCard(
                          selected: mode == BookingSearchMode.broker,
                          icon: Icons.person_rounded,
                          title: 'Search Broker',
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
                  if (mode == BookingSearchMode.broker) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: Color(0xFFE1E8F2)),
                    const SizedBox(height: 10),
                    _buildBrokerListOptions(context),
                  ],
                ],
              ),
            );
          },
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
                              color: const Color(0xFFD2DCEA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Choose Trucks',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: const Color(0xFF0B1F3A),
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
                                icon: Icons.local_shipping_rounded,
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
                                icon: Icons.person_rounded,
                                title: 'Search Broker',
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
                        const Divider(height: 1, color: Color(0xFFE1E8F2)),
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
            const Icon(
              Icons.my_location_rounded,
              color: Color(0xFF0B1F3A),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Search Radius',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF0B1F3A),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF7EF),
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
            inactiveTrackColor: const Color(0xFFE2E8F2),
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

    return Column(
      children: [
        SizedBox(
          height: 132,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardWidth = min(250.0, constraints.maxWidth * 0.66);
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                itemCount: vehicles.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final vehicle = vehicles[index];
                  return SizedBox(
                    width: cardWidth,
                    child: _ChooseTruckCard(
                      vehicle: vehicle,
                      selected: selectedIndex == index,
                      onTap: () => _selectVehicleForSearchStep(index),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBrokerListOptions(BuildContext context) {
    if (_loadingEligibleBrokers) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 28),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_eligibleBrokersError != null) {
      return _InlineRetryCard(
        message: _eligibleBrokersError!,
        onRetry: _loadEligibleBrokers,
      );
    }
    if (_eligibleBrokers.isEmpty) {
      return _InlineRetryCard(
        message: 'No eligible brokers found for this route yet.',
        onRetry: _loadEligibleBrokers,
      );
    }
    return Column(
      children: _eligibleBrokers
          .map(
            (broker) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
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
          )
          .toList(growable: false),
    );
  }

  // ignore: unused_element
  Widget _buildBrokerMap(BuildContext context, List<NearbyTruck> trucks) {
    final cameraTarget = _brokerMapCenter();
    final markers = _buildBrokerMarkers(trucks);
    final polylines = _buildBrokerPolylines();
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;

    _scheduleBrokerRouteRefresh();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: cameraTarget,
        zoom: pickup != null && drop != null ? 8.4 : 10.2,
      ),
      mapType: MapType.normal,
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trafficEnabled: true,
      onMapCreated: (controller) {
        _brokerMapController = controller;
        _scheduleBrokerRouteRefresh();
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitBrokerCamera());
      },
    );
  }

  Set<Marker> _buildBrokerMarkers(List<NearbyTruck> trucks) {
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
    return const [];
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
                color: const Color(0xFF101828),
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
                  : const Icon(Icons.gps_fixed_rounded, size: 14),
              label: Text(
                _resolvingCurrentLocation
                    ? 'Locating...'
                    : 'Use current location',
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF1F88C9),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
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
              child: OutlinedButton.icon(
                onPressed: () async {
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
                      city: selection.city.isNotEmpty
                          ? selection.city
                          : _draft.city,
                    );
                    _fromController.text = selection.formattedAddress;
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add loading'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F88C9),
                  side: const BorderSide(color: Color(0xFFD7E7F4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
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
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Add unloading'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F88C9),
                  side: const BorderSide(color: Color(0xFFD7E7F4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Select the weight of your goods',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _weightError != null
                  ? const Color(0xFFE23A4B)
                  : const Color(0xFFD7DCE3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
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
                    hintText: 'Enter tonnage',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ton',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111111),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (_weightError != null) ...[
          const SizedBox(height: 6),
          Text(
            _weightError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFE23A4B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [1.0, 4.5, 7.0, 12.0, 15.0, 18.0, 25.0]
              .map(
                (value) => _WeightChip(
                  label: '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} ton',
                  selected: !_weightUnknown && (weight - value).abs() < 0.001,
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
        const SizedBox(height: 18),
        _buildScheduleSection(context),
      ],
    );
  }

  Widget _buildScheduleSection(BuildContext context) {
    final scheduled = _draft.scheduledDate;
    final isLater = _draft.isScheduled;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pickup time',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                icon: Icon(Icons.flash_on_rounded, size: 16),
                label: Text('Book Now'),
              ),
              ButtonSegment(
                value: true,
                icon: Icon(Icons.schedule_rounded, size: 16),
                label: Text('Book Later'),
              ),
            ],
            selected: {isLater},
            onSelectionChanged: (selection) {
              final later = selection.first;
              setState(() {
                _draft = _draft.copyWith(
                  isScheduled: later,
                  scheduledDate: later
                      ? (scheduled != null && scheduled.isAfter(DateTime.now())
                            ? scheduled
                            : DateTime.now().add(const Duration(hours: 3)))
                      : scheduled,
                );
              });
            },
          ),
          if (isLater) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _pickScheduledDateTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE4EAF1)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: Color(0xFF2FA56E),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        scheduled == null
                            ? 'Choose date and time'
                            : _formatDateTime(scheduled),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_rounded, size: 16),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWeightBottomActions(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _advanceFromWeightStep(unknown: true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE9ECF2),
                foregroundColor: const Color(0xFF111111),
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text(
                "I don't know my material weight",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting
                  ? null
                  : () => _advanceFromWeightStep(unknown: _weightUnknown),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
              ),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
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
        if (_haltingNote != null) ...[
          _HaltingInfoCard(message: _haltingNote!),
          const SizedBox(height: 12),
        ],
        _CheckoutChoiceCard(
          selectedMethod: _selectedPaymentMethod,
          requiresAdvance: false,
          advanceAmount: 0,
          onSelect: (method) {
            setState(() => _selectedPaymentMethod = method);
          },
        ),
      ],
    );
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8EDF2)),
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
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Dont worry, I will help you reach your package in its proper destination safely.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
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
                    color: const Color(0xFFEFF8F2),
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

enum _DirectNegotiationStage { compose, waiting, payment, confirmed }

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
  String? _errorMessage;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.googlePay;
  Timer? _pollTimer;
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _jobRequestSubscription;

  double get _finalNegotiationAmount {
    final request = _request;
    final source = request?.amountText.isNotEmpty == true
        ? request!.amountText
        : widget.initialPrice.toString();
    final parsed = double.tryParse(source.replaceAll(RegExp(r'[^0-9.]'), ''));
    return parsed ?? widget.initialPrice;
  }

  bool get _requiresAdvancePayment =>
      _finalNegotiationAmount > _advancePaymentThreshold;

  double get _advancePaymentAmount =>
      (_finalNegotiationAmount * _advancePaymentPct * 100).round() / 100;

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

    final amountController = TextEditingController(text: request.amountText);
    try {
      final shouldSend = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Counter offer'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Send'),
            ),
          ],
        ),
      );
      if (shouldSend != true) return;

      final amount =
          double.tryParse(
            amountController.text.replaceAll(RegExp(r'[^0-9.]'), ''),
          ) ??
          0;
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
      amountController.dispose();
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
            ? '20% advance payment'
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
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          body,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF667085),
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE8EDF2)),
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
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request == null
                      ? 'Live updates will appear here.'
                      : 'Current amount: ${request.amountText}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
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
              color: const Color(0xFFB42318),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (request?.isActionableByClient == true) ...[
          const SizedBox(height: 16),
          _NegotiationActionButtons(
            acceptLabel: request!.isClientTurnToConfirm ? 'Confirm' : 'Accept',
            canCounter: false,
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
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE8EDF2)),
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
                      color: const Color(0xFF667085),
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
    final requiresAdvance = _requiresAdvancePayment;
    final advanceAmount = _advancePaymentAmount;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          requiresAdvance ? 'Choose payment' : 'Complete payment',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          requiresAdvance
              ? 'Bookings over ₹${_advancePaymentThreshold.toStringAsFixed(0)} need a 20% advance to confirm. You can still pay the full amount now.'
              : 'The booking is confirmed. Continue to secure checkout to complete payment.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF667085),
            height: 1.45,
          ),
        ),
        if (requiresAdvance) ...[
          const SizedBox(height: 10),
          Text(
            '20% advance: ${_formatRupees(advanceAmount)}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF2FA56E),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          'Razorpay checkout will show the available payment methods before you pay.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF667085)),
        ),
        const SizedBox(height: 16),
        _CheckoutChoiceCard(
          selectedMethod: _selectedPaymentMethod,
          requiresAdvance: requiresAdvance,
          advanceAmount: advanceAmount,
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
                : const Text('Continue to secure checkout'),
          ),
        ),
      ],
    );
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
          decoration: const BoxDecoration(
            color: Colors.white,
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
                      color: const Color(0xFFD0D5DD),
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
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use the slider to set the amount you want to continue with.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF667085),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
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
                inactiveColor: const Color(0xFFE4E7EC),
                label: '₹${displayValue.toStringAsFixed(0)}',
                onChanged: onChanged,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${minPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                  Text(
                    '₹${maxPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
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
              color: const Color(0xFFB42318),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
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
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: isBusy ? null : onAccept,
            child: Text(acceptLabel),
          ),
        ),
        const SizedBox(height: 10),
        if (canCounter)
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: isBusy ? null : onCounter,
                  child: const Text('Counter'),
                ),
              ),
            ],
          )
        else
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: isBusy ? null : onReject,
              child: const Text('Reject'),
            ),
          ),
      ],
    );
  }
}

// ignore: unused_element
class _MapHintPill extends StatelessWidget {
  const _MapHintPill({
    required this.icon,
    required this.label,
    // ignore: unused_element_parameter
    this.accent = const Color(0xFF101828),
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckoutChoiceCard extends StatelessWidget {
  const _CheckoutChoiceCard({
    required this.selectedMethod,
    required this.requiresAdvance,
    required this.advanceAmount,
    required this.onSelect,
  });

  final PaymentMethod selectedMethod;
  final bool requiresAdvance;
  final double advanceAmount;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    final fullSelected =
        selectedMethod != PaymentMethod.advance &&
        selectedMethod != PaymentMethod.payLater;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _CheckoutChoiceTile(
            title: 'Pay securely now',
            subtitle: 'Choose UPI, card, bank, or wallet in checkout',
            icon: Icons.lock_outline_rounded,
            selected: fullSelected,
            onTap: () => onSelect(PaymentMethod.googlePay),
          ),
          if (requiresAdvance)
            _CheckoutChoiceTile(
              title: 'Pay 20% advance',
              subtitle:
                  '${_formatRupees(advanceAmount)} now, balance on delivery',
              icon: Icons.payments_outlined,
              selected: selectedMethod == PaymentMethod.advance,
              onTap: () => onSelect(PaymentMethod.advance),
            )
          else
            _CheckoutChoiceTile(
              title: 'Pay later',
              subtitle: 'Confirm now and settle after delivery',
              icon: Icons.schedule_send_rounded,
              selected: selectedMethod == PaymentMethod.payLater,
              onTap: () => onSelect(PaymentMethod.payLater),
            ),
        ],
      ),
    );
  }
}

class _CheckoutChoiceTile extends StatelessWidget {
  const _CheckoutChoiceTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: Icon(icon, color: selected ? accent : const Color(0xFF667085)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected ? accent : const Color(0xFF98A2B3),
      ),
    );
  }
}

class _LocationLaunchCard extends StatelessWidget {
  const _LocationLaunchCard({
    required this.pickupValue,
    required this.dropValue,
    required this.onPickupTap,
    required this.onDropTap,
  });

  final String pickupValue;
  final String dropValue;
  final VoidCallback onPickupTap;
  final VoidCallback onDropTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEFF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPickupTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38B47A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DDE4),
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
                          pickupValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF9B9B9B),
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: const Color(0xFFE9EDF2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onDropTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF05252),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dropValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF9B9B9B),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
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

class _WeightStepRouteSummary extends StatelessWidget {
  const _WeightStepRouteSummary({
    required this.pickupAddress,
    required this.dropAddress,
    required this.onEditTap,
  });

  final String pickupAddress;
  final String dropAddress;
  final VoidCallback onEditTap;

  String _headline(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'Add location';
    }
    return parts.first;
  }

  String _subtitle(String address) {
    final parts = address
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
    if (parts.length <= 1) {
      return address.isEmpty ? 'Tap + to add details' : address;
    }
    return parts.skip(1).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FD),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF38B47A),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              Container(
                width: 2,
                height: 22,
                margin: const EdgeInsets.symmetric(vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFFF05252),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.arrow_downward_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _headline(pickupAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(pickupAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _headline(dropAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111111),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _subtitle(dropAddress),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onEditTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFE9EBF2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.edit_rounded, size: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF111111),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      selectedColor: const Color(0xFF111111),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE0E4EA)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _BookingSuccessCard extends StatelessWidget {
  const _BookingSuccessCard({
    required this.bookingReference,
    required this.onTrack,
    required this.onHome,
    this.title = 'Booking confirmed',
    this.message = 'Your booking has been successfully placed.',
  });

  final String? bookingReference;
  final VoidCallback onTrack;
  final VoidCallback onHome;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2FA56E),
              size: 58,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            bookingReference == null || bookingReference!.isEmpty
                ? 'Booking Number: Pending'
                : 'Booking Number: $bookingReference',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTrack,
                  child: const Text('Track booking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  child: const Text('Go to home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingWaitingCard extends StatelessWidget {
  const _BookingWaitingCard({
    required this.bookingReference,
    required this.driverRequest,
    required this.onTrack,
    required this.onHome,
  });

  final String? bookingReference;
  final ClientBookingOffer? driverRequest;
  final VoidCallback onTrack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final request = driverRequest;
    final awaitingConfirmation = request?.isAwaitingConfirmation == true;
    final yourTurn = request?.isClientTurnToConfirm == true;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1A73E8).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.hourglass_top_rounded,
              color: Color(0xFF1A73E8),
              size: 52,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            awaitingConfirmation
                ? (yourTurn
                      ? 'The broker accepted - confirm or decline'
                      : 'Waiting for broker confirmation')
                : 'Waiting for driver response',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            request == null
                ? 'Your booking request has been sent. We will update you as soon as the truck responds.'
                : awaitingConfirmation
                ? (yourTurn
                      ? 'The broker already committed. Respond now to finish the booking.'
                      : 'You already committed. Waiting for the broker to confirm.')
                : 'Request sent to ${request.brokerName.isNotEmpty ? request.brokerName : 'the selected truck'}. Open tracking to review the live negotiation.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            bookingReference == null || bookingReference!.isEmpty
                ? 'Booking Number: Pending'
                : 'Booking Number: $bookingReference',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (request != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.brokerName.isNotEmpty
                        ? request.brokerName
                        : 'Selected truck',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    awaitingConfirmation
                        ? (yourTurn
                              ? 'The broker accepted. Confirm or decline to finish.'
                              : 'Waiting for the broker to confirm your earlier acceptance.')
                        : request.isCountered
                        ? 'Driver countered. Tracking will show the next action.'
                        : request.driverTimedOut
                        ? 'Driver timed out. The broker can take over now.'
                        : 'Waiting on the driver to respond.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTrack,
                  child: const Text('Open tracking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  child: const Text('Go to home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _truckCategoryForVehicle(String label) {
  final text = label.toLowerCase();
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big')) return 'large';
  return 'pooling';
}

double _parsePrice(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

double _priceValue(String value) {
  if (_parsePrice(value) <= 0) {
    return 0;
  }
  return _parsePrice(value);
}

String _priceInputText(String value) {
  final parsed = _parsePrice(value);
  if (parsed <= 0) {
    return '';
  }
  return parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 2);
}

double _readDistanceValue(Object? data, Map<String, dynamic> fallback) {
  final value = _readDoubleValue(data, fallback, const ['distance']);
  return value ?? 0;
}

double? _readDoubleValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate == null) continue;
    final parsed = double.tryParse(candidate.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

double _readMoneyValue(Object? data, Map<String, dynamic> fallback) {
  return _readDoubleValue(data, fallback, const [
        'estimated_amount',
        'estimatedAmount',
        'amount',
        'total',
        'total_amount',
        'totalAmount',
        'fare',
        'price',
        'value',
        'quoted_price',
        'quotedPrice',
      ]) ??
      0;
}

int? _readIntValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate == null) continue;
    final parsed = int.tryParse(candidate.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _displayPriceLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Loading...' : trimmed;
}

double? _readBookingCoordinate(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _extractBookingNumber(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    for (final key in [
      'booking_number',
      'bookingNumber',
      'booking_no',
      'bookingNo',
      'booking_ref',
      'booking_reference',
      'reference',
      'id',
      'tracking_number',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
  }
  for (final key in [
    'booking_number',
    'bookingNumber',
    'booking_no',
    'bookingNo',
    'booking_ref',
    'booking_reference',
    'reference',
    'id',
    'tracking_number',
  ]) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

String _extractBookingId(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    for (final key in const ['booking_id', 'bookingId', 'id', 'uuid']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    final booking = data['booking'];
    if (booking is Map<String, dynamic>) {
      for (final key in const ['booking_id', 'bookingId', 'id', 'uuid']) {
        final value = booking[key]?.toString().trim();
        if (value != null && value.isNotEmpty) return value;
      }
    }
  }
  for (final key in const ['booking_id', 'bookingId', 'id', 'uuid']) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

ClientBookingOffer? _extractDriverRequest(Map<String, dynamic> json) {
  final data = json['data'];
  final root = data is Map<String, dynamic> ? data : json;

  final candidates = <Object?>[
    root['request'],
    root['driverRequest'],
    root['driver_request'],
    root['item'],
    root,
  ];

  for (final candidate in candidates) {
    if (candidate is Map<String, dynamic>) {
      if (candidate.containsKey('id') || candidate.containsKey('status')) {
        return ClientBookingOffer.fromJson(candidate);
      }
    } else if (candidate is Map) {
      final map = candidate.cast<String, dynamic>();
      if (map.containsKey('id') || map.containsKey('status')) {
        return ClientBookingOffer.fromJson(map);
      }
    }
  }

  return null;
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.pickupTitle,
    this.distanceText,
    this.amountText,
    this.dropValue,
  });

  final String pickupTitle;
  final String? distanceText;
  final String? amountText;
  final String? dropValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEFF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2FA56E),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE23A4B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C2430),
                            ),
                      ),
                      if (distanceText != null && distanceText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          distanceText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF667085),
                                fontSize: 11,
                              ),
                        ),
                      ],
                      if (amountText != null && amountText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          amountText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF1F88C9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dropValue ?? 'Where is your Drop ?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF1C2430),
                                fontSize: 13,
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
      ),
    );
  }
}

class _SearchModeCard extends StatelessWidget {
  const _SearchModeCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : const Color(0xFF0B1F3A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(17),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF2FA56E) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFD4DEEC),
            width: 1.4,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2FA56E).withValues(alpha: 0.24),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: foreground, size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChooseTruckCard extends StatelessWidget {
  const _ChooseTruckCard({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFD8E1ED),
            width: selected ? 2 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF36506F).withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -6,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5F8ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF12B76A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Available',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF079455),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: SizedBox(
                    height: 48,
                    child: Image.asset(vehicle.assetPath, fit: BoxFit.contain),
                  ),
                ),
                const Spacer(),
                Text(
                  vehicle.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: const Color(0xFF0B1F3A),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    _TruckSpec(
                      icon: Icons.scale_rounded,
                      label: vehicle.capacity,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TruckSpec extends StatelessWidget {
  const _TruckSpec({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF7D8AA0)),
        const SizedBox(width: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF6A7890),
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SearchMethodSheet extends StatelessWidget {
  const _SearchMethodSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: Center(
        child: Container(
          width: 86,
          height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFFC8D3E1),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _EligibleBrokerTile extends StatelessWidget {
  const _EligibleBrokerTile({
    required this.broker,
    required this.selected,
    required this.onTap,
  });

  final _EligibleBroker broker;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = broker.isOnline
        ? const Color(0xFF2FA56E)
        : const Color(0xFF98A2B3);
    final detailParts = <String>[
      if (broker.phone.isNotEmpty) broker.phone,
      if (broker.serviceCity.isNotEmpty) broker.serviceCity,
    ];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFEFF8F2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF2FA56E) : const Color(0xFFE4EAF1),
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected
                  ? const Color(0xFF2FA56E)
                  : const Color(0xFFF1F5F9),
              child: Icon(
                Icons.business_center_rounded,
                size: 19,
                color: selected ? Colors.white : const Color(0xFF667085),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          broker.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          broker.isOnline ? 'Online' : 'Offline',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detailParts.isEmpty
                        ? 'Eligible broker'
                        : detailParts.join('  |  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${broker.truckCount} truck${broker.truckCount == 1 ? '' : 's'} available',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected
                  ? const Color(0xFF2FA56E)
                  : const Color(0xFF98A2B3),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineRetryCard extends StatelessWidget {
  const _InlineRetryCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE4EAF1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF667085)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _HaltingInfoCard extends StatelessWidget {
  const _HaltingInfoCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF2D58A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.timer_outlined, size: 20, color: Color(0xFFB88900)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF6F5200),
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectVehicleScreen extends ConsumerStatefulWidget {
  const SelectVehicleScreen({
    super.key,
    required this.bookingData,
    this.initialIndex = 0,
  });

  final BookingData bookingData;
  final int initialIndex;

  @override
  ConsumerState<SelectVehicleScreen> createState() =>
      _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends ConsumerState<SelectVehicleScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pricingState = ref.watch(clientPricingProvider);
    final options = resolveVehicleOptions(
      tripType: widget.bookingData.tripType,
      pricing: pricingState.valueOrNull,
      isLoading: pricingState.isLoading,
    );
    final safeIndex = options.isEmpty
        ? 0
        : _selectedIndex.clamp(0, options.length - 1).toInt();
    final selected = options[safeIndex];
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(18, 12, 18, 132 + bottomInset),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        borderRadius: BorderRadius.circular(999),
                        child: const SizedBox(
                          width: 28,
                          height: 28,
                          child: Icon(Icons.arrow_back_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookingSummaryCard(
                    pickupTitle: widget.bookingData.from,
                    distanceText: widget.bookingData.distanceText,
                    amountText: widget.bookingData.amountText,
                    dropValue: widget.bookingData.to,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your vehicle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...options.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VehicleOptionTile(
                        option: entry.value,
                        selected: safeIndex == entry.key,
                        onTap: () => setState(() => _selectedIndex = entry.key),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: bottomInset + 12,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(selected);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text('Proceed with ${selected.label}'),
                    ),
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

class _VehicleOptionTile extends StatelessWidget {
  const _VehicleOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? option.accentColor : const Color(0xFFE7EEF5),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.045 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1.14 : 1.0,
              curve: Curves.easeOutBack,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(option.assetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.capacity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _displayPriceLabel(option.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? 'Selected' : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? option.accentColor : Colors.transparent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClientBottomBar extends StatelessWidget {
  const ClientBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 24,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: NavItem(
                  label: 'Home',
                  icon: LucideIcons.house,
                  selected: currentIndex == 0,
                  onTap: () => onTap(0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NavItem(
                  label: 'Activity',
                  icon: LucideIcons.map,
                  selected: currentIndex == 1,
                  onTap: () => onTap(1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NavItem(
                  label: 'Profile',
                  icon: LucideIcons.user,
                  selected: currentIndex == 2,
                  onTap: () => onTap(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : Colors.black45;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(child: Icon(icon, size: 20, color: color)),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
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
