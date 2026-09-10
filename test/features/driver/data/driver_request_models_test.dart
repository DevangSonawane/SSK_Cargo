import 'package:flutter_test/flutter_test.dart';
import 'package:ssk/features/driver/data/driver_request_models.dart';

void main() {
  group('DriverRequestPage', () {
    test(
      'parses React driver request response as swipeable new travel item',
      () {
        final page = DriverRequestPage.fromJson({
          'success': true,
          'message': 'Driver requests fetched',
          'data': {
            'requests': [
              {
                'id': '024d04e3-b6ae-44df-a232-91465200e83f',
                'bookingId': '22473ff6-fbe2-465a-a35e-d1bef506cd64',
                'bookingNumber': 'BKG-202609-046',
                'clientName': 'Devang Sonawane',
                'clientPhone': null,
                'driverId': '679801de-5bdd-4a6f-a637-6443da951cc2',
                'driverName': 'driver test',
                'driverPhone': '9555023235',
                'brokerId': 'a8d69bf6-b59c-4c9e-98bf-d07c80b62cc2',
                'brokerName': 'Test Broker',
                'brokerPhone': '9000000003',
                'truckId': '8a6f0b2c-8d59-4762-803d-f7edffa701a7',
                'truckReg': 'MH-14-CD-5678',
                'truckType': 'Large Truck',
                'truckCategory': 'large',
                'pickup': 'metro station, Kandivali West, Mumbai',
                'drop': 'Kamaraj Nagar, Kandivali West, Mumbai',
                'weight': '1.00 tons',
                'amount': '1339.80',
                'status': 'pending',
                'jobRequestId': null,
                'driverTimedOut': false,
                'pendingConfirmationBy': null,
                'offerHistory': [
                  {
                    'at': '2026-09-10T11:15:27.819Z',
                    'by': 'client',
                    'note': null,
                    'amount': '1339.80',
                  },
                ],
                'createdAt': '2026-09-10T11:15:27.819Z',
                'updatedAt': '2026-09-10T11:15:27.819Z',
              },
            ],
          },
        });

        expect(page.requests, hasLength(1));

        final request = page.requests.single;
        expect(request.displayRef, 'BKG-202609-046');
        expect(request.amount, 1339.80);
        expect(request.pickup, contains('Kandivali'));
        expect(request.drop, contains('Kandivali'));
        expect(request.status, 'pending');
        expect(request.driverTimedOut, isFalse);
        expect(request.isVisibleInNewTravel, isTrue);
        expect(request.canNegotiate, isTrue);
      },
    );

    test('does not mark string false timeout values as timed out', () {
      final request = DriverRequestItem.fromMap({
        'id': 'request-id',
        'status': 'pending',
        'driverTimedOut': 'false',
      });

      expect(request.driverTimedOut, isFalse);
      expect(request.canNegotiate, isTrue);
    });
  });
}
