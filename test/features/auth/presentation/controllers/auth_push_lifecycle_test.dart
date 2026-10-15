import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/services/app_socket_service.dart';
import 'package:gadidost/core/services/client_push_notification_service.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';

Map<String, dynamic> response(String access) => {
  'data': {
    'user': {'id': 'A', 'role': 'driver'},
    'tokens': {'access_token': access, 'refresh_token': 'refresh'},
  },
};

class _Api extends SskApiClient {
  _Api() : super(Dio());
  Completer<Map<String, dynamic>>? pendingRefresh;
  Completer<Map<String, dynamic>>? pendingLogin;

  @override
  Future<Map<String, dynamic>> refreshSession({required String refreshToken}) =>
      pendingRefresh?.future ?? Future.value(response('fresh'));

  @override
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) => pendingLogin?.future ?? Future.value(response('login'));

  @override
  Future<Map<String, dynamic>> logout({
    required String refreshToken,
    bool allDevices = false,
  }) async => {};
}

class _Push extends ClientPushNotificationService {
  _Push(super.apiClient);
  final calls = <String>[];

  @override
  void updateSession(AuthSession session) {
    calls.add('update ${session.tokens.accessToken}');
  }

  @override
  Future<void> syncForSession(AuthSession session) async {
    calls.add('sync ${session.tokens.accessToken}');
  }

  @override
  Future<void> clearForSession() async {
    calls.add('clear');
  }
}

class _Socket implements AppSocketService {
  @override
  Future<io.Socket?> connect(String accessToken) async => null;
  @override
  Future<io.Socket?> ensureConnected({required String accessToken}) async =>
      null;
  @override
  void reset() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _Api api;
  late _Push push;
  late ProviderContainer container;
  late AuthController auth;

  setUp(() {
    api = _Api();
    push = _Push(api);
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        clientPushNotificationServiceProvider.overrideWithValue(push),
        appSocketServiceProvider.overrideWithValue(_Socket()),
      ],
    );
    auth = container.read(authSessionProvider.notifier);
    auth.bootstrapSession(AuthSession.fromLoginResponse(response('old')));
  });

  tearDown(() => container.dispose());

  test('successful refresh supplies new credentials to push service', () async {
    expect(await auth.refreshTokens(), isTrue);
    expect(push.calls, ['sync old', 'update fresh']);
  });

  test('normal logout clears push state', () async {
    await auth.logout();
    expect(push.calls, ['sync old', 'clear']);
    expect(auth.session, isNull);
  });

  test('forced local logout clears push state', () async {
    await auth.forceLocalLogout();
    expect(push.calls, ['sync old', 'clear']);
    expect(auth.session, isNull);
  });

  test('late auth refresh cannot restore a logged-out push session', () async {
    api.pendingRefresh = Completer<Map<String, dynamic>>();
    final refresh = auth.refreshTokens();
    await auth.forceLocalLogout();
    api.pendingRefresh!.complete(response('late'));
    expect(await refresh, isFalse);
    expect(auth.session, isNull);
    expect(push.calls, ['sync old', 'clear']);
  });

  test('late login cannot register after logout', () async {
    api.pendingLogin = Completer<Map<String, dynamic>>();
    final login = auth.login(email: 'example', password: 'example');
    final assertion = expectLater(login, throwsStateError);
    await auth.forceLocalLogout();
    api.pendingLogin!.complete(response('late'));
    await assertion;
    expect(auth.session, isNull);
    expect(push.calls, ['sync old', 'clear', 'clear']);
  });

  test('auth provider disposal clears push state', () {
    container.invalidate(authSessionProvider);
    expect(push.calls, ['sync old', 'clear']);
  });
}
