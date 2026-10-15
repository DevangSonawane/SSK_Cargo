import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/services/local_push_presenter.dart';

void main() {
  test('same request id correlates across FCM and socket payloads', () {
    final fcm = pushCorrelationKey({
      'type': 'booking',
      'notification_id': 'row-1',
      'driver_request_id': 'req-9',
    });
    // The app layer normalises the socket row id to the same meta key before
    // keying, so the second channel stays silent for the same row.
    final socket = pushCorrelationKey({'driver_request_id': 'req-9'});
    expect(socket, 'request:req-9');
    expect(fcm, 'request:req-9');
  });

  test('distinct notification rows never share a key', () {
    final one = pushCorrelationKey({
      'type': 'trip',
      'notification_id': 'row-1',
      'trip_id': 'trip-a',
    });
    final two = pushCorrelationKey({
      'type': 'trip',
      'notification_id': 'row-2',
      'trip_id': 'trip-a',
    });
    expect(one, isNot(two));
  });

  test('dedup shows once per window, then again after expiry', () {
    final dedup = RecentAlertDedup(window: const Duration(seconds: 30));
    final start = DateTime(2026, 10, 15, 12);
    expect(dedup.noteShown('request:req-1', start), isTrue);
    expect(
      dedup.noteShown('request:req-1', start.add(const Duration(seconds: 5))),
      isFalse,
    );
    expect(
      dedup.noteShown('request:req-1', start.add(const Duration(seconds: 31))),
      isTrue,
    );
    expect(dedup.noteShown('request:req-2', start), isTrue);
  });

  test('payload round-trips through encode/decode', () {
    const payload = {'driver_request_id': 'req-9', 'booking_id': 'BKG-1'};
    expect(decodePushPayload(encodePushPayload(payload)), payload);
    expect(decodePushPayload('corrupt{{{'), isEmpty);
    expect(decodePushPayload(null), isEmpty);
  });

  test('local ids are stable and non-negative', () {
    const payload = {'notification_id': 'row-1'};
    expect(pushLocalId(payload), pushLocalId(payload));
    expect(pushLocalId(payload) >= 0, isTrue);
  });
}
