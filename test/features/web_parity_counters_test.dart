// Web-parity checks for driver-request counters (DriverRequestCard.jsx /
// JobRequests.jsx): per-side counter cap and the optional `note`.
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

/// Captures the outgoing request instead of hitting the network.
class _Capture extends Interceptor {
  final requests = <RequestOptions>[];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    handler.resolve(
      Response<Map<String, dynamic>>(
        requestOptions: options,
        statusCode: 200,
        data: {'success': true},
      ),
    );
  }
}

BrokerDriverRequest _request({
  required String id,
  int used = 0,
  int max = 0,
}) => BrokerDriverRequest(
  id: id,
  bookingId: 'booking-$id',
  jobRequestId: '',
  bookingNumber: 'BKG-$id',
  pendingConfirmationBy: '',
  clientName: 'Client',
  clientPhone: '',
  driverName: 'Ramesh Patil',
  driverPhone: '',
  brokerName: '',
  brokerPhone: '',
  truckReg: 'MH12 AB 4521',
  truckType: 'Open Body',
  truckCategory: 'LCV',
  pickup: 'Andheri East, Mumbai',
  drop: 'Hinjewadi, Pune',
  weight: '3 tons',
  amount: 18500,
  status: 'pending',
  driverTimedOut: true,
  offerCount: 1,
  isExpress: false,
  requestedAt: null,
  updatedAt: null,
  raw: const {},
  respondentCountersUsed: used,
  maxCountersPerSide: max,
);

void main() {
  group('counter limit (respondentCountersUsed / maxCountersPerSide)', () {
    test('reached only when a positive cap is used up', () {
      expect(_request(id: 'a', used: 2, max: 2).counterLimitReached, isTrue);
      expect(_request(id: 'b', used: 1, max: 2).counterLimitReached, isFalse);
      // Cap missing (0) means unlimited — web treats it as Infinity.
      expect(_request(id: 'c', used: 5).counterLimitReached, isFalse);
    });

    test('parsed from socket/notification payloads (camel + snake)', () {
      final camel = brokerDriverRequestFromNotificationPayload({
        'driver_request_id': 'r1',
        'data': {
          'request': {'respondentCountersUsed': 2, 'maxCountersPerSide': 2},
        },
      });
      expect(camel.counterLimitReached, isTrue);

      final snake = brokerDriverRequestFromNotificationPayload({
        'driver_request_id': 'r2',
        'respondent_counters_used': '1',
        'max_counters_per_side': '2',
      });
      expect(snake.respondentCountersUsed, 1);
      expect(snake.maxCountersPerSide, 2);
      expect(snake.counterLimitReached, isFalse);
    });
  });

  group('counter note is sent like the web', () {
    late _Capture capture;
    late SskApiClient api;

    setUp(() {
      capture = _Capture();
      api = SskApiClient(Dio()..interceptors.add(capture));
    });

    test('driver/broker counter sends trimmed note', () async {
      await api.counterDriverRequestAsDriver(
        accessToken: 't',
        id: 'r1',
        amount: 17000,
        note: '  Toll on this route  ',
      );
      final req = capture.requests.single;
      expect(req.path, '/api/driver-requests/r1/counter');
      expect(req.method, 'PATCH');
      expect(req.data, {'amount': 17000, 'note': 'Toll on this route'});
    });

    test('blank note is omitted (web: note.trim() || undefined)', () async {
      await api.counterDriverRequestAsDriver(
        accessToken: 't',
        id: 'r1',
        amount: 17000,
        note: '   ',
      );
      expect(capture.requests.single.data, {'amount': 17000});
    });

    test('job-request counter sends note too', () async {
      await api.counterJobRequest(
        accessToken: 't',
        id: 'j1',
        amount: 21000,
        note: 'Loading takes 2 hrs',
      );
      final req = capture.requests.single;
      expect(req.path, '/api/jobs/requests/j1/counter');
      expect(req.data, {'amount': 21000, 'note': 'Loading takes 2 hrs'});
    });
  });

  testWidgets('broker card hides Change Fare once the counter cap is used', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1170, 4200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          brokerDriverRequestsProvider.overrideWith(
            (ref, q) async => [
              _request(id: '1', used: 1, max: 2),
              _request(id: '2', used: 2, max: 2),
            ],
          ),
          clientNotificationsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const BrokerDriverRequestsScreen(),
        ),
      ),
    );
    await tester.pump();

    final l10n = lookupAppLocalizations(const Locale('en'));
    // Only the card with a counter left offers Change Fare.
    expect(find.text(l10n.brokerDriverReqChangeFare), findsOneWidget);
    expect(find.text(l10n.counterLimitReachedNotice), findsOneWidget);
    expect(find.text(l10n.brokerDriverReqAccept), findsNWidgets(2));
  });
}
