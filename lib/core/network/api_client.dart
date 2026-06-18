import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: 'https://api.ssk.local',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );
});

class SskApiClient {
  SskApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> ping() async {
    final response = await _dio.get<Map<String, dynamic>>('/ping');
    return response.data ?? <String, dynamic>{};
  }
}

final apiClientProvider = Provider<SskApiClient>((ref) {
  return SskApiClient(ref.watch(dioProvider));
});
