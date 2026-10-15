import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/services/fcm_message_service.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';

AuthSession session([String user = 'A']) => AuthSession(
  user: SskUser.fromJson({'id': user, 'role': 'client'}),
  tokens: AuthTokens.fromJson({'access_token': 'access'}),
);

RemoteMessage message(String id, [Map<String, dynamic> data = const {}]) =>
    RemoteMessage(
      messageId: id,
      data: {'notification_id': id, ...data},
      notification: const RemoteNotification(title: 'Update', body: 'Body'),
    );

Future<void> flush() => Future<void>.delayed(Duration.zero);

void main() {
  late StreamController<RemoteMessage> foreground;
  late StreamController<RemoteMessage> opened;
  late FcmMessageService service;
  late List<String> navigated;
  late List<String?> presented;
  late int revisions;
  RemoteMessage? initial;
  Future<NotificationDestination> Function(NotificationIntent, AuthSession)?
  resolve;

  setUp(() {
    foreground = StreamController.broadcast(sync: true);
    opened = StreamController.broadcast(sync: true);
    navigated = [];
    presented = [];
    revisions = 0;
    initial = null;
    resolve = null;
    service = FcmMessageService(
      source: FcmMessageSource(
        foreground: foreground.stream,
        opened: opened.stream,
        initial: () async => initial,
      ),
      resolve: (intent, auth) =>
          resolve?.call(intent, auth) ??
          Future.value(const NotificationDestination('/client/notifications')),
      navigate: (destination, intent) => navigated.add(intent.notificationId),
      present: (message) => presented.add(message.messageId),
      notificationsChanged: () => revisions++,
    );
  });

  tearDown(() async {
    service.dispose();
    await foreground.close();
    await opened.close();
  });

  test(
    'foreground refreshes history and presents once without navigating',
    () async {
      service.setSession(session(), navigationReady: true);
      await service.start();
      foreground.add(message('one'));
      foreground.add(message('one'));
      expect(presented, ['one']);
      expect(revisions, 1);
      expect(navigated, isEmpty);
    },
  );

  test(
    'foreground presents every push once — FCM-vs-socket dedup lives in the app layer',
    () async {
      service.setSession(session(), navigationReady: true);
      await service.start();
      foreground.add(message('chat', {'thread_id': 'thread'}));
      foreground.add(message('request', {'driver_request_id': 'request'}));
      foreground.add(message('job', {'job_request_id': 'job'}));
      foreground.add(message('job', {'job_request_id': 'job'}));
      expect(presented, ['chat', 'request', 'job']);
      expect(revisions, 3);
    },
  );

  test('background tap navigates exactly once', () async {
    service.setSession(session(), navigationReady: true);
    await service.start();
    opened.add(message('one'));
    opened.add(message('one'));
    await flush();
    expect(navigated, ['one']);
  });

  test(
    'terminated initial tap waits for both login and navigation readiness',
    () async {
      initial = message('cold');
      await service.start();
      expect(navigated, isEmpty);
      service.setSession(session(), navigationReady: false);
      await flush();
      expect(navigated, isEmpty);
      service.setSession(session(), navigationReady: true);
      await flush();
      expect(navigated, ['cold']);
      opened.add(message('cold'));
      await flush();
      expect(navigated, ['cold']);
    },
  );

  test('foreground delivery does not consume subsequent tap', () async {
    service.setSession(session(), navigationReady: true);
    await service.start();
    foreground.add(message('one'));
    opened.add(message('one'));
    await flush();
    expect(presented, ['one']);
    expect(navigated, ['one']);
  });

  test('in-flight resolution cannot navigate into another account', () async {
    final result = Completer<NotificationDestination>();
    resolve = (_, _) => result.future;
    service.setSession(session(), navigationReady: true);
    await service.start();
    opened.add(message('old'));
    service.setSession(session('B'), navigationReady: true);
    result.complete(const NotificationDestination('/client/notifications'));
    await flush();
    expect(navigated, isEmpty);
    resolve = null;
    opened.add(message('new'));
    await flush();
    expect(navigated, ['new']);
  });

  test(
    'tap survives interrupted navigation and same-user reauthentication',
    () async {
      final result = Completer<NotificationDestination>();
      resolve = (_, _) => result.future;
      service.setSession(session(), navigationReady: true);
      await service.start();
      opened.add(message('one'));
      service.setSession(null, navigationReady: false);
      result.complete(const NotificationDestination('/client/notifications'));
      await flush();
      expect(navigated, isEmpty);
      resolve = null;
      service.setSession(session(), navigationReady: true);
      await flush();
      expect(navigated, ['one']);
    },
  );

  test(
    'initial-message failure is non-fatal and opened listener remains usable',
    () async {
      service.dispose();
      service = FcmMessageService(
        source: FcmMessageSource(
          foreground: foreground.stream,
          opened: opened.stream,
          initial: () async => throw StateError('unavailable'),
        ),
        resolve: (_, _) async =>
            const NotificationDestination('/client/notifications'),
        navigate: (_, intent) => navigated.add(intent.notificationId),
        present: (_) {},
        notificationsChanged: () {},
      );
      service.setSession(session(), navigationReady: true);
      await service.start();
      opened.add(message('one'));
      await flush();
      expect(navigated, ['one']);
    },
  );

  test(
    'dispose cancels reception and ignores delayed initial notification',
    () async {
      final initialResult = Completer<RemoteMessage?>();
      service.dispose();
      service = FcmMessageService(
        source: FcmMessageSource(
          foreground: foreground.stream,
          opened: opened.stream,
          initial: () => initialResult.future,
        ),
        resolve: (_, _) async =>
            const NotificationDestination('/client/notifications'),
        navigate: (_, intent) => navigated.add(intent.notificationId),
        present: (_) => presented.add('unexpected'),
        notificationsChanged: () {},
      );
      service.setSession(session(), navigationReady: true);
      final started = service.start();
      service.dispose();
      initialResult.complete(message('late'));
      await started;
      foreground.add(message('late'));
      expect(navigated, isEmpty);
      expect(presented, isEmpty);
      expect(opened.hasListener, isFalse);
    },
  );
}
