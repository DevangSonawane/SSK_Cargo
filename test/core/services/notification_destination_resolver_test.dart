import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/services/fcm_message_service.dart';
import 'package:gadidost/core/services/notification_destination_resolver.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/broker/presentation/widgets/broker_flow_widgets.dart';
import 'package:gadidost/features/client/data/client_booking_models.dart';
import 'package:gadidost/features/driver/data/driver_request_models.dart';

AuthSession session(String role) => AuthSession(
  user: SskUser.fromJson({'id': 'user', 'role': role}),
  tokens: AuthTokens.fromJson({'access_token': 'access'}),
);

class _Api extends SskApiClient {
  _Api() : super(Dio());
  final calls = <String>[];
  bool fail = false;

  @override
  Future<Map<String, dynamic>> getBookingById({
    required String accessToken,
    required String id,
  }) async {
    calls.add('booking:$id');
    if (fail) throw const ApiException('missing', statusCode: 404);
    return {
      'data': {
        'booking': {'id': id, 'status': 'confirmed'},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getTrip({
    required String accessToken,
    required String tripId,
  }) async {
    calls.add('trip:$tripId');
    return {
      'data': {
        'trip': {'id': tripId, 'booking_id': 'from-trip'},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getDriverRequestById({
    required String accessToken,
    required String id,
  }) async {
    calls.add('driver:$id');
    return {
      'data': {
        'request': {'id': id, 'status': 'pending'},
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getJobRequests({
    required String accessToken,
    int page = 1,
    int limit = 10,
  }) async {
    calls.add('jobs');
    return {
      'data': {
        'requests': [
          {'id': 'job', 'status': 'pending'},
        ],
      },
    };
  }

  @override
  Future<Map<String, dynamic>> getNotifications({
    required String accessToken,
    int limit = 10,
  }) async {
    return {
      'data': {
        'notifications': [
          {
            'id': 'persisted',
            'type': 'booking',
            'meta': {'booking_id': 'stored-booking'},
          },
        ],
      },
    };
  }
}

void main() {
  late _Api api;
  late NotificationDestinationResolver resolver;
  setUp(() {
    api = _Api();
    resolver = NotificationDestinationResolver(api);
  });

  test('metadata IDs win over type and follow the declared priority', () {
    final data = {for (final key in NotificationIntent.routingKeys) key: key};
    for (final key in NotificationIntent.routingKeys) {
      expect(NotificationIntent({'type': 'general', ...data}).targetKey, key);
      data.remove(key);
    }
    expect(NotificationIntent(data).targetKey, isNull);
  });

  test(
    'driver request resolves a real model before opening the card',
    () async {
      final destination = await resolver.resolve(
        NotificationIntent({
          'type': 'chat',
          'driver_request_id': 'request',
          'trip_id': 'trip',
        }),
        session('driver'),
      );
      expect(destination.location, '/driver/request');
      expect((destination.extra as DriverRequestItem).id, 'request');
      expect(api.calls, ['driver:request']);
      expect(
        notificationDestinationIsOpen(
          destination,
          '/driver/request',
          destination.extra,
        ),
        isTrue,
      );
      expect(
        notificationDestinationIsOpen(
          destination,
          '/driver/order-accepted',
          destination.extra,
        ),
        isTrue,
      );
      expect(
        notificationDestinationIsOpen(
          destination,
          '/driver/request',
          DriverRequestItem.fromMap({'id': 'other'}),
        ),
        isFalse,
      );
    },
  );

  test(
    'broker job request resolves through the existing paginated loader',
    () async {
      final destination = await resolver.resolve(
        NotificationIntent({'job_request_id': 'job', 'trip_id': 'trip'}),
        session('broker'),
      );
      expect(destination.location, '/broker/request');
      expect((destination.extra as BookingRequest).id, 'job');
    },
  );

  test('trip wins over booking and thread for a driver', () async {
    final destination = await resolver.resolve(
      NotificationIntent({
        'trip_id': 'trip',
        'booking_id': 'booking',
        'thread_id': 'thread',
      }),
      session('driver'),
    );
    expect(destination.location, '/driver/delivery-details/trip');
    expect(api.calls, isEmpty);
  });

  for (final role in ['broker', 'client']) {
    test('$role trip resolves its booking before opening tracking', () async {
      final destination = await resolver.resolve(
        NotificationIntent({'trip_id': 'trip', 'booking_id': 'wrong-booking'}),
        session(role),
      );
      expect(destination.location, '/$role/tracking/details');
      expect((destination.extra as ClientBooking).id, 'from-trip');
      expect(api.calls, ['trip:trip', 'booking:from-trip']);
    });
  }

  test(
    'booking takes precedence over thread and is fetched for client',
    () async {
      final destination = await resolver.resolve(
        NotificationIntent({'booking_id': 'booking', 'thread_id': 'thread'}),
        session('client'),
      );
      expect(destination.location, '/client/tracking/details');
      expect((destination.extra as ClientBooking).id, 'booking');
    },
  );

  test(
    'thread-only messages use each role\'s supported direct route',
    () async {
      for (final entry in {
        'client': '/chats',
        'driver': '/driver/chats',
        'broker': '/broker/chats',
      }.entries) {
        final destination = await resolver.resolve(
          NotificationIntent({
            'type': 'general',
            'thread_id': 'thread/with slash',
          }),
          session(entry.key),
        );
        expect(
          destination.location,
          '${entry.value}/direct/thread%2Fwith%20slash',
        );
      }
    },
  );

  test('nested persisted metadata and sparse pushes are supported', () async {
    final direct = await resolver.resolve(
      NotificationIntent({
        'meta': {'booking_id': 'nested'},
      }),
      session('driver'),
    );
    expect(direct.location, '/driver/deliveries/nested');
    final sparse = await resolver.resolve(
      NotificationIntent({'notification_id': 'persisted'}),
      session('client'),
    );
    expect((sparse.extra as ClientBooking).id, 'stored-booking');
  });

  test(
    'unknown, incident, dispute, and unavailable targets use history',
    () async {
      for (final data in [
        <String, dynamic>{},
        {'type': 'unknown'},
        {'incident_id': 'incident'},
        {'dispute_id': 'dispute'},
        {'driver_request_id': 'wrong-role'},
      ]) {
        expect(
          (await resolver.resolve(
            NotificationIntent(data),
            session('client'),
          )).location,
          '/client/notifications',
        );
      }
      api.fail = true;
      expect(
        (await resolver.resolve(
          NotificationIntent({'booking_id': 'missing'}),
          session('client'),
        )).location,
        '/client/notifications',
      );
    },
  );
}
