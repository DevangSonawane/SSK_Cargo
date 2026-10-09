import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class _TruckChoice {
  const _TruckChoice({
    required this.id,
    required this.registration,
    required this.category,
  });

  final String id;
  final String registration;
  final String category;
}

/// New monthly-hire listing — shared by brokers (`/broker/monthly-hiring/new`,
/// picks from the fleet) and drivers (`/driver/monthly-hiring/new`, fixed to
/// the assigned truck). Web parity: `MonthlyHiringForm.jsx`.
class BrokerMonthlyHiringFormScreen extends ConsumerStatefulWidget {
  const BrokerMonthlyHiringFormScreen({super.key});

  @override
  ConsumerState<BrokerMonthlyHiringFormScreen> createState() =>
      _BrokerMonthlyHiringFormScreenState();
}

class _BrokerMonthlyHiringFormScreenState
    extends ConsumerState<BrokerMonthlyHiringFormScreen> {
  List<_TruckChoice> _trucks = const [];
  bool _loadingTrucks = true;
  String _truckId = '';
  String _pricingType = 'fixed';
  bool _submitting = false;
  String? _error;
  final _rateController = TextEditingController();
  final _notesController = TextEditingController();

  bool get _isBroker {
    final role = ref
        .read(authSessionProvider)
        .valueOrNull
        ?.user
        .role
        .trim()
        .toLowerCase();
    return role == 'broker';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadTrucks());
  }

  @override
  void dispose() {
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _str(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  List<_TruckChoice> _choicesFromList(Object? list) {
    if (list is! Iterable) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(
          (t) => _TruckChoice(
            id: _str(t, const ['id', 'truck_id', 'uuid']),
            registration: _str(
              t,
              const ['registration', 'registration_number', 'plate_number'],
            ),
            category: _str(
              t,
              const ['category', 'truck_category', 'type', 'truck_type'],
            ),
          ),
        )
        .where((t) => t.id.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _loadTrucks() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      if (mounted) setState(() => _loadingTrucks = false);
      return;
    }
    try {
      if (_isBroker) {
        final response = await ref
            .read(apiClientProvider)
            .getTrucks(
              accessToken: session.tokens.accessToken,
              limit: 100,
            );
        final data = response['data'];
        final Object? list = data is Map<String, dynamic>
            ? (data['trucks'] ?? data['items'] ?? response['trucks'])
            : response['trucks'];
        if (!mounted) return;
        final choices = _choicesFromList(list);
        setState(() {
          _trucks = choices;
          if (choices.isNotEmpty) _truckId = choices.first.id;
          _loadingTrucks = false;
        });
      } else {
        final response = await ref
            .read(apiClientProvider)
            .getDriverTruck(accessToken: session.tokens.accessToken);
        final data = response['data'];
        final Object? truck = data is Map<String, dynamic>
            ? (data['truck'] ?? data)
            : null;
        if (!mounted) return;
        final choices = truck is Map<String, dynamic>
            ? _choicesFromList([truck])
            : const <_TruckChoice>[];
        setState(() {
          _trucks = choices;
          if (choices.isNotEmpty) _truckId = choices.first.id;
          _loadingTrucks = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _trucks = const [];
          _loadingTrucks = false;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final rate = double.tryParse(_rateController.text.trim()) ?? 0;
    if (_truckId.isEmpty) {
      setState(
        () => _error = _isBroker
            ? 'Select a truck first.'
            : 'You need an assigned truck first.',
      );
      return;
    }
    if (rate <= 0) {
      setState(() => _error = 'Enter a valid rate.');
      return;
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await ref
          .read(apiClientProvider)
          .createMonthlyHiringListing(
            accessToken: session.tokens.accessToken,
            truckId: _truckId,
            pricingType: _pricingType,
            rateAmount: rate,
            availabilityNotes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle listed for monthly hire.')),
      );
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = error.toString().replaceFirst('ApiException: ', ''),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _trucks.where((t) => t.id == _truckId).toList();
    return Theme(
      data: Theme.of(context),
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        appBar: AppBar(
          backgroundColor: AppColors.canvas,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(AppIcons.arrow_back_rounded),
          ),
          title: const Text(
            'List Vehicle for Monthly Hire',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const Text(
              'Set your rate — our team reaches out when a client enquires nearby.',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: _loadingTrucks
                  ? const SizedBox(
                      height: 48,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _trucks.isEmpty
                  ? Text(
                      _isBroker
                          ? 'Add a truck to your fleet first before listing it for monthly hire.'
                          : 'You don\u2019t have a truck assigned yet — ask your broker to assign one.',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Truck',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_isBroker)
                          DropdownButtonFormField<String>(
                            initialValue: _truckId.isEmpty ? null : _truckId,
                            isExpanded: true,
                            dropdownColor: Colors.white,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                            ),
                            items: _trucks
                                .map(
                                  (t) => DropdownMenuItem<String>(
                                    value: t.id,
                                    child: Text(
                                      '${t.registration} — ${t.category.isEmpty ? 'Truck' : t.category}',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) => setState(
                              () => _truckId = value ?? _truckId,
                            ),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.fillSubtle,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              selected.isEmpty
                                  ? 'Truck'
                                  : '${selected.first.registration} — ${selected.first.category.isEmpty ? 'Truck' : selected.first.category}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        const Text(
                          'Pricing',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textSecondary,
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
                                    right: opt.$1 == 'fixed' ? 8 : 0,
                                  ),
                                  child: OutlinedButton(
                                    onPressed: () => setState(
                                      () => _pricingType = opt.$1,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _pricingType == opt.$1
                                          ? AppColors.brand
                                          : Colors.white,
                                      foregroundColor: _pricingType == opt.$1
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                      side: BorderSide(
                                        color: _pricingType == opt.$1
                                            ? AppColors.brand
                                            : AppColors.line,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(opt.$2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            labelText: _pricingType == 'per_km'
                                ? 'Rate per KM (₹)'
                                : 'Monthly Rate (₹)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _notesController,
                          maxLines: 3,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText: 'Availability Notes (optional)',
                            hintText:
                                'e.g. Available across Maharashtra, driver included',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.dangerIcon,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: _submitting
                                  ? null
                                  : () => context.pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton(
                                onPressed: _submitting ? null : _submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.brand,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  _submitting
                                      ? 'Listing…'
                                      : 'List for Monthly Hire',
                                ),
                              ),
                            ),
                          ],
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
