import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../widgets/broker_flow_widgets.dart';

class AddDriverScreen extends ConsumerStatefulWidget {
  const AddDriverScreen({super.key, this.existingDriver});

  final BrokerDriver? existingDriver;

  @override
  ConsumerState<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends ConsumerState<AddDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _aadhaarController = TextEditingController();
  final _licenseExpiryController = TextEditingController();
  final _truckIdController = TextEditingController();
  final _picker = ImagePicker();

  String? _selectedTruckId;
  String? _selectedStatus;
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  Uint8List? _pickedAvatarBytes;
  String? _pickedAvatarDataUrl;
  String? _originalAvatarUrl;

  bool get _isEditing => widget.existingDriver != null;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _aadhaarController.dispose();
    _licenseExpiryController.dispose();
    _truckIdController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    final driver = widget.existingDriver;
    if (driver == null) {
      return;
    }

    _nameController.text = driver.name;
    _phoneController.text = driver.phone;
    _licenseController.text = driver.licenseNo;
    _aadhaarController.text = driver.aadhaar;
    _licenseExpiryController.text = driver.licenseExpiry;
    _originalAvatarUrl = driver.avatar;
    _selectedStatus = _driverStatusToApiValue(driver.status);
    if (driver.assignedVehicle.isNotEmpty) {
      _truckIdController.text = driver.assignedVehicle;
    }
  }

  bool get _hasPickedAvatar => _pickedAvatarBytes != null;

  String? get _avatarPreviewUrl => _hasPickedAvatar ? null : _originalAvatarUrl;

  String _mimeTypeForName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  String _buildDataUrl(Uint8List bytes, String name) {
    final mimeType = _mimeTypeForName(name);
    return 'data:$mimeType;base64,${base64Encode(bytes)}';
  }

  Future<void> _pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) {
      return;
    }

    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }

    setState(() {
      _pickedAvatarBytes = bytes;
      _pickedAvatarDataUrl = _buildDataUrl(bytes, picked.name);
    });
  }

  Future<void> _pickLicenseExpiry() async {
    final currentText = _licenseExpiryController.text.trim();
    final today = DateTime.now();
    final parsedDate = DateTime.tryParse(currentText);
    final initialDate = parsedDate == null || parsedDate.isBefore(today)
        ? today.add(const Duration(days: 365))
        : parsedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 20)),
    );

    if (picked == null) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _licenseExpiryController.text = _isoDate(picked);
    });
  }

  Future<void> _submitDriver(List<BrokerVehicle> trucks) async {
    if (_isSubmitting) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to create a driver.'),
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final licenseNo = _licenseController.text.trim();
    final aadhaar = _aadhaarController.text.replaceAll(' ', '').trim();
    final licenseExpiry = _licenseExpiryController.text.trim();
    final manualTruckId = _truckIdController.text.trim();
    final avatar = _pickedAvatarDataUrl ?? _originalAvatarUrl ?? '';
    final selectedTruck = _selectedTruckId == null
        ? null
        : _truckById(trucks, _selectedTruckId!);
    final selectedTruckLabel = selectedTruck?.label ?? '';
    final selectedTruckPlate = selectedTruck?.plateNumber ?? '';
    final truckId = selectedTruck != null ? selectedTruck.id : manualTruckId;
    String? createdUserId;
    BrokerDriver? recoveredDriver;

    if (truckId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a truck or enter a truck ID.'),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      if (_isEditing) {
        await apiClient.updateDriverProfile(
          accessToken: session.tokens.accessToken,
          id: widget.existingDriver!.id,
          driver:
              {
                'license_no': licenseNo,
                'license_expiry': licenseExpiry,
                'aadhaar': aadhaar,
                'truck_id': truckId,
                if (avatar.isNotEmpty) 'avatar': avatar,
                if (_selectedStatus != null && _selectedStatus!.isNotEmpty)
                  'status': _selectedStatus,
              }..removeWhere(
                (key, value) =>
                    value == null || value.toString().trim().isEmpty,
              ),
        );
      } else {
        try {
          final registrationResponse = await apiClient.register(
            name: name,
            email: email,
            password: password,
            phone: phone.isEmpty ? null : phone,
            role: 'driver',
          );

          final userId = _extractUserId(registrationResponse);
          if (userId.isEmpty) {
            throw StateError('Could not determine the created driver user id.');
          }
          createdUserId = userId;
        } on ApiException catch (error) {
          if (error.statusCode != 409) {
            rethrow;
          }

          recoveredDriver = await _findRecoveredDriver(
            ref: ref,
            name: name,
            phone: phone,
            licenseNo: licenseNo,
            aadhaar: aadhaar,
          );
          if (recoveredDriver == null) {
            rethrow;
          }

          createdUserId = recoveredDriver.id;
        }

        if (recoveredDriver == null) {
          try {
            await apiClient.createDriverProfile(
              accessToken: session.tokens.accessToken,
              driver:
                  {
                    'user_id': createdUserId,
                    'license_no': licenseNo,
                    'license_expiry': licenseExpiry,
                    'aadhaar': aadhaar,
                    'truck_id': truckId,
                    if (avatar.isNotEmpty) 'avatar': avatar,
                  }..removeWhere(
                    (key, value) =>
                        value == null || value.toString().trim().isEmpty,
                  ),
            );
          } on ApiException {
            recoveredDriver = await _findRecoveredDriver(
              ref: ref,
              name: name,
              phone: phone,
              licenseNo: licenseNo,
              aadhaar: aadhaar,
            );
            if (recoveredDriver == null) {
              rethrow;
            }
            createdUserId = recoveredDriver.id;
          }
        }
      }

      if (!mounted) return;

      final effectiveDriverId =
          createdUserId ?? recoveredDriver?.id ?? widget.existingDriver!.id;
      final notifier = ref.read(brokerDriversProvider.notifier);
      final updatedDriver = BrokerDriver(
        id: effectiveDriverId,
        name: name,
        phone: phone.isEmpty ? '+91 90000 00000' : phone,
        licenseNo: licenseNo,
        licenseExpiry: licenseExpiry,
        aadhaar: aadhaar,
        avatar: avatar,
        vehicleType: selectedTruckLabel.isNotEmpty
            ? selectedTruckLabel
            : 'Assigned truck',
        status: _selectedStatus == null
            ? (widget.existingDriver?.status ?? BrokerDriverStatus.offline)
            : _driverStatusFromApi(_selectedStatus!),
        currentLocation:
            widget.existingDriver?.currentLocation ?? 'Awaiting activation',
        assignedVehicle: selectedTruckPlate.isNotEmpty
            ? selectedTruckPlate
            : truckId,
        onTripSince: widget.existingDriver?.onTripSince ?? '',
        currentBookingRef: widget.existingDriver?.currentBookingRef ?? '',
      );

      notifier.state = [
        updatedDriver,
        ...notifier.state.where((driver) => driver.id != updatedDriver.id),
      ];
      ref.invalidate(
        brokerDriversApiProvider((status: null, page: 1, limit: 10)),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver profile saved successfully.'),
          backgroundColor: Color(0xFF2FA56E),
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFFE23A4B),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trucksAsync = ref.watch(
      brokerTrucksProvider((status: null, page: 1, limit: 50)),
    );
    final trucks = trucksAsync.valueOrNull ?? const <BrokerVehicle>[];
    final driver = widget.existingDriver;
    final selectedTruckId =
        _selectedTruckId ??
        (driver == null
            ? null
            : _truckIdForDriver(trucks, driver.assignedVehicle));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit driver' : 'Add driver'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/broker/tracking'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Center(
            child: Column(
              children: [
                SskProfileAvatar(
                  imageUrl: _avatarPreviewUrl,
                  imageBytes: _pickedAvatarBytes,
                  size: 108,
                  onTap: _pickAvatar,
                ),
                const SizedBox(height: 10),
                Text(
                  'Tap to choose driver photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE8EDF2)),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3EEFF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_rounded,
                    color: Color(0xFF7A5AF8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditing
                        ? 'Update the driver profile details and save the changes.'
                        : 'Create a driver login, then attach the driver profile to a truck.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Form(
            key: _formKey,
            child: Column(
              children: [
                if (!_isEditing) ...[
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icons.person_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter full name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      labelText: 'Email',
                      prefixIcon: Icons.email_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter email';
                      }
                      if (!value.contains('@')) {
                        return 'Enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
                    ],
                    decoration: _fieldDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icons.phone_rounded,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(
                        Icons.lock_rounded,
                        color: Color(0xFF667085),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF1F88C9),
                          width: 1.4,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter password';
                      }
                      if (value.length < 8) {
                        return 'Use at least 8 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                ] else ...[
                  _ReadonlyDriverHeader(driver: driver!),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _licenseController,
                  textInputAction: TextInputAction.next,
                  decoration: _fieldDecoration(
                    labelText: 'License number',
                    prefixIcon: Icons.badge_rounded,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter license number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _aadhaarController,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(12),
                  ],
                  decoration: _fieldDecoration(
                    labelText: 'Aadhaar number',
                    prefixIcon: Icons.credit_card_rounded,
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(' ', '').trim() ?? '';
                    if (digits.isEmpty) {
                      return 'Enter Aadhaar number';
                    }
                    if (digits.length != 12) {
                      return 'Aadhaar must be 12 digits';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _licenseExpiryController,
                  readOnly: true,
                  onTap: _pickLicenseExpiry,
                  decoration:
                      _fieldDecoration(
                        labelText: 'License expiry',
                        prefixIcon: Icons.event_rounded,
                        hintText: 'YYYY-MM-DD',
                      ).copyWith(
                        suffixIcon: IconButton(
                          onPressed: _pickLicenseExpiry,
                          icon: const Icon(Icons.calendar_month_rounded),
                          tooltip: 'Pick date',
                        ),
                      ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Select license expiry';
                    }
                    if (DateTime.tryParse(value.trim()) == null) {
                      return 'Use a valid date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                if (trucks.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: selectedTruckId,
                    decoration: _fieldDecoration(
                      labelText: 'Assign truck',
                      prefixIcon: Icons.local_shipping_rounded,
                    ),
                    items: trucks
                        .map(
                          (truck) => DropdownMenuItem<String>(
                            value: truck.id,
                            child: Text(
                              '${truck.label} • ${truck.plateNumber}',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedTruckId = value),
                    validator: (value) {
                      if ((value ?? '').isEmpty) {
                        return 'Select a truck';
                      }
                      return null;
                    },
                  )
                else
                  TextFormField(
                    controller: _truckIdController,
                    textInputAction: TextInputAction.next,
                    decoration: _fieldDecoration(
                      labelText: 'Truck ID',
                      prefixIcon: Icons.local_shipping_rounded,
                      hintText: 'Enter truck UUID',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter truck ID';
                      }
                      return null;
                    },
                  ),
                const SizedBox(height: 12),
                if (_isEditing)
                  DropdownButtonFormField<String>(
                    initialValue:
                        _selectedStatus ??
                        _driverStatusToApiValue(driver!.status),
                    decoration: _fieldDecoration(
                      labelText: 'Status',
                      prefixIcon: Icons.toggle_on_rounded,
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: 'available',
                        child: Text('Available'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'on_trip',
                        child: Text('On trip'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'offline',
                        child: Text('Offline'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedStatus = value),
                  ),
                if (_isEditing) const SizedBox(height: 12),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => _submitDriver(trucks),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F88C9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _isEditing ? 'Update driver' : 'Create driver',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                if (trucksAsync.hasError) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Truck list could not be loaded. You can still enter a truck ID manually.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadonlyDriverHeader extends StatelessWidget {
  const _ReadonlyDriverHeader({required this.driver});

  final BrokerDriver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            driver.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            driver.phone,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
          ),
        ],
      ),
    );
  }
}

InputDecoration _fieldDecoration({
  required String labelText,
  required IconData prefixIcon,
  String? hintText,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    filled: true,
    fillColor: Colors.white,
    prefixIcon: Icon(prefixIcon, color: const Color(0xFF667085)),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFFE3E8EF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF1F88C9), width: 1.4),
    ),
  );
}

String _isoDate(DateTime date) {
  return date.toIso8601String().split('T').first;
}

String _driverStatusToApiValue(BrokerDriverStatus status) {
  switch (status) {
    case BrokerDriverStatus.onTrip:
      return 'on_trip';
    case BrokerDriverStatus.idle:
      return 'available';
    case BrokerDriverStatus.offline:
      return 'offline';
  }
}

BrokerDriverStatus _driverStatusFromApi(String status) {
  switch (status.toLowerCase()) {
    case 'on_trip':
    case 'in_transit':
    case 'assigned':
      return BrokerDriverStatus.onTrip;
    case 'available':
    case 'idle':
      return BrokerDriverStatus.idle;
    case 'offline':
    default:
      return BrokerDriverStatus.offline;
  }
}

BrokerVehicle? _truckById(List<BrokerVehicle> trucks, String id) {
  for (final truck in trucks) {
    if (truck.id == id) {
      return truck;
    }
  }
  return null;
}

String? _truckIdForDriver(List<BrokerVehicle> trucks, String assignedVehicle) {
  for (final truck in trucks) {
    if (truck.id == assignedVehicle || truck.plateNumber == assignedVehicle) {
      return truck.id;
    }
  }
  return null;
}

String _extractUserId(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    final nestedUser = data['user'];
    if (nestedUser is Map<String, dynamic>) {
      final userId = nestedUser['id']?.toString().trim();
      if (userId != null && userId.isNotEmpty) {
        return userId;
      }
    }

    final dataId = data['id']?.toString().trim();
    if (dataId != null && dataId.isNotEmpty) {
      return dataId;
    }

    final userId = data['user_id']?.toString().trim();
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
  }

  final rootId = response['user_id']?.toString().trim();
  if (rootId != null && rootId.isNotEmpty) {
    return rootId;
  }

  final rootDataId = response['id']?.toString().trim();
  if (rootDataId != null && rootDataId.isNotEmpty) {
    return rootDataId;
  }

  return '';
}

Future<BrokerDriver?> _findRecoveredDriver({
  required WidgetRef ref,
  required String name,
  required String phone,
  required String licenseNo,
  required String aadhaar,
}) async {
  try {
    final drivers = await ref.read(
      brokerDriversApiProvider((status: null, page: 1, limit: 100)).future,
    );
    for (final driver in drivers) {
      if (_matchesRecoveredDriver(
        driver,
        name: name,
        phone: phone,
        licenseNo: licenseNo,
        aadhaar: aadhaar,
      )) {
        return driver;
      }
    }
  } catch (_) {
    // If we cannot refresh the driver list, surface the original backend error.
  }

  return null;
}

bool _matchesRecoveredDriver(
  BrokerDriver driver, {
  required String name,
  required String phone,
  required String licenseNo,
  required String aadhaar,
}) {
  final normalizedName = _normalizeLookupValue(name);
  final normalizedPhone = _normalizeLookupValue(phone);
  final normalizedLicense = _normalizeLookupValue(licenseNo);
  final normalizedAadhaar = _normalizeLookupValue(aadhaar);

  final driverName = _normalizeLookupValue(driver.name);
  final driverPhone = _normalizeLookupValue(driver.phone);
  final driverLicense = _normalizeLookupValue(driver.licenseNo);
  final driverAadhaar = _normalizeLookupValue(driver.aadhaar);

  final strongMatch =
      normalizedLicense.isNotEmpty && normalizedLicense == driverLicense;
  final aadhaarMatch =
      normalizedAadhaar.isNotEmpty && normalizedAadhaar == driverAadhaar;
  final phoneMatch =
      normalizedPhone.isNotEmpty && normalizedPhone == driverPhone;
  final nameMatch = normalizedName.isNotEmpty && normalizedName == driverName;

  return strongMatch ||
      (phoneMatch && (nameMatch || normalizedLicense.isEmpty)) ||
      (aadhaarMatch && (nameMatch || normalizedPhone.isEmpty));
}

String _normalizeLookupValue(String value) {
  return value.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase().trim();
}
