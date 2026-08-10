import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_models.dart';
import '../network/api_client.dart';

final clientPushNotificationServiceProvider =
    Provider<ClientPushNotificationService>((ref) {
      return ClientPushNotificationService(ref);
    });

class ClientPushNotificationService {
  ClientPushNotificationService(this._ref);

  final Ref _ref;

  StreamSubscription<String>? _tokenRefreshSubscription;
  String? _lastRegisteredToken;
  bool _firebaseInitializationAttempted = false;
  bool _firebaseReady = false;

  Future<void> syncForSession(AuthSession session) async {
    if (!_isSupportedPlatform) {
      return;
    }

    final ready = await _ensureFirebaseReady();
    if (!ready) {
      return;
    }

    try {
      final messaging = FirebaseMessaging.instance;
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      developer.log(
        'Push permission status=${permission.authorizationStatus}',
        name: 'SSK.Push',
      );

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(session, token);
      }

      await _tokenRefreshSubscription?.cancel();
      _tokenRefreshSubscription = messaging.onTokenRefresh.listen((newToken) {
        unawaited(_registerToken(session, newToken));
      });
    } catch (error, stackTrace) {
      developer.log(
        'Push sync failed: $error',
        name: 'SSK.Push',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> clearForSession(AuthSession session) async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    final token = _lastRegisteredToken;
    if (token == null || token.isEmpty) {
      _lastRegisteredToken = null;
      return;
    }

    try {
      await _ref
          .read(apiClientProvider)
          .unregisterDeviceToken(
            accessToken: session.tokens.accessToken,
            token: token,
          );
    } catch (error, stackTrace) {
      developer.log(
        'Push unregister failed: $error',
        name: 'SSK.Push',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _lastRegisteredToken = null;
    }
  }

  Future<void> _registerToken(AuthSession session, String token) async {
    if (token.isEmpty || token == _lastRegisteredToken) {
      return;
    }

    try {
      await _ref
          .read(apiClientProvider)
          .registerDeviceToken(
            accessToken: session.tokens.accessToken,
            token: token,
            platform: _platformName,
          );
      _lastRegisteredToken = token;
    } catch (error, stackTrace) {
      developer.log(
        'Push register failed: $error',
        name: 'SSK.Push',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _ensureFirebaseReady() async {
    if (_firebaseReady) {
      return true;
    }

    if (_firebaseInitializationAttempted && !_firebaseReady) {
      return false;
    }

    _firebaseInitializationAttempted = true;

    if (Firebase.apps.isNotEmpty) {
      _firebaseReady = true;
      return true;
    }

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      return true;
    } catch (error, stackTrace) {
      developer.log(
        'Firebase initialize failed: $error',
        name: 'SSK.Push',
        error: error,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  bool get _isSupportedPlatform {
    if (kIsWeb) {
      return false;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  String get _platformName {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      _ => 'unknown',
    };
  }
}
