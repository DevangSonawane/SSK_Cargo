import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:developer' as developer;

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://gadidosti-backend.onrender.com',
      contentType: Headers.jsonContentType,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
      },
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
        data: {
          'email': email,
          'password': password,
        },
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
        data: {
          'id_token': idToken,
          'role': role,
        },
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
          'phone': phone?.isEmpty == true ? null : phone,
          'password': password,
          'role': role,
        }..removeWhere((key, value) => value == null),
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
        data: {
          'refresh_token': refreshToken,
          'all_devices': allDevices,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> getProfile({
    required String accessToken,
  }) async {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/user/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> cancelBooking({
    required String accessToken,
    required String id,
  }) async {
    developer.log(
      'PATCH /api/bookings/$id/cancel',
      name: 'SSK.API',
    );
    return _request(
      () => _dio.patch<Map<String, dynamic>>(
        '/api/bookings/$id/cancel',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
          if (profileImage != null && profileImage.isNotEmpty) 'profile_image': profileImage,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
        data: {
          'documents': documents,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> getBrokerKycStatus({
    required String accessToken,
  }) async {
    return _request(
      () => _dio.get<Map<String, dynamic>>(
        '/api/kyc/status',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
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
