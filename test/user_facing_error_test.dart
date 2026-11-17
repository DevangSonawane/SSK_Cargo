import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/utils/user_facing_error.dart';

void main() {
  const generic = 'Something went wrong. Please try again.';

  group('userFacingError', () {
    test('keeps readable server messages', () {
      expect(
        userFacingError(
          const ApiException('Insufficient wallet balance', statusCode: 400),
        ),
        'Insufficient wallet balance',
      );
    });

    test('hides technical server messages', () {
      for (final raw in [
        'Cannot read properties of undefined (reading \'id\')',
        'PrismaClientKnownRequestError: Unique constraint failed',
        '<!DOCTYPE html><html><body>Bad Gateway</body></html>',
        '{"code":"E_BAD"}',
        'KYC_VERIFICATION_REQUIRED',
        'Request failed with status code 400',
      ]) {
        expect(
          userFacingError(ApiException(raw, statusCode: 400)),
          isNot(raw),
          reason: raw,
        );
      }
    });

    test('maps 5xx, offline and timeouts', () {
      expect(
        userFacingError(const ApiException('Readable text', statusCode: 502)),
        contains('server'),
      );
      expect(
        userFacingError(const ApiException('Failed host lookup')),
        contains('internet'),
      );
      expect(userFacingError(const SocketException('x')), contains('internet'));
      expect(userFacingError(TimeoutException('x')), contains('longer'));
    });

    test('never leaks Firebase configuration errors', () {
      final error = FirebaseAuthException(
        code: 'app-not-authorized',
        message:
            'This app is not authorized to use Firebase Authentication. '
            'Please verify that the correct package name, SHA-1, and SHA-256',
      );
      final text = userFacingError(error);
      expect(text, isNot(contains('SHA')));
      expect(text, contains('verify your number'));
    });

    test('strips Exception prefix but keeps friendly text', () {
      expect(
        userFacingError(Exception('Please log in as a client first.')),
        'Please log in as a client first.',
      );
      expect(
        userFacingError(
          StateError("type 'Null' is not a subtype of type 'String'"),
        ),
        generic,
      );
    });
  });
}
