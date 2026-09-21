import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
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

  String _normalizeDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

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
      maxWidth: 1600,
      maxHeight: 1600,
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
    final phone = _phoneController.text.trim();
    final licenseNo = _licenseController.text.trim();
    final aadhaar = _normalizeDigits(_aadhaarController.text);
    final licenseExpiry = _licenseExpiryController.text.trim();
    final manualTruckId = _truckIdController.text.trim();
    final avatar = _pickedAvatarDataUrl ?? _originalAvatarUrl ?? '';
    final selectedTruck = _selectedTruckId == null
        ? null
        : _truckById(trucks, _selectedTruckId!);
    final truckId = selectedTruck != null ? selectedTruck.id : manualTruckId;

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
                if (aadhaar.isNotEmpty) 'aadhaar': aadhaar,
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
        final registrationResponse = await apiClient.createDriverRegistration(
          accessToken: session.tokens.accessToken,
          driver:
              {
                'name': name,
                'phone': phone,
                'email': email,
                'license_no': licenseNo,
                'license_expiry': licenseExpiry,
              }..removeWhere(
                (key, value) =>
                    value == null || value.toString().trim().isEmpty,
              ),
        );

        final driverId = _extractUserId(registrationResponse);
        if (driverId.isEmpty) {
          throw StateError('Could not determine the created driver id.');
        }

        final driverUpdate =
            <String, dynamic>{
              'license_no': licenseNo,
              'license_expiry': licenseExpiry,
              'truck_id': truckId,
              if (aadhaar.isNotEmpty) 'aadhaar': aadhaar,
              if (avatar.isNotEmpty) 'avatar': avatar,
              if (_selectedStatus != null && _selectedStatus!.isNotEmpty)
                'status': _selectedStatus,
            }..removeWhere(
              (key, value) => value == null || value.toString().trim().isEmpty,
            );

        if (driverUpdate.isNotEmpty) {
          await apiClient.updateDriverProfile(
            accessToken: session.tokens.accessToken,
            id: driverId,
            driver: driverUpdate,
          );
        }
      }

      if (!mounted) return;

      ref.invalidate(
        brokerDriversApiProvider((status: null, page: 1, limit: 10)),
      );
      ref.invalidate(
        brokerDriversApiProvider((status: null, page: 1, limit: 50)),
      );
      ref.invalidate(
        brokerDriversApiProvider((status: null, page: 1, limit: 100)),
      );
      ref.invalidate(brokerDriversProvider);
      ref.invalidate(brokerTrucksProvider((status: null, page: 1, limit: 50)));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Driver profile saved successfully.'),
          backgroundColor: AppColors.brand,
        ),
      );
      Navigator.of(context).pop();
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: AppColors.dangerIcon,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.dangerIcon,
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

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              Row(
                children: [
                  BrokerBackButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEditing ? 'Edit Driver' : 'Add Driver',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isEditing
                              ? 'Update the driver account'
                              : 'Create a driver account',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DriverAvatarHero(
                imageUrl: _avatarPreviewUrl,
                imageBytes: _pickedAvatarBytes,
                isEditing: _isEditing,
                driverName: _isEditing ? widget.existingDriver!.name : null,
                onTap: _pickAvatar,
              ),
              const SizedBox(height: 18),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (!_isEditing) ...[
                      _FormSection(
                        title: 'Account Details',
                        icon: AppIcons.person_rounded,
                        iconColor: AppColors.brand,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            textInputAction: TextInputAction.next,
                            decoration: brokerFieldDecoration(
                              labelText: 'Full name',
                              prefixIcon: AppIcons.person_rounded,
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
                            decoration: brokerFieldDecoration(
                              labelText: 'Email',
                              prefixIcon: AppIcons.email_rounded,
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
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9+\s-]'),
                              ),
                            ],
                            decoration: brokerFieldDecoration(
                              labelText: 'Mobile number',
                              prefixIcon: AppIcons.phone_rounded,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            decoration:
                                brokerFieldDecoration(
                                  labelText: 'Password',
                                  prefixIcon: AppIcons.lock_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      );
                                    },
                                    icon: Icon(
                                      _obscurePassword
                                          ? AppIcons.visibility_off_outlined
                                          : AppIcons.visibility_outlined,
                                    ),
                                    tooltip: _obscurePassword
                                        ? 'Show password'
                                        : 'Hide password',
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
                        ],
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      _ReadonlyDriverCard(driver: driver!),
                      const SizedBox(height: 14),
                    ],
                    _FormSection(
                      title: 'License & Documents',
                      icon: AppIcons.badge_rounded,
                      iconColor: AppColors.brandDark,
                      children: [
                        TextFormField(
                          controller: _licenseController,
                          textInputAction: TextInputAction.next,
                          decoration: brokerFieldDecoration(
                            labelText: 'License number',
                            prefixIcon: AppIcons.badge_rounded,
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
                            _AadhaarSpacingFormatter(),
                          ],
                          decoration: brokerFieldDecoration(
                            labelText: 'Aadhaar number',
                            prefixIcon: AppIcons.credit_card_rounded,
                          ),
                          validator: (value) {
                            final digits =
                                value?.replaceAll(' ', '').trim() ?? '';
                            if (digits.isEmpty && !_isEditing) {
                              return 'Enter Aadhaar number';
                            }
                            if (digits.isEmpty && _isEditing) {
                              return null;
                            }
                            if (digits.length != 12) {
                              return 'Aadhaar must be 12 digits';
                            }
                            return null;
                          },
                        ),
                        if (_isEditing)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              'Leave blank to keep the current Aadhaar on file.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _licenseExpiryController,
                          readOnly: true,
                          onTap: _pickLicenseExpiry,
                          decoration: brokerFieldDecoration(
                            labelText: 'License expiry',
                            prefixIcon: AppIcons.event_rounded,
                            hintText: 'YYYY-MM-DD',
                            suffixIcon: AppIcons.calendar_month_rounded,
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
                      ],
                    ),
                    const SizedBox(height: 14),
                    _FormSection(
                      title: 'Vehicle Assignment',
                      icon: AppIcons.local_shipping_rounded,
                      iconColor: AppColors.brand,
                      children: [
                        if (trucks.isNotEmpty)
                          DropdownButtonFormField<String>(
                            initialValue: selectedTruckId,
                            isExpanded: true,
                            isDense: true,
                            itemHeight: 56,
                            dropdownColor: Colors.white,
                            menuMaxHeight: 320,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            icon: const Icon(
                              AppIcons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                            decoration: brokerFieldDecoration(
                              labelText: 'Assign truck',
                              prefixIcon: AppIcons.local_shipping_rounded,
                            ),
                            items: trucks
                                .map(
                                  (truck) => DropdownMenuItem<String>(
                                    value: truck.id,
                                    child: Text(
                                      '${truck.label} • ${truck.plateNumber}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                            decoration: brokerFieldDecoration(
                              labelText: 'Truck ID',
                              prefixIcon: AppIcons.local_shipping_rounded,
                              hintText: 'Enter truck UUID',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter truck ID';
                              }
                              return null;
                            },
                          ),
                        if (_isEditing) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue:
                                _selectedStatus ??
                                _driverStatusToApiValue(driver!.status),
                            isExpanded: true,
                            isDense: true,
                            itemHeight: 56,
                            dropdownColor: Colors.white,
                            menuMaxHeight: 320,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            icon: const Icon(
                              AppIcons.keyboard_arrow_down_rounded,
                              color: AppColors.textSecondary,
                            ),
                            decoration: brokerFieldDecoration(
                              labelText: 'Status',
                              prefixIcon: AppIcons.toggle_on_rounded,
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
                        ],
                      ],
                    ),
                    if (trucksAsync.hasError) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Truck list could not be loaded. You can still enter a truck ID manually.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _submitDriver(trucks),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
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
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    AppIcons.local_shipping_rounded,
                                    color: Colors.white,
                                    size: 23,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 1,
                                    height: 24,
                                    color: Colors.white.withValues(alpha: 0.55),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _isEditing ? 'Update Driver' : 'Add Driver',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
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
    );
  }
}

class _DriverAvatarHero extends StatelessWidget {
  const _DriverAvatarHero({
    required this.imageUrl,
    required this.imageBytes,
    required this.isEditing,
    required this.driverName,
    required this.onTap,
  });

  final String? imageUrl;
  final Uint8List? imageBytes;
  final bool isEditing;
  final String? driverName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.brand, AppColors.brandDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              SskProfileAvatar(
                imageUrl: imageUrl,
                imageBytes: imageBytes,
                size: 84,
                borderColor: Colors.white,
                onTap: onTap,
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    AppIcons.camera_alt_outlined,
                    color: AppColors.brandDark,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing && driverName != null
                      ? driverName!
                      : 'Add driver photo',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isEditing && driverName != null
                      ? 'Tap to update the driver photo'
                      : 'Tap the camera to add a driver photo',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          AppIcons.camera_alt_outlined,
                          color: Colors.white,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Change Photo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
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

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _ReadonlyDriverCard extends StatelessWidget {
  const _ReadonlyDriverCard({required this.driver});

  final BrokerDriver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.brandFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  AppIcons.person_rounded,
                  color: AppColors.brand,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Account Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            driver.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            driver.phone,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

String _isoDate(DateTime date) {
  return date.toIso8601String().split('T').first;
}

class _AadhaarSpacingFormatter extends TextInputFormatter {
  const _AadhaarSpacingFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      buffer.write(digits[i]);
      if (i == 3 || i == 7) {
        buffer.write(' ');
      }
    }
    final text = buffer.toString().trimRight();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
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
