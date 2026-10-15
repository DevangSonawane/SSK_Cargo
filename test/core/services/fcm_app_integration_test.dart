import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gadidost/app.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/providers/app_providers.dart';
import 'package:gadidost/core/providers/locale_provider.dart';
import 'package:gadidost/core/router/app_router.dart';
import 'package:gadidost/core/services/app_socket_service.dart';
import 'package:gadidost/core/services/fcm_message_service.dart';
import 'package:gadidost/core/services/local_push_presenter.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';

class _FakePresenter implements PushPresenter {
  final shown = <Map<String, String>>[];
  int taps = 0;

  @override
  Future<void> init({required void Function(Map<String, dynamic>) onTap}) async {}

  @override
  Future<void> showSystem({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    bool chat = false,
  }) async {
    shown.add({'title': title, 'body': body});
  }
}

class _Api extends SskApiClient {
  _Api() : super(Dio());
  final readIds = <String>[];
  @override
  Future<Map<String, dynamic>> getUnreadChatCount({
    required String accessToken,
  }) async => {
    'data': {'count': 0},
  };
  @override
  Future<Map<String, dynamic>> getNotifications({
    required String accessToken,
    int limit = 10,
  }) async => {
    'data': {'notifications': []},
  };
  @override
  Future<Map<String, dynamic>> markNotificationRead({
    required String accessToken,
    required String id,
  }) async {
    readIds.add(id);
    return {};
  }
}

class _Auth extends AuthController {
  _Auth(super.ref, super.apiClient);
  void signIn() {
    state = AsyncData(
      AuthSession(
        user: SskUser.fromJson({'id': 'A', 'role': 'client'}),
        tokens: AuthTokens.fromJson({'access_token': 'access'}),
      ),
    );
  }
}

class _Socket implements AppSocketService {
  @override
  Stream<Map<String, dynamic>> get loginAttemptAlertStream =>
      const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get chatMessageStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get chatEscalatedStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get driverRequestStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get jobRequestStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get tripJoinRequestStream =>
      const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'cold tap survives login navigation; foreground UI and duplicate taps work',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final key = GlobalKey<NavigatorState>();
      final router = GoRouter(
        navigatorKey: key,
        initialLocation: '/login',
        routes: [
          for (final path in [
            '/login',
            '/client/home',
            '/client/notifications',
          ])
            GoRoute(
              path: path,
              builder: (_, _) => Scaffold(body: Text(path)),
            ),
        ],
      );
      final opened = StreamController<RemoteMessage>.broadcast(sync: true);
      final foreground = StreamController<RemoteMessage>.broadcast(sync: true);
      const initial = RemoteMessage(
        messageId: 'cold',
        data: {'notification_id': 'cold'},
      );
      final api = _Api();
      final presenter = _FakePresenter();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          rootNavigatorKeyProvider.overrideWithValue(key),
          appRouterProvider.overrideWithValue(router),
          apiClientProvider.overrideWithValue(api),
          authSessionProvider.overrideWith((ref) => _Auth(ref, api)),
          appSocketServiceProvider.overrideWithValue(_Socket()),
          pushPresenterProvider.overrideWithValue(presenter),
          fcmMessageSourceProvider.overrideWithValue(
            FcmMessageSource(
              foreground: foreground.stream,
              opened: opened.stream,
              initial: () async => initial,
            ),
          ),
        ],
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const SSKApp()),
      );
      await tester.pumpAndSettle();
      expect(find.text('/login'), findsOneWidget);
      (container.read(authSessionProvider.notifier) as _Auth).signIn();
      await tester.pumpAndSettle();
      expect(find.text('/login'), findsOneWidget);
      router.go('/client/home');
      await tester.pumpAndSettle();
      expect(find.text('/client/notifications'), findsOneWidget);
      expect(api.readIds, ['cold']);
      opened.add(initial);
      await tester.pumpAndSettle();
      expect(api.readIds, ['cold']);
      foreground.add(
        const RemoteMessage(
          messageId: 'foreground',
          data: {'notification_id': 'foreground'},
          notification: RemoteNotification(
            title: 'Push title',
            body: 'Push body',
          ),
        ),
      );
      await tester.pump();
      expect(
        presenter.shown,
        [
          {'title': 'Push title', 'body': 'Push body'},
        ],
      );
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      router.dispose();
      await opened.close();
      await foreground.close();
    },
  );
}
