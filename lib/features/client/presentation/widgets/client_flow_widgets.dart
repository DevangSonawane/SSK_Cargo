import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/google_places_provider.dart';
import '../../../../core/services/google_places_service.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';
import '../controllers/client_bookings_controller.dart';
import 'google_places_autocomplete_field.dart';

enum TripType { interCity, intraCity }

enum _LocationFieldKind { pickup, drop }

class _LocationDetailsScreen extends ConsumerStatefulWidget {
  const _LocationDetailsScreen({
    required this.kind,
    required this.initialValue,
  });

  final _LocationFieldKind kind;
  final String initialValue;

  @override
  ConsumerState<_LocationDetailsScreen> createState() =>
      _LocationDetailsScreenState();
}

class _LocationDetailsScreenState
    extends ConsumerState<_LocationDetailsScreen> {
  late final TextEditingController _controller;
  bool _resolvingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _hintText => widget.kind == _LocationFieldKind.pickup
      ? 'Enter your loading address'
      : 'Enter your unloading address';

  String get _useCurrentLocationLabel =>
      widget.kind == _LocationFieldKind.pickup
      ? 'Use your current location'
      : 'Use current location';

  IconData get _fieldIcon => widget.kind == _LocationFieldKind.pickup
      ? Icons.arrow_upward_rounded
      : Icons.arrow_downward_rounded;

  Color get _fieldIconColor => widget.kind == _LocationFieldKind.pickup
      ? const Color(0xFF38B47A)
      : const Color(0xFFF05252);

  Future<void> _useCurrentLocation() async {
    if (widget.kind != _LocationFieldKind.pickup || _resolvingCurrentLocation) {
      return;
    }

    setState(() {
      _resolvingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on location services to autofill pickup.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is needed to autofill pickup.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final service = ref.read(googlePlacesServiceProvider);
      final address = await service.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;

      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resolve your current address yet.'),
          ),
        );
        return;
      }

      Navigator.of(context).pop(
        GooglePlaceSelection(
          placeId: '',
          formattedAddress: address,
          latitude: position.latitude,
          longitude: position.longitude,
          city: '',
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingCurrentLocation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(999),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                  child: Icon(Icons.arrow_back_rounded, size: 24),
                ),
              ),
              const SizedBox(height: 34),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: const Color(0xFFE7EEF6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _fieldIconColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_fieldIcon, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GooglePlacesAutocompleteField(
                        controller: _controller,
                        label: '',
                        hintText: _hintText,
                        embedded: true,
                        showLabel: false,
                        autofocus: true,
                        onSelected: (selection) {
                          Navigator.of(context).pop(selection);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.kind == _LocationFieldKind.pickup) ...[
                const SizedBox(height: 26),
                InkWell(
                  onTap: _resolvingCurrentLocation ? null : _useCurrentLocation,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        _resolvingCurrentLocation
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.my_location_rounded,
                                color: Color(0xFF2D8EDB),
                                size: 24,
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _useCurrentLocationLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: const Color(0xFF2D8EDB),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: const Color(0xFFE6EAF0)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

extension TripTypeDisplayLabel on TripType {
  String get displayLabel => switch (this) {
    TripType.interCity => 'Full truck',
    TripType.intraCity => 'Part truck',
  };

  String get helperText => switch (this) {
    TripType.interCity => 'Dedicated truck for one shipment',
    TripType.intraCity => 'Share capacity and optimize cost',
  };
}

class BookingData {
  const BookingData({
    required this.from,
    required this.to,
    required this.tripType,
    this.city = '',
    this.vehicle,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.material = '',
    this.additionalNotes = '',
    this.weight = 0,
    this.quantity = 1,
    this.weightUnit = 'tons',
    this.truckCategory = '',
    this.scheduledDate,
    this.distance = 0,
    this.durationMin,
    this.durationInTrafficMin,
    this.amount = 0,
    this.brokerId = '',
    this.truckId = '',
    this.paymentMode = PaymentMode.payLater,
    this.selectedPaymentLabel = '',
  });

  final String from;
  final String to;
  final TripType tripType;
  final String city;
  final VehicleOption? vehicle;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final String material;
  final String additionalNotes;
  final double weight;
  final int quantity;
  final String weightUnit;
  final String truckCategory;
  final DateTime? scheduledDate;
  final double distance;
  final int? durationMin;
  final int? durationInTrafficMin;
  final double amount;
  final String brokerId;
  final String truckId;
  final PaymentMode paymentMode;
  final String selectedPaymentLabel;

  String get transportType =>
      tripType == TripType.interCity ? 'inter' : 'intra';
  String get truckType => vehicle?.label ?? '';
  String get weightText => weight > 0 ? '$weight $weightUnit' : '';
  String get distanceText => distance > 0
      ? '${distance.toStringAsFixed(distance % 1 == 0 ? 0 : 1)} km'
      : '';
  String get amountText =>
      amount > 0 ? '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}' : '';

  BookingData copyWith({
    String? from,
    String? to,
    TripType? tripType,
    String? city,
    VehicleOption? vehicle,
    double? pickupLat,
    double? pickupLng,
    double? dropLat,
    double? dropLng,
    String? material,
    String? additionalNotes,
    double? weight,
    int? quantity,
    String? weightUnit,
    String? truckCategory,
    DateTime? scheduledDate,
    double? distance,
    int? durationMin,
    int? durationInTrafficMin,
    double? amount,
    String? brokerId,
    String? truckId,
    PaymentMode? paymentMode,
    String? selectedPaymentLabel,
  }) {
    return BookingData(
      from: from ?? this.from,
      to: to ?? this.to,
      tripType: tripType ?? this.tripType,
      city: city ?? this.city,
      vehicle: vehicle ?? this.vehicle,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropLat: dropLat ?? this.dropLat,
      dropLng: dropLng ?? this.dropLng,
      material: material ?? this.material,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      weight: weight ?? this.weight,
      quantity: quantity ?? this.quantity,
      weightUnit: weightUnit ?? this.weightUnit,
      truckCategory: truckCategory ?? this.truckCategory,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      distance: distance ?? this.distance,
      durationMin: durationMin ?? this.durationMin,
      durationInTrafficMin: durationInTrafficMin ?? this.durationInTrafficMin,
      amount: amount ?? this.amount,
      brokerId: brokerId ?? this.brokerId,
      truckId: truckId ?? this.truckId,
      paymentMode: paymentMode ?? this.paymentMode,
      selectedPaymentLabel: selectedPaymentLabel ?? this.selectedPaymentLabel,
    );
  }
}

enum PaymentMode { payNow, payLater }

enum PaymentMethod {
  googlePay,
  phonePe,
  paytm,
  otherUpi,
  card,
  cashOnDelivery,
  netBanking,
  emi,
  payLater,
}

extension PaymentMethodLabel on PaymentMethod {
  String get label {
    return switch (this) {
      PaymentMethod.googlePay => 'Google Pay',
      PaymentMethod.phonePe => 'PhonePe',
      PaymentMethod.paytm => 'PayTM',
      PaymentMethod.otherUpi => 'Other UPI',
      PaymentMethod.card => 'Card',
      PaymentMethod.cashOnDelivery => 'Cash On Delivery',
      PaymentMethod.netBanking => 'Net Banking',
      PaymentMethod.emi => 'EMI',
      PaymentMethod.payLater => 'Pay later',
    };
  }
}

class TruckSize {
  const TruckSize({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class VehicleOption {
  const VehicleOption({
    required this.label,
    required this.capacity,
    required this.price,
    required this.accentColor,
    required this.assetPath,
  });

  final String label;
  final String capacity;
  final String price;
  final Color accentColor;
  final String assetPath;
}

const vehicleOptions = <VehicleOption>[
  VehicleOption(
    label: 'Small truck',
    capacity: '500 kg',
    price: '₹899',
    accentColor: Color(0xFF2FA56E),
    assetPath: 'assets/trucks/small truck.png',
  ),
  VehicleOption(
    label: 'Medium truck',
    capacity: '1.5 ton',
    price: '₹1,499',
    accentColor: Color(0xFF1F88C9),
    assetPath: 'assets/trucks/medium truck.png',
  ),
  VehicleOption(
    label: 'Big truck',
    capacity: '3 ton',
    price: '₹2,299',
    accentColor: Color(0xFF7A5AF8),
    assetPath: 'assets/trucks/big truck.png',
  ),
  VehicleOption(
    label: 'Truck pooling',
    capacity: 'Shared capacity',
    price: '₹499',
    accentColor: Color(0xFFF59E0B),
    assetPath: 'assets/trucks/truck pooling.png',
  ),
];

List<VehicleOption> resolveVehicleOptions({
  required TripType tripType,
  ClientPricingConfig? pricing,
  required bool isLoading,
}) {
  if (isLoading) {
    return vehicleOptions
        .map(
          (vehicle) => VehicleOption(
            label: vehicle.label,
            capacity: vehicle.capacity,
            price: 'Loading...',
            accentColor: vehicle.accentColor,
            assetPath: vehicle.assetPath,
          ),
        )
        .toList(growable: false);
  }

  if (pricing == null) {
    return vehicleOptions;
  }

  return vehicleOptions
      .map(
        (vehicle) => VehicleOption(
          label: vehicle.label,
          capacity: vehicle.capacity,
          price: _vehiclePriceLabel(
            label: vehicle.label,
            tripType: tripType,
            pricing: pricing,
            fallback: vehicle.price,
          ),
          accentColor: vehicle.accentColor,
          assetPath: vehicle.assetPath,
        ),
      )
      .toList(growable: false);
}

String _vehiclePriceLabel({
  required String label,
  required TripType tripType,
  required ClientPricingConfig pricing,
  required String fallback,
}) {
  if (tripType == TripType.intraCity) {
    final tier = _intraCityTierForVehicle(pricing, label);
    final baseFare = tier?.baseFare ?? 0;
    if (baseFare > 0) {
      final toll = tier?.tollFixedAmount ?? 0;
      if (toll > 0) {
        return '${_formatRupees(baseFare)} + toll ${_formatRupees(toll)}';
      }
      return _formatRupees(baseFare);
    }
    return fallback;
  }

  final interCityRate = pricing.interCity.baseRatePerKm;
  if (interCityRate > 0) {
    return '${_formatRupees(interCityRate)}/km';
  }

  return fallback;
}

String _formatRupees(double amount) {
  return '₹${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 2)}';
}

ClientTruckPricingTier? _intraCityTierForVehicle(
  ClientPricingConfig pricing,
  String label,
) {
  final text = label.toLowerCase();
  if (text.contains('small')) return pricing.intraCity.small;
  if (text.contains('medium')) return pricing.intraCity.medium;
  if (text.contains('big') || text.contains('large')) {
    return pricing.intraCity.large;
  }
  return pricing.intraCity.small;
}

class TrackingDemoShipment {
  const TrackingDemoShipment({
    required this.packageName,
    required this.trackingId,
    required this.fromLocation,
    required this.toLocation,
    required this.status,
    required this.customerName,
    required this.weight,
    required this.timeline,
    this.pickupLat,
    this.pickupLng,
    this.dropLat,
    this.dropLng,
    this.liveLat,
    this.liveLng,
    this.bookingId,
    this.bookingStatus,
    this.assignedDriverName,
    this.assignedTruckName,
  });

  final String packageName;
  final String trackingId;
  final String fromLocation;
  final String toLocation;
  final String status;
  final String customerName;
  final String weight;
  final List<TrackingTimelineStep> timeline;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropLat;
  final double? dropLng;
  final double? liveLat;
  final double? liveLng;
  final String? bookingId;
  final String? bookingStatus;
  final String? assignedDriverName;
  final String? assignedTruckName;
}

class TrackingTimelineStep {
  const TrackingTimelineStep({
    required this.title,
    required this.subtitle,
    required this.completed,
  });

  final String title;
  final String subtitle;
  final bool completed;
}

TrackingDemoShipment trackingShipmentFromBooking(ClientBooking booking) {
  final status = booking.status.toLowerCase();
  final raw = booking.raw;
  debugPrint(
    '[TrackingShipment] bookingId=${booking.id} '
    'pickup=${_readBookingCoordinate(raw, const ['pickup_lat', 'pickupLat'])},'
    '${_readBookingCoordinate(raw, const ['pickup_lng', 'pickupLng'])} '
    'drop=${_readBookingCoordinate(raw, const ['drop_lat', 'dropLat'])},'
    '${_readBookingCoordinate(raw, const ['drop_lng', 'dropLng'])} '
    'live=${_readBookingCoordinate(raw, const ['current_lat', 'currentLat', 'truck_lat', 'truckLat'])},'
    '${_readBookingCoordinate(raw, const ['current_lng', 'currentLng', 'truck_lng', 'truckLng'])}',
  );
  return TrackingDemoShipment(
    packageName: booking.displayTitle,
    trackingId: booking.bookingRef.isEmpty ? booking.id : booking.bookingRef,
    fromLocation: booking.pickupLocation.isEmpty
        ? 'Pickup location not provided'
        : booking.pickupLocation,
    toLocation: booking.dropoffLocation.isEmpty
        ? 'Drop-off location not provided'
        : booking.dropoffLocation,
    status: booking.displayStatusLabel,
    customerName: booking.clientName,
    weight: booking.weight.isEmpty ? booking.vehicleType : booking.weight,
    pickupLat: _readBookingCoordinate(raw, const ['pickup_lat', 'pickupLat']),
    pickupLng: _readBookingCoordinate(raw, const ['pickup_lng', 'pickupLng']),
    dropLat: _readBookingCoordinate(raw, const ['drop_lat', 'dropLat']),
    dropLng: _readBookingCoordinate(raw, const ['drop_lng', 'dropLng']),
    liveLat: _readBookingCoordinate(raw, const [
      'current_lat',
      'currentLat',
      'truck_lat',
      'truckLat',
    ]),
    liveLng: _readBookingCoordinate(raw, const [
      'current_lng',
      'currentLng',
      'truck_lng',
      'truckLng',
    ]),
    bookingId: booking.id,
    bookingStatus: status,
    timeline: _timelineForStatus(status, booking),
  );
}

List<TrackingTimelineStep> _timelineForStatus(
  String status,
  ClientBooking booking,
) {
  final origin = booking.pickupLocation.isEmpty
      ? 'Pickup location not provided'
      : booking.pickupLocation;
  final destination = booking.dropoffLocation.isEmpty
      ? 'Drop-off location not provided'
      : booking.dropoffLocation;

  switch (status) {
    case 'completed':
    case 'delivered':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Assigned',
          subtitle: 'Vehicle assigned',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Completed successfully',
          completed: true,
        ),
      ];
    case 'assigned':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Assigned',
          subtitle: 'Driver assigned',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
    case 'en_route_pickup':
    case 'picked_up':
    case 'in_transit':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Assigned',
          subtitle: 'Driver assigned',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
    case 'confirmed':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Confirmed',
          subtitle: 'Waiting for assignment',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
    case 'cancelled':
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Cancelled',
          subtitle: 'Booking was cancelled',
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Cancelled',
          completed: false,
        ),
      ];
    case 'pending':
    default:
      return [
        TrackingTimelineStep(
          title: 'Booking created',
          subtitle: origin,
          completed: true,
        ),
        TrackingTimelineStep(
          title: 'Pending',
          subtitle: 'Waiting for confirmation',
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'In transit',
          subtitle: destination,
          completed: false,
        ),
        TrackingTimelineStep(
          title: 'Delivered',
          subtitle: 'Pending',
          completed: false,
        ),
      ];
  }
}

const trackingDemoShipments = <TrackingDemoShipment>[
  TrackingDemoShipment(
    packageName: 'MacBook Air M3',
    trackingId: 'TRK-SSK-20489',
    fromLocation: 'Mumbai Warehouse',
    toLocation: 'Pune Distribution Center',
    status: 'Your package is in transit',
    customerName: 'Aarav Mehta',
    weight: '2.40 KG',
    pickupLat: 19.0760,
    pickupLng: 72.8777,
    dropLat: 18.5204,
    dropLng: 73.8567,
    liveLat: 18.7640,
    liveLng: 73.4100,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Mumbai Warehouse',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Pune Gateway Hub',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Pune Distribution Center',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Awaiting final handoff',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Apple iPhone 15 Pro',
    trackingId: 'TRK-SSK-20841',
    fromLocation: 'Navi Mumbai Hub',
    toLocation: 'Bangalore Tech Park',
    status: 'Arriving at next checkpoint',
    customerName: 'Karan Shah',
    weight: '1.15 KG',
    pickupLat: 19.0330,
    pickupLng: 73.0297,
    dropLat: 12.9716,
    dropLng: 77.5946,
    liveLat: 16.0800,
    liveLng: 75.3500,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Navi Mumbai Hub',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Kolhapur Sorting Center',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Bangalore Tech Park',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Final confirmation pending',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Office Chair Set',
    trackingId: 'TRK-SSK-21077',
    fromLocation: 'Delhi DC-3',
    toLocation: 'Jaipur Office',
    status: 'Awaiting dispatch',
    customerName: 'Neha Kapoor',
    weight: '8.60 KG',
    pickupLat: 28.7041,
    pickupLng: 77.1025,
    dropLat: 26.9124,
    dropLng: 75.7873,
    liveLat: 27.5400,
    liveLng: 76.4200,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Delhi DC-3',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Load assigned',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Queue for pickup',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Not started yet',
        completed: false,
      ),
    ],
  ),
  TrackingDemoShipment(
    packageName: 'Printer Cartridge Box',
    trackingId: 'TRK-SSK-21330',
    fromLocation: 'Pune Cargo Yard',
    toLocation: 'Hyderabad Retail Store',
    status: 'Out for pickup',
    customerName: 'Rohan Kulkarni',
    weight: '4.05 KG',
    pickupLat: 18.5204,
    pickupLng: 73.8567,
    dropLat: 17.3850,
    dropLng: 78.4867,
    liveLat: 17.9400,
    liveLng: 76.9900,
    timeline: [
      TrackingTimelineStep(
        title: 'Tracking Number Created',
        subtitle: 'Pune Cargo Yard',
        completed: true,
      ),
      TrackingTimelineStep(
        title: 'In Transit',
        subtitle: 'Pickup scheduled',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Out for Delivery',
        subtitle: 'Not started',
        completed: false,
      ),
      TrackingTimelineStep(
        title: 'Delivered',
        subtitle: 'Pending',
        completed: false,
      ),
    ],
  ),
];

class PillTag extends StatelessWidget {
  const PillTag({
    super.key,
    required this.label,
    required this.icon,
    required this.backgroundColor,
    this.textColor = Colors.white,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationArc extends StatelessWidget {
  const LocationArc({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE6EDF3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: scheme.primary, size: 17),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pick up from',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mumbai, Maharashtra',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: const Color(0xFF17324D),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 12,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class BannerCard extends StatelessWidget {
  const BannerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: const AspectRatio(
        aspectRatio: 2,
        child: Image(
          image: AssetImage('assets/client/test.png'),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}

Future<void> showTripTypeSheet(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  onOpen?.call();
  try {
    final tripType =
        initialTripType ??
        await showModalBottomSheet<TripType>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const TripTypeSheet(),
        );
    if (tripType == null || !context.mounted) return;

    final bookingData = await Navigator.of(context).push<BookingData>(
      MaterialPageRoute(
        builder: (context) => BookingLocationScreen(
          tripType: tripType,
          initialVehicleIndex: initialVehicleIndex ?? 0,
        ),
      ),
    );
    if (bookingData == null || !context.mounted) return;

    final vehicle = await Navigator.of(context).push<VehicleOption>(
      MaterialPageRoute(
        builder: (context) => SelectVehicleScreen(
          bookingData: bookingData,
          initialIndex: initialVehicleIndex ?? 0,
        ),
      ),
    );
    if (vehicle == null || !context.mounted) return;
  } finally {
    onClose?.call();
  }
}

Future<void> showBookingFlow(
  BuildContext context, {
  TripType? initialTripType,
  int? initialVehicleIndex,
  VoidCallback? onOpen,
  VoidCallback? onClose,
}) async {
  await showTripTypeSheet(
    context,
    initialTripType: initialTripType,
    initialVehicleIndex: initialVehicleIndex,
    onOpen: onOpen,
    onClose: onClose,
  );
}

class TrackingMockCard extends StatelessWidget {
  const TrackingMockCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final double progress;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE7EEF5)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEAF2F8),
                    valueColor: AlwaysStoppedAnimation(accent),
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

class PackageTrackingCard extends StatelessWidget {
  const PackageTrackingCard({super.key, required this.shipment, this.onTap});

  final TrackingDemoShipment shipment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0F3F7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D9),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(7),
                  child: Image.asset('assets/package.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shipment.packageName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF121826),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '#Tracking ID: ${shipment.trackingId}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black45,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 28,
                  height: 28,
                ),
                icon: const Icon(Icons.more_horiz_rounded, size: 22),
                color: Colors.black45,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 14,
                child: Column(
                  children: [
                    const SizedBox(height: 3),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 30,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F4E8),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2FA56E),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      shipment.fromLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Shipping to:',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.black38,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      shipment.toLocation,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF1C2430),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFECEFF3)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 5),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: const Color(0xFF2FA56E),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Status:',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: const Color(0xFF1C2430),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  shipment.status,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF1C2430),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (onTap == null) {
      return card;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: card,
    );
  }
}

class TruckIllustration extends StatelessWidget {
  const TruckIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 10,
            left: 4,
            child: Container(
              width: 52,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2FA56E).withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.local_shipping_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          Positioned(
            right: 6,
            top: 16,
            child: Container(
              width: 20,
              height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF1F88C9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: 13,
              ),
            ),
          ),
          const Positioned(bottom: 10, left: 10, child: Wheel()),
          const Positioned(bottom: 10, right: 10, child: Wheel()),
        ],
      ),
    );
  }
}

class Wheel extends StatelessWidget {
  const Wheel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF17324D),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE7EEF5)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2FA56E).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF2FA56E)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.black38),
          ],
        ),
      ),
    );
  }
}

class SheetContainer extends StatelessWidget {
  const SheetContainer({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: DraggableScrollableSheet(
        initialChildSize: 0.46,
        minChildSize: 0.36,
        maxChildSize: 0.86,
        expand: false,
        builder: (context, controller) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 54,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDE7EF),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 18),
                  child,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class TripTypeSheet extends StatelessWidget {
  const TripTypeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bottomInset = _sheetBottomInset(context);
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 46,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE7EF),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Choose trip type',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 16),
            ),
            const SizedBox(height: 12),
            _TripTypeRow(
              imagePath: 'assets/trucks/inter-city.png',
              label: TripType.interCity.displayLabel,
              helperText: TripType.interCity.helperText,
              onTap: () => Navigator.of(context).pop(TripType.interCity),
            ),
            const SizedBox(height: 10),
            _TripTypeRow(
              imagePath: 'assets/trucks/intra-city.png',
              label: TripType.intraCity.displayLabel,
              helperText: TripType.intraCity.helperText,
              onTap: () => Navigator.of(context).pop(TripType.intraCity),
            ),
          ],
        ),
      ),
    );
  }
}

double _sheetBottomInset(BuildContext context) {
  final viewPadding = MediaQuery.of(context).viewPadding.bottom;
  return viewPadding > 0 ? viewPadding + 28 : 28;
}

class _TripTypeRow extends StatelessWidget {
  const _TripTypeRow({
    required this.imagePath,
    required this.label,
    required this.helperText,
    required this.onTap,
  });

  final String imagePath;
  final String label;
  final String helperText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F6F8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Row(
          children: [
            Image.asset(imagePath, width: 54, height: 54, fit: BoxFit.contain),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    helperText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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

class BookingLocationScreen extends ConsumerStatefulWidget {
  const BookingLocationScreen({
    super.key,
    required this.tripType,
    this.initialVehicleIndex = 0,
    this.autoOpenLocationFlow = false,
  });

  final TripType tripType;
  final int initialVehicleIndex;
  final bool autoOpenLocationFlow;

  @override
  ConsumerState<BookingLocationScreen> createState() =>
      _BookingLocationScreenState();
}

enum _BookingFlowStep { location, itemDetails, brokerSelection, payment }

enum _NegotiationSheetStep { slider, loading, counterOffer }

enum _TruckAction { continueBooking, negotiate }

class _NegotiationSheetResult {
  const _NegotiationSheetResult._(this.accepted, this.amount);

  factory _NegotiationSheetResult.accepted(double amount) =>
      _NegotiationSheetResult._(true, amount);

  factory _NegotiationSheetResult.chooseAnotherBroker() =>
      const _NegotiationSheetResult._(false, null);

  final bool accepted;
  final double? amount;
}

const _brokerNegotiationMessages = <String>[
  'Sending your negotiation offer',
  'Waiting for the broker to review it',
  'Give us a moment, the broker is responding',
];

class _BookingLocationScreenState extends ConsumerState<BookingLocationScreen> {
  static const LatLng _fallbackMapCenter = LatLng(19.0760, 72.8777);

  late final TextEditingController _fromController;
  late final TextEditingController _toController;
  late final TextEditingController _weightController;
  late final TextEditingController _amountController;
  late VehicleOption _vehicle;
  GoogleMapController? _brokerMapController;
  BitmapDescriptor? _truckMarkerIcon;
  BitmapDescriptor? _pickupMarkerIcon;
  BitmapDescriptor? _dropMarkerIcon;
  List<LatLng> _brokerRoutePoints = const [];
  int _brokerRouteRequestToken = 0;

  _BookingFlowStep _step = _BookingFlowStep.location;
  NearbyTruck? _selectedTruck;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.googlePay;
  bool _submitting = false;
  bool _resolvingDistance = false;
  bool _resolvingCurrentLocation = false;
  bool _bookingCreated = false;
  String? _bookingReference;
  bool _weightUnknown = false;
  String? _weightError;
  late BookingData _draft;
  late int _vehicleIndex;
  bool _autoLocationFlowStarted = false;

  @override
  void initState() {
    super.initState();
    ref.read(bottomNavVisibleProvider.notifier).state = false;
    _loadTruckMarkerIcon();
    _vehicleIndex = widget.initialVehicleIndex;
    final initialPricingState = ref.read(clientPricingProvider);
    final vehicles = resolveVehicleOptions(
      tripType: widget.tripType,
      pricing: initialPricingState.valueOrNull,
      isLoading: initialPricingState.isLoading,
    );
    _vehicleIndex = _vehicleIndex.clamp(0, vehicles.length - 1).toInt();
    _vehicle = vehicles[_vehicleIndex];
    _draft = BookingData(
      from: '',
      to: '',
      tripType: widget.tripType,
      city: '',
      vehicle: _vehicle,
      truckCategory: _truckCategoryForVehicle(_vehicle.label),
      scheduledDate: DateTime.now().add(const Duration(hours: 3)),
      amount: _priceValue(_vehicle.price),
    );
    _fromController = TextEditingController(text: _draft.from);
    _toController = TextEditingController();
    _weightController = TextEditingController();
    _amountController = TextEditingController(
      text: _priceInputText(_vehicle.price),
    );

    if (widget.autoOpenLocationFlow) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _runAutoLocationFlow();
        }
      });
    }
  }

  @override
  void dispose() {
    ref.read(bottomNavVisibleProvider.notifier).state = true;
    _brokerMapController?.dispose();
    _fromController.dispose();
    _toController.dispose();
    _weightController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadTruckMarkerIcon() async {
    try {
      final truck = await _buildTruckCircleMarkerIcon(
        'assets/trucks/small truck.png',
      );
      final pickup = await _buildDotMarkerIcon(const Color(0xFF22C55E));
      final drop = await _buildDotMarkerIcon(const Color(0xFFEF4444));
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = truck;
        _pickupMarkerIcon = pickup;
        _dropMarkerIcon = drop;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _truckMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        );
        _pickupMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueGreen,
        );
        _dropMarkerIcon = BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        );
      });
    }
  }

  Future<void> _refreshBrokerRoute() async {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final token = ++_brokerRouteRequestToken;
    if (pickup == null || drop == null) {
      if (mounted) {
        setState(() {
          _brokerRoutePoints = const [];
        });
      }
      return;
    }

    try {
      final service = ref.read(googlePlacesServiceProvider);
      final route = await service.fetchDrivingRoute(
        originLatitude: pickup.latitude,
        originLongitude: pickup.longitude,
        destinationLatitude: drop.latitude,
        destinationLongitude: drop.longitude,
      );
      if (!mounted || token != _brokerRouteRequestToken) {
        return;
      }
      setState(() {
        _brokerRoutePoints = route;
      });
    } catch (_) {
      if (!mounted || token != _brokerRouteRequestToken) {
        return;
      }
      setState(() {
        _brokerRoutePoints = const [];
      });
    }
  }

  Future<GooglePlaceSelection?> _openLocationDetailsScreen(
    _LocationFieldKind kind,
  ) async {
    final initialValue = kind == _LocationFieldKind.pickup
        ? _fromController.text
        : _toController.text;

    return Navigator.of(context).push<GooglePlaceSelection>(
      MaterialPageRoute(
        builder: (context) =>
            _LocationDetailsScreen(kind: kind, initialValue: initialValue),
      ),
    );
  }

  Future<void> _runAutoLocationFlow() async {
    if (_autoLocationFlowStarted || !mounted) {
      return;
    }
    _autoLocationFlowStarted = true;

    final pickup = await _openLocationDetailsScreen(_LocationFieldKind.pickup);
    if (pickup == null || !mounted) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        from: pickup.formattedAddress,
        pickupLat: pickup.latitude,
        pickupLng: pickup.longitude,
        city: pickup.city.isNotEmpty ? pickup.city : _draft.city,
      );
      _fromController.text = pickup.formattedAddress;
    });

    final drop = await _openLocationDetailsScreen(_LocationFieldKind.drop);
    if (drop == null || !mounted) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        to: drop.formattedAddress,
        dropLat: drop.latitude,
        dropLng: drop.longitude,
      );
      _toController.text = drop.formattedAddress;
    });

    if (mounted) {
      await _resolveDistanceAndContinue();
    }
  }

  Future<BitmapDescriptor> _buildTruckCircleMarkerIcon(String assetPath) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 40.0;
    const center = Offset(size / 2, size / 2);
    const radius = size / 2;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 1), radius - 4, shadowPaint);

    final borderPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - 3, borderPaint);

    final imageData = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      imageData.buffer.asUint8List(),
      targetWidth: 18,
      targetHeight: 18,
    );
    final frame = await codec.getNextFrame();

    final clipRect = Rect.fromCircle(center: center, radius: radius - 8);
    canvas.save();
    canvas.clipPath(Path()..addOval(clipRect));
    canvas.drawImageRect(
      frame.image,
      Rect.fromLTWH(
        0,
        0,
        frame.image.width.toDouble(),
        frame.image.height.toDouble(),
      ),
      clipRect,
      Paint(),
    );
    canvas.restore();

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to build truck marker icon');
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<BitmapDescriptor> _buildDotMarkerIcon(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 20.0;
    final center = const Offset(size / 2, size / 2);
    final outer = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final inner = Paint()..color = color;
    canvas.drawCircle(center, 9, outer);
    canvas.drawCircle(center, 6, inner);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw StateError('Failed to build marker icon');
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  Future<void> _advanceFromWeightStep({required bool unknown}) async {
    final rawWeight = _weightController.text.trim();
    final parsedWeight = double.tryParse(rawWeight);

    if (!unknown && (parsedWeight == null || parsedWeight <= 0)) {
      setState(() {
        _weightUnknown = false;
        _weightError = 'Enter weight';
      });
      return;
    }

    setState(() {
      _weightUnknown = unknown;
      _weightError = null;
      _draft = _draft.copyWith(
        weight: unknown ? 0 : parsedWeight ?? 0,
        quantity: 1,
        material: '',
        additionalNotes: '',
      );
      _selectedTruck = null;
      _step = _BookingFlowStep.brokerSelection;
    });
  }

  Future<void> _next() async {
    switch (_step) {
      case _BookingFlowStep.location:
        if (_toController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter the drop location.')),
          );
          return;
        }
        await _resolveDistanceAndContinue();
        return;
      case _BookingFlowStep.itemDetails:
        await _advanceFromWeightStep(unknown: _weightUnknown);
        return;
      case _BookingFlowStep.brokerSelection:
        return;
      case _BookingFlowStep.payment:
        setState(() {
          _draft = _draft.copyWith(
            selectedPaymentLabel: _selectedPaymentMethod.label,
          );
        });
        await _submitBooking();
        return;
    }
  }

  void _acceptSelectedBroker(NearbyTruck truck) {
    setState(() {
      _draft = _draft.copyWith(brokerId: truck.id);
      _step = _BookingFlowStep.payment;
    });
  }

  Future<void> _openNegotiationSheet(NearbyTruck truck) async {
    final basePrice = _draft.amount > 0
        ? _draft.amount
        : _priceValue(_vehicle.price);
    final lower = basePrice * 0.84;
    final upper = basePrice * 1.08;
    final initial = _draft.amount > 0
        ? _draft.amount.clamp(lower, upper).toDouble()
        : basePrice.clamp(lower, upper).toDouble();

    final outcome = await showModalBottomSheet<_NegotiationSheetResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BrokerNegotiationSheet(
        truck: truck,
        minPrice: lower,
        maxPrice: upper,
        initialPrice: initial,
      ),
    );

    if (!mounted || outcome == null) {
      return;
    }

    if (outcome.accepted) {
      setState(() {
        _draft = _draft.copyWith(brokerId: truck.id, amount: outcome.amount);
        _step = _BookingFlowStep.payment;
      });
    }
  }

  Future<void> _handleTruckTap(NearbyTruck truck) async {
    setState(() {
      _selectedTruck = truck;
    });

    final action = await _showTruckActionDialog(truck);
    if (!mounted || action == null) {
      return;
    }

    if (action == _TruckAction.continueBooking) {
      _acceptSelectedBroker(truck);
      return;
    }

    await _openNegotiationSheet(truck);
  }

  Future<_TruckAction?> _showTruckActionDialog(NearbyTruck truck) {
    return showDialog<_TruckAction>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          title: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  truck.displayTitle,
                  style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                icon: const Icon(Icons.close_rounded),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 34,
                  height: 34,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                truck.displaySubtitle,
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFF2FA56E),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      truck.capacity.isNotEmpty
                          ? truck.capacity
                          : 'Available truck',
                      style: Theme.of(dialogContext).textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF101828),
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(
                      dialogContext,
                    ).pop(_TruckAction.continueBooking),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(dialogContext).pop(_TruckAction.negotiate),
                    child: const Text('Negotiate'),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _resolveDistanceAndContinue() async {
    if (_resolvingDistance) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }

    final pickup = _fromController.text.trim();
    final drop = _toController.text.trim();
    if (pickup.isEmpty || drop.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both pickup and drop locations.'),
        ),
      );
      return;
    }

    setState(() {
      _resolvingDistance = true;
    });

    try {
      await _resolveTypedCoordinates(pickup: pickup, drop: drop);
      await _refreshBrokerRoute();
      final city = _draft.transportType == 'intra'
          ? (_draft.city.isNotEmpty
                ? _draft.city
                : _deriveCityFromLocation(pickup, drop))
          : '';
      if (city.isNotEmpty || _draft.city.isNotEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _draft = _draft.copyWith(city: city);
        });
      }
      await _validateLocationStep(pickup, drop);
      final response = await ref
          .read(apiClientProvider)
          .getDistanceEstimate(
            accessToken: session.tokens.accessToken,
            pickup: pickup,
            drop: drop,
          );
      final data = response['data'];
      final distance = _readDistanceValue(data, response);
      final durationMin = _readIntValue(data, response, const [
        'durationMin',
        'duration_min',
      ]);
      final durationInTrafficMin = _readIntValue(data, response, const [
        'durationInTrafficMin',
        'duration_in_traffic_min',
      ]);
      final estimatedAmount = await _estimateBookingAmount(
        accessToken: session.tokens.accessToken,
        distance: distance,
        durationMin: durationMin,
        durationInTrafficMin: durationInTrafficMin,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _draft = _draft.copyWith(
          to: drop,
          from: pickup,
          city: city,
          vehicle: _vehicle,
          truckCategory: _truckCategoryForVehicle(_vehicle.label),
          distance: distance,
          durationMin: durationMin,
          durationInTrafficMin: durationInTrafficMin,
          amount: estimatedAmount ?? _draft.amount,
        );
        _amountController.text = estimatedAmount == null
            ? _amountController.text
            : _priceInputText(estimatedAmount.toString());
        _step = _BookingFlowStep.itemDetails;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingDistance = false;
        });
      }
    }
  }

  Future<void> _resolveTypedCoordinates({
    required String pickup,
    required String drop,
  }) async {
    final service = ref.read(googlePlacesServiceProvider);
    final pickupNeedsResolution =
        _draft.pickupLat == null || _draft.pickupLng == null;
    final dropNeedsResolution =
        _draft.dropLat == null || _draft.dropLng == null;

    GooglePlaceSelection? pickupSelection;
    if (pickupNeedsResolution) {
      pickupSelection = await service.geocodeAddress(address: pickup);
    }

    GooglePlaceSelection? dropSelection;
    if (dropNeedsResolution) {
      dropSelection = await service.geocodeAddress(address: drop);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      if (pickupSelection != null &&
          pickupSelection.latitude != null &&
          pickupSelection.longitude != null) {
        _draft = _draft.copyWith(
          from: pickupSelection.formattedAddress.isNotEmpty
              ? pickupSelection.formattedAddress
              : pickup,
          pickupLat: pickupSelection.latitude,
          pickupLng: pickupSelection.longitude,
          city: pickupSelection.city.isNotEmpty
              ? pickupSelection.city
              : _draft.city,
        );
        if (pickupSelection.formattedAddress.isNotEmpty) {
          _fromController.text = pickupSelection.formattedAddress;
        }
      }

      if (dropSelection != null &&
          dropSelection.latitude != null &&
          dropSelection.longitude != null) {
        _draft = _draft.copyWith(
          to: dropSelection.formattedAddress.isNotEmpty
              ? dropSelection.formattedAddress
              : drop,
          dropLat: dropSelection.latitude,
          dropLng: dropSelection.longitude,
        );
        if (dropSelection.formattedAddress.isNotEmpty) {
          _toController.text = dropSelection.formattedAddress;
        }
      }
    });
  }

  Future<void> _useCurrentLocationForPickup() async {
    if (_resolvingCurrentLocation) {
      return;
    }

    setState(() {
      _resolvingCurrentLocation = true;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on location services to autofill pickup.'),
          ),
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is needed to autofill pickup.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final service = ref.read(googlePlacesServiceProvider);
      final address = await service.reverseGeocode(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;

      if (address.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not resolve your current address yet.'),
          ),
        );
        return;
      }

      setState(() {
        final city = _deriveCityFromLocation(address, '');
        _draft = _draft.copyWith(
          from: address,
          pickupLat: position.latitude,
          pickupLng: position.longitude,
          city: city.isNotEmpty ? city : _draft.city,
        );
        _fromController.text = address;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _resolvingCurrentLocation = false;
        });
      }
    }
  }

  Future<double?> _estimateBookingAmount({
    required String accessToken,
    required double distance,
    required int? durationMin,
    required int? durationInTrafficMin,
  }) async {
    try {
      final payload = <String, dynamic>{
        'distance': distance,
        'truck_category': _truckCategoryForVehicle(_vehicle.label),
        'transport_type': _draft.transportType,
        'truck_type': _vehicle.label,
      };
      if (durationMin != null) {
        payload['duration_min'] = durationMin;
      }
      if (durationInTrafficMin != null) {
        payload['duration_in_traffic_min'] = durationInTrafficMin;
      }
      final response = await ref
          .read(apiClientProvider)
          .estimatePricing(accessToken: accessToken, payload: payload);
      return _readMoneyValue(response['data'], response);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submitBooking() async {
    if (_submitting || _bookingCreated) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in again to create a booking.'),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .createBooking(
            accessToken: session.tokens.accessToken,
            booking: _bookingPayload(),
            idempotencyKey: _buildIdempotencyKey(),
          );
      final bookingNumber = _extractBookingNumber(response);
      final resolvedBookingNumber = bookingNumber.isNotEmpty
          ? bookingNumber
          : await _fetchLatestBookingNumber(session.tokens.accessToken);

      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _bookingCreated = true;
        _bookingReference = resolvedBookingNumber;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('ApiException: ', '')),
        ),
      );
    }
  }

  Map<String, dynamic> _bookingPayload() {
    final scheduled =
        _draft.scheduledDate ?? DateTime.now().add(const Duration(hours: 3));
    return <String, dynamic>{
      'pickup_location': _draft.from,
      'pickup_lat': _draft.pickupLat ?? 0,
      'pickup_lng': _draft.pickupLng ?? 0,
      'drop_location': _draft.to,
      'drop_lat': _draft.dropLat ?? 0,
      'drop_lng': _draft.dropLng ?? 0,
      'truck_type': _draft.truckType,
      'truck_category': _draft.truckCategory.isEmpty
          ? _truckCategoryForVehicle(_vehicle.label)
          : _draft.truckCategory,
      'city': _draft.transportType == 'intra'
          ? _draft.city.isNotEmpty
                ? _draft.city
                : _deriveCityFromLocation(_draft.from, _draft.to)
          : _draft.city,
      'weight': _draft.weight,
      'weight_unit': _draft.weightUnit,
      'quantity': _draft.quantity,
      'material': _draft.material,
      'transport_type': _draft.transportType,
      'scheduled_date': scheduled.toUtc().toIso8601String(),
      'distance': _draft.distance,
      'amount': _draft.amount,
      'payment_status': 'pending',
    };
  }

  Future<void> _validateLocationStep(String pickup, String drop) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      throw StateError('No active session');
    }

    final locationPayload = <String, dynamic>{
      'pickup_location': pickup,
      'drop_location': drop,
      'transport_type': _draft.transportType,
      if (_draft.transportType == 'intra')
        'city': _draft.city.isNotEmpty
            ? _draft.city
            : _deriveCityFromLocation(pickup, drop),
    };

    await ref
        .read(apiClientProvider)
        .validateBookingLocation(
          accessToken: session.tokens.accessToken,
          location: locationPayload,
        );
  }

  String _buildIdempotencyKey() {
    final payload = <String, dynamic>{
      ..._bookingPayload(),
      'attempted_at': DateTime.now().microsecondsSinceEpoch,
    };
    final normalized = payload.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('|');
    final timestamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    final hash = normalized.hashCode.abs().toRadixString(36);
    final random = Random().nextInt(1 << 32).toRadixString(36);
    return '$timestamp-$hash-$random';
  }

  String _deriveCityFromLocation(String pickup, String drop) {
    String cityFromAddress(String value) {
      final segments = value
          .split(',')
          .map((segment) => segment.trim())
          .where((segment) => segment.isNotEmpty)
          .toList(growable: false);
      if (segments.length >= 2) {
        return segments[1];
      }
      if (segments.isNotEmpty) {
        return segments.first;
      }
      return '';
    }

    final pickupCity = cityFromAddress(pickup);
    if (pickupCity.isNotEmpty) {
      return pickupCity;
    }
    return cityFromAddress(drop);
  }

  Future<String> _fetchLatestBookingNumber(String accessToken) async {
    final response = await ref
        .read(apiClientProvider)
        .getBookings(accessToken: accessToken, page: 1, limit: 20);
    final bookingsPage = ClientBookingPage.fromJson(response);
    if (bookingsPage.bookings.isEmpty) {
      return '';
    }

    final candidates = bookingsPage.bookings
        .where(_matchesDraftBooking)
        .toList();
    final booking = candidates.isNotEmpty
        ? candidates.first
        : bookingsPage.bookings.first;
    return booking.bookingNumber.isNotEmpty
        ? booking.bookingNumber
        : (booking.bookingRef.isNotEmpty ? booking.bookingRef : booking.id);
  }

  bool _matchesDraftBooking(ClientBooking booking) {
    final draftPickup = _draft.from.trim().toLowerCase();
    final draftDrop = _draft.to.trim().toLowerCase();
    final draftMaterial = _draft.material.trim().toLowerCase();
    final draftAmount = _draft.amount.toStringAsFixed(2);
    final bookingAmount = booking.amountText.replaceAll(RegExp(r'[^0-9.]'), '');
    return booking.pickupLocation.trim().toLowerCase() == draftPickup &&
        booking.dropoffLocation.trim().toLowerCase() == draftDrop &&
        (draftMaterial.isEmpty ||
            booking.packageName.trim().toLowerCase().contains(draftMaterial) ||
            booking.raw['material']?.toString().trim().toLowerCase() ==
                draftMaterial) &&
        (bookingAmount.isEmpty ||
            bookingAmount == draftAmount ||
            bookingAmount == _draft.amount.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(clientPricingProvider, (previous, next) {
      final pricing = next.valueOrNull;
      if (pricing == null || !mounted) {
        return;
      }
      final vehicles = resolveVehicleOptions(
        tripType: widget.tripType,
        pricing: pricing,
        isLoading: false,
      );
      if (vehicles.isEmpty) return;
      final safeIndex = _vehicleIndex.clamp(0, vehicles.length - 1).toInt();
      final updatedVehicle = vehicles[safeIndex];
      setState(() {
        _vehicle = updatedVehicle;
        _draft = _draft.copyWith(
          vehicle: updatedVehicle,
          truckCategory: _truckCategoryForVehicle(updatedVehicle.label),
          amount: _priceValue(updatedVehicle.price),
        );
        _amountController.text = _priceInputText(updatedVehicle.price);
      });
    });

    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final showBottomButton = switch (_step) {
      _BookingFlowStep.location || _BookingFlowStep.payment => true,
      _BookingFlowStep.itemDetails => false,
      _BookingFlowStep.brokerSelection => false,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _bookingCreated || !showBottomButton
          ? const SizedBox.shrink()
          : Padding(
              padding: EdgeInsets.fromLTRB(18, 10, 18, bottomInset + 44),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submitting ? null : _next,
                  child: (_submitting || _resolvingDistance)
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(switch (_step) {
                          _BookingFlowStep.location => 'Next',
                          _BookingFlowStep.payment => 'Continue',
                          _BookingFlowStep.brokerSelection => 'Continue',
                          _BookingFlowStep.itemDetails => 'Next',
                        }),
                ),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            if (_step == _BookingFlowStep.location) {
                              Navigator.of(context).pop();
                              return;
                            }
                            setState(() {
                              _step = switch (_step) {
                                _BookingFlowStep.location =>
                                  _BookingFlowStep.location,
                                _BookingFlowStep.itemDetails =>
                                  _BookingFlowStep.location,
                                _BookingFlowStep.brokerSelection =>
                                  _BookingFlowStep.itemDetails,
                                _BookingFlowStep.payment =>
                                  _BookingFlowStep.brokerSelection,
                              };
                            });
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: Icon(Icons.arrow_back_rounded, size: 18),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          switch (_step) {
                            _BookingFlowStep.location => 'Location',
                            _BookingFlowStep.itemDetails => 'Weight',
                            _BookingFlowStep.brokerSelection => 'Choose trucks',
                            _BookingFlowStep.payment => 'Payment',
                          },
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: const Color(0xFF667085),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCurrentStep(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(BuildContext context) {
    return switch (_step) {
      _BookingFlowStep.location => _buildLocationStep(context),
      _BookingFlowStep.itemDetails => _buildItemDetailsStep(context),
      _BookingFlowStep.brokerSelection => _buildBrokerSelectionStep(context),
      _BookingFlowStep.payment =>
        _bookingCreated
            ? _buildSuccessStep(context)
            : _buildPaymentStep(context),
    };
  }

  Widget _buildBrokerSelectionStep(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.72;
    final pickup = _pickupLatLng;
    final nearbyTrucksAsync = pickup == null
        ? const AsyncValue<List<NearbyTruck>>.data(<NearbyTruck>[])
        : ref.watch(
            clientNearbyTrucksProvider((
              pickupLat: pickup.latitude,
              pickupLng: pickup.longitude,
              radiusKm: 25,
              page: 1,
              limit: 20,
            )),
          );
    final nearbyTrucks = nearbyTrucksAsync.valueOrNull ?? const <NearbyTruck>[];
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewPadding.bottom + 12,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tap a truck on the map to continue or negotiate.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF667085),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: height,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      _buildBrokerMap(context, nearbyTrucks),
                      if (nearbyTrucksAsync.isLoading)
                        const Positioned.fill(
                          child: IgnorePointer(
                            child: ColoredBox(color: Color(0x0AFFFFFF)),
                          ),
                        ),
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _MapHintPill(
                          icon: Icons.local_shipping_rounded,
                          label: 'Live trucks',
                        ),
                      ),
                      if (_selectedTruck != null)
                        Positioned(
                          right: 16,
                          bottom: 16,
                          child: _MapHintPill(
                            icon: Icons.touch_app_rounded,
                            label: _selectedTruck!.displayTitle,
                            accent: const Color(0xFF2FA56E),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBrokerMap(BuildContext context, List<NearbyTruck> trucks) {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final cameraTarget = _brokerMapCenter();
    final markers = _buildBrokerMarkers(trucks);
    final polylines = _buildBrokerPolylines();

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: cameraTarget,
        zoom: pickup != null && drop != null ? 9.6 : 11.6,
      ),
      mapType: MapType.normal,
      markers: markers,
      polylines: polylines,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      compassEnabled: false,
      mapToolbarEnabled: false,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      tiltGesturesEnabled: false,
      trafficEnabled: false,
      onMapCreated: (controller) {
        _brokerMapController = controller;
      },
    );
  }

  Set<Marker> _buildBrokerMarkers(List<NearbyTruck> trucks) {
    final icon =
        _truckMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    final markers = <Marker>{};

    for (final truck in trucks) {
      if (!truck.hasLocation) {
        continue;
      }
      markers.add(
        Marker(
          markerId: MarkerId(truck.id),
          position: LatLng(truck.currentLat, truck.currentLng),
          icon: icon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: _selectedTruck?.id == truck.id ? 2 : 1,
          infoWindow: InfoWindow(
            title: truck.displayTitle,
            snippet: truck.displaySubtitle,
          ),
          onTap: () => _handleTruckTap(truck),
        ),
      );
    }

    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    final pickupIcon =
        _pickupMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    final dropIcon =
        _dropMarkerIcon ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);

    if (pickup != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup-point'),
          position: pickup,
          icon: pickupIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          infoWindow: const InfoWindow(title: 'Pickup'),
        ),
      );
    }

    if (drop != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('drop-point'),
          position: drop,
          icon: dropIcon,
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 3,
          infoWindow: const InfoWindow(title: 'Drop'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildBrokerPolylines() {
    final path = _brokerRoutePath();
    if (path.length < 2) {
      return const {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('booking-route'),
        points: path,
        color: const Color(0xFF6B8FAF),
        width: 8,
        geodesic: true,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  LatLng? get _pickupLatLng {
    final lat = _draft.pickupLat;
    final lng = _draft.pickupLng;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng? get _dropLatLng {
    final lat = _draft.dropLat;
    final lng = _draft.dropLng;
    if (lat == null || lng == null) {
      return null;
    }
    return LatLng(lat, lng);
  }

  LatLng _brokerMapCenter() {
    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    if (pickup != null && drop != null) {
      return LatLng(
        (pickup.latitude + drop.latitude) / 2,
        (pickup.longitude + drop.longitude) / 2,
      );
    }
    return pickup ?? drop ?? _fallbackMapCenter;
  }

  List<LatLng> _brokerRoutePath() {
    if (_brokerRoutePoints.length >= 2) {
      return _brokerRoutePoints;
    }

    final pickup = _pickupLatLng;
    final drop = _dropLatLng;
    if (pickup == null || drop == null) {
      return const [];
    }

    final midLat = (pickup.latitude + drop.latitude) / 2;
    final midLng = (pickup.longitude + drop.longitude) / 2;
    final latDelta = (drop.latitude - pickup.latitude).abs();
    final lngDelta = (drop.longitude - pickup.longitude).abs();
    final bend = max(latDelta, lngDelta) * 0.30 + 0.015;
    final direction = pickup.longitude < drop.longitude ? 1 : -1;

    return [
      pickup,
      LatLng(
        pickup.latitude + (drop.latitude - pickup.latitude) * 0.22,
        pickup.longitude + (drop.longitude - pickup.longitude) * 0.14,
      ),
      LatLng(midLat + bend, midLng + (bend * 0.35 * direction)),
      LatLng(
        pickup.latitude + (drop.latitude - pickup.latitude) * 0.74,
        pickup.longitude + (drop.longitude - pickup.longitude) * 0.70,
      ),
      drop,
    ];
  }

  Widget _buildLocationStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Location',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF101828),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _resolvingCurrentLocation
                  ? null
                  : _useCurrentLocationForPickup,
              icon: _resolvingCurrentLocation
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.gps_fixed_rounded, size: 14),
              label: Text(
                _resolvingCurrentLocation
                    ? 'Locating...'
                    : 'Use current location',
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: const Color(0xFF1F88C9),
                textStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _LocationLaunchCard(
          pickupValue: _fromController.text.isEmpty
              ? 'Enter loading location'
              : _fromController.text,
          dropValue: _toController.text.isEmpty
              ? 'Enter unloading location'
              : _toController.text,
          onPickupTap: () async {
            final selection = await _openLocationDetailsScreen(
              _LocationFieldKind.pickup,
            );
            if (selection == null || !mounted) {
              return;
            }
            setState(() {
              _draft = _draft.copyWith(
                from: selection.formattedAddress,
                pickupLat: selection.latitude,
                pickupLng: selection.longitude,
                city: selection.city.isNotEmpty ? selection.city : _draft.city,
              );
              _fromController.text = selection.formattedAddress;
            });
          },
          onDropTap: () async {
            final selection = await _openLocationDetailsScreen(
              _LocationFieldKind.drop,
            );
            if (selection == null || !mounted) {
              return;
            }
            setState(() {
              _draft = _draft.copyWith(
                to: selection.formattedAddress,
                dropLat: selection.latitude,
                dropLng: selection.longitude,
              );
              _toController.text = selection.formattedAddress;
            });
          },
        ),
      ],
    );
  }

  Widget _buildItemDetailsStep(BuildContext context) {
    final weight = double.tryParse(_weightController.text.trim()) ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final selection = await _openLocationDetailsScreen(
                    _LocationFieldKind.pickup,
                  );
                  if (selection == null || !mounted) {
                    return;
                  }
                  setState(() {
                    _draft = _draft.copyWith(
                      from: selection.formattedAddress,
                      pickupLat: selection.latitude,
                      pickupLng: selection.longitude,
                      city: selection.city.isNotEmpty
                          ? selection.city
                          : _draft.city,
                    );
                    _fromController.text = selection.formattedAddress;
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Add loading'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F88C9),
                  side: const BorderSide(color: Color(0xFFD7E7F4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  final selection = await _openLocationDetailsScreen(
                    _LocationFieldKind.drop,
                  );
                  if (selection == null || !mounted) {
                    return;
                  }
                  setState(() {
                    _draft = _draft.copyWith(
                      to: selection.formattedAddress,
                      dropLat: selection.latitude,
                      dropLng: selection.longitude,
                    );
                    _toController.text = selection.formattedAddress;
                  });
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('+ Add unloading'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF1F88C9),
                  side: const BorderSide(color: Color(0xFFD7E7F4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Select the weight of your goods',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF111111),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _weightError != null
                  ? const Color(0xFFE23A4B)
                  : const Color(0xFFD7DCE3),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onSubmitted: (_) =>
                      _advanceFromWeightStep(unknown: _weightUnknown),
                  onChanged: (_) {
                    if (_weightUnknown || _weightError != null) {
                      setState(() {
                        _weightUnknown = false;
                        _weightError = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(
                    hintText: 'Enter tonnage',
                    isDense: true,
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ton',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF111111),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        if (_weightError != null) ...[
          const SizedBox(height: 6),
          Text(
            _weightError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFE23A4B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [1.0, 4.5, 7.0, 12.0, 15.0, 18.0, 25.0]
              .map(
                (value) => _WeightChip(
                  label: '${value.toStringAsFixed(value % 1 == 0 ? 0 : 1)} ton',
                  selected: !_weightUnknown && (weight - value).abs() < 0.001,
                  onTap: () {
                    setState(() {
                      _weightUnknown = false;
                      _weightError = null;
                      _weightController.text = value.toStringAsFixed(
                        value % 1 == 0 ? 0 : 1,
                      );
                    });
                    _advanceFromWeightStep(unknown: false);
                  },
                ),
              )
              .toList(growable: false),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              _weightController.clear();
              _advanceFromWeightStep(unknown: true);
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE9ECF2),
              foregroundColor: const Color(0xFF111111),
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text(
              "I don't know my material weight",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _submitting
                ? null
                : () => _advanceFromWeightStep(unknown: _weightUnknown),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2FA56E),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
            ),
            child: const Text(
              'Submit',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(BuildContext context) {
    return _PaymentMethodsCard(
      selectedMethod: _selectedPaymentMethod,
      onSelect: (method) {
        setState(() => _selectedPaymentMethod = method);
      },
    );
  }

  Widget _buildSuccessStep(BuildContext context) {
    return _BookingSuccessCard(
      bookingReference: _bookingReference,
      onTrack: () => context.go('/client/tracking'),
      onHome: _goToClientHome,
    );
  }

  void _goToClientHome() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
      return;
    }
    context.go('/client/home');
  }
}

class _BrokerDiscoveryLoader extends StatefulWidget {
  const _BrokerDiscoveryLoader({required this.messages});

  final List<String> messages;

  @override
  State<_BrokerDiscoveryLoader> createState() => _BrokerDiscoveryLoaderState();
}

class _BrokerDiscoveryLoaderState extends State<_BrokerDiscoveryLoader> {
  Timer? _timer;
  int _messageIndex = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || widget.messages.isEmpty) {
        return;
      }
      setState(() {
        _messageIndex = (_messageIndex + 1) % widget.messages.length;
      });
    });
  }

  @override
  void didUpdateWidget(covariant _BrokerDiscoveryLoader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messages != widget.messages) {
      _messageIndex = 0;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.messages.isEmpty
        ? 'Connecting brokers near you'
        : widget.messages[_messageIndex % widget.messages.length];

    return SizedBox(
      width: double.infinity,
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFFE8EDF2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const CircularProgressIndicator(
                  color: Color(0xFF2FA56E),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 28),
                Text(
                  message,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: const Color(0xFF101828),
                    fontWeight: FontWeight.w800,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'Dont worry, I will help you reach your package in its proper destination safely.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF667085),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Searching live rates and nearby partners',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrokerNegotiationSheet extends StatefulWidget {
  const _BrokerNegotiationSheet({
    required this.truck,
    required this.minPrice,
    required this.maxPrice,
    required this.initialPrice,
  });

  final NearbyTruck truck;
  final double minPrice;
  final double maxPrice;
  final double initialPrice;

  @override
  State<_BrokerNegotiationSheet> createState() =>
      _BrokerNegotiationSheetState();
}

class _BrokerNegotiationSheetState extends State<_BrokerNegotiationSheet> {
  _NegotiationSheetStep _step = _NegotiationSheetStep.slider;
  late double _value;
  double? _counterOffer;
  int _negotiationToken = 0;

  @override
  void initState() {
    super.initState();
    _value = widget.initialPrice;
  }

  void _startNegotiation() {
    final token = ++_negotiationToken;
    setState(() {
      _step = _NegotiationSheetStep.loading;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || token != _negotiationToken) {
        return;
      }
      final counterOffer = double.parse((_value * 1.11).toStringAsFixed(0));
      setState(() {
        _counterOffer = counterOffer;
        _step = _NegotiationSheetStep.counterOffer;
      });
    });
  }

  void _acceptCounterOffer() {
    Navigator.of(
      context,
    ).pop(_NegotiationSheetResult.accepted(_counterOffer ?? _value));
  }

  void _chooseAnotherBroker() {
    Navigator.of(context).pop(_NegotiationSheetResult.chooseAnotherBroker());
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.56,
      minChildSize: 0.42,
      maxChildSize: 0.78,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD0D5DD),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: switch (_step) {
                    _NegotiationSheetStep.slider => _NegotiationSliderStep(
                      key: const ValueKey('slider'),
                      truck: widget.truck,
                      value: _value,
                      minPrice: widget.minPrice,
                      maxPrice: widget.maxPrice,
                      onChanged: (value) {
                        setState(() {
                          _value = value;
                        });
                      },
                      onNegotiate: _startNegotiation,
                    ),
                    _NegotiationSheetStep.loading => _NegotiationLoadingStep(
                      key: const ValueKey('loading'),
                      truck: widget.truck,
                      messages: _brokerNegotiationMessages,
                    ),
                    _NegotiationSheetStep.counterOffer =>
                      _NegotiationCounterOfferStep(
                        key: const ValueKey('counter'),
                        truck: widget.truck,
                        counterOfferAmount: _counterOffer ?? _value,
                        onAccept: _acceptCounterOffer,
                        onCancel: _chooseAnotherBroker,
                      ),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NegotiationSliderStep extends StatelessWidget {
  const _NegotiationSliderStep({
    super.key,
    required this.truck,
    required this.value,
    required this.minPrice,
    required this.maxPrice,
    required this.onChanged,
    required this.onNegotiate,
  });

  final NearbyTruck truck;
  final double value;
  final double minPrice;
  final double maxPrice;
  final ValueChanged<double> onChanged;
  final VoidCallback onNegotiate;

  @override
  Widget build(BuildContext context) {
    final displayValue = value.roundToDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Negotiate with ${truck.displayTitle}',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: const Color(0xFF101828),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Use the slider to set a single offer amount. This stays inside the popup.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF667085),
            height: 1.45,
          ),
        ),
        const SizedBox(height: 22),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Offer price',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '₹${displayValue.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFF2FA56E),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Slider(
                value: value.clamp(minPrice, maxPrice),
                min: minPrice,
                max: maxPrice,
                divisions: 24,
                activeColor: const Color(0xFF2FA56E),
                inactiveColor: const Color(0xFFE4E7EC),
                label: '₹${displayValue.toStringAsFixed(0)}',
                onChanged: onChanged,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${minPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                  Text(
                    '₹${maxPrice.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: onNegotiate,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2FA56E),
            ),
            child: const Text('Negotiate'),
          ),
        ),
      ],
    );
  }
}

class _NegotiationLoadingStep extends StatelessWidget {
  const _NegotiationLoadingStep({
    super.key,
    required this.truck,
    required this.messages,
  });

  final NearbyTruck truck;
  final List<String> messages;

  @override
  Widget build(BuildContext context) {
    final message = messages.isEmpty
        ? 'Waiting for broker response'
        : messages.first;

    return SizedBox(
      height: 320,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF2FA56E),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Negotiating with ${truck.displayTitle}...',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NegotiationCounterOfferStep extends StatelessWidget {
  const _NegotiationCounterOfferStep({
    super.key,
    required this.truck,
    required this.counterOfferAmount,
    required this.onAccept,
    required this.onCancel,
  });

  final NearbyTruck truck;
  final double counterOfferAmount;
  final VoidCallback onAccept;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE8EDF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${truck.displayTitle} replied with a new price',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: const Color(0xFF101828),
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You can accept it or choose another broker.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF667085),
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2FA56E).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_shipping_rounded,
                      color: Color(0xFF2FA56E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          truck.displaySubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF667085),
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Counter offer: ₹${counterOfferAmount.toStringAsFixed(counterOfferAmount % 1 == 0 ? 0 : 2)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF101828),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                    ),
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE23A4B),
                      side: const BorderSide(color: Color(0xFFE23A4B)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MapHintPill extends StatelessWidget {
  const _MapHintPill({
    required this.icon,
    required this.label,
    this.accent = const Color(0xFF101828),
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({
    required this.selectedMethod,
    required this.onSelect,
  });

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              'UPI, Cards & Other Methods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF101828),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          _PaymentTopRow(selectedMethod: selectedMethod, onSelect: onSelect),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          _PaymentListTile(
            icon: Icons.credit_card_rounded,
            title: 'Pay using card',
            subtitle: 'All card supported',
            selected: selectedMethod == PaymentMethod.card,
            onTap: () => onSelect(PaymentMethod.card),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          _PaymentListTile(
            icon: Icons.account_balance_rounded,
            title: 'Net banking',
            subtitle: 'All Indian banks',
            selected: selectedMethod == PaymentMethod.netBanking,
            onTap: () => onSelect(PaymentMethod.netBanking),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          _PaymentListTile(
            icon: Icons.calendar_month_rounded,
            title: 'EMI',
            subtitle: 'Card, EarlySalary and more',
            selected: selectedMethod == PaymentMethod.emi,
            trailingChip: 'NO COST EMI AVAILABLE',
            onTap: () => onSelect(PaymentMethod.emi),
          ),
          const Divider(height: 1, color: Color(0xFFE8EDF2)),
          _PaymentListTile(
            icon: Icons.schedule_send_rounded,
            title: 'Pay later',
            subtitle: 'Confirm now and pay after delivery',
            selected: selectedMethod == PaymentMethod.payLater,
            onTap: () => onSelect(PaymentMethod.payLater),
          ),
        ],
      ),
    );
  }
}

class _PaymentTopRow extends StatelessWidget {
  const _PaymentTopRow({required this.selectedMethod, required this.onSelect});

  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PaymentListTile(
            icon: Icons.double_arrow_rounded,
            title: 'UPI',
            subtitle: 'Pay with one-set UPI, apps or choose other',
            selected: _isUpiSelected(selectedMethod),
            compact: true,
            leadingWidget: SvgPicture.asset(
              'assets/upi-icon.svg',
              width: 32,
              height: 32,
            ),
            onTap: () => onSelect(PaymentMethod.googlePay),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _UpiAppTile(
                  label: 'Google Pay',
                  selected: selectedMethod == PaymentMethod.googlePay,
                  accentColor: const Color(0xFF1A73E8),
                  logoAssetPath: 'assets/svgs/icons8-google-pay.svg',
                  onTap: () => onSelect(PaymentMethod.googlePay),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UpiAppTile(
                  label: 'PhonePe',
                  selected: selectedMethod == PaymentMethod.phonePe,
                  accentColor: const Color(0xFF5F3DC4),
                  logoAssetPath: 'assets/svgs/icons8-phone-pe.svg',
                  onTap: () => onSelect(PaymentMethod.phonePe),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _UpiAppTile(
                  label: 'PayTM',
                  selected: selectedMethod == PaymentMethod.paytm,
                  accentColor: const Color(0xFF0F4C81),
                  logoAssetPath: 'assets/svgs/icons8-paytm.svg',
                  onTap: () => onSelect(PaymentMethod.paytm),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isUpiSelected(PaymentMethod method) {
    return method == PaymentMethod.googlePay ||
        method == PaymentMethod.phonePe ||
        method == PaymentMethod.paytm ||
        method == PaymentMethod.otherUpi;
  }
}

class _UpiAppTile extends StatelessWidget {
  const _UpiAppTile({
    required this.label,
    required this.selected,
    required this.accentColor,
    this.logoAssetPath,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accentColor;
  final String? logoAssetPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
              color: selected
                  ? accentColor.withValues(alpha: 0.08)
                  : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? accentColor : const Color(0xFFE8EDF2),
                width: selected ? 1.5 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: logoAssetPath != null
                ? Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      logoAssetPath!,
                      fit: BoxFit.contain,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFF667085),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentListTile extends StatelessWidget {
  const _PaymentListTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.trailingChip,
    this.leadingWidget,
    this.compact = false,
  });

  final IconData? icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final String? trailingChip;
  final Widget? leadingWidget;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF1F88C9);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 0 : 16,
          vertical: compact ? 6 : 14,
        ),
        child: Row(
          children: [
            if (leadingWidget != null)
              SizedBox(
                width: compact ? 28 : 34,
                height: compact ? 28 : 34,
                child: Center(child: leadingWidget!),
              )
            else
              Icon(
                icon,
                color: selected ? accent : const Color(0xFF667085),
                size: compact ? 22 : 26,
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF101828),
                              ),
                        ),
                      ),
                      if (trailingChip != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8F2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            trailingChip!,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: const Color(0xFF2FA56E),
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF98A2B3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (selected)
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF2FA56E),
                size: 20,
              )
            else
              const Icon(
                Icons.circle_outlined,
                color: Color(0xFFD0D5DD),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

class _LocationLaunchCard extends StatelessWidget {
  const _LocationLaunchCard({
    required this.pickupValue,
    required this.dropValue,
    required this.onPickupTap,
    required this.onDropTap,
  });

  final String pickupValue;
  final String dropValue;
  final VoidCallback onPickupTap;
  final VoidCallback onDropTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEAEFF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onPickupTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: const Color(0xFF38B47A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      Container(
                        width: 2,
                        height: 28,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7DDE4),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupValue,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: const Color(0xFF9B9B9B),
                                fontSize: 17,
                                fontWeight: FontWeight.w400,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1, color: const Color(0xFFE9EDF2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: onDropTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF05252),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_downward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      dropValue,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF9B9B9B),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeightChip extends StatelessWidget {
  const _WeightChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      labelStyle: TextStyle(
        color: selected ? Colors.white : const Color(0xFF111111),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      selectedColor: const Color(0xFF111111),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE0E4EA)),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}

class _BookingSuccessCard extends StatelessWidget {
  const _BookingSuccessCard({
    required this.bookingReference,
    required this.onTrack,
    required this.onHome,
  });

  final String? bookingReference;
  final VoidCallback onTrack;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8EF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2FA56E).withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Color(0xFF2FA56E),
              size: 58,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Booking confirmed',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Your booking has been successfully placed.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: const Color(0xFF667085)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            bookingReference == null || bookingReference!.isEmpty
                ? 'Booking Number: Pending'
                : 'Booking Number: $bookingReference',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: const Color(0xFF101828),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onTrack,
                  child: const Text('Track booking'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onHome,
                  child: const Text('Go to home'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _truckCategoryForVehicle(String label) {
  final text = label.toLowerCase();
  if (text.contains('small')) return 'small';
  if (text.contains('medium')) return 'medium';
  if (text.contains('big')) return 'large';
  return 'pooling';
}

double _parsePrice(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(digits) ?? 0;
}

double _priceValue(String value) {
  if (_parsePrice(value) <= 0) {
    return 0;
  }
  return _parsePrice(value);
}

String _priceInputText(String value) {
  final parsed = _parsePrice(value);
  if (parsed <= 0) {
    return '';
  }
  return parsed.toStringAsFixed(parsed % 1 == 0 ? 0 : 2);
}

double _readDistanceValue(Object? data, Map<String, dynamic> fallback) {
  final value = _readDoubleValue(data, fallback, const ['distance']);
  return value ?? 0;
}

double? _readDoubleValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate == null) continue;
    final parsed = double.tryParse(candidate.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

double _readMoneyValue(Object? data, Map<String, dynamic> fallback) {
  return _readDoubleValue(data, fallback, const [
        'estimated_amount',
        'estimatedAmount',
        'amount',
        'total',
        'total_amount',
        'totalAmount',
        'fare',
        'price',
        'value',
        'quoted_price',
        'quotedPrice',
      ]) ??
      0;
}

int? _readIntValue(
  Object? data,
  Map<String, dynamic> fallback,
  List<String> keys,
) {
  final candidates = <Object?>[];
  if (data is Map<String, dynamic>) {
    for (final key in keys) {
      candidates.add(data[key]);
    }
  }
  for (final key in keys) {
    candidates.add(fallback[key]);
  }

  for (final candidate in candidates) {
    if (candidate == null) continue;
    final parsed = int.tryParse(candidate.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _displayPriceLabel(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? 'Loading...' : trimmed;
}

double? _readBookingCoordinate(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value == null) continue;
    final parsed = double.tryParse(value.toString());
    if (parsed != null) return parsed;
  }
  return null;
}

String _extractBookingNumber(Map<String, dynamic> json) {
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    for (final key in [
      'booking_number',
      'bookingNumber',
      'booking_no',
      'bookingNo',
      'booking_ref',
      'booking_reference',
      'reference',
      'id',
      'tracking_number',
    ]) {
      final value = data[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
  }
  for (final key in [
    'booking_number',
    'bookingNumber',
    'booking_no',
    'bookingNo',
    'booking_ref',
    'booking_reference',
    'reference',
    'id',
    'tracking_number',
  ]) {
    final value = json[key]?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return '';
}

class _BookingSummaryCard extends StatelessWidget {
  const _BookingSummaryCard({
    required this.pickupTitle,
    this.distanceText,
    this.amountText,
    this.dropValue,
  });

  final String pickupTitle;
  final String? distanceText;
  final String? amountText;
  final String? dropValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEAEFF4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 2),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2FA56E),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 2,
                  height: 36,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                Container(
                  width: 2,
                  height: 16,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9E0E7),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE23A4B),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1C2430),
                            ),
                      ),
                      if (distanceText != null && distanceText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          distanceText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF667085),
                                fontSize: 11,
                              ),
                        ),
                      ],
                      if (amountText != null && amountText!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          amountText!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: const Color(0xFF1F88C9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          dropValue ?? 'Where is your Drop ?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: const Color(0xFF1C2430),
                                fontSize: 13,
                              ),
                        ),
                      ),
                    ],
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

class SelectVehicleScreen extends ConsumerStatefulWidget {
  const SelectVehicleScreen({
    super.key,
    required this.bookingData,
    this.initialIndex = 0,
  });

  final BookingData bookingData;
  final int initialIndex;

  @override
  ConsumerState<SelectVehicleScreen> createState() =>
      _SelectVehicleScreenState();
}

class _SelectVehicleScreenState extends ConsumerState<SelectVehicleScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final pricingState = ref.watch(clientPricingProvider);
    final options = resolveVehicleOptions(
      tripType: widget.bookingData.tripType,
      pricing: pricingState.valueOrNull,
      isLoading: pricingState.isLoading,
    );
    final safeIndex = options.isEmpty
        ? 0
        : _selectedIndex.clamp(0, options.length - 1).toInt();
    final selected = options[safeIndex];
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            SingleChildScrollView(
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
                          child: Icon(Icons.arrow_back_rounded, size: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _BookingSummaryCard(
                    pickupTitle: widget.bookingData.from,
                    distanceText: widget.bookingData.distanceText,
                    amountText: widget.bookingData.amountText,
                    dropValue: widget.bookingData.to,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Select your vehicle',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...options.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VehicleOptionTile(
                        option: entry.value,
                        selected: safeIndex == entry.key,
                        onTap: () => setState(() => _selectedIndex = entry.key),
                      ),
                    ),
                  ),
                ],
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
                      onPressed: () {
                        Navigator.of(context).pop(selected);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text('Proceed with ${selected.label}'),
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
}

class _VehicleOptionTile extends StatelessWidget {
  const _VehicleOptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final VehicleOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? option.accentColor : const Color(0xFFE7EEF5),
            width: selected ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: selected ? 0.045 : 0.03),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedScale(
              duration: const Duration(milliseconds: 180),
              scale: selected ? 1.14 : 1.0,
              curve: Curves.easeOutBack,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(option.assetPath, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF101828),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    option.capacity,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _displayPriceLabel(option.price),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? 'Selected' : '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: selected ? option.accentColor : Colors.transparent,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ClientBottomBar extends StatelessWidget {
  const ClientBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Color(0x16000000),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: NavItem(
                label: 'Home',
                assetPath: 'assets/home.png',
                selected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NavItem(
                label: 'Activity',
                assetPath: 'assets/tracking.png',
                selected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: NavItem(
                label: 'Profile',
                assetPath: 'assets/user.png',
                selected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.assetPath,
    this.assetSize = 18,
  });

  final String label;
  final IconData? icon;
  final String? assetPath;
  final double assetSize;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = selected ? scheme.primary : Colors.black45;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(top: 2, bottom: 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: Center(
                child: assetPath != null
                    ? Image.asset(
                        assetPath!,
                        width: assetSize,
                        height: assetSize,
                        fit: BoxFit.contain,
                        color: color,
                        colorBlendMode: BlendMode.srcIn,
                      )
                    : Icon(icon, size: 20, color: color),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
