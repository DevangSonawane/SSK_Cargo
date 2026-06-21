import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../widgets/broker_flow_widgets.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _plateController = TextEditingController();
  final _capacityController = TextEditingController();
  final _documentController = TextEditingController();
  String? _driverName;
  int _selectedVehicleIndex = 1;

  @override
  void dispose() {
    _plateController.dispose();
    _capacityController.dispose();
    _documentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drivers = ref.watch(brokerDriversProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Add vehicle'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text(
            'Choose the vehicle type and fill in the fleet details.',
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
                }),
              );
            },
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _plateController,
            decoration: const InputDecoration(
              labelText: 'Number plate',
              prefixIcon: Icon(Icons.confirmation_number_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacityController,
            decoration: const InputDecoration(
              labelText: 'Capacity',
              prefixIcon: Icon(Icons.scale_rounded),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _driverName,
            decoration: const InputDecoration(
              labelText: 'Assign driver',
              prefixIcon: Icon(Icons.person_rounded),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Unassigned'),
              ),
              ...drivers.map(
                (driver) => DropdownMenuItem<String?>(
                  value: driver.name,
                  child: Text(driver.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _driverName = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _documentController,
            decoration: const InputDecoration(
              labelText: 'RC / document upload',
              prefixIcon: Icon(Icons.upload_file_rounded),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final selectedVehicle = vehicleOptions[_selectedVehicleIndex];
                final notifier = ref.read(brokerVehiclesProvider.notifier);
                notifier.state = [
                  BrokerVehicle(
                    id: 'veh-${DateTime.now().millisecondsSinceEpoch}',
                    label: selectedVehicle.label,
                    plateNumber: _plateController.text.trim().isEmpty
                        ? 'MH 00 XX 0000'
                        : _plateController.text.trim(),
                    capacity: _capacityController.text.trim().isEmpty
                        ? selectedVehicle.capacity
                        : _capacityController.text.trim(),
                    status: BrokerVehicleStatus.idle,
                    assignedDriverName: _driverName ?? 'Unassigned',
                    assetPath: selectedVehicle.assetPath,
                  ),
                  ...notifier.state,
                ];
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Save vehicle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
