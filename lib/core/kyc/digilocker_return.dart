import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Path DigiLocker sends the user back to. It is registered as an Android
/// App Link (and, once the backend hosts the association files, an iOS
/// Universal Link), so when DigiLocker redirects here the OS hands the URL
/// to the app instead of the browser. GoRouter's `onEnter` swallows it (see
/// app_router.dart) so the current screen keeps its state.
const String kDigilockerReturnPath = '/kyc/digilocker/return';

/// Host that serves [kDigilockerReturnPath]. Must match the
/// `<data android:host>` in AndroidManifest.xml and the backend's
/// `/.well-known/assetlinks.json` / `apple-app-site-association`.
const String kDigilockerReturnHost = 'apigadidosti.asynk.in';

/// Where DigiLocker sends the user afterwards (backend requires https).
const String kDigilockerRedirectUrl =
    'https://$kDigilockerReturnHost$kDigilockerReturnPath';

/// One "user came back from DigiLocker" event, raised by the router when the
/// return link opens the app. [verificationId] is DigiLocker's
/// `verification_id` query param (may be null if the backend page strips it;
/// the card falls back to the id it already holds).
class DigilockerReturnEvent {
  const DigilockerReturnEvent({this.verificationId, required this.at});

  final String? verificationId;
  final DateTime at;
}

/// Latest return event. The DigiLocker card listens to this to close the
/// in-app browser tab and resolve the session immediately.
final digilockerReturnProvider = StateProvider<DigilockerReturnEvent?>(
  (ref) => null,
);

/// A DigiLocker session that was started but not yet resolved.
class PendingDigilockerSession {
  const PendingDigilockerSession({
    required this.verificationId,
    required this.startedAt,
  });

  final String verificationId;
  final DateTime startedAt;
}

/// Persists the in-flight `verificationId` per user + role, so the result
/// can still be read after Android kills the app while the user is in the
/// browser, or after they log in again. Cleared once the session resolves
/// (done / failed).
class DigilockerSessionStore {
  DigilockerSessionStore._();

  /// Results stay readable well past the ~10 min consent-link lifetime, but
  /// a day-old pending session is not worth resurrecting.
  static const Duration _maxAge = Duration(hours: 24);

  static String _key(String userId, String role) =>
      'digilocker_pending_${role.trim().toLowerCase()}_$userId';

  static Future<void> save({
    required String userId,
    required String role,
    required String verificationId,
  }) async {
    if (userId.isEmpty || verificationId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key(userId, role),
        jsonEncode({
          'verificationId': verificationId,
          'startedAt': DateTime.now().toUtc().toIso8601String(),
        }),
      );
    } catch (_) {
      // Best effort: the in-memory id still covers the common case.
    }
  }

  static Future<PendingDigilockerSession?> load({
    required String userId,
    required String role,
  }) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key(userId, role));
      if (raw == null || raw.isEmpty) return null;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final id = map['verificationId']?.toString() ?? '';
      final startedAt =
          DateTime.tryParse(map['startedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      if (id.isEmpty ||
          DateTime.now().toUtc().difference(startedAt.toUtc()) > _maxAge) {
        await prefs.remove(_key(userId, role));
        return null;
      }
      return PendingDigilockerSession(
        verificationId: id,
        startedAt: startedAt,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear({
    required String userId,
    required String role,
  }) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key(userId, role));
    } catch (_) {}
  }
}
