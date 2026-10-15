import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/services/app_socket_service.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gadidost/features/driver/data/driver_request_models.dart';

Map<String, dynamic> _page(List<Map<String, dynamic>> requests) => {
  'data': {'requests': requests},
};

Map<String, dynamic> _request(String id, {String weight = '5 tons'}) => {
  'id': id,
  'driverId': 'driver-5-ton',
  'weight': weight,
  'status': 'pending',
};

class _Api extends SskApiClient {
  _Api() : super(Dio());
  List<Map<String, dynamic>> eligible = [];
  final pending = <Completer<Map<String, dynamic>>>[];
  bool defer = false;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> getDriverRequests({
    required String accessToken,
    int page = 1,
    int limit = 20,
  }) async {
    calls++;
    if (!defer) return _page(eligible);
    final response = Completer<Map<String, dynamic>>();
    pending.add(response);
    return response.future;
  }
}

class _Socket extends AppSocketService {
  _Socket(super.ref);
  final events = StreamController<Map<String, dynamic>>.broadcast();
  @override
  Stream<Map<String, dynamic>> get driverRequestStream => events.stream;
  @override
  Future<io.Socket?> connect(String accessToken) async => null;
}

class _Auth extends AuthController {
  _Auth(super.ref, super.api) {
    state = AsyncData(
      AuthSession.fromLoginResponse({
        'data': {
          'user': {'id': 'driver-5-ton', 'role': 'driver'},
          'tokens': {'access_token': 'test-token'},
        },
      }),
    );
  }
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Api api;
  late _Socket socket;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<List<DriverRequestItem>>> subscription;

  setUp(() async {
    api = _Api();
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authSessionProvider.overrideWith((ref) => _Auth(ref, api)),
        appSocketServiceProvider.overrideWith((ref) => socket = _Socket(ref)),
      ],
    );
    subscription = container.listen(driverRequestFeedProvider, (_, _) {});
    await _settle();
  });

  tearDown(() async {
    subscription.close();
    container.dispose();
    await socket.events.close();
  });

  test(
    '10-ton socket offer excluded by API never flashes on 5-ton driver',
    () async {
      final observed = <List<DriverRequestItem>>[];
      final listener = container.listen(driverRequestFeedProvider, (_, next) {
        if (next.valueOrNull != null) observed.add(next.valueOrNull!);
      });
      socket.events.add(_request('oversized', weight: '10 tons'));
      await _settle();
      expect(api.calls, 2);
      expect(container.read(driverRequestFeedProvider).requireValue, isEmpty);
      expect(observed.expand((items) => items), isEmpty);
      listener.close();
    },
  );

  test('eligible new socket offer appears after server confirmation', () async {
    api.defer = true;
    socket.events.add(_request('valid'));
    await _settle();
    expect(container.read(driverRequestFeedProvider).requireValue, isEmpty);
    api.pending.single.complete(_page([_request('valid')]));
    await _settle();
    expect(
      container.read(driverRequestFeedProvider).requireValue.single.id,
      'valid',
    );
  });

  test('failed confirmation does not insert a speculative offer', () async {
    api.defer = true;
    socket.events.add(_request('unconfirmed'));
    await _settle();
    api.pending.single.completeError(Exception('Network unavailable'));
    await _settle();
    expect(container.read(driverRequestFeedProvider).requireValue, isEmpty);
  });

  test(
    'older in-flight fetch cannot overwrite a newer confirmed list',
    () async {
      api.defer = true;
      final feed = container.read(driverRequestFeedProvider.notifier);
      final older = feed.refresh();
      final newer = feed.refresh();
      api.pending[1].complete(_page([_request('valid')]));
      await newer;
      api.pending[0].complete(_page([]));
      await older;
      expect(
        container.read(driverRequestFeedProvider).requireValue.single.id,
        'valid',
      );
    },
  );

  test('existing negotiation updates still merge immediately', () async {
    api.eligible = [_request('existing')];
    await container.read(driverRequestFeedProvider.notifier).refresh();
    final callsBefore = api.calls;
    socket.events.add({
      'id': 'existing',
      'status': 'countered',
      'amount': 1500,
    });
    await _settle();
    final item = container.read(driverRequestFeedProvider).requireValue.single;
    expect(item.status, 'countered');
    expect(item.amount, 1500);
    expect(item.weight, '5 tons');
    expect(api.calls, callsBefore);
  });
}
