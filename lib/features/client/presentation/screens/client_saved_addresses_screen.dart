import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/google_places_autocomplete_field.dart';

class ClientSavedAddressesScreen extends ConsumerStatefulWidget {
  const ClientSavedAddressesScreen({super.key});

  @override
  ConsumerState<ClientSavedAddressesScreen> createState() =>
      _ClientSavedAddressesScreenState();
}

class _ClientSavedAddressesScreenState
    extends ConsumerState<ClientSavedAddressesScreen> {
  final List<_SavedAddress> _addresses = [];
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  bool _error = false;
  String? _deletingId;
  String? _defaultingId;
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_SavedAddress> get _filteredAddresses {
    final q = _query.trim().toLowerCase();
    return _addresses
        .where((address) {
          if (q.isEmpty) return true;
          return [
            address.label,
            address.address,
            address.contactName,
            address.contactPhone,
          ].any((value) => value.toLowerCase().contains(q));
        })
        .toList(growable: false);
  }

  Future<void> _load() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = false;
        _addresses.clear();
      });
      return;
    }

    if (mounted) {
      setState(() {
        _loading = true;
        _error = false;
      });
    }

    try {
      final response = await ref
          .read(apiClientProvider)
          .getSavedAddresses(accessToken: session.tokens.accessToken);
      final addresses = _parseAddresses(response);
      if (!mounted) return;
      setState(() {
        _addresses
          ..clear()
          ..addAll(addresses);
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _openEditor({_SavedAddress? address}) async {
    final saved = await context.push<bool>(
      address == null
          ? '/client/saved-addresses/new'
          : '/client/saved-addresses/${address.id}/edit',
      extra: address,
    );
    if (saved == true && mounted) {
      await _load();
    }
  }

  Future<void> _setDefault(_SavedAddress address) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _defaultingId == address.id) return;

    setState(() {
      _defaultingId = address.id;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .setDefaultSavedAddress(
            accessToken: session.tokens.accessToken,
            id: address.id,
          );
      final updated = _SavedAddress.fromJson(_pickItem(response, 'address'));
      if (!mounted) return;
      setState(() {
        if (updated.id.isNotEmpty) {
          for (var i = 0; i < _addresses.length; i++) {
            _addresses[i] = _addresses[i].copyWith(
              isDefault: _addresses[i].id == address.id,
            );
          }
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _defaultingId = null;
        });
      }
    }
  }

  Future<void> _deleteAddress(_SavedAddress address) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _deletingId == address.id) return;

    setState(() {
      _deletingId = address.id;
    });

    try {
      await ref
          .read(apiClientProvider)
          .deleteSavedAddress(
            accessToken: session.tokens.accessToken,
            id: address.id,
          );
      if (!mounted) return;
      setState(() {
        _addresses.removeWhere((item) => item.id == address.id);
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Address removed.')));
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _deletingId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    final filtered = _filteredAddresses;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text('Saved Addresses'),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2FA56E),
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            if (session == null)
              const _EmptyState(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to manage addresses',
                subtitle:
                    'We need an active client session before we can load your saved locations.',
              )
            else if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error)
              _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load saved addresses',
                subtitle: 'Pull to refresh or try again in a moment.',
                actionLabel: 'Retry',
                onAction: _load,
              )
            else if (_addresses.isEmpty)
              _EmptyState(
                icon: Icons.location_on_outlined,
                title: 'No saved addresses yet',
                subtitle:
                    'Save your frequent pickup and drop-off locations to check out faster next time.',
                actionLabel: 'Add Address',
                onAction: _openEditor,
              )
            else ...[
              _SavedAddressSearchField(
                controller: _searchController,
                query: _query,
                onQueryChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (filtered.isEmpty)
                const _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No addresses match your search',
                  subtitle: 'Try another name, address, or contact.',
                )
              else
                _AddressList(
                  addresses: filtered,
                  defaultingId: _defaultingId,
                  deletingId: _deletingId,
                  onAdd: _openEditor,
                  onEdit: (address) => _openEditor(address: address),
                  onSetDefault: _setDefault,
                  onDelete: _deleteAddress,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedAddressSearchField extends StatelessWidget {
  const _SavedAddressSearchField({
    required this.controller,
    required this.query,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: _savedCardDecoration(
        radius: 12,
      ).copyWith(border: Border.all(color: const Color(0xFFE4E7EC))),
      child: Row(
        children: [
          const SizedBox(width: 13),
          const Icon(Icons.search_rounded, color: Color(0xFFD0D5DD), size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onQueryChanged,
              decoration: const InputDecoration(
                hintText: 'Search saved addresses...',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (query.isNotEmpty)
            IconButton(
              onPressed: () {
                controller.clear();
                onQueryChanged('');
              },
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _AddressList extends StatelessWidget {
  const _AddressList({
    required this.addresses,
    required this.defaultingId,
    required this.deletingId,
    required this.onAdd,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final List<_SavedAddress> addresses;
  final String? defaultingId;
  final String? deletingId;
  final VoidCallback onAdd;
  final ValueChanged<_SavedAddress> onEdit;
  final ValueChanged<_SavedAddress> onSetDefault;
  final ValueChanged<_SavedAddress> onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 650
            ? 2
            : 1;
        final mainAxisExtent = crossAxisCount == 1 ? 150.0 : 144.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            mainAxisExtent: mainAxisExtent,
          ),
          itemCount: addresses.length + 1,
          itemBuilder: (context, index) {
            if (index == addresses.length) {
              return _AddAddressTile(onTap: onAdd);
            }
            final address = addresses[index];
            return _AddressListTile(
              address: address,
              isDefaulting: defaultingId == address.id,
              isDeleting: deletingId == address.id,
              onEdit: () => onEdit(address),
              onSetDefault: address.isDefault
                  ? null
                  : () => onSetDefault(address),
              onDelete: () => onDelete(address),
            );
          },
        );
      },
    );
  }
}

class _AddAddressTile extends StatelessWidget {
  const _AddAddressTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFB8DCC7), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F4E8),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(Icons.add_rounded, color: Color(0xFF2FA56E)),
            ),
            const SizedBox(height: 10),
            Text(
              'Add New Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14.5,
                color: const Color(0xFF101828),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pickup or Drop-off Location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF667085),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientSavedAddressEditorScreen extends ConsumerStatefulWidget {
  const ClientSavedAddressEditorScreen({
    super.key,
    this.addressId,
    this.initialAddress,
  });

  final String? addressId;
  final Object? initialAddress;

  @override
  ConsumerState<ClientSavedAddressEditorScreen> createState() =>
      _ClientSavedAddressEditorScreenState();
}

class _ClientSavedAddressEditorScreenState
    extends ConsumerState<ClientSavedAddressEditorScreen> {
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  late final TextEditingController _floorController;
  late final TextEditingController _contactNameController;
  late final TextEditingController _contactPhoneController;
  _AddressDraft _draft = const _AddressDraft();
  bool _loading = false;
  bool _loadError = false;
  bool _saving = false;
  bool _locating = false;
  String? _errorMessage;

  bool get _isEditing => widget.addressId?.isNotEmpty == true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress is _SavedAddress
        ? widget.initialAddress as _SavedAddress
        : null;
    _draft = _AddressDraft(
      label: initial?.label ?? '',
      address: initial?.address ?? '',
      floor: initial?.floor ?? '',
      latitude: initial?.latitude,
      longitude: initial?.longitude,
      city: initial?.city ?? '',
      addressType: initial?.addressType ?? 'pickup',
      contactName: initial?.contactName ?? '',
      contactPhone: initial?.contactPhone ?? '',
    );
    _labelController = TextEditingController(text: _draft.label);
    _addressController = TextEditingController(text: _draft.address);
    _floorController = TextEditingController(text: _draft.floor);
    _contactNameController = TextEditingController(text: _draft.contactName);
    _contactPhoneController = TextEditingController(text: _draft.contactPhone);
    if (_isEditing && initial == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitialAddress();
      });
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _floorController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _applyAddress(_SavedAddress address) {
    _draft = _AddressDraft(
      label: address.label,
      address: address.address,
      floor: address.floor,
      latitude: address.latitude,
      longitude: address.longitude,
      city: address.city,
      addressType: address.addressType,
      contactName: address.contactName,
      contactPhone: address.contactPhone,
    );
    _labelController.text = _draft.label;
    _addressController.text = _draft.address;
    _floorController.text = _draft.floor;
    _contactNameController.text = _draft.contactName;
    _contactPhoneController.text = _draft.contactPhone;
  }

  Future<void> _loadInitialAddress() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final id = widget.addressId;
    if (session == null || id == null || id.isEmpty || !mounted) return;

    setState(() {
      _loading = true;
      _loadError = false;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .getSavedAddresses(accessToken: session.tokens.accessToken);
      _SavedAddress? found;
      for (final address in _parseAddresses(response)) {
        if (address.id == id) {
          found = address;
          break;
        }
      }
      if (!mounted) return;
      if (found == null) {
        setState(() {
          _loadError = true;
        });
      } else {
        final loadedAddress = found;
        setState(() {
          _applyAddress(loadedAddress);
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    final address = _addressController.text.trim();
    final floor = _floorController.text.trim();
    final contactName = _contactNameController.text.trim();
    final contactPhone = _contactPhoneController.text.trim();

    if (label.isEmpty) {
      setState(() {
        _errorMessage = 'Give this address a name, such as Home or Warehouse.';
      });
      return;
    }
    if (address.isEmpty) {
      setState(() {
        _errorMessage = 'Search and select an address from Google Maps.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _errorMessage = null;
    });

    try {
      final session = ref.read(authSessionProvider).valueOrNull;
      if (session == null) {
        throw const ApiException('Please sign in again to save this address.');
      }
      final draft = _draft.copyWith(
        label: label,
        address: address,
        floor: floor,
        contactName: contactName,
        contactPhone: contactPhone,
      );
      final api = ref.read(apiClientProvider);
      if (_isEditing) {
        await api.updateSavedAddress(
          accessToken: session.tokens.accessToken,
          id: widget.addressId!,
          label: draft.label,
          address: draft.address,
          floor: draft.floor,
          latitude: draft.latitude,
          longitude: draft.longitude,
          city: draft.city,
          addressType: draft.addressType,
          contactName: draft.contactName,
          contactPhone: draft.contactPhone,
        );
      } else {
        await api.createSavedAddress(
          accessToken: session.tokens.accessToken,
          label: draft.label,
          address: draft.address,
          floor: draft.floor,
          latitude: draft.latitude,
          longitude: draft.longitude,
          city: draft.city,
          addressType: draft.addressType,
          contactName: draft.contactName,
          contactPhone: draft.contactPhone,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Address updated.' : 'Address saved.'),
        ),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException
            ? error.message
            : error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Future<void> _openMapPicker() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final initialTarget = _draft.latitude != null && _draft.longitude != null
        ? LatLng(_draft.latitude!, _draft.longitude!)
        : const LatLng(19.0760, 72.8777);

    final selection = await Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _SavedAddressMapPicker(
          initialTarget: initialTarget,
          initialAddress: _addressController.text.trim(),
        ),
      ),
    );

    if (selection == null || !mounted) return;
    final latitude = selection.latitude;
    final longitude = selection.longitude;
    if (latitude == null || longitude == null) return;

    final fallback =
        'Pinned location (${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)})';
    final address = selection.formattedAddress.trim().isNotEmpty
        ? selection.formattedAddress.trim()
        : fallback;

    setState(() {
      _addressController.text = address;
      _draft = _draft.copyWith(
        address: address,
        latitude: latitude,
        longitude: longitude,
        city: selection.city,
      );
      _errorMessage = null;
    });
  }

  Future<void> _applyPoint(LatLng point) async {
    setState(() {
      _draft = _draft.copyWith(
        latitude: point.latitude,
        longitude: point.longitude,
      );
      _locating = true;
      _errorMessage = null;
    });

    try {
      final resolved = await ref
          .read(googlePlacesServiceProvider)
          .reverseGeocode(latitude: point.latitude, longitude: point.longitude);
      if (!mounted) return;
      final fallback =
          'Pinned location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
      final address = resolved.isNotEmpty ? resolved : fallback;
      setState(() {
        _addressController.text = address;
        _draft = _draft.copyWith(address: address);
      });
    } catch (_) {
      if (!mounted) return;
      final fallback =
          'Pinned location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
      setState(() {
        _addressController.text = fallback;
        _draft = _draft.copyWith(address: fallback);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve this map point.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _locating = false;
        });
      }
    }
  }

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _locating = true;
      _errorMessage = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw const ApiException('Location services are turned off.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const ApiException('Location permission is required.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;
      setState(() {
        _locating = false;
      });
      await _applyPoint(LatLng(position.latitude, position.longitude));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _locating = false;
        _errorMessage = error is ApiException
            ? error.message
            : 'Could not get your current location.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCoordinates = _draft.latitude != null && _draft.longitude != null;
    final title = _isEditing ? 'Edit Address' : 'Add Address';

    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FB),
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(false),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(title),
        ),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF2FA56E)),
                const SizedBox(height: 12),
                Text(
                  'Loading address...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_loadError) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF5F7FB),
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(false),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(title),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              _EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Could not load this address',
                subtitle:
                    'Go back to saved addresses and try editing it again.',
                actionLabel: 'Back to Saved Addresses',
                onAction: () => context.pop(false),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(false),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(title),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 840;
            final mapPosition = hasCoordinates
                ? LatLng(_draft.latitude!, _draft.longitude!)
                : const LatLng(19.0760, 72.8777);

            final form = _AddressFormSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(text: 'Type'),
                  const SizedBox(height: 8),
                  _AddressTypeSelector(
                    value: _draft.addressType,
                    onChanged: (value) => setState(
                      () => _draft = _draft.copyWith(addressType: value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Name'),
                  const SizedBox(height: 8),
                  _CardField(
                    leading: Icons.business_outlined,
                    child: TextField(
                      controller: _labelController,
                      maxLength: 60,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Home, Office, Warehouse 2',
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const _FieldLabel(text: 'Address'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _locating ? null : _useCurrentLocation,
                        icon: _locating
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location_rounded, size: 15),
                        label: const Text('Use current'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF2FA56E),
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _CardField(
                    leading: Icons.location_on_outlined,
                    child: GooglePlacesAutocompleteField(
                      controller: _addressController,
                      label: '',
                      hintText: 'Search, or tap the map...',
                      showLabel: false,
                      onSelected: (selection) {
                        setState(() {
                          _draft = _draft.copyWith(
                            address: selection.formattedAddress,
                            latitude: selection.latitude,
                            longitude: selection.longitude,
                            city: selection.city,
                          );
                          _errorMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Search, tap the map, or drag the pin once it is placed.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      height: 1.3,
                    ),
                  ),
                  if (_draft.city.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'City: ${_draft.city}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'Floor / Unit', trailing: '(optional)'),
                  const SizedBox(height: 8),
                  _CardField(
                    child: TextField(
                      controller: _floorController,
                      maxLength: 100,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: '3rd Floor, Flat 402, Gate 2',
                        counterText: '',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _FieldLabel(text: 'On-site Contact', trailing: '(optional)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _CardField(
                          child: TextField(
                            controller: _contactNameController,
                            maxLength: 60,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              hintText: 'Contact name',
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CardField(
                          leading: Icons.phone_outlined,
                          child: TextField(
                            controller: _contactPhoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 20,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: '+91',
                              counterText: '',
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(message: _errorMessage!),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2FA56E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(_isEditing ? 'Save Changes' : 'Save Address'),
                    ),
                  ),
                ],
              ),
            );

            final map = _EditorMapPanel(
              hasCoordinates: hasCoordinates,
              position: mapPosition,
              address: _addressController.text.trim(),
              resolving: _locating,
              onTapPoint: _applyPoint,
              onDragEnd: _applyPoint,
              onFullscreen: _openMapPicker,
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              children: [
                if (wide)
                  SizedBox(
                    height: constraints.maxHeight - 24,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: SingleChildScrollView(child: form)),
                        const SizedBox(width: 16),
                        Expanded(child: map),
                      ],
                    ),
                  )
                else ...[
                  form,
                  const SizedBox(height: 14),
                  SizedBox(height: 360, child: map),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AddressFormSurface extends StatelessWidget {
  const _AddressFormSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _savedCardDecoration(radius: 22),
      child: child,
    );
  }
}

class _EditorMapPanel extends StatelessWidget {
  const _EditorMapPanel({
    required this.hasCoordinates,
    required this.position,
    required this.address,
    required this.resolving,
    required this.onTapPoint,
    required this.onDragEnd,
    required this.onFullscreen,
  });

  final bool hasCoordinates;
  final LatLng position;
  final String address;
  final bool resolving;
  final ValueChanged<LatLng> onTapPoint;
  final ValueChanged<LatLng> onDragEnd;
  final VoidCallback onFullscreen;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          GoogleMap(
            key: ValueKey(
              '${position.latitude.toStringAsFixed(6)}:${position.longitude.toStringAsFixed(6)}:$hasCoordinates',
            ),
            initialCameraPosition: CameraPosition(target: position, zoom: 15),
            markers: hasCoordinates
                ? {
                    Marker(
                      markerId: const MarkerId('saved-address-editor'),
                      position: position,
                      draggable: true,
                      onDragEnd: onDragEnd,
                    ),
                  }
                : const <Marker>{},
            onTap: onTapPoint,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
          ),
          Positioned(
            left: 12,
            top: 12,
            child: IconButton(
              onPressed: onFullscreen,
              tooltip: 'Open map picker',
              icon: const Icon(Icons.open_in_full_rounded, size: 18),
              color: const Color(0xFF344054),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: resolving
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.location_on_outlined,
                            color: Color(0xFF2FA56E),
                          ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      address.isEmpty
                          ? 'Tap the map to choose an exact spot'
                          : address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF344054),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
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

class _SavedAddressMapPicker extends ConsumerStatefulWidget {
  const _SavedAddressMapPicker({
    required this.initialTarget,
    required this.initialAddress,
  });

  final LatLng initialTarget;
  final String initialAddress;

  @override
  ConsumerState<_SavedAddressMapPicker> createState() =>
      _SavedAddressMapPickerState();
}

class _SavedAddressMapPickerState
    extends ConsumerState<_SavedAddressMapPicker> {
  late LatLng _selectedPoint;
  late String _selectedAddress;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _selectedPoint = widget.initialTarget;
    _selectedAddress = widget.initialAddress;
  }

  Future<void> _selectPoint(LatLng point) async {
    setState(() {
      _selectedPoint = point;
      _resolving = true;
    });

    try {
      final address = await ref
          .read(googlePlacesServiceProvider)
          .reverseGeocode(latitude: point.latitude, longitude: point.longitude);
      if (!mounted) return;
      setState(() {
        _selectedAddress = address.isNotEmpty
            ? address
            : 'Pinned location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedAddress =
            'Pinned location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve this map point.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolving = false;
        });
      }
    }
  }

  void _useSelection() {
    Navigator.of(context).pop(
      GooglePlaceSelection(
        placeId: '',
        formattedAddress: _selectedAddress,
        latitude: _selectedPoint.latitude,
        longitude: _selectedPoint.longitude,
        city: '',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialTarget,
              zoom: 15,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('saved-address-picker'),
                position: _selectedPoint,
              ),
            },
            onTap: _selectPoint,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: const Color(0xFF101828),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _resolving ? null : _useSelection,
                    icon: _resolving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Use'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF101828).withValues(alpha: 0.16),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF6EF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.location_on_outlined,
                      color: Color(0xFF2FA56E),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedAddress.isEmpty
                          ? 'Tap the map to choose an exact spot'
                          : _selectedAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF344054),
                        fontWeight: FontWeight.w700,
                        height: 1.3,
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

class _AddressListTile extends StatelessWidget {
  const _AddressListTile({
    required this.address,
    required this.isDefaulting,
    required this.isDeleting,
    required this.onEdit,
    required this.onSetDefault,
    required this.onDelete,
  });

  final _SavedAddress address;
  final bool isDefaulting;
  final bool isDeleting;
  final VoidCallback onEdit;
  final VoidCallback? onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final meta = _AddressTypeMeta.from(address.addressType);
    return Container(
      decoration: _savedCardDecoration(radius: 14),
      padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: meta.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(meta.icon, color: meta.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        address.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF101828),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _AddressTypeChip(meta: meta, dense: true),
                  ],
                ),
                if (address.isDefault) ...[
                  const SizedBox(height: 5),
                  const _DefaultBadge(dense: true),
                ],
                const SizedBox(height: 6),
                Text(
                  address.address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.3,
                  ),
                ),
                if (address.floor.isNotEmpty ||
                    address.contactName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (address.floor.isNotEmpty) address.floor,
                      if (address.contactName.isNotEmpty)
                        [
                          address.contactName,
                          if (address.contactPhone.isNotEmpty)
                            address.contactPhone,
                        ].join(' · '),
                    ].join(' • '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(
            width: 32,
            child: Column(
              children: [
                if (!address.isDefault)
                  _AddressIconAction(
                    icon: Icons.star_outline_rounded,
                    onTap: isDefaulting ? null : onSetDefault,
                    loading: isDefaulting,
                    tooltip: 'Set default',
                  ),
                _AddressIconAction(
                  icon: Icons.edit_outlined,
                  onTap: onEdit,
                  tooltip: 'Edit',
                ),
                _AddressIconAction(
                  icon: Icons.delete_outline_rounded,
                  onTap: isDeleting ? null : onDelete,
                  loading: isDeleting,
                  danger: true,
                  tooltip: 'Remove',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressTypeMeta {
  const _AddressTypeMeta({
    required this.label,
    required this.icon,
    required this.background,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color background;
  final Color color;

  static _AddressTypeMeta from(String type) {
    if (type == 'dropoff') {
      return const _AddressTypeMeta(
        label: 'Drop-off',
        icon: Icons.remove_shopping_cart_outlined,
        background: Color(0xFFFFF7ED),
        color: Color(0xFFEA580C),
      );
    }
    return const _AddressTypeMeta(
      label: 'Pickup',
      icon: Icons.add_business_outlined,
      background: Color(0xFFEAF6EF),
      color: Color(0xFF2FA56E),
    );
  }
}

class _AddressTypeChip extends StatelessWidget {
  const _AddressTypeChip({required this.meta, this.dense = false});

  final _AddressTypeMeta meta;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: meta.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(meta.icon, size: dense ? 11 : 13, color: meta.color),
          const SizedBox(width: 5),
          Text(
            meta.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: meta.color,
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _DefaultBadge extends StatelessWidget {
  const _DefaultBadge({this.dense = false});

  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 7 : 9,
        vertical: dense ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF6EF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_rounded,
            size: dense ? 11 : 13,
            color: const Color(0xFF2FA56E),
          ),
          const SizedBox(width: 4),
          Text(
            'Default',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: const Color(0xFF2FA56E),
              fontSize: dense ? 10 : 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddressIconAction extends StatelessWidget {
  const _AddressIconAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.loading = false,
    this.danger = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  final bool loading;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: loading ? null : onTap,
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 30,
          height: 30,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    size: 17,
                    color: danger
                        ? const Color(0xFFE23A4B)
                        : const Color(0xFF98A2B3),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AddressTypeSelector extends StatelessWidget {
  const _AddressTypeSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AddressTypeOption(
            meta: _AddressTypeMeta.from('pickup'),
            selected: value != 'dropoff',
            onTap: () => onChanged('pickup'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _AddressTypeOption(
            meta: _AddressTypeMeta.from('dropoff'),
            selected: value == 'dropoff',
            onTap: () => onChanged('dropoff'),
          ),
        ),
      ],
    );
  }
}

class _AddressTypeOption extends StatelessWidget {
  const _AddressTypeOption({
    required this.meta,
    required this.selected,
    required this.onTap,
  });

  final _AddressTypeMeta meta;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? meta.background : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? meta.color.withValues(alpha: 0.35)
                : const Color(0xFFE4E7EC),
          ),
        ),
        child: Row(
          children: [
            Icon(meta.icon, color: meta.color, size: 18),
            const SizedBox(width: 8),
            Text(
              meta.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: selected ? meta.color : const Color(0xFF667085),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _savedCardDecoration({required double radius}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: const Color(0xFFF2F4F7)),
    boxShadow: [
      BoxShadow(
        color: const Color(0xFF101828).withValues(alpha: 0.06),
        blurRadius: 18,
        offset: const Offset(0, 8),
      ),
    ],
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: const Color(0xFF667085),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 6),
          Text(
            trailing!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF98A2B3)),
          ),
        ],
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.child, this.leading});

  final Widget child;
  final IconData? leading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            Icon(leading, size: 18, color: const Color(0xFFD0D5DD)),
            const SizedBox(width: 10),
          ],
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECDD6)),
      ),
      child: Text(
        message,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: const Color(0xFFB42318)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F4E8),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF2FA56E), size: 28),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF667085),
              height: 1.4,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onAction,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2FA56E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SavedAddress {
  const _SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.floor,
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.addressType,
    required this.contactName,
    required this.contactPhone,
    required this.isDefault,
  });

  final String id;
  final String label;
  final String address;
  final String floor;
  final double? latitude;
  final double? longitude;
  final String city;
  final String addressType;
  final String contactName;
  final String contactPhone;
  final bool isDefault;

  factory _SavedAddress.fromJson(Map<String, dynamic> json) {
    return _SavedAddress(
      id: _readString(json, const ['id']),
      label: _readString(json, const ['label']),
      address: _readString(json, const ['address']),
      floor: _readString(json, const ['floor']),
      latitude: _readDouble(json, const ['lat', 'latitude']),
      longitude: _readDouble(json, const ['lng', 'longitude']),
      city: _readString(json, const ['city']),
      addressType:
          _readString(json, const [
                'addressType',
                'address_type',
              ]).toLowerCase() ==
              'dropoff'
          ? 'dropoff'
          : 'pickup',
      contactName: _readString(json, const [
        'contactName',
        'contact_name',
        'contact_person',
      ]),
      contactPhone: _readString(json, const [
        'contactPhone',
        'contact_phone',
        'phone',
      ]),
      isDefault: _readBool(json, const ['isDefault', 'is_default']),
    );
  }

  _SavedAddress copyWith({
    String? label,
    String? address,
    String? floor,
    double? latitude,
    double? longitude,
    String? city,
    String? addressType,
    String? contactName,
    String? contactPhone,
    bool? isDefault,
  }) {
    return _SavedAddress(
      id: id,
      label: label ?? this.label,
      address: address ?? this.address,
      floor: floor ?? this.floor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      addressType: addressType ?? this.addressType,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class _AddressDraft {
  const _AddressDraft({
    this.label = '',
    this.address = '',
    this.floor = '',
    this.latitude,
    this.longitude,
    this.city = '',
    this.addressType = 'pickup',
    this.contactName = '',
    this.contactPhone = '',
  });

  final String label;
  final String address;
  final String floor;
  final double? latitude;
  final double? longitude;
  final String city;
  final String addressType;
  final String contactName;
  final String contactPhone;

  _AddressDraft copyWith({
    String? label,
    String? address,
    String? floor,
    double? latitude,
    double? longitude,
    String? city,
    String? addressType,
    String? contactName,
    String? contactPhone,
  }) {
    return _AddressDraft(
      label: label ?? this.label,
      address: address ?? this.address,
      floor: floor ?? this.floor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      addressType: addressType ?? this.addressType,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
    );
  }
}

List<_SavedAddress> _parseAddresses(Map<String, dynamic> response) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final raw =
      data['addresses'] ??
      data['items'] ??
      data['results'] ??
      data['rows'] ??
      data['data'];
  final list = raw is List ? raw : const <dynamic>[];
  return list
      .whereType<Map<String, dynamic>>()
      .map(_SavedAddress.fromJson)
      .where((address) => address.id.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _pickItem(Map<String, dynamic> response, String key) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final item = data[key];
  if (item is Map<String, dynamic>) {
    return item;
  }
  return const <String, dynamic>{};
}

String _readString(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return '';
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final parsed = double.tryParse(value);
      if (parsed != null) {
        return parsed;
      }
    }
  }
  return null;
}

bool _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
  }
  return false;
}
