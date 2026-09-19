import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ssk/core/theme/app_icons.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/presentation/widgets/client_flow_widgets.dart';
import '../../../client/presentation/widgets/tracking_route_map_view.dart';
import '../../data/driver_trip_handoff_utils.dart';

class DriverThankYouScreen extends ConsumerStatefulWidget {
  const DriverThankYouScreen({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<DriverThankYouScreen> createState() =>
      _DriverThankYouScreenState();
}

class _DriverThankYouScreenState extends ConsumerState<DriverThankYouScreen> {
  TrackingDemoShipment? _shipment;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(driverActiveTripIdProvider.notifier).state = null;
      ref.read(driverTripSessionProvider.notifier).state = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadTrip());
    });
  }

  Future<void> _loadTrip() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .getTrip(
            accessToken: session.tokens.accessToken,
            tripId: widget.tripId,
          );
      final trip = extractTripFromResponse(response) ?? response;
      final shipment = _shipmentFromTrip(trip);
      if (!mounted || shipment == null) {
        return;
      }
      setState(() => _shipment = shipment);
    } catch (_) {
      // Route rendering is optional on this screen; keep the fallback.
    }
  }

  TrackingDemoShipment? _shipmentFromTrip(Map<String, dynamic> trip) {
    final pickup = _mapFrom(trip['pickup'] ?? trip['pickupLocation']);
    final drop = _mapFrom(trip['drop'] ?? trip['dropoffLocation']);
    final pickupLabel = _locationLabel(pickup);
    final dropLabel = _locationLabel(drop);
    final bookingNumber = _stringFrom(trip, const [
      'bookingNumber',
      'booking_number',
    ]);
    final id = _stringFrom(trip, const ['id', 'tripId', 'trip_id']);

    if (pickupLabel.isEmpty &&
        dropLabel.isEmpty &&
        bookingNumber.isEmpty &&
        id.isEmpty) {
      return null;
    }

    return TrackingDemoShipment(
      packageName: bookingNumber.isNotEmpty ? bookingNumber : 'Trip',
      trackingId: bookingNumber.isNotEmpty ? bookingNumber : id,
      fromLocation: pickupLabel.isNotEmpty ? pickupLabel : 'Pickup location',
      toLocation: dropLabel.isNotEmpty ? dropLabel : 'Drop location',
      status: 'Completed',
      customerName: _stringFrom(trip, const ['customerName', 'clientName']),
      weight: _stringFrom(trip, const [
        'weight',
        'cargoWeight',
        'cargo_weight',
      ]),
      timeline: const [],
      pickupLat:
          _doubleFrom(pickup, const ['lat', 'latitude']) ??
          _doubleFrom(trip, const ['pickupLat', 'pickup_lat']),
      pickupLng:
          _doubleFrom(pickup, const ['lng', 'longitude']) ??
          _doubleFrom(trip, const ['pickupLng', 'pickup_lng']),
      dropLat:
          _doubleFrom(drop, const ['lat', 'latitude']) ??
          _doubleFrom(trip, const ['dropLat', 'drop_lat']),
      dropLng:
          _doubleFrom(drop, const ['lng', 'longitude']) ??
          _doubleFrom(trip, const ['dropLng', 'drop_lng']),
      tripId: id,
    );
  }

  Map<String, dynamic> _mapFrom(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return value.cast<String, dynamic>();
    }
    return const <String, dynamic>{};
  }

  String _locationLabel(Map<String, dynamic> location) {
    final label = _stringFrom(location, const [
      'label',
      'address',
      'formattedAddress',
      'formatted_address',
      'name',
    ]);
    return label.isNotEmpty ? label : '';
  }

  String _stringFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      if (value is num) {
        return value.toString();
      }
    }
    return '';
  }

  double? _doubleFrom(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) {
        return value.toDouble();
      }
      if (value is String) {
        final parsed = double.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_shipment == null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE3F4E9), Color(0xFFF6FCF8), Colors.white],
                ),
              ),
            )
          else
            TrackingRouteMapView(shipment: _shipment!, liveMode: false),
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.18),
                    Colors.transparent,
                    Colors.white.withValues(alpha: 0.62),
                  ],
                  stops: const [0.0, 0.32, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: Align(
                alignment: Alignment.topCenter,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.94),
                    borderRadius: BorderRadius.circular(999),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.10),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        AppIcons.check_circle_rounded,
                        size: 16,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Trip completed',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0.78, end: 1),
                duration: const Duration(milliseconds: 520),
                curve: Curves.elasticOut,
                builder: (context, scale, child) {
                  return Transform.scale(scale: scale, child: child);
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                  builder: (context, opacity, child) {
                    return Opacity(opacity: opacity, child: child);
                  },
                  child: Container(
                    width: 176,
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brand.withValues(alpha: 0.22),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            AppIcons.check_rounded,
                            color: AppColors.brand,
                            size: 58,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Delivery complete',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Thank you for completing this trip',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 12 + bottomInset,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppShadows.float,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        AppIcons.receipt_long_rounded,
                        size: 15,
                        color: AppColors.brand,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          widget.tripId,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brandTint,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Paid',
                          style: TextStyle(
                            color: AppColors.brand,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.go('/driver/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Back to trips',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
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
