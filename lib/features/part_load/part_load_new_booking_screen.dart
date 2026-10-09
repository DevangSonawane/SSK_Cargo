// Part-Load new-booking entry — standalone duplicate (does NOT reuse the
// full-truck BookingLocationScreen). Simple form -> creates a
// truck_category=part + search_mode=part_load booking -> pushes the
// PartLoadSearchScreen. Coordinates are typed/pasted for v1; a map picker
// can be added later without touching full-truck files.
//
// Layout mirrors SelectVehicleScreen: surface scaffold, 18/12/18 page
// padding, section labels, carded borderless fields, floating bottom CTA
// with the same 0.14/18 shadow and radius-18 green button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../auth/presentation/controllers/auth_controller.dart';
import 'part_load_api.dart';
import 'part_load_search_screen.dart';

class PartLoadNewBookingScreen extends ConsumerStatefulWidget {
  const PartLoadNewBookingScreen({super.key});

  @override
  ConsumerState<PartLoadNewBookingScreen> createState() =>
      _PartLoadNewBookingScreenState();
}

class _PartLoadNewBookingScreenState
    extends ConsumerState<PartLoadNewBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pickup = TextEditingController();
  final _pickupLat = TextEditingController();
  final _pickupLng = TextEditingController();
  final _drop = TextEditingController();
  final _dropLat = TextEditingController();
  final _dropLng = TextEditingController();
  final _weight = TextEditingController(text: '3');
  bool _sending = false;

  static const _quickWeights = <double>[1, 3, 5, 10];

  @override
  void dispose() {
    _pickup.dispose();
    _pickupLat.dispose();
    _pickupLng.dispose();
    _drop.dispose();
    _dropLat.dispose();
    _dropLng.dispose();
    _weight.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      final token =
          ref.read(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
      if (token.isEmpty) throw Exception('Please log in as a client first.');
      final res = await ref.read(partLoadApiProvider).createPartBooking(
            accessToken: token,
            pickupLocation: _pickup.text.trim(),
            pickupLat: double.parse(_pickupLat.text.trim()),
            pickupLng: double.parse(_pickupLng.text.trim()),
            dropLocation: _drop.text.trim(),
            dropLat: double.parse(_dropLat.text.trim()),
            dropLng: double.parse(_dropLng.text.trim()),
            weightTons: double.parse(_weight.text.trim()),
          );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PartLoadSearchScreen(
            bookingId: res.bookingId,
            bookingNumber: res.bookingNumber,
            pickup: _pickup.text.trim(),
            pickupLat: double.parse(_pickupLat.text.trim()),
            pickupLng: double.parse(_pickupLng.text.trim()),
            drop: _drop.text.trim(),
            dropLat: double.parse(_dropLat.text.trim()),
            dropLng: double.parse(_dropLng.text.trim()),
            weightTons: double.parse(_weight.text.trim()),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      backgroundColor: context.colors.surface,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(18, 12, 18, 132 + bottomInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(AppIcons.arrow_back_rounded, size: 18),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Part Truck — shared booking',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: context.colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Fixed price · No negotiation · On-trip trucks only',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: context.colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.colors.brandFill,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: context.colors.brandBorder),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            AppIcons.inventory_2_rounded,
                            color: Color(0xFF2FA56E),
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Shared capacity — we find trucks already on-trip heading your way with enough spare space.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: context.colors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel(context, 'Pickup'),
                    const SizedBox(height: 8),
                    _FieldCard(
                      controller: _pickup,
                      hint: 'Pickup location',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _FieldCard(
                            controller: _pickupLat,
                            hint: 'Pickup lat',
                            numeric: true,
                            validator: (v) =>
                                double.tryParse(v?.trim() ?? '') == null
                                    ? 'Number required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FieldCard(
                            controller: _pickupLng,
                            hint: 'Pickup lng',
                            numeric: true,
                            validator: (v) =>
                                double.tryParse(v?.trim() ?? '') == null
                                    ? 'Number required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel(context, 'Drop-off'),
                    const SizedBox(height: 8),
                    _FieldCard(
                      controller: _drop,
                      hint: 'Drop location',
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _FieldCard(
                            controller: _dropLat,
                            hint: 'Drop lat',
                            numeric: true,
                            validator: (v) =>
                                double.tryParse(v?.trim() ?? '') == null
                                    ? 'Number required'
                                    : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _FieldCard(
                            controller: _dropLng,
                            hint: 'Drop lng',
                            numeric: true,
                            validator: (v) =>
                                double.tryParse(v?.trim() ?? '') == null
                                    ? 'Number required'
                                    : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _sectionLabel(context, 'Weight (tons)'),
                    const SizedBox(height: 8),
                    _FieldCard(
                      controller: _weight,
                      hint: '0.0',
                      numeric: true,
                      validator: (v) {
                        final d = double.tryParse(v?.trim() ?? '');
                        if (d == null || d <= 0) return 'Enter tons > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickWeights.map((value) {
                        final current =
                            double.tryParse(_weight.text.trim()) ?? -1;
                        final selected = (current - value).abs() < 0.001;
                        return InkWell(
                          onTap: () => setState(
                            () => _weight.text = value.toStringAsFixed(
                                value % 1 == 0 ? 0 : 1),
                          ),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? context.colors.brandFill
                                  : context.colors.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: selected
                                    ? const Color(0xFF2FA56E)
                                    : context.colors.line,
                                width: selected ? 1.6 : 1,
                              ),
                            ),
                            child: Text(
                              '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)}t',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: selected
                                        ? context.colors.brandEmphasis
                                        : context.colors.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                        );
                      }).toList(growable: false),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: bottomInset + 12,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _sending ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _sending ? 'Creating…' : 'Find trucks to share',
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.1,
          ),
    );
  }
}

/// Carded borderless field — same look as the location-step inputs:
/// surface card, radius 16, line border, borderless 15px text.
class _FieldCard extends StatelessWidget {
  const _FieldCard({
    required this.controller,
    required this.hint,
    this.numeric = false,
    this.validator,
  });

  final TextEditingController controller;
  final String hint;
  final bool numeric;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.colors.line),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.colors.textPrimary,
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: context.colors.textTertiary,
                    fontWeight: FontWeight.w400,
                    fontSize: 15,
                  ),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          isDense: true,
        ),
        validator: validator,
      ),
    );
  }
}
