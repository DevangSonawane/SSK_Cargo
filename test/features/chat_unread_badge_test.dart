// Web parity: the chat badge comes from GET /api/chat/unread-count — re-read
// after a thread is marked read, every 20s, and never bumped for the chat
// that's currently open (ChatUnreadContext.jsx / useUnreadChatCount.jsx).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/providers/app_providers.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gadidost/features/chat/data/chat_unread.dart';
import 'package:gadidost/features/chat/presentation/widgets/booking_chat_view.dart';
import 'package:gadidost/l10n/app_localizations.dart';

class _Auth extends AuthController {
  _Auth(super.ref, super.apiClient, AuthSession session) {
    state = AsyncData<AuthSession?>(session);
  }
}

/// Fake chat backend. `unread` is what /unread-count reports; marking the
/// thread read zeroes it, like the real server.
class _ChatBackend extends Interceptor {
  int unread = 3;
  final paths = <String>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    paths.add('${options.method} ${options.path}');
    Map<String, dynamic> data = {'success': true, 'data': <String, dynamic>{}};
    if (options.path == '/api/chat/unread-count') {
      data = {
        'success': true,
        'data': {'unreadCount': unread},
      };
    } else if (options.path == '/api/chat/bookings/b-1/thread') {
      data = {
        'success': true,
        'data': {
          'thread': {'id': 't-1', 'stage': 'human', 'isLocked': false},
        },
      };
    } else if (options.path == '/api/chat/threads/t-1/messages') {
      data = {
        'success': true,
        'data': {'messages': <dynamic>[]},
      };
    } else if (options.path == '/api/chat/threads/t-1/read') {
      unread = 0;
    }
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: data,
      ),
    );
  }
}

AuthSession _session() => AuthSession.fromLoginResponse({
  'data': {
    'user': {'id': 'client-1', 'role': 'client'},
    'tokens': {'access_token': 'test'},
  },
});

void main() {
  test('poll interval matches the web (20s)', () {
    expect(kChatUnreadPollInterval, const Duration(seconds: 20));
  });

  group('ChatUnreadRefresher', () {
    late _ChatBackend backend;
    late ProviderContainer container;

    setUp(() {
      backend = _ChatBackend();
      final api = SskApiClient(Dio()..interceptors.add(backend));
      container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          authSessionProvider.overrideWith(
            (ref) => _Auth(ref, api, _session()),
          ),
        ],
      );
    });
    tearDown(() => container.dispose());

    test('badge is set from the server count, not a local tally', () async {
      container.read(chatUnreadCountProvider.notifier).state = 99;
      await container.read(chatUnreadRefresherProvider).refresh();
      expect(container.read(chatUnreadCountProvider), 3);

      backend.unread = 0;
      await container.read(chatUnreadRefresherProvider).refresh();
      expect(container.read(chatUnreadCountProvider), 0);
    });

    test('messages for the open chat are recognised (never counted)', () {
      final refresher = container.read(chatUnreadRefresherProvider);
      container.read(openChatThreadIdProvider.notifier).state = 't-1';
      expect(refresher.isForOpenThread({'threadId': 't-1'}), isTrue);
      expect(refresher.isForOpenThread({'thread_id': 't-1'}), isTrue);
      expect(refresher.isForOpenThread({'threadId': 't-2'}), isFalse);
      container.read(openChatThreadIdProvider.notifier).state = null;
      expect(refresher.isForOpenThread({'threadId': 't-1'}), isFalse);
    });
  });

  testWidgets('opening a chat marks it read and the badge drops to 0', (
    tester,
  ) async {
    final backend = _ChatBackend();
    final api = SskApiClient(Dio()..interceptors.add(backend));
    final container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authSessionProvider.overrideWith((ref) => _Auth(ref, api, _session())),
        // Socket can't reach anything in tests; keep it local and inert.
        dioProvider.overrideWithValue(
          Dio(BaseOptions(baseUrl: 'http://127.0.0.1:9')),
        ),
      ],
    );
    addTearDown(container.dispose);

    // Badge starts stale (3 unread) — what users saw after reading chats.
    container.read(chatUnreadCountProvider.notifier).state = 3;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BookingChatView(
              bookingId: 'b-1',
              accessToken: 'test',
              currentUserId: 'client-1',
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(backend.paths, contains('PATCH /api/chat/threads/t-1/read'));
    expect(container.read(openChatThreadIdProvider), 't-1');
    expect(container.read(chatUnreadCountProvider), 0);

    // Closing the chat clears the "open chat" marker.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(container.read(openChatThreadIdProvider), isNull);
    // Let the socket library's own retry/close timers run out.
    await tester.pump(const Duration(seconds: 30));
  });
}
