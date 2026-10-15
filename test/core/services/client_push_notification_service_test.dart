import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/services/client_push_notification_service.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';

AuthSession session(String user, [String? access]) => AuthSession(
  user: SskUser.fromJson({'id': user}),
  tokens: AuthTokens.fromJson({'access_token': access ?? user}),
);

class _Settings implements NotificationSettings {
  @override
  AuthorizationStatus get authorizationStatus => AuthorizationStatus.authorized;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Messaging implements FirebaseMessaging {
  final changes = StreamController<String>.broadcast(sync: true);
  Future<String?> Function() readToken = () async => 'device';

  @override
  Stream<String> get onTokenRefresh => changes.stream;

  @override
  Future<String?> getToken({
    String? vapidKey,
    String? serviceWorkerScriptPath,
  }) => readToken();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #requestPermission) {
      return Future<NotificationSettings>.value(_Settings());
    }
    return super.noSuchMethod(invocation);
  }
}

class _Api extends SskApiClient {
  _Api() : super(Dio());
  final calls = <String>[];
  Future<void> Function()? beforeRegister;
  bool failDelete = false;

  @override
  Future<Map<String, dynamic>> registerDeviceToken({
    required String accessToken,
    required String token,
    required String platform,
  }) async {
    calls.add('POST $accessToken $token $platform');
    await beforeRegister?.call();
    return {};
  }

  @override
  Future<Map<String, dynamic>> unregisterDeviceToken({
    required String accessToken,
    required String token,
  }) async {
    calls.add('DELETE $accessToken $token');
    if (failDelete) throw const ApiException('offline');
    return {};
  }
}

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late _Api api;
  late _Messaging messaging;
  late ClientPushNotificationService service;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    api = _Api();
    messaging = _Messaging();
    service = ClientPushNotificationService(api, messaging: messaging);
  });

  tearDown(() async {
    service.dispose();
    await service.clearForSession();
    await messaging.changes.close();
    debugDefaultTargetPlatformOverride = null;
  });

  test('registers after session sync and on each token refresh', () async {
    await service.syncForSession(session('A'));
    messaging.changes.add('rotated');
    await flush();
    expect(api.calls, ['POST A device android', 'POST A rotated android']);
    await service.clearForSession();
    expect(api.calls.skip(2), ['DELETE A device', 'DELETE A rotated']);
    expect(messaging.changes.hasListener, isFalse);
  });

  test(
    'token refresh reads current credentials without another permission sync',
    () async {
      await service.syncForSession(session('A', 'old'));
      service.updateSession(session('A', 'fresh'));
      messaging.changes.add('rotated');
      await flush();
      expect(api.calls, [
        'POST old device android',
        'POST fresh rotated android',
      ]);
    },
  );

  test('queued token refresh reads credentials at dispatch time', () async {
    final sent = Completer<void>();
    final finish = Completer<void>();
    api.beforeRegister = () async {
      if (!sent.isCompleted) {
        sent.complete();
        await finish.future;
      }
    };
    final sync = service.syncForSession(session('A', 'old'));
    await sent.future;
    messaging.changes.add('rotated');
    service.updateSession(session('A', 'fresh'));
    finish.complete();
    await sync;
    await flush();
    expect(api.calls, [
      'POST old device android',
      'POST fresh rotated android',
    ]);
  });

  test('late SDK result from previous account cannot register', () async {
    final oldToken = Completer<String?>();
    messaging.readToken = () => oldToken.future;
    final first = service.syncForSession(session('A'));
    await flush();
    messaging.readToken = () async => 'device';
    await service.syncForSession(session('B'));
    oldToken.complete('old-device');
    await first;
    expect(api.calls, ['POST B device android']);
  });

  test(
    'same device is reassigned on account switch after old cleanup',
    () async {
      await service.syncForSession(session('A'));
      await service.syncForSession(session('B'));
      expect(api.calls, [
        'POST A device android',
        'DELETE A device',
        'POST B device android',
      ]);
    },
  );

  test('logout invalidates SDK work still waiting for a token', () async {
    final token = Completer<String?>();
    messaging.readToken = () => token.future;
    final sync = service.syncForSession(session('A'));
    await flush();
    await service.clearForSession();
    token.complete('late');
    await sync;
    messaging.changes.add('also-late');
    await flush();
    expect(api.calls, isEmpty);
  });

  test('in-flight POST is cleaned before next account registers', () async {
    final sent = Completer<void>();
    final finish = Completer<void>();
    api.beforeRegister = () async {
      if (!sent.isCompleted) {
        sent.complete();
        await finish.future;
      }
    };
    final first = service.syncForSession(session('A'));
    await sent.future;
    messaging.changes.add('queued-old-token');
    final logout = service.clearForSession();
    final second = service.syncForSession(session('B'));
    await flush();
    expect(api.calls, ['POST A device android']);
    finish.complete();
    await Future.wait([first, logout, second]);
    expect(api.calls, [
      'POST A device android',
      'DELETE A device',
      'POST B device android',
    ]);
  });

  test('failed registration is retried with refreshed auth', () async {
    api.beforeRegister = () async =>
        throw const ApiException('expired', statusCode: 401);
    await service.syncForSession(session('A', 'old'));
    api.beforeRegister = null;
    await service.syncForSession(session('A', 'fresh'));
    expect(api.calls, ['POST old device android', 'POST fresh device android']);
  });

  test('cleanup failure is non-fatal and does not block new account', () async {
    await service.syncForSession(session('A'));
    api.failDelete = true;
    await service.clearForSession();
    await service.syncForSession(session('B'));
    expect(api.calls.last, 'POST B device android');
  });

  test(
    'dispose cancels listener, cleans up, and prevents further work',
    () async {
      await service.syncForSession(session('A'));
      service.dispose();
      await service.clearForSession();
      await service.syncForSession(session('B'));
      messaging.changes.add('late');
      await flush();
      expect(messaging.changes.hasListener, isFalse);
      expect(api.calls, ['POST A device android', 'DELETE A device']);
    },
  );

  test('newer refresh event wins over delayed getToken result', () async {
    final token = Completer<String?>();
    messaging.readToken = () => token.future;
    final sync = service.syncForSession(session('A'));
    await flush();
    messaging.changes.add('fresh-device');
    token.complete('stale-device');
    await sync;
    await flush();
    expect(api.calls, ['POST A fresh-device android']);
  });
}
