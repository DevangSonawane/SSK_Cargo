import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';

/// Verifies the authenticated account-deletion request contract:
/// POST /api/account-deletion-requests/me with only an optional reason —
/// name/email/phone/audience come from the verified account server-side.
void main() {
  late Dio dio;
  late SskApiClient api;
  late RequestOptions captured;

  setUp(() {
    dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.resolve(
            Response<Map<String, dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: {
                'success': true,
                'data': {'id': 'req-1', 'status': 'pending'},
              },
            ),
          );
        },
      ),
    );
    api = SskApiClient(dio);
  });

  test('posts to /me with reason and bearer token', () async {
    final result = await api.requestAccountDeletion(
      accessToken: 'access-123',
      reason: '  leaving  ',
    );
    expect(captured.path, '/api/account-deletion-requests/me');
    expect(captured.method, 'POST');
    expect(
      captured.headers['Authorization'],
      'Bearer access-123',
    );
    expect(captured.data, {'reason': 'leaving'});
    expect(result['success'], isTrue);
  });

  test('omits reason when blank', () async {
    await api.requestAccountDeletion(accessToken: 'access-123', reason: '   ');
    expect(captured.data, isEmpty);
  });

  test('omits reason when null', () async {
    await api.requestAccountDeletion(accessToken: 'access-123');
    expect(captured.data, isEmpty);
  });
}
