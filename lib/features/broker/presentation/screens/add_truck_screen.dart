import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../widgets/broker_flow_widgets.dart';

class AddTruckScreen extends ConsumerStatefulWidget {
  const AddTruckScreen({
    super.key,
    this.existingTruck,
  });

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
      _selectedDriver = _driverForName(truck.assignedDriverName);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please assign a driver.')),
      );
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
        'driver_id': driver.id,
        'type': selectedVehicle.label,
        'category': _truckCategoryForVehicle(selectedVehicle.label),
        'capacity': _capacityController.text.trim(),
        'make': _makeController.text.trim(),
        'year': year,
        'insurance_expiry': _insuranceExpiryController.text.trim(),
      };

      if (widget.existingTruck == null) {
        await ref.read(apiClientProvider).createTruck(
              accessToken: session.tokens.accessToken,
              truck: {
                'registration': _registrationController.text.trim(),
                ...truckPayload,
              },
            );
      } else {
        await ref.read(apiClientProvider).updateTruck(
              accessToken: session.tokens.accessToken,
              id: widget.existingTruck!.id,
              truck: truckPayload,
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
        SnackBar(content: Text(error.toString().replaceFirst('ApiException: ', ''))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(brokerDriversProvider);
    final isEditing = widget.existingTruck != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE3E8EF)),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF101828),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEditing ? 'Edit truck' : 'Add truck',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF101828),
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
                    isEditing
                        ? 'Update the truck details and save the changes.'
                        : 'Choose the truck type and fill in the fleet details.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                  ),
                  const SizedBox(height: 18),
                  GridView.builder(
                    itemCount: vehicleOptions.length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.05,
                    ),
                    itemBuilder: (context, index) {
                      final vehicle = vehicleOptions[index];
                      return VehicleSelectionTile(
                        vehicle: vehicle,
                        selected: _selectedVehicleIndex == index,
                        onTap: () => setState(() {
                          _selectedVehicleIndex = index;
                          if (!isEditing && _capacityController.text.trim().isEmpty) {
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
                    decoration: _fieldDecoration(
                      labelText: 'Registration',
                      prefixIcon: Icons.confirmation_number_rounded,
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
                    decoration: _fieldDecoration(
                      labelText: 'Capacity',
                      prefixIcon: Icons.scale_rounded,
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
                    decoration: _fieldDecoration(
                      labelText: 'Assign driver',
                      prefixIcon: Icons.person_rounded,
                    ),
                    items: drivers
                        .map(
                          (driver) => DropdownMenuItem<BrokerDriver>(
                            value: driver,
                            child: Text(driver.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => _selectedDriver = value),
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
                    decoration: _fieldDecoration(
                      labelText: 'Make',
                      prefixIcon: Icons.precision_manufacturing_rounded,
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
                    decoration: _fieldDecoration(
                      labelText: 'Year',
                      prefixIcon: Icons.event_rounded,
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
                    textInputAction: TextInputAction.done,
                    decoration: _fieldDecoration(
                      labelText: 'Insurance expiry',
                      hintText: 'YYYY-MM-DD',
                      prefixIcon: Icons.event_available_rounded,
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
                        backgroundColor: const Color(0xFF1F88C9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
                          : const Text(
                              'Save truck',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
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

BrokerDriver? _driverForName(String name) {
  for (final driver in mockBrokerDrivers) {
    if (driver.name == name) {
      return driver;
    }
  }
  return null;
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

String _truckCategoryForVehicle(String label) {
  final text = label.toLowerCase();
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big')) return 'large';
  return 'part';
}
