import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';

typedef ClientBookingsQuery = ({String? status, int page, int limit});
typedef NearbyTrucksQuery = ({
  double pickupLat,
  double pickupLng,
  double? radiusKm,
  int page,
  int limit,
  String? truckCategory,
  String? bodyType,
});

final clientBookingsProvider = FutureProvider.autoDispose
    .family<ClientBookingPage, ClientBookingsQuery>((ref, query) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookings(
            accessToken: session.tokens.accessToken,
            status: query.status,
            page: query.page,
            limit: query.limit,
          );

      return ClientBookingPage.fromJson(response);
    });

final clientPricingProvider = FutureProvider.autoDispose<ClientPricingConfig?>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    return null;
  }

  try {
    final response = await ref
        .watch(apiClientProvider)
        .getAdminPricing(accessToken: session.tokens.accessToken);
    return ClientPricingConfig.fromJson(response);
  } catch (_) {
    return null;
  }
});

/// Live truck taxonomy for pickers — `GET /api/config/vehicle-types`,
/// same endpoint the web `BookTruck.jsx` picker is built from. Each entry
/// carries its own `id` (the real `truck_category` string), display `name`,
/// `capacity`, and `basePrice` minimum fare. Falls back to the static 8-type
/// + part list when the endpoint is unreachable, so the picker never empties.
final vehicleTypesProvider = FutureProvider.autoDispose<List<VehicleType>>((
  ref,
) async {
  try {
    final response = await ref.watch(apiClientProvider).getVehicleTypes();
    final types = parseVehicleTypesResponse(response);
    if (types.isNotEmpty) return types;
  } catch (_) {
    // Falls through to the static fallback below.
  }
  return fallbackVehicleTypes();
});

final clientBookingOffersProvider = FutureProvider.autoDispose
    .family<List<ClientBookingOffer>, String>((ref, bookingId) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookingOffers(
            accessToken: session.tokens.accessToken,
            bookingId: bookingId,
          );

      final data = response['data'];
      final items = data is Map<String, dynamic>
          ? (data['offers'] ?? data['items'] ?? data['results'] ?? data['rows'])
          : response['offers'] ?? response['items'] ?? response['results'];

      final list = items is List
          ? items
          : data is List
          ? data
          : const <dynamic>[];

      return list
          .whereType<Map<String, dynamic>>()
          .map(ClientBookingOffer.fromJson)
          .where((offer) => offer.id.isNotEmpty)
          .toList();
    });

final clientNearbyTrucksProvider = FutureProvider.autoDispose
    .family<List<NearbyTruck>, NearbyTrucksQuery>((ref, query) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getNearbyTrucks(
            accessToken: session.tokens.accessToken,
            pickupLat: query.pickupLat,
            pickupLng: query.pickupLng,
            truckCategory: query.truckCategory,
            bodyType: query.bodyType,
            radiusKm: query.radiusKm,
            page: query.page,
            limit: query.limit,
          );

      return NearbyTruckPage.fromJson(response).trucks;
    });
