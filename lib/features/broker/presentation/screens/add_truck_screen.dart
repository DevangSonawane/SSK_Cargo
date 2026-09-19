import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../widgets/broker_flow_widgets.dart';

class AddTruckScreen extends ConsumerStatefulWidget {
  const AddTruckScreen({super.key, this.existingTruck});

  final BrokerVehicle? existingTruck;

  @override
  ConsumerState<AddTruckScreen> createState() => _AddTruckScreenState();
}

class _AddTruckScreenState extends ConsumerState<AddTruckScreen> {
  final _formKey = GlobalKey<FormState>();
  final _registrationController = TextEditingController();
  final _capacityController = TextEditingController();
  final _makeController = TextEditingController();
  final _yearController = TextEditingController();
  final _insuranceExpiryController = TextEditingController();
  BrokerDriver? _selectedDriver;
  int _selectedVehicleIndex = 1;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final truck = widget.existingTruck;
    if (truck != null) {
      _registrationController.text = truck.plateNumber;
      _capacityController.text = truck.capacity;
      _makeController.text = truck.make;
      _yearController.text = truck.year;
      _insuranceExpiryController.text = truck.insuranceExpiry;
      _selectedVehicleIndex = _vehicleIndexForLabel(truck.label);
    }
  }

  @override
  void dispose() {
    _registrationController.dispose();
    _capacityController.dispose();
    _makeController.dispose();
    _yearController.dispose();
    _insuranceExpiryController.dispose();
    super.dispose();
  }

  Future<void> _submitTruck() async {
    if (_submitting) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to add a truck.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final selectedVehicle = vehicleOptions[_selectedVehicleIndex];
    final driver = _selectedDriver;
    if (driver == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please assign a driver.')));
      return;
    }

    final year = int.tryParse(_yearController.text.trim());
    if (year == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid year.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final truckPayload = {
        'type': selectedVehicle.label,
        'category': _truckCategoryForVehicle(selectedVehicle.label),
        'capacity': _capacityController.text.trim(),
        'make': _makeController.text.trim(),
        'year': year,
        'insurance_expiry': _insuranceExpiryController.text.trim(),
      };

      if (widget.existingTruck == null) {
        final response = await ref
            .read(apiClientProvider)
            .createTruck(
              accessToken: session.tokens.accessToken,
              truck: {
                'registration': _registrationController.text.trim(),
                ...truckPayload,
              },
            );
        final truckId = _extractEntityId(response);
        if (truckId.isNotEmpty) {
          await ref
              .read(apiClientProvider)
              .updateDriverProfile(
                accessToken: session.tokens.accessToken,
                id: driver.id,
                driver: {'truck_id': truckId},
              );
        }
      } else {
        await ref
            .read(apiClientProvider)
            .updateTruck(
              accessToken: session.tokens.accessToken,
              id: widget.existingTruck!.id,
              truck: truckPayload,
            );
        await ref
            .read(apiClientProvider)
            .updateDriverProfile(
              accessToken: session.tokens.accessToken,
              id: driver.id,
              driver: {'truck_id': widget.existingTruck!.id},
            );
      }

      if (!mounted) return;

      ref.invalidate(brokerTrucksProvider((status: null, page: 1, limit: 50)));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingTruck == null
                ? 'Truck added successfully.'
                : 'Truck updated successfully.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Future<void> _pickInsuranceExpiry() async {
    final now = DateTime.now();
    final parsed = DateTime.tryParse(_insuranceExpiryController.text.trim());
    final initialDate = parsed ?? now;
    final firstDate = DateTime(now.year, 1, 1);
    final lastDate = DateTime(now.year + 20, 12, 31);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(firstDate)
          ? firstDate
          : (initialDate.isAfter(lastDate) ? lastDate : initialDate),
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select insurance expiry date',
    );

    if (picked == null || !mounted) return;

    setState(() {
      _insuranceExpiryController.text = picked
          .toIso8601String()
          .split('T')
          .first;
    });
  }

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(
      brokerDriversApiProvider((status: null, page: 1, limit: 50)),
    );
    final drivers = driversAsync.valueOrNull ?? const <BrokerDriver>[];
    final isEditing = widget.existingTruck != null;
    if (_selectedDriver == null &&
        widget.existingTruck != null &&
        drivers.isNotEmpty) {
      final resolved = _driverForName(
        drivers,
        widget.existingTruck!.assignedDriverName,
      );
      if (resolved != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedDriver == null) {
            setState(() => _selectedDriver = resolved);
          }
        });
      }
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          children: [
            Row(
              children: [
                BrokerBackButton(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEditing ? 'Edit Truck' : 'Add Truck',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose the truck type and fill in the fleet details.',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select truck type',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    itemCount: vehicleOptions.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.08,
                        ),
                    itemBuilder: (context, index) {
                      final vehicle = vehicleOptions[index];
                      return VehicleSelectionTile(
                        vehicle: vehicle,
                        selected: _selectedVehicleIndex == index,
                        onTap: () => setState(() {
                          _selectedVehicleIndex = index;
                          if (!isEditing &&
                              _capacityController.text.trim().isEmpty) {
                            _capacityController.text = vehicle.capacity;
                          }
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _registrationController,
                    textInputAction: TextInputAction.next,
                    decoration: brokerFieldDecoration(
                      labelText: 'Registration',
                      prefixIcon: AppIcons.confirmation_number_rounded,
                    ),
                    enabled: !isEditing,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter registration number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _capacityController,
                    textInputAction: TextInputAction.next,
                    decoration: brokerFieldDecoration(
                      labelText: 'Capacity',
                      prefixIcon: AppIcons.scale_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter capacity';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<BrokerDriver>(
                    initialValue: _selectedDriver,
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
                    selectedItemBuilder: (context) {
                      return drivers
                          .map(
                            (driver) => Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                children: [
                                  _DriverAvatar(
                                    initials: _driverInitials(driver.name),
                                    compact: true,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      driver.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList();
                    },
                    decoration: brokerFieldDecoration(
                      labelText: 'Assign driver',
                      prefixIcon: AppIcons.person_rounded,
                    ),
                    items: drivers
                        .map(
                          (driver) => DropdownMenuItem<BrokerDriver>(
                            value: driver,
                            child: _DriverDropdownMenuItem(driver: driver),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedDriver = value),
                    validator: (value) {
                      if (value == null) {
                        return 'Select a driver';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _makeController,
                    textInputAction: TextInputAction.next,
                    decoration: brokerFieldDecoration(
                      labelText: 'Make',
                      prefixIcon: AppIcons.precision_manufacturing_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter truck make';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _yearController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: brokerFieldDecoration(
                      labelText: 'Year',
                      prefixIcon: AppIcons.event_rounded,
                    ),
                    validator: (value) {
                      final parsed = int.tryParse(value?.trim() ?? '');
                      if (parsed == null || parsed < 1900) {
                        return 'Enter a valid year';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _insuranceExpiryController,
                    readOnly: true,
                    textInputAction: TextInputAction.done,
                    onTap: _pickInsuranceExpiry,
                    decoration: brokerFieldDecoration(
                      labelText: 'Insurance expiry',
                      hintText: 'Pick a date',
                      prefixIcon: AppIcons.event_available_rounded,
                      suffixIcon: AppIcons.calendar_month_rounded,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter insurance expiry date';
                      }
                      if (DateTime.tryParse(value.trim()) == null) {
                        return 'Use YYYY-MM-DD';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submitTruck,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
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
                          : Text(
                              isEditing ? 'Save changes' : 'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
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

String _extractEntityId(Map<String, dynamic> response) {
  final data = response['data'];
  if (data is Map<String, dynamic>) {
    for (final key in const ['id', 'truck_id', 'uuid']) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) {
        return value;
      }
    }
    final nestedTruck = data['truck'];
    if (nestedTruck is Map<String, dynamic>) {
      for (final key in const ['id', 'truck_id', 'uuid']) {
        final value = nestedTruck[key]?.toString().trim();
        if (value != null && value.isNotEmpty) {
          return value;
        }
      }
    }
  }

  for (final key in const ['id', 'truck_id', 'uuid']) {
    final value = response[key]?.toString().trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }

  return '';
}

int _vehicleIndexForLabel(String label) {
  final lower = label.toLowerCase();
  for (var i = 0; i < vehicleOptions.length; i++) {
    final option = vehicleOptions[i];
    if (option.label.toLowerCase() == lower) {
      return i;
    }
  }
  if (lower.contains('small')) return 0;
  if (lower.contains('medium')) return 1;
  if (lower.contains('big')) return 2;
  return 3;
}

BrokerDriver? _driverForName(List<BrokerDriver> drivers, String name) {
  for (final driver in drivers) {
    if (driver.name == name) {
      return driver;
    }
  }
  return null;
}


String _truckCategoryForVehicle(String label) {
  final text = label.toLowerCase();
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big')) return 'large';
  return 'part';
}

String _driverInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final first = parts.first;
    return first.substring(0, first.length.clamp(1, 2)).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}

class _DriverDropdownMenuItem extends StatelessWidget {
  const _DriverDropdownMenuItem({required this.driver});

  final BrokerDriver driver;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _DriverAvatar(initials: _driverInitials(driver.name), compact: false),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            driver.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.initials, required this.compact});

  final String initials;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 34 : 38,
      height: compact ? 34 : 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brand, AppColors.brandBright],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          fontSize: 12,
        ),
      ),
    );
  }
}
