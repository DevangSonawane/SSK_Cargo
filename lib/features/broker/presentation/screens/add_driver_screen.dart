import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../widgets/broker_flow_widgets.dart';

class AddDriverScreen extends ConsumerStatefulWidget {
  const AddDriverScreen({super.key});

  @override
  ConsumerState<AddDriverScreen> createState() => _AddDriverScreenState();
}

class _AddDriverScreenState extends ConsumerState<AddDriverScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _vehicleType;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _licenseController.dispose();
    _vehicleNumberController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Add driver'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/broker/profile'),
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
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
                    Icons.local_shipping_rounded,
                    color: Color(0xFF7A5AF8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Create a driver login and assign the initial vehicle.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF667085),
                        ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Mobile number',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _licenseController,
            decoration: const InputDecoration(
              labelText: 'Driver license no.',
              prefixIcon: Icon(Icons.badge_rounded),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _vehicleType,
            decoration: const InputDecoration(
              labelText: 'Vehicle type',
              prefixIcon: Icon(Icons.local_shipping_rounded),
            ),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Select vehicle type'),
              ),
              ...vehicleOptions.map(
                (vehicle) => DropdownMenuItem<String?>(
                  value: vehicle.label,
                  child: Text(vehicle.label),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _vehicleType = value),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _vehicleNumberController,
            decoration: const InputDecoration(
              labelText: 'Vehicle number',
              prefixIcon: Icon(Icons.pin_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_rounded),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                ),
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : () async {
                final selectedVehicle = _vehicleType ?? 'Unassigned';
                final name = _nameController.text.trim();
                final email = _emailController.text.trim();
                final password = _passwordController.text;

                if (name.isEmpty || email.isEmpty || password.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name, email, and password are required.')),
                  );
                  return;
                }

                setState(() => _isSubmitting = true);
                try {
                  await ref.read(authSessionProvider.notifier).register(
                        name: name,
                        email: email,
                        phone: _phoneController.text.trim().isEmpty
                            ? null
                            : _phoneController.text.trim(),
                        password: password,
                        role: 'driver',
                      );

                  if (!context.mounted) return;

                  final notifier = ref.read(brokerDriversProvider.notifier);
                  notifier.state = [
                    BrokerDriver(
                      id: 'drv-${DateTime.now().millisecondsSinceEpoch}',
                      name: name,
                      phone: _phoneController.text.trim().isEmpty
                          ? '+91 90000 00000'
                          : _phoneController.text.trim(),
                      licenseNo: _licenseController.text.trim().isEmpty
                          ? 'DL-0000-NEW'
                          : _licenseController.text.trim(),
                      vehicleType: selectedVehicle,
                      assignedVehicle: _vehicleNumberController.text.trim().isEmpty
                          ? 'Unassigned'
                          : _vehicleNumberController.text.trim(),
                      status: BrokerDriverStatus.offline,
                      currentLocation: 'Offline until login',
                      onTripSince: '',
                      currentBookingRef: '',
                    ),
                    ...notifier.state,
                  ];
                  Navigator.of(context).pop();
                } on ApiException catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.message),
                      backgroundColor: const Color(0xFFE23A4B),
                    ),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(error.toString()),
                      backgroundColor: const Color(0xFFE23A4B),
                    ),
                  );
                } finally {
                  if (context.mounted) {
                    setState(() => _isSubmitting = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F88C9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Create driver',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
