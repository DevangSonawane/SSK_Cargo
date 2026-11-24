import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale;

import '../../features/auth/data/otp_service.dart';
import '../../l10n/app_localizations.dart';
import '../network/api_client.dart';

/// Turns any error (backend, network, Firebase, Dart) into a short, plain
/// sentence that is safe to show to the user in a snackbar or error state.
///
/// Rules:
/// * Server messages are shown only when they read like a human sentence
///   (e.g. "Insufficient wallet balance"). Anything technical — stack traces,
///   JSON/HTML bodies, exception class names, error codes, URLs, SHA/package
///   config hints — is replaced with a generic friendly message.
/// * Network problems, timeouts, 5xx and auth expiry get dedicated messages.
/// * The raw error is always written to the developer log for debugging.
String userFacingError(Object? error, {String? fallback}) {
  final text = _resolve(error, fallback);
  if (error != null) {
    developer.log('Shown to user: "$text" ← $error', name: 'SSK.Error');
  }
  return text;
}

/// Localizations kept in sync by the app shell (`MaterialApp.builder`) so the
/// helper can be called from anywhere without a [BuildContext].
class UserFacingErrorL10n {
  UserFacingErrorL10n._();

  static AppLocalizations? current;
}

AppLocalizations get _l10n =>
    UserFacingErrorL10n.current ?? lookupAppLocalizations(const Locale('en'));

String _resolve(Object? error, String? fallback) {
  final generic = fallback ?? _l10n.errorGeneric;
  if (error == null) return generic;

  if (error is OtpException) {
    return _isFriendly(error.message) ? error.message : generic;
  }
  if (error is ApiException) return _fromApi(error, generic);
  if (error is DioException) return _fromDio(error, generic);
  if (error is FirebaseAuthException) return _fromFirebaseAuth(error, generic);
  if (error is FirebaseException) {
    return error.code == 'unavailable' || error.code == 'network-request-failed'
        ? _l10n.errorNoInternet
        : generic;
  }
  if (error is SocketException || error is HttpException) {
    return _l10n.errorNoInternet;
  }
  if (error is TimeoutException) return _l10n.errorTimeout;
  if (error is PlatformException) {
    final message = error.message?.trim() ?? '';
    return _isFriendly(message) ? message : generic;
  }
  if (error is String) return _isFriendly(error) ? error.trim() : generic;

  // `Exception('Please log in first.')`, `StateError('…')` and friends: keep
  // the text when it is a sentence written for people, drop it otherwise.
  final message = _stripPrefixes(error.toString());
  return _isFriendly(message) ? message : generic;
}

String _fromApi(ApiException error, String generic) {
  final status = error.statusCode;
  final message = error.message.trim();
  final friendly = _isFriendly(message);

  // No HTTP response at all: device offline, DNS failure, timeout.
  if (status == null) {
    final lower = message.toLowerCase();
    if (lower.contains('timeout') || lower.contains('timed out')) {
      return _l10n.errorTimeout;
    }
    return _l10n.errorNoInternet;
  }
  if (status >= 500) return _l10n.errorServer;
  if (status == 401) return friendly ? message : _l10n.errorSessionExpired;
  if (status == 408) return _l10n.errorTimeout;
  if (status == 429) return _l10n.errorTooManyRequests;
  if (friendly) return message;
  if (status == 403) return _l10n.errorNotAllowed;
  if (status == 404) return _l10n.errorNotFound;
  if (status == 400 || status == 422) return _l10n.errorCheckDetails;
  return generic;
}

String _fromDio(DioException error, String generic) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return _l10n.errorTimeout;
    case DioExceptionType.connectionError:
      return _l10n.errorNoInternet;
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode ?? 0;
      if (status >= 500) return _l10n.errorServer;
      final data = error.response?.data;
      final message = data is Map ? data['message']?.toString() ?? '' : '';
      return _isFriendly(message) ? message.trim() : generic;
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return error.error is SocketException ? _l10n.errorNoInternet : generic;
  }
}

String _fromFirebaseAuth(FirebaseAuthException error, String generic) {
  return switch (error.code) {
    'network-request-failed' => _l10n.errorNoInternet,
    'too-many-requests' || 'quota-exceeded' => _l10n.errorTooManyRequests,
    'invalid-verification-code' => _l10n.errorOtpWrong,
    'code-expired' || 'session-expired' => _l10n.errorOtpExpired,
    'invalid-phone-number' => _l10n.errorInvalidPhone,
    // App-configuration problems (SHA/Play Integrity/reCAPTCHA) are never
    // the user's fault and the raw text is meaningless to them.
    _ => _l10n.errorVerificationUnavailable,
  };
}

String _stripPrefixes(String text) {
  var result = text.trim();
  for (final prefix in const [
    'Exception: ',
    'ApiException: ',
    'Bad state: ',
    'Invalid argument(s): ',
    'FormatException: ',
  ]) {
    if (result.startsWith(prefix)) result = result.substring(prefix.length);
  }
  // `ApiException(500): …` style toString().
  result = result.replaceFirst(RegExp(r'^ApiException\(\d*\):\s*'), '');
  return result.trim();
}

final _technicalPattern = RegExp(
  [
    r'exception',
    r'\berror:',
    r'stack ?trace',
    r'\bnull\b',
    r'undefined',
    r'\bNaN\b',
    r'is not a subtype',
    r'nosuchmethod',
    r'type .* is not',
    r'status code',
    r'\bdio\b',
    r'socket',
    r'econn',
    r'errno',
    r'failed host lookup',
    r'xmlhttprequest',
    r'https?://',
    r'<[a-z!/]', // HTML
    r'[{}\[\]]', // JSON / maps / lists
    r'\b[A-Z0-9]+(_[A-Z0-9]+)+\b', // ERROR_CODES
    r'sha-?1|sha-?256|package name|firebase|play_integrity|recaptcha',
    r'prisma|sequelize|mongo|postgres|sql|duplicate key|constraint',
    r'cast to objectid|validation failed|internal server',
    r'\bat [\w.$<>]+ \(', // JS stack frame
    r'#\d+\s+\w', // Dart stack frame
    r'\.dart\b|\.js\b|\.ts\b',
  ].join('|'),
  caseSensitive: false,
);

/// True when [message] reads like something written for an end user.
bool _isFriendly(String message) {
  final text = message.trim();
  if (text.length < 3 || text.length > 160) return false;
  if (text.contains('\n')) return false;
  if (!RegExp(r'[A-Za-zऀ-ॿ]').hasMatch(text)) return false;
  return !_technicalPattern.hasMatch(text);
}
