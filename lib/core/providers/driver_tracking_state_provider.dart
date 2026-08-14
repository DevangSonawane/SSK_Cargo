import 'package:flutter_riverpod/flutter_riverpod.dart';

class DriverTripSession {
  const DriverTripSession({
    required this.tripId,
    this.bookingId,
    this.bookingNumber,
    this.status,
    this.paymentStatus,
    this.updatedAt,
  });

  final String tripId;
  final String? bookingId;
  final String? bookingNumber;
  final String? status;
  final String? paymentStatus;
  final DateTime? updatedAt;

  bool get hasTripId => tripId.trim().isNotEmpty;

  DriverTripSession copyWith({
    String? tripId,
    String? bookingId,
    String? bookingNumber,
    String? status,
    String? paymentStatus,
    DateTime? updatedAt,
  }) {
    return DriverTripSession(
      tripId: tripId ?? this.tripId,
      bookingId: bookingId ?? this.bookingId,
      bookingNumber: bookingNumber ?? this.bookingNumber,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

final driverOnlineProvider = StateProvider<bool>((ref) => true);
final driverActiveTripIdProvider = StateProvider<String?>((ref) => null);
final driverTripSessionProvider = StateProvider<DriverTripSession?>((ref) => null);

final driverTrackingEnabledProvider = Provider<bool>((ref) {
  final tripSession = ref.watch(driverTripSessionProvider);
  return ref.watch(driverOnlineProvider) ||
      (ref.watch(driverActiveTripIdProvider) ?? '').trim().isNotEmpty ||
      (tripSession?.tripId ?? '').trim().isNotEmpty;
});
