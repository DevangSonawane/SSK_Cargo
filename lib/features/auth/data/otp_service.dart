import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Number of digits in a Firebase phone OTP.
const int kOtpLength = 6;

/// A readable OTP failure. [wrongCode] is true when the user mistyped the
/// code (the boxes shake and clear); otherwise the code entry is fine but
/// something else failed (expired, rate-limited, network).
class OtpException implements Exception {
  const OtpException(this.message, {this.wrongCode = false});

  final String message;
  final bool wrongCode;

  @override
  String toString() => message;
}

/// Android instant verification / SMS auto-retrieval for [phone].
class OtpAutoVerification {
  const OtpAutoVerification({
    required this.phone,
    required this.idToken,
    this.smsCode,
  });

  final String phone;
  final String idToken;
  final String? smsCode;
}

/// Phone OTP through Firebase Phone Auth
/// (docs/reference/FIREBASE_PHONE_AUTH_FLUTTER_GUIDE.md).
///
/// Firebase sends and checks the code on-device; a successful check yields a
/// Firebase ID token for `POST /api/auth/firebase-login`. The Firebase user
/// is signed out right after, since the backend session is what the app uses.
class OtpService {
  OtpService(this._auth);

  final FirebaseAuth _auth;
  final _verificationIds = <String, String>{};
  final _resendTokens = <String, int?>{};
  final _autoVerified = <String, OtpAutoVerification>{};
  final _autoController = StreamController<OtpAutoVerification>.broadcast();

  /// Fires when Android verifies a number without the user typing the code.
  Stream<OtpAutoVerification> get autoVerifications => _autoController.stream;

  /// A verification that completed before the code screen was listening
  /// (instant verification). Consumed on read.
  OtpAutoVerification? takeAutoVerification(String phone) =>
      _autoVerified.remove(phone);

  /// Sends the code to the 10-digit Indian [phone]. Completes once Firebase
  /// has sent the SMS (or verified the number instantly).
  Future<void> sendOtp({required String phone}) {
    final completer = Completer<void>();
    void finish([Object? error]) {
      if (completer.isCompleted) return;
      error == null ? completer.complete() : completer.completeError(error);
    }

    _autoVerified.remove(phone);
    _auth
        .verifyPhoneNumber(
          phoneNumber: '+91$phone',
          forceResendingToken: _resendTokens[phone],
          timeout: const Duration(seconds: 60),
          verificationCompleted: (credential) async {
            try {
              final idToken = await _signInForToken(credential);
              final result = OtpAutoVerification(
                phone: phone,
                idToken: idToken,
                smsCode: credential.smsCode,
              );
              if (_autoController.hasListener) {
                _autoController.add(result);
              } else {
                _autoVerified[phone] = result;
              }
              finish();
            } on OtpException catch (error) {
              finish(error);
            }
          },
          verificationFailed: (error) => finish(_mapError(error)),
          codeSent: (verificationId, resendToken) {
            _verificationIds[phone] = verificationId;
            _resendTokens[phone] = resendToken;
            finish();
          },
          codeAutoRetrievalTimeout: (verificationId) {
            _verificationIds[phone] = verificationId;
          },
        )
        .catchError((Object error) => finish(_mapError(error)));
    return completer.future;
  }

  /// Checks [code] for [phone] and returns the Firebase ID token.
  Future<String> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final verificationId = _verificationIds[phone];
    if (verificationId == null) {
      throw const OtpException('Code expired. Tap "Resend code".');
    }
    return _signInForToken(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      ),
    );
  }

  Future<String> _signInForToken(PhoneAuthCredential credential) async {
    try {
      final result = await _auth.signInWithCredential(credential);
      final idToken = await result.user?.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw const OtpException('Could not verify this number. Try again.');
      }
      return idToken;
    } on FirebaseAuthException catch (error) {
      throw _mapError(error);
    } finally {
      unawaited(_auth.signOut().catchError((_) {}));
    }
  }

  OtpException _mapError(Object error) {
    if (error is OtpException) return error;
    if (error is! FirebaseAuthException) {
      return const OtpException('Something went wrong. Please try again.');
    }
    return switch (error.code) {
      'invalid-verification-code' => const OtpException(
        'That code isn\'t right. Try again.',
        wrongCode: true,
      ),
      'invalid-phone-number' => const OtpException(
        'That mobile number doesn\'t look right.',
      ),
      'too-many-requests' => const OtpException(
        'Too many attempts. Please wait a few minutes and try again.',
      ),
      'code-expired' || 'session-expired' => const OtpException(
        'Code expired. Tap "Resend code".',
      ),
      'quota-exceeded' => const OtpException(
        'SMS limit reached for now. Please try again later.',
      ),
      'network-request-failed' => const OtpException(
        'No internet connection. Check your network and try again.',
      ),
      _ => OtpException(error.message ?? 'Could not send the code.'),
    };
  }
}

final otpServiceProvider = Provider<OtpService>(
  (ref) => OtpService(FirebaseAuth.instance),
);

/// Strips everything but digits and keeps the last 10 (Indian mobile).
String normalizeIndianPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
}

/// `98765 43210` style display for a 10-digit number.
String formatIndianPhone(String phone) {
  final digits = normalizeIndianPhone(phone);
  if (digits.length != 10) return '+91 $digits';
  return '+91 ${digits.substring(0, 5)} ${digits.substring(5)}';
}
