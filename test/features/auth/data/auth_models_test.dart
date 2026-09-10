import 'package:flutter_test/flutter_test.dart';
import 'package:ssk/features/auth/data/auth_models.dart';

void main() {
  group('SskUser', () {
    test('parses address from profile response user payload', () {
      final session = AuthSession.fromProfileResponse(
        profile: {
          'success': true,
          'data': {
            'user': {
              'id': 'broker-id',
              'name': 'Test Broker',
              'email': 'broker@example.com',
              'phone': '9000000003',
              'role': 'broker',
              'status': 'active',
              'address': 'Kandivali West, Mumbai',
            },
          },
        },
        tokens: const AuthTokens(
          accessToken: 'access-token',
          refreshToken: 'refresh-token',
          tokenType: 'Bearer',
          expiresIn: '3600',
        ),
      );

      expect(session.user.address, 'Kandivali West, Mumbai');
      expect(session.user.role, 'broker');
    });
  });
}
