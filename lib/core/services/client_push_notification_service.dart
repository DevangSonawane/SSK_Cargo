import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../features/auth/data/auth_models.dart';
import '../network/api_client.dart';

final clientPushNotificationServiceProvider =
    Provider<ClientPushNotificationService>((ref) {
      final service = ClientPushNotificationService(
        ref.read(apiClientProvider),
      );
      ref.onDispose(service.dispose);
      return service;
    });

class _PushSession {
  _PushSession(this.session);

  AuthSession session;
  // Include attempted sends: a transport failure can hide a successful upsert.
  final Set<String> tokens = <String>{};
}

class ClientPushNotificationService {
  ClientPushNotificationService(
    this._apiClient, {
    FirebaseMessaging? messaging,
    Future<void> Function()? ensureAndroidPermission,
  }) : _messagingOverride = messaging,
       _ensureAndroidPermissionOverride = ensureAndroidPermission;

  final SskApiClient _apiClient;
  final FirebaseMessaging? _messagingOverride;
  final Future<void> Function()? _ensureAndroidPermissionOverride;
  StreamSubscription<String>? _tokenRefreshSubscription;
  _PushSession? _active;
  int _generation = 0;
  bool _disposed = false;
  Future<void> _operations = Future<void>.value();

  bool _isCurrent(_PushSession owner, int generation) =>
      !_disposed && identical(_active, owner) && generation == _generation;

  /// Refresh credentials without restarting SDK work or triggering a POST/401/
  /// auth-refresh loop. Failed sends can retry on the next token/session sync.
  void updateSession(AuthSession session) {
    final owner = _active;
    if (!_disposed &&
        owner != null &&
        owner.session.user.id == session.user.id) {
      owner.session = session;
    }
  }

  Future<void> syncForSession(AuthSession session) async {
    if (_disposed || !_isSupportedPlatform) return;

    var owner = _active;
    if (owner == null || owner.session.user.id != session.user.id) {
      if (owner != null) _queueCleanup(owner);
      owner = _PushSession(session);
      _active = owner;
    } else {
      // Existing listeners/queued operations read these credentials at send time.
      owner.session = session;
    }
    final currentOwner = owner;
    final generation = ++_generation;
    final cancellation = _cancelSubscription();

    try {
      await cancellation;
      if (!_isCurrent(currentOwner, generation)) return;
      // main.dart owns Firebase initialization. Access failures remain non-fatal.
      final messaging = _messagingOverride ?? FirebaseMessaging.instance;
      // Subscribe before awaiting permission/getToken so rotations are not lost.
      var tokenRefreshed = false;
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen(
        (token) {
          if (!_isCurrent(currentOwner, generation)) return;
          tokenRefreshed = true;
          unawaited(_queueRegistration(currentOwner, generation, token));
        },
        onError: (Object error, StackTrace stackTrace) {
          _logFailure('Token refresh stream', error);
        },
      );
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      if (!_isCurrent(currentOwner, generation)) return;
      developer.log(
        'Push permission status=${permission.authorizationStatus}',
        name: 'SSK.Push',
      );
      // Firebase's requestPermission is a no-op on Android. Android 13+
      // requires a runtime POST_NOTIFICATIONS prompt or the OS silently
      // blocks the tray with no Allow/Deny dialog ever shown.
      await _ensureAndroidNotificationPermission();
      if (!_isCurrent(currentOwner, generation)) return;
      final token = await messaging.getToken();
      if (!_isCurrent(currentOwner, generation)) return;
      // A refresh event is newer than a potentially stale getToken result.
      if (!tokenRefreshed && token != null && token.isNotEmpty) {
        await _queueRegistration(currentOwner, generation, token);
      }
    } catch (error) {
      _logFailure('Push sync', error);
    }
  }

  /// Android-only runtime prompt. Non-fatal and never blocks token
  /// registration — a denied device still gets a backend token, the OS
  /// just won't show the tray. iOS is handled by Firebase requestPermission.
  Future<void> _ensureAndroidNotificationPermission() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    try {
      if (_ensureAndroidPermissionOverride != null) {
        await _ensureAndroidPermissionOverride();
        return;
      }
      var status = await Permission.notification.status;
      if (status.isGranted || status.isLimited) return;
      if (status.isPermanentlyDenied) {
        developer.log(
          'Android push permission permanently denied',
          name: 'SSK.Push',
        );
        return;
      }
      status = await Permission.notification.request();
      developer.log(
        'Android push permission status=$status',
        name: 'SSK.Push',
      );
    } catch (error) {
      _logFailure('Android push permission', error);
    }
  }

  /// Invalidates SDK work immediately; cleanup waits for any in-flight POST.
  Future<void> clearForSession() {
    final owner = _active;
    _active = null;
    ++_generation;
    final cancellation = _cancelSubscription();
    final cleanup = owner == null ? _operations : _queueCleanup(owner);
    return Future.wait([cancellation, cleanup]).then((_) {});
  }

  Future<void> _cancelSubscription() async {
    final subscription = _tokenRefreshSubscription;
    _tokenRefreshSubscription = null;
    try {
      await subscription?.cancel();
    } catch (error) {
      _logFailure('Token subscription cancellation', error);
    }
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _operations = _operations.then((_) async {
      try {
        await operation();
      } catch (error) {
        _logFailure('Push token operation', error);
      }
    });
    return _operations;
  }

  Future<void> _queueRegistration(
    _PushSession owner,
    int generation,
    String token,
  ) {
    if (token.isEmpty) return Future<void>.value();
    return _enqueue(() async {
      if (!_isCurrent(owner, generation)) return;
      owner.tokens.add(token);
      await _apiClient.registerDeviceToken(
        accessToken: owner.session.tokens.accessToken,
        token: token,
        platform: _platformName,
      );
      developer.log('Device token registered', name: 'SSK.Push');
    });
  }

  Future<void> _queueCleanup(_PushSession owner) => _enqueue(() async {
    // Serialized with POSTs and subsequent owners' registrations: an old DELETE
    // must never remove a token after it has been reassigned to a new account.
    for (final token in owner.tokens) {
      try {
        await _apiClient.unregisterDeviceToken(
          accessToken: owner.session.tokens.accessToken,
          token: token,
        );
        developer.log('Device token unregistered', name: 'SSK.Push');
      } catch (error) {
        _logFailure('Push unregister', error);
      }
    }
    owner.tokens.clear();
  });

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(clearForSession());
  }

  void _logFailure(String operation, Object error) {
    // Do not log exception messages, request objects, or device/access tokens.
    final status = error is ApiException ? ' status=${error.statusCode}' : '';
    developer.log(
      '$operation failed (${error.runtimeType})$status',
      name: 'SSK.Push',
    );
  }

  bool get _isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  String get _platformName =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
}
