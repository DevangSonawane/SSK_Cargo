import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The code [MockOtpService] accepts until a real SMS provider is wired up.
const String kMockOtpCode = '1234';

/// Number of digits in a phone OTP.
const int kOtpLength = 4;

/// Sends and checks phone OTPs.
///
/// Today this is backed by [MockOtpService] (any number, code `1234`). When
/// the SMS gateway is integrated, swap the implementation in
/// [otpServiceProvider] — the login and signup screens only talk to this
/// interface.
abstract class OtpService {
  /// Whether codes are mocked — screens show a "test mode" hint when true.
  bool get isMock;

  Future<void> sendOtp({required String phone});

  /// Returns true when [code] is the OTP sent to [phone].
  Future<bool> verifyOtp({required String phone, required String code});
}

class MockOtpService implements OtpService {
  const MockOtpService();

  @override
  bool get isMock => true;

  @override
  Future<void> sendOtp({required String phone}) =>
      Future<void>.delayed(const Duration(milliseconds: 700));

  @override
  Future<bool> verifyOtp({required String phone, required String code}) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    return code == kMockOtpCode;
  }
}

final otpServiceProvider = Provider<OtpService>(
  (ref) => const MockOtpService(),
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
