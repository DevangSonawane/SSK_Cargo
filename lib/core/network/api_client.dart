import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://apigadidosti.asynk.in',
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'Accept': 'application/json'},
    ),
  );
});

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class SskApiClient {
  SskApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> health() async {
    return _request(() => _dio.get<Map<String, dynamic>>('/api/health'));
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    developer.log(
      'POST /api/auth/login baseUrl=${_dio.options.baseUrl} email=$email passwordLength=${password.length}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'email': email, 'password': password},
      ),
    );
  }

  Future<Map<String, dynamic>> googleLogin({
    required String idToken,
    required String role,
  }) async {
    developer.log(
      'POST /api/auth/google role=$role idTokenLength=${idToken.length}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/auth/google',
        data: {'id_token': idToken, 'role': role},
      ),
    );
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'name': name,
          'email': email,
          'password': password,
          'role': role,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> logout({
    required String refreshToken,
    bool allDevices = false,
  }) async {
    developer.log(
      'POST /api/auth/logout allDevices=$allDevices refreshTokenLength=${refreshToken.length}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/auth/logout',
        data: {'refresh_token': refreshToken, 'all_devices': allDevices},
      ),
    );
  }

  Future<Map<String, dynamic>> getProfile({required String accessToken}) async {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/user/profile',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getTrip({
    required String accessToken,
    required String tripId,
  }) async {
    developer.log('GET /api/trips/$tripId', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/trips/$tripId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getBookings({
    required String accessToken,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    developer.log(
      'GET /api/bookings status=$status page=$page limit=$limit',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/bookings',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'limit': limit,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getBookingOffers({
    required String accessToken,
    required String bookingId,
  }) async {
    developer.log('GET /api/bookings/$bookingId/offers', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/bookings/$bookingId/offers',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> createBooking({
    required String accessToken,
    required Map<String, dynamic> booking,
  }) async {
    developer.log(
      'POST /api/bookings keys=${booking.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/bookings',
        data: booking,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getDistanceEstimate({
    required String accessToken,
    required String pickup,
    required String drop,
  }) async {
    developer.log(
      'POST /api/config/distance pickup=$pickup drop=$drop',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/config/distance',
        data: {'pickup': pickup, 'drop': drop},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> estimatePricing({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    developer.log(
      'POST /api/pricing/estimate keys=${payload.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/pricing/estimate',
        data: payload,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> createTruck({
    required String accessToken,
    required Map<String, dynamic> truck,
  }) async {
    developer.log(
      'POST /api/vehicles/trucks keys=${truck.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/vehicles/trucks',
        data: truck,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> createDriverRegistration({
    required String accessToken,
    required Map<String, dynamic> driver,
  }) async {
    developer.log(
      'POST /api/vehicles/drivers/register keys=${driver.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/vehicles/drivers/register',
        data: driver,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> createDriverProfile({
    required String accessToken,
    required Map<String, dynamic> driver,
  }) async {
    developer.log(
      'POST /api/vehicles/drivers keys=${driver.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/vehicles/drivers',
        data: driver,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getDriverById({
    required String accessToken,
    required String id,
  }) async {
    developer.log('GET /api/vehicles/drivers/$id', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/vehicles/drivers/$id',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> deleteDriver({
    required String accessToken,
    required String id,
  }) async {
    developer.log('DELETE /api/vehicles/drivers/$id', name: 'SSK.API');
    return _request(
      () => _dio.delete<Map<String, dynamic>>(
        '/api/vehicles/drivers/$id',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> updateDriverProfile({
    required String accessToken,
    required String id,
    required Map<String, dynamic> driver,
  }) async {
    developer.log(
      'PATCH /api/vehicles/drivers/$id keys=${driver.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/vehicles/drivers/$id',
        data: driver,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getDrivers({
    required String accessToken,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    developer.log(
      'GET /api/vehicles/drivers status=$status page=$page limit=$limit',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/vehicles/drivers',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'limit': limit,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> updateTruck({
    required String accessToken,
    required String id,
    required Map<String, dynamic> truck,
  }) async {
    developer.log(
      'PATCH /api/vehicles/trucks/$id keys=${truck.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/vehicles/trucks/$id',
        data: truck,
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getTruckById({
    required String accessToken,
    required String id,
  }) async {
    developer.log('GET /api/vehicles/trucks/$id', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/vehicles/trucks/$id',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> deleteTruck({
    required String accessToken,
    required String id,
  }) async {
    developer.log('DELETE /api/vehicles/trucks/$id', name: 'SSK.API');
    return _request(
      () => _dio.delete<Map<String, dynamic>>(
        '/api/vehicles/trucks/$id',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> declineJobRequest({
    required String accessToken,
    required String id,
  }) async {
    developer.log('PATCH /api/jobs/requests/$id/decline', name: 'SSK.API');
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/jobs/requests/$id/decline',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> counterJobRequest({
    required String accessToken,
    required String id,
    required num amount,
    String? note,
  }) async {
    developer.log(
      'PATCH /api/jobs/requests/$id/counter amount=$amount noteSet=${note != null && note.isNotEmpty}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/jobs/requests/$id/counter',
        data: {
          'amount': amount,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> acceptJobRequest({
    required String accessToken,
    required String id,
  }) async {
    developer.log('PATCH /api/jobs/requests/$id/accept', name: 'SSK.API');
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/jobs/requests/$id/accept',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> assignDriverToJob({
    required String accessToken,
    required String id,
    required String driverId,
    required String truckId,
  }) async {
    developer.log(
      'POST /api/jobs/$id/assign-driver driverId=$driverId truckId=$truckId',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/jobs/$id/assign-driver',
        data: {'driverId': driverId, 'truckId': truckId},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getJobRequests({
    required String accessToken,
    int page = 1,
    int limit = 10,
  }) async {
    developer.log(
      'GET /api/jobs/requests page=$page limit=$limit',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/jobs/requests',
        queryParameters: {'page': page, 'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> clientAcceptCounterOffer({
    required String accessToken,
    required String id,
  }) async {
    developer.log(
      'PATCH /api/jobs/requests/$id/client-accept',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/jobs/requests/$id/client-accept',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> clientRejectCounterOffer({
    required String accessToken,
    required String id,
  }) async {
    developer.log(
      'PATCH /api/jobs/requests/$id/client-reject',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/jobs/requests/$id/client-reject',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> clientCounterOffer({
    required String accessToken,
    required String id,
    required num amount,
    String? note,
  }) async {
    developer.log(
      'PATCH /api/jobs/requests/$id/client-counter amount=$amount noteSet=${note != null && note.isNotEmpty}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/jobs/requests/$id/client-counter',
        data: {
          'amount': amount,
          if (note != null && note.isNotEmpty) 'note': note,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getTrucks({
    required String accessToken,
    String? status,
    int page = 1,
    int limit = 10,
  }) async {
    developer.log(
      'GET /api/vehicles/trucks status=$status page=$page limit=$limit',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/vehicles/trucks',
        queryParameters: {
          if (status != null && status.isNotEmpty) 'status': status,
          'page': page,
          'limit': limit,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getTruckByFilterLookup({
    required String accessToken,
    required String phone,
  }) async {
    developer.log(
      'GET /api/vehicles/drivers/lookup phone=$phone',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/vehicles/drivers/lookup',
        queryParameters: {'phone': phone},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> cancelBooking({
    required String accessToken,
    required String id,
  }) async {
    developer.log('PATCH /api/bookings/$id/cancel', name: 'SSK.API');
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/bookings/$id/cancel',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> reportTripIssue({
    required String accessToken,
    required String tripId,
    required String reason,
    required String notes,
  }) async {
    developer.log(
      'POST /api/trips/$tripId/report-issue reason=$reason notesLength=${notes.length}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/trips/$tripId/report-issue',
        data: {'reason': reason, 'notes': notes},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getTripIncidents({
    required String accessToken,
    required String tripId,
  }) async {
    developer.log('GET /api/trips/$tripId/incidents', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/trips/$tripId/incidents',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> updateTripIncidentMechanic({
    required String accessToken,
    required String tripId,
    required String incidentId,
    String? status,
    String? mechanicName,
    String? mechanicPhone,
    String? notes,
  }) async {
    developer.log(
      'PATCH /api/trips/$tripId/incidents/$incidentId/mechanic status=$status mechanicNameSet=${mechanicName != null && mechanicName.isNotEmpty}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/trips/$tripId/incidents/$incidentId/mechanic',
        data: {
          if (status != null && status.isNotEmpty) 'status': status,
          if (mechanicName != null && mechanicName.isNotEmpty)
            'mechanicName': mechanicName,
          if (mechanicPhone != null && mechanicPhone.isNotEmpty)
            'mechanicPhone': mechanicPhone,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> resolveTripIncident({
    required String accessToken,
    required String tripId,
    required String incidentId,
  }) async {
    developer.log(
      'PATCH /api/trips/$tripId/incidents/$incidentId/resolve',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/trips/$tripId/incidents/$incidentId/resolve',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> uploadTripPod({
    required String accessToken,
    required String tripId,
    required List<MultipartFile> files,
  }) async {
    developer.log(
      'POST /api/trips/$tripId/pod files=${files.length}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/trips/$tripId/pod',
        data: FormData.fromMap({'files': files}),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> uploadDriverPaymentQr({
    required String accessToken,
    required String filePath,
  }) async {
    final filename = filePath.split(RegExp(r'[\\/]+')).last;
    developer.log(
      'POST /api/vehicles/drivers/me/payment-qr file=$filename',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/vehicles/drivers/me/payment-qr',
        data: FormData.fromMap({
          'file': MultipartFile.fromFileSync(filePath, filename: filename),
        }),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> collectTripPayment({
    required String accessToken,
    required String tripId,
    required String mode,
  }) async {
    developer.log(
      'PATCH /api/trips/$tripId/collect-payment mode=$mode',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/trips/$tripId/collect-payment',
        data: {'mode': mode},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> completeTrip({
    required String accessToken,
    required String tripId,
  }) async {
    developer.log(
      'PATCH /api/trips/$tripId/status status=completed',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/trips/$tripId/status',
        data: {'status': 'completed'},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> updateDriverLocation({
    required String accessToken,
    required double lat,
    required double lng,
  }) async {
    developer.log(
      'PATCH /api/vehicles/drivers/me/location lat=$lat lng=$lng',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/vehicles/drivers/me/location',
        data: {'lat': lat, 'lng': lng},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> updateTripLocation({
    required String accessToken,
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    developer.log(
      'PATCH /api/trips/$tripId/location lat=$lat lng=$lng',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/trips/$tripId/location',
        data: {'lat': lat, 'lng': lng},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    required String name,
    required String email,
    String? phone,
    String? profileImage,
  }) async {
    developer.log(
      'PUT /api/user/profile name=$name email=$email phoneSet=${phone != null && phone.isNotEmpty} profileImageSet=${profileImage != null && profileImage.isNotEmpty}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.put<Map<String, dynamic>>(
        '/api/user/profile',
        data: {
          'name': name,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (profileImage != null && profileImage.isNotEmpty)
            'profile_image': profileImage,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    developer.log(
      'PUT /api/user/change-password currentPasswordLength=${currentPassword.length} newPasswordLength=${newPassword.length}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.put<Map<String, dynamic>>(
        '/api/user/change-password',
        data: {
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> submitBrokerKyc({
    required String accessToken,
    required Map<String, dynamic> documents,
  }) async {
    developer.log(
      'POST /api/kyc/broker documents=${documents.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/kyc/broker',
        data: {'documents': documents},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> submitDriverKyc({
    required String accessToken,
    required Map<String, dynamic> documents,
  }) async {
    developer.log(
      'POST /api/kyc/driver documents=${documents.keys.join(',')}',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/kyc/driver',
        data: {'documents': documents},
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> uploadBrokerKycDocument({
    required String accessToken,
    required String documentKey,
    required String filePath,
  }) async {
    final filename = filePath.split(RegExp(r'[\\/]+')).last;
    developer.log(
      'POST /api/kyc/documents/upload documentKey=$documentKey file=$filename',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.post<Map<String, dynamic>>(
        '/api/kyc/documents/upload',
        data: FormData.fromMap({
          'file': MultipartFile.fromFileSync(filePath, filename: filename),
          'document_key': documentKey,
        }),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getBrokerKycStatus({
    required String accessToken,
  }) async {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/kyc/status',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getKycStatus({
    required String accessToken,
  }) async {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/kyc/status',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getAdminPricing({
    required String accessToken,
  }) async {
    developer.log('GET /api/admin/pricing', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/admin/pricing',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getKycStatusForUser({
    required String accessToken,
    required String userId,
  }) async {
    developer.log('GET /api/kyc/$userId', name: 'SSK.API');
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/kyc/$userId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> getBrokerKycDocuments({
    required String accessToken,
  }) async {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/kyc/documents',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  Future<Map<String, dynamic>> _request(
    Future<Response<Map<String, dynamic>>> Function() call,
  ) async {
    try {
      final response = await call();
      developer.log(
        'Request succeeded status=${response.statusCode} path=${response.requestOptions.path}',
        name: 'SSK.API',
      );
      return response.data ?? <String, dynamic>{};
    } on DioException catch (error) {
      developer.log(
        'Request failed status=${error.response?.statusCode} path=${error.requestOptions.path} data=${error.response?.data}',
        name: 'SSK.API',
      );
      throw ApiException(
        _extractMessage(error),
        statusCode: error.response?.statusCode,
      );
    }
  }

  String _extractMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map<String, dynamic>) {
      final message = responseData['message'];
      if (message != null) {
        return message.toString();
      }
      final errors = responseData['errors'];
      if (errors != null) {
        return errors.toString();
      }
    }
    if (responseData != null) {
      return responseData.toString();
    }
    return error.message ?? 'Request failed';
  }
}

final apiClientProvider = Provider<SskApiClient>((ref) {
  return SskApiClient(ref.watch(dioProvider));
});
