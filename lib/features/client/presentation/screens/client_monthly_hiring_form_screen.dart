import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';

/// New monthly-hiring enquiry form — web `MonthlyHiringForm.jsx` parity.
/// Lead capture only: records the enquiry for the team to follow up on.
class ClientMonthlyHiringFormScreen extends ConsumerStatefulWidget {
  const ClientMonthlyHiringFormScreen({super.key});

  @override
  ConsumerState<ClientMonthlyHiringFormScreen> createState() =>
      _ClientMonthlyHiringFormScreenState();
}

class _ClientMonthlyHiringFormScreenState
    extends ConsumerState<ClientMonthlyHiringFormScreen> {
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _truckCategory = '';
  List<VehicleType> _truckTypes = const [];
  DateTime? _startDate;
  DateTime? _endDate;
  String _pricingType = 'fixed';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTruckTypes());
  }

  @override
  void dispose() {
    _locationController.dispose();
    _budgetController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTruckTypes() async {
    try {
      final response = await ref.read(apiClientProvider).getVehicleTypes();
      if (!mounted) return;
      final types = parseVehicleTypesResponse(response);
      if (types.isNotEmpty) {
        setState(() => _truckTypes = types);
      }
    } catch (_) {
      // Dropdown falls back to "Any category".
    }
  }

  String _formatDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${value.day} ${months[value.month - 1]} ${value.year}';
  }

  String _apiDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initial = isStart
        ? (_startDate ?? today)
        : (_endDate ?? _startDate ?? today);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(today) ? today : initial,
      firstDate: isStart ? today : (_startDate ?? today),
      lastDate: DateTime(now.year + 3),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && !_endDate!.isAfter(picked)) {
          _endDate = null;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final location = _locationController.text.trim();
    if (location.isEmpty) {
      _snack('Please tell us where you need the vehicle');
      return;
    }
    if (_startDate == null || _endDate == null) {
      _snack('Please select both a start and end date');
      return;
    }
    if (!_endDate!.isAfter(_startDate!)) {
      _snack('End date must be after the start date');
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _snack('Please sign in again to submit.');
      return;
    }
    final budgetText = _budgetController.text.trim();
    final budget = budgetText.isEmpty ? null : double.tryParse(budgetText);
    if (budgetText.isNotEmpty && budget == null) {
      _snack('Please enter a valid budget amount');
      return;
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(apiClientProvider)
          .createMonthlyHiringEnquiry(
            accessToken: session.tokens.accessToken,
            location: location,
            truckCategory: _truckCategory.isEmpty ? null : _truckCategory,
            startDate: _apiDate(_startDate!),
            endDate: _apiDate(_endDate!),
            pricingType: _pricingType,
            budgetAmount: budget,
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enquiry submitted — our team will get in touch soon'),
        ),
      );
      context.pop(true);
    } on ApiException catch (error) {
      _snack(error.message);
    } catch (error) {
      _snack(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        backgroundColor: colors.canvas,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(AppIcons.arrow_back_rounded),
        ),
        title: const Text('New Enquiry'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell us what you need — our team will get back to you with options.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: colors.line),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF101828).withValues(alpha: 0.06),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Label(
                      icon: AppIcons.location_on_outlined,
                      text: 'Location / Route',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Pune, or Pune to Mumbai corridor',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Label(
                      icon: AppIcons.local_shipping_outlined,
                      text: 'Truck Category',
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      menuMaxHeight: 360,
                      initialValue: _truckCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      selectedItemBuilder: (context) => [
                        const Text(
                          'Any category',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        for (final type in _truckTypes)
                          Text(
                            type.capacity.isNotEmpty
                                ? '${type.name} · ${type.capacity}'
                                : type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text(
                            'Any category',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        for (final type in _truckTypes)
                          DropdownMenuItem(
                            value: type.id,
                            child: Text(
                              type.capacity.isNotEmpty
                                  ? '${type.name} · ${type.capacity}'
                                  : type.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) =>
                          setState(() => _truckCategory = value ?? ''),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stackDates = constraints.maxWidth < 360;
                        final startField = _DateField(
                          label: 'Start Date',
                          text: _startDate == null
                              ? 'Select start date'
                              : _formatDate(_startDate!),
                          onTap: () => _pickDate(isStart: true),
                        );
                        final endField = _DateField(
                          label: 'End Date',
                          text: _endDate == null
                              ? 'Select end date'
                              : _formatDate(_endDate!),
                          onTap: () => _pickDate(isStart: false),
                        );
                        if (stackDates) {
                          return Column(
                            children: [
                              startField,
                              const SizedBox(height: 12),
                              endField,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: startField),
                            const SizedBox(width: 12),
                            Expanded(child: endField),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Pricing Preference',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        for (final opt in const [
                          ('fixed', 'Fixed Rate'),
                          ('per_km', 'Per KM Rate'),
                        ])
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: opt.$1 == 'fixed' ? 6 : 0,
                                left: opt.$1 == 'fixed' ? 0 : 6,
                              ),
                              child: OutlinedButton(
                                onPressed: () =>
                                    setState(() => _pricingType = opt.$1),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: _pricingType == opt.$1
                                      ? AppColors.brand
                                      : null,
                                  foregroundColor: _pricingType == opt.$1
                                      ? Colors.white
                                      : colors.textPrimary,
                                  side: BorderSide(
                                    color: _pricingType == opt.$1
                                        ? AppColors.brand
                                        : colors.line,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  opt.$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Label(
                      icon: AppIcons.payments_outlined,
                      text: _pricingType == 'per_km'
                          ? 'Budget (₹ per km) (optional)'
                          : 'Monthly Budget (₹) (optional)',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _budgetController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Your expected budget',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _Label(
                      icon: AppIcons.description_outlined,
                      text: 'Additional Details (optional)',
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 5,
                      maxLength: 2000,
                      decoration: const InputDecoration(
                        hintText:
                            'Anything else that would help — cargo type, expected daily runs, etc.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(color: colors.line),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: FilledButton.icon(
                        onPressed: _submitting ? null : _submit,
                        icon: const Icon(AppIcons.send_rounded, size: 18),
                        label: Text(
                          _submitting ? 'Submitting...' : 'Submit Enquiry',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.brand,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: context.colors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: context.colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.text,
    required this.onTap,
  });

  final String label;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(icon: AppIcons.calendar_month_outlined, text: label),
        const SizedBox(height: 8),
        _DateButton(text: text, onTap: onTap),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: colors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
              ),
            ),
            Icon(
              AppIcons.calendar_month_outlined,
              size: 18,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
