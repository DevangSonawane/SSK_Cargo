import 'package:flutter/material.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:ssk/core/theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/controllers/client_bookings_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../widgets/broker_flow_widgets.dart';
import 'package:ssk/l10n/app_localizations.dart';

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
  // Tracks whether the user has tapped a tile yet — before that, an edit
  // flow highlights by the existing truck's category (stable across the
  // 4-item fallback → 9-item live list switch), not by a stale index.
  bool _userPickedVehicle = false;
  String _editingCategory = '';

  @override
  void initState() {
    super.initState();
    // Fresh driver options for the assignment dropdown — never cached.
    // Deferred past the first frame: ref.invalidate() touches the provider
    // container, which isn't reachable from initState itself.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(
        brokerDriversApiProvider((status: null, page: 1, limit: 50)),
      );
    });
    final truck = widget.existingTruck;
    if (truck != null) {
      _registrationController.text = truck.plateNumber;
      _capacityController.text = truck.capacity;
      _makeController.text = truck.make;
      _yearController.text = truck.year;
      _insuranceExpiryController.text = truck.insuranceExpiry;
      _editingCategory = _categoryForExistingTruck(
        label: truck.label,
        category: truck.category,
      );
      _selectedVehicleIndex = _indexForCategory(
        _optionsFromTypes(null),
        _editingCategory,
      );
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

  List<VehicleOption> _resolveOptions() {
    return _optionsFromTypes(ref.read(vehicleTypesProvider).valueOrNull);
  }

  /// Builds the grid options from live vehicle-types, falling back to the
  /// static 9-item list (same as web's FALLBACK_TRUCKS) while loading or on
  /// error — the grid always shows all 9 types, never the old hardcoded 4.
  List<VehicleOption> _optionsFromTypes(List<VehicleType>? types) {
    if (types != null && types.isNotEmpty) {
      return vehicleOptionsFromTypes(types);
    }
    return vehicleOptionsFromTypes(fallbackVehicleTypes());
  }

  int _effectiveIndex(List<VehicleOption> options) {
    if (!_userPickedVehicle && widget.existingTruck != null) {
      return _indexForCategory(options, _editingCategory);
    }
    if (options.isEmpty) return 0;
    return _selectedVehicleIndex.clamp(0, options.length - 1).toInt();
  }

  Future<void> _submitTruck() async {
    if (_submitting) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.addTruckPleaseSignInAgainToAddA)),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Live taxonomy (same endpoint the client picker uses) — falls back to
    // the hardcoded list while loading so the grid never empties.
    final options = _resolveOptions();
    final selectedVehicle =
        options[_effectiveIndex(options).clamp(0, options.length - 1).toInt()];
    final driver = _selectedDriver;

    final yearText = _yearController.text.trim();
    final year = yearText.isEmpty ? null : int.tryParse(yearText);

    setState(() {
      _submitting = true;
    });

    try {
      final truckPayload = <String, dynamic>{
        'type': selectedVehicle.label,
        'category': categoryForVehicleOption(selectedVehicle),
        'capacity': _capacityController.text.trim(),
        'make': _makeController.text.trim(),
        'year': year,
        'insurance_expiry': _insuranceExpiryController.text.trim(),
      }..removeWhere((key, value) => value == null);

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
        // Assignment is optional and goes through the dedicated endpoint,
        // like the web app — never by writing truck_id onto the driver.
        if (truckId.isNotEmpty && driver != null) {
          await ref
              .read(apiClientProvider)
              .assignDriverToTruck(
                accessToken: session.tokens.accessToken,
                truckId: truckId,
                driverId: driver.id,
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
        if (driver != null) {
          await ref
              .read(apiClientProvider)
              .assignDriverToTruck(
                accessToken: session.tokens.accessToken,
                truckId: widget.existingTruck!.id,
                driverId: driver.id,
              );
        }
      }

      if (!mounted) return;

      ref.invalidate(brokerTrucksProvider((status: null, page: 1, limit: 50)));
      ref.invalidate(brokerVehiclesProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existingTruck == null
                ? AppLocalizations.of(context)!.addTruckAddedSuccessfully
                : AppLocalizations.of(context)!.addTruckUpdatedSuccessfully,
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
    final l10n = AppLocalizations.of(context)!;
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

    return Theme(
      data: AppTheme.light,
      child: Scaffold(
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
                          isEditing
                              ? AppLocalizations.of(context)!.addTruckEditTruck
                              : AppLocalizations.of(context)!.addTruckAddTruck,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.addTruckChooseTheTruckTypeAndFillIn,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
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
                      l10n.addTruckSelectTruckType,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Builder(
                      builder: (context) {
                        // watch (not read): rebuilds the grid when the live
                        // 9-type list arrives instead of sticking to fallback.
                        final typesState = ref.watch(vehicleTypesProvider);
                        final options = _optionsFromTypes(
                          typesState.valueOrNull,
                        );
                        final effectiveIndex =
                            _effectiveIndex(options).clamp(0, options.length - 1).toInt();
                        return GridView.builder(
                          itemCount: options.length,
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
                            final vehicle = options[index];
                            return VehicleSelectionTile(
                              vehicle: vehicle,
                              selected: effectiveIndex == index,
                              onTap: () => setState(() {
                                _userPickedVehicle = true;
                                _selectedVehicleIndex = index;
                                if (!isEditing &&
                                    _capacityController.text.trim().isEmpty) {
                                  _capacityController.text = vehicle.capacity;
                                }
                              }),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _registrationController,
                      textInputAction: TextInputAction.next,
                      decoration: brokerFieldDecoration(
                        labelText: AppLocalizations.of(context)!.addTruckRegistration,
                        prefixIcon: AppIcons.confirmation_number_rounded,
                      ),
                      enabled: !isEditing,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return l10n.addVehicleErrRegistration;
                        }
                        // Same format check as the web app (create only —
                        // existing plates are grandfathered in).
                        if (widget.existingTruck == null &&
                            !RegExp(
                              r'^[A-Z]{2}[-\s]?\d{1,2}[-\s]?[A-Z]{1,3}[-\s]?\d{1,4}$',
                              caseSensitive: false,
                            ).hasMatch(text)) {
                          return AppLocalizations.of(context)!
                              .addTruckErrRegistrationLooksInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacityController,
                      textInputAction: TextInputAction.next,
                      decoration: brokerFieldDecoration(
                        labelText: AppLocalizations.of(context)!.addTruckCapacity,
                        prefixIcon: AppIcons.scale_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.addVehicleErrCapacity;
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
                        labelText: AppLocalizations.of(context)!.addTruckAssignDriverOptional,
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
                        // Assignment is optional, like the web — a truck can
                        // be created first and assigned a driver later.
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _makeController,
                      textInputAction: TextInputAction.next,
                      decoration: brokerFieldDecoration(
                        labelText: AppLocalizations.of(context)!.addTruckMakeOptional,
                        prefixIcon: AppIcons.precision_manufacturing_rounded,
                      ),
                      validator: (value) {
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
                        labelText: AppLocalizations.of(context)!.addTruckYearOptional,
                        prefixIcon: AppIcons.event_rounded,
                      ),
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (text.isEmpty) {
                          return null;
                        }
                        final parsed = int.tryParse(text);
                        if (parsed == null || parsed < 1900) {
                          return l10n.addVehicleErrYear;
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
                        labelText: AppLocalizations.of(context)!.addTruckInsuranceExpiry,
                        hintText: AppLocalizations.of(context)!.addTruckPickADate,
                        prefixIcon: AppIcons.event_available_rounded,
                        suffixIcon: AppIcons.calendar_month_rounded,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!
                              .addVehicleErrInsuranceExpiry;
                        }
                        if (DateTime.tryParse(value.trim()) == null) {
                          return l10n.addVehicleUseYyyyMmdd;
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
                            borderRadius: BorderRadius.circular(
                              AppRadius.button,
                            ),
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

int _indexForCategory(List<VehicleOption> options, String category) {
  final want = category.trim().toLowerCase();
  if (want.isNotEmpty) {
    for (var i = 0; i < options.length; i++) {
      if (options[i].id.trim().toLowerCase() == want) return i;
    }
  }
  // Fallback while the live list hasn't loaded (or for legacy labels):
  // closest size bucket rather than a wrong exact index.
  if (want.isNotEmpty) {
    if (const {'3_wheeler', 'tata_ace', 'pickup_8ft', 'small'}.contains(want)) {
      return _indexForIdOr(options, const ['small'], 0);
    }
    if (const {'pickup_10ft', '14ft', 'medium'}.contains(want)) {
      return _indexForIdOr(options, const ['medium'], 1);
    }
    if (const {'17ft', '19ft', '22ft', 'large', 'big'}.contains(want)) {
      return _indexForIdOr(options, const ['large', 'big'], 2);
    }
    if (want == 'part' || want == 'pooling') {
      return _indexForIdOr(options, const ['part'], options.length - 1);
    }
  }
  return options.isEmpty ? 0 : options.length - 1;
}

int _indexForIdOr(
  List<VehicleOption> options,
  List<String> ids,
  int fallback,
) {
  for (var i = 0; i < options.length; i++) {
    if (ids.contains(options[i].id.trim().toLowerCase())) return i;
  }
  if (options.isEmpty) return 0;
  return fallback.clamp(0, options.length - 1).toInt();
}

/// Real category for an existing truck — prefers the stored `category`,
/// falls back to mapping its free-text label (old trucks predate ids).
String _categoryForExistingTruck({required String label, String category = ''}) {
  if (category.trim().isNotEmpty) return category.trim();
  final text = label.toLowerCase();
  if (text.contains('3 wheeler') || text.contains('3_wheeler')) {
    return '3_wheeler';
  }
  if (text.contains('tata ace') || text.contains('tata_ace')) return 'tata_ace';
  if (text.contains('pickup 8') || text.contains('pickup_8')) {
    return 'pickup_8ft';
  }
  if (text.contains('pickup 10') || text.contains('pickup_10')) {
    return 'pickup_10ft';
  }
  if (text.contains('22ft') || text.contains('22 ft')) return '22ft';
  if (text.contains('19ft') || text.contains('19 ft')) return '19ft';
  if (text.contains('17ft') || text.contains('17 ft')) return '17ft';
  if (text.contains('14ft') || text.contains('14 ft')) return '14ft';
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big') || text.contains('large')) return 'large';
  return 'part';
}

BrokerDriver? _driverForName(List<BrokerDriver> drivers, String name) {
  for (final driver in drivers) {
    if (driver.name == name) {
      return driver;
    }
  }
  return null;
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
    final l10n = AppLocalizations.of(context)!;
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
    final l10n = AppLocalizations.of(context)!;
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