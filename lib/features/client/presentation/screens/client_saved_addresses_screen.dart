import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
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
  bool _loading = true;
  bool _error = false;
  String? _deletingId;
  String? _defaultingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
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
      final response = await ref.read(apiClientProvider).getSavedAddresses(
            accessToken: session.tokens.accessToken,
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _SavedAddressEditorSheet(
          initialAddress: address,
          onSave: (draft) async {
            final api = ref.read(apiClientProvider);
            if (address == null) {
              final response = await api.createSavedAddress(
                accessToken: session.tokens.accessToken,
                label: draft.label,
                address: draft.address,
                floor: draft.floor,
                latitude: draft.latitude,
                longitude: draft.longitude,
                city: draft.city,
              );
              final saved = _SavedAddress.fromJson(
                _pickItem(response, 'address'),
              );
              if (saved.id.isNotEmpty) {
                if (mounted) {
                  setState(() {
                    _addresses.insert(0, saved);
                  });
                }
              } else {
                await _load();
              }
            } else {
              final response = await api.updateSavedAddress(
                accessToken: session.tokens.accessToken,
                id: address.id,
                label: draft.label,
                address: draft.address,
                floor: draft.floor,
                latitude: draft.latitude,
                longitude: draft.longitude,
                city: draft.city,
              );
              final updated = _SavedAddress.fromJson(
                _pickItem(response, 'address'),
              );
              if (updated.id.isNotEmpty && mounted) {
                setState(() {
                  final index = _addresses.indexWhere((item) => item.id == address.id);
                  if (index != -1) {
                    _addresses[index] = updated;
                  }
                });
              } else {
                await _load();
              }
            }
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    address == null ? 'Address saved.' : 'Address updated.',
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _setDefault(_SavedAddress address) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null || _defaultingId == address.id) return;

    setState(() {
      _defaultingId = address.id;
    });

    try {
      final response = await ref.read(apiClientProvider).setDefaultSavedAddress(
            accessToken: session.tokens.accessToken,
            id: address.id,
          );
      final updated = _SavedAddress.fromJson(_pickItem(response, 'address'));
      if (!mounted) return;
      setState(() {
        if (updated.id.isNotEmpty) {
          for (var i = 0; i < _addresses.length; i++) {
            _addresses[i] = _addresses[i].copyWith(isDefault: _addresses[i].id == address.id);
          }
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
      await ref.read(apiClientProvider).deleteSavedAddress(
            accessToken: session.tokens.accessToken,
            id: address.id,
          );
      if (!mounted) return;
      setState(() {
        _addresses.removeWhere((item) => item.id == address.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address removed.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
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
        actions: [
          IconButton(
            onPressed: _openEditor,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add address',
          ),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2FA56E),
        onRefresh: _load,
        child: session == null
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                children: const [
                  _EmptyState(
                    icon: Icons.lock_outline_rounded,
                    title: 'Sign in to manage addresses',
                    subtitle: 'We need an active client session before we can load your saved locations.',
                  ),
                ],
              )
            : _loading
                ? const Center(child: CircularProgressIndicator())
                : _error
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                        children: [
                          _EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Could not load saved addresses',
                            subtitle: 'Pull to refresh or try again in a moment.',
                            actionLabel: 'Retry',
                            onAction: _load,
                          ),
                        ],
                      )
                    : _addresses.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                            children: [
                              _EmptyState(
                                icon: Icons.location_on_outlined,
                                title: 'No saved addresses yet',
                                subtitle: 'Save your frequent pickup and drop-off locations to check out faster next time.',
                                actionLabel: 'Add Address',
                                onAction: _openEditor,
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                            itemCount: _addresses.length + 1,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              if (index == _addresses.length) {
                                return _AddTile(onTap: _openEditor);
                              }
                              final address = _addresses[index];
                              return _AddressCard(
                                address: address,
                                isDefaulting: _defaultingId == address.id,
                                isDeleting: _deletingId == address.id,
                                onEdit: () => _openEditor(address: address),
                                onSetDefault: address.isDefault
                                    ? null
                                    : () => _setDefault(address),
                                onDelete: () => _deleteAddress(address),
                              );
                            },
                          ),
      ),
    );
  }
}

class _SavedAddressEditorSheet extends ConsumerStatefulWidget {
  const _SavedAddressEditorSheet({
    required this.onSave,
    this.initialAddress,
  });

  final _SavedAddress? initialAddress;
  final Future<void> Function(_AddressDraft draft) onSave;

  @override
  ConsumerState<_SavedAddressEditorSheet> createState() =>
      _SavedAddressEditorSheetState();
}

class _SavedAddressEditorSheetState
    extends ConsumerState<_SavedAddressEditorSheet> {
  late final TextEditingController _labelController;
  late final TextEditingController _addressController;
  late final TextEditingController _floorController;
  _AddressDraft _draft = const _AddressDraft();
  bool _saving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialAddress;
    _draft = _AddressDraft(
      label: initial?.label ?? '',
      address: initial?.address ?? '',
      floor: initial?.floor ?? '',
      latitude: initial?.latitude,
      longitude: initial?.longitude,
      city: initial?.city ?? '',
    );
    _labelController = TextEditingController(text: _draft.label);
    _addressController = TextEditingController(text: _draft.address);
    _floorController = TextEditingController(text: _draft.floor);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _floorController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final label = _labelController.text.trim();
    final address = _addressController.text.trim();
    final floor = _floorController.text.trim();

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
      await widget.onSave(
        _draft.copyWith(
          label: label,
          address: address,
          floor: floor,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error is ApiException ? error.message : error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasCoordinates =
        _draft.latitude != null && _draft.longitude != null;

    return Padding(
      padding: EdgeInsets.only(left: 12, right: 12, bottom: bottomInset + 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 54,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1E5EB),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.initialAddress == null ? 'Add Address' : 'Edit Address',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF101828),
                    ),
              ),
              const SizedBox(height: 16),
              _FieldLabel(text: 'Name'),
              const SizedBox(height: 8),
              _CardField(
                child: TextField(
                  controller: _labelController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Home, Office, Warehouse 2',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _FieldLabel(text: 'Address'),
              const SizedBox(height: 8),
              _CardField(
                child: GooglePlacesAutocompleteField(
                  controller: _addressController,
                  label: '',
                  hintText: 'Search on Google Maps...',
                  showLabel: false,
                  onSelected: (selection) {
                    setState(() {
                      _draft = _draft.copyWith(
                        address: selection.formattedAddress,
                        latitude: selection.latitude,
                        longitude: selection.longitude,
                        city: selection.city,
                      );
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pick a Google result to save coordinates for quick re-use later.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
              ),
              if (hasCoordinates) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 170,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _draft.latitude!,
                          _draft.longitude!,
                        ),
                        zoom: 15,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId('saved-address'),
                          position: LatLng(
                            _draft.latitude!,
                            _draft.longitude!,
                          ),
                        ),
                      },
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      scrollGesturesEnabled: false,
                      rotateGesturesEnabled: false,
                      tiltGesturesEnabled: false,
                      myLocationButtonEnabled: false,
                      compassEnabled: false,
                    ),
                  ),
                ),
              ],
              if (_draft.city.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'City: ${_draft.city}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                      ),
                ),
              ],
              const SizedBox(height: 14),
              _FieldLabel(
                text: 'Floor / Unit',
                trailing: '(optional)',
              ),
              const SizedBox(height: 8),
              _CardField(
                child: TextField(
                  controller: _floorController,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    hintText: '3rd Floor, Flat 402, Gate 2',
                    border: InputBorder.none,
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 14),
                _InlineError(message: _errorMessage!),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2FA56E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
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
                      : Text(
                          widget.initialAddress == null
                              ? 'Save Address'
                              : 'Save Changes',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F4E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF2FA56E),
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
                            address.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101828),
                                ),
                          ),
                        ),
                        if (address.isDefault)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F4E8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Default',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: const Color(0xFF2FA56E),
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      address.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF667085),
                            height: 1.35,
                          ),
                    ),
                    if (address.floor.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        address.floor,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF98A2B3),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (onSetDefault != null)
                TextButton.icon(
                  onPressed: isDefaulting ? null : onSetDefault,
                  icon: isDefaulting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.star_outline_rounded, size: 18),
                  label: const Text('Set default'),
                ),
              const Spacer(),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit',
              ),
              IconButton(
                onPressed: isDeleting ? null : onDelete,
                icon: isDeleting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.delete_outline_rounded),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        height: 128,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFFB8DCC7),
            width: 1.5,
            style: BorderStyle.solid,
          ),
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
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF2FA56E),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Add Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
            ),
          ],
        ),
      ),
    );
  }
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF98A2B3),
                ),
          ),
        ],
      ],
    );
  }
}

class _CardField extends StatelessWidget {
  const _CardField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: child,
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
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFB42318),
            ),
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
    required this.isDefault,
  });

  final String id;
  final String label;
  final String address;
  final String floor;
  final double? latitude;
  final double? longitude;
  final String city;
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
  });

  final String label;
  final String address;
  final String floor;
  final double? latitude;
  final double? longitude;
  final String city;

  _AddressDraft copyWith({
    String? label,
    String? address,
    String? floor,
    double? latitude,
    double? longitude,
    String? city,
  }) {
    return _AddressDraft(
      label: label ?? this.label,
      address: address ?? this.address,
      floor: floor ?? this.floor,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
    );
  }
}

List<_SavedAddress> _parseAddresses(Map<String, dynamic> response) {
  final payload = response['data'];
  final data = payload is Map<String, dynamic> ? payload : response;
  final raw = data['addresses'] ?? data['items'] ?? data['results'] ?? data['rows'] ?? data['data'];
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
