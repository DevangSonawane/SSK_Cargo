// Part-Load API — standalone, duplicated (not reusing full-truck wrappers).
// Uses the shared Dio (base URL + JSON) but its own method set so
// full-truck code in core/network/api_client.dart stays untouched.

import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'part_load_models.dart';

class PartLoadApi {
  PartLoadApi(this._dio);
  final Dio _dio;

  Options _auth(String accessToken) =>
      Options(headers: {'Authorization': 'Bearer $accessToken'});

  Map<String, dynamic> _asMap(Response<Map<String, dynamic>> res) =>
      res.data ?? <String, dynamic>{};

  /// Create a part-load booking: truck_category=part, search_mode=part_load.
  /// Returns (bookingId, bookingNumber).
  Future<({String bookingId, String bookingNumber})> createPartBooking({
    required String accessToken,
    required String pickupLocation,
    required double pickupLat,
    required double pickupLng,
    required String dropLocation,
    required double dropLat,
    required double dropLng,
    required double weightTons,
    double? distanceKm,
  }) async {
    final payload = <String, dynamic>{
      'truck_category': 'part',
      'search_mode': 'part_load',
      'pickup_location': pickupLocation,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'drop_location': dropLocation,
      'drop_lat': dropLat,
      'drop_lng': dropLng,
      'weight': weightTons,
      'weight_unit': 'tons',
      if (distanceKm != null && distanceKm > 0) 'distance': distanceKm,
    };
    developer.log('POST /api/bookings (part_load)', name: 'SSK.PartLoad');
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/bookings',
      data: payload,
      options: _auth(accessToken),
    );
    final body = _asMap(res);
    final data = (body['data'] is Map)
        ? (body['data'] as Map).cast<String, dynamic>()
        : body;
    final booking = data['booking'];
    final m = booking is Map
        ? booking.cast<String, dynamic>()
        : data;
    String read(List<String> keys) {
      for (final k in keys) {
        final v = m[k]?.toString().trim() ?? '';
        if (v.isNotEmpty && v.toLowerCase() != 'null') return v;
      }
      final b = body['bookingId']?.toString() ?? '';
      return b;
    }

    final id = read(const ['id', 'bookingId', 'booking_id']);
    final number = (m['bookingNumber'] ?? m['booking_number'] ?? m['bookingRef'] ?? '')
        .toString();
    if (id.isEmpty) {
      throw Exception(
          (body['message'] ?? 'Failed to create part-load booking').toString());
    }
    return (bookingId: id, bookingNumber: number);
  }

  /// GET /api/vehicles/trucks/nearby-on-trip
  Future<List<PartLoadTruck>> searchNearbyOnTrip({
    required String accessToken,
    required double pickupLat,
    required double pickupLng,
    required double dropLat,
    required double dropLng,
    required double weightTons,
    double radiusKm = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/vehicles/trucks/nearby-on-trip',
      queryParameters: {
        'pickup_lat': pickupLat,
        'pickup_lng': pickupLng,
        'drop_lat': dropLat,
        'drop_lng': dropLng,
        'weight_tons': weightTons,
        'radius_km': radiusKm,
      },
      options: _auth(accessToken),
    );
    final body = _asMap(res);
    final data = (body['data'] is Map)
        ? (body['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final list = data['trucks'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => PartLoadTruck.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// POST /api/trip-join-requests
  Future<PartLoadJoinRequest> requestTruck({
    required String accessToken,
    required String bookingId,
    required String targetTripId,
  }) async {
    developer.log(
      'POST /api/trip-join-requests booking=$bookingId targetTrip=$targetTripId',
      name: 'SSK.PartLoad',
    );
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/api/trip-join-requests',
        data: {'booking_id': bookingId, 'target_trip_id': targetTripId},
        options: _auth(accessToken),
      );
      final req = PartLoadJoinRequest.fromResponse(_asMap(res));
      if (req == null) {
        throw Exception(
            (_asMap(res)['message'] ?? 'Failed to send request').toString());
      }
      return req;
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? ((e.response!.data as Map)['message']?.toString() ??
              'Truck no longer available — pick another.')
          : 'Truck no longer available — pick another.';
      throw Exception(msg);
    }
  }

  /// GET /api/trip-join-requests/booking/:bookingId — 404 = no request yet.
  Future<PartLoadJoinRequest?> getRequestForBooking({
    required String accessToken,
    required String bookingId,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/api/trip-join-requests/booking/$bookingId',
        options: _auth(accessToken),
      );
      return PartLoadJoinRequest.fromResponse(_asMap(res));
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      final body = e.response?.data;
      if (body is Map && body['success'] == false) return null;
      rethrow;
    }
  }

  /// GET /api/trip-join-requests — driver inbox / broker timed-out view.
  Future<List<PartLoadJoinRequest>> listInbox({
    required String accessToken,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/trip-join-requests',
      queryParameters: {'page': page, 'limit': limit},
      options: _auth(accessToken),
    );
    final body = _asMap(res);
    final data = (body['data'] is Map)
        ? (body['data'] as Map).cast<String, dynamic>()
        : <String, dynamic>{};
    final list = data['requests'] ?? data['items'] ?? data['rows'];
    if (list is! List) {
      developer.log(
        'GET /api/trip-join-requests -> no list (keys=${data.keys.join(',')})',
        name: 'SSK.PartLoad',
      );
      return const [];
    }
    final items = list
        .whereType<Map>()
        .map((e) => PartLoadJoinRequest.fromJson(e.cast<String, dynamic>()))
        .toList();
    developer.log(
      'GET /api/trip-join-requests -> ${items.length} rows '
      '(${items.where((r) => r.isPending).length} pending)',
      name: 'SSK.PartLoad',
    );
    return items;
  }

  Future<void> acceptRequest({
    required String accessToken,
    required String requestId,
  }) async {
    try {
      await _dio.patch<Map<String, dynamic>>(
        '/api/trip-join-requests/$requestId/accept',
        options: _auth(accessToken),
      );
    } on DioException catch (e) {
      final msg = (e.response?.data is Map)
          ? ((e.response!.data as Map)['message']?.toString() ??
              'Could not accept — it may have gone stale.')
          : 'Could not accept — it may have gone stale.';
      throw Exception(msg);
    }
  }

  Future<void> declineRequest({
    required String accessToken,
    required String requestId,
  }) async {
    await _dio.patch<Map<String, dynamic>>(
      '/api/trip-join-requests/$requestId/decline',
      options: _auth(accessToken),
    );
  }
}

final partLoadApiProvider = Provider<PartLoadApi>((ref) {
  return PartLoadApi(ref.watch(dioProvider));
});
