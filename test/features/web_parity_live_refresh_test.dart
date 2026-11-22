// Web-parity checks: upload timeout (services/api.js UPLOAD_TIMEOUT_MS) and
// the safety-net polling on broker lists (DriverRequests.jsx 30s,
// JobRequests.jsx 8s).
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/theme/app_theme.dart';
import 'package:gadidost/features/broker/presentation/screens/broker_driver_requests_screen.dart';
import 'package:gadidost/features/broker/presentation/widgets/broker_flow_widgets.dart';
import 'package:gadidost/features/client/presentation/controllers/client_notifications_controller.dart';
import 'package:gadidost/l10n/app_localizations.dart';

/// Records the timeouts each request actually goes out with.
class _Recorder extends Interceptor {
  final seen = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    seen.add(options);
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      ),
    );
  }
}

void main() {
  group('upload timeout (web UPLOAD_TIMEOUT_MS = 60s)', () {
    late Dio dio;
    late _Recorder recorder;

    setUp(() {
      recorder = _Recorder();
      dio =
          Dio(
              BaseOptions(
                sendTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 30),
              ),
            )
            ..interceptors.add(const UploadTimeoutInterceptor())
            ..interceptors.add(recorder);
    });

    test('multipart uploads get 60s send + receive', () async {
      await dio.post<Map<String, dynamic>>(
        '/api/trips/t1/pod',
        data: FormData.fromMap({'note': 'x'}),
      );
      final req = recorder.seen.single;
      expect(req.sendTimeout, kUploadTimeout);
      expect(req.receiveTimeout, kUploadTimeout);
    });

    test('plain JSON calls keep the 15s/30s defaults', () async {
      await dio.patch<Map<String, dynamic>>(
        '/api/trips/t1/status',
        data: {'status': 'delivered'},
      );
      final req = recorder.seen.single;
      expect(req.sendTimeout, const Duration(seconds: 15));
      expect(req.receiveTimeout, const Duration(seconds: 30));
    });

    test('the app Dio client has the interceptor installed', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        container.read(dioProvider).interceptors,
        contains(isA<UploadTimeoutInterceptor>()),
      );
    });
  });

  testWidgets('broker Driver Requests re-fetches every 30s like the web', (
    tester,
  ) async {
    var fetches = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brokerDriverRequestsProvider.overrideWith((ref, q) async {
            fetches++;
            return const <BrokerDriverRequest>[];
          }),
          clientNotificationsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BrokerDriverRequestsScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(fetches, 1);

    await tester.pump(const Duration(seconds: 29));
    expect(fetches, 1, reason: 'no refresh before the 30s mark');

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    expect(fetches, 2);

    await tester.pump(const Duration(seconds: 30));
    await tester.pump();
    expect(fetches, 3);

    // Leaving the screen stops the poll.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 90));
    expect(fetches, 3);
  });
}
