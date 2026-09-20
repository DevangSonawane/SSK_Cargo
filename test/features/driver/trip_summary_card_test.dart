import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ssk/features/driver/data/driver_dashboard_models.dart';
import 'package:ssk/features/driver/presentation/widgets/trip_summary_card.dart';

DriverTripSummary _fakeTrip({
  String status = 'delivered',
  double amount = 1450,
  String bookingId = 'BK-2481',
}) {
  return DriverTripSummary(
    id: 'trip-1',
    bookingId: bookingId,
    bookingNumber: '2481',
    fromLocation: 'Andheri East, Mumbai',
    toLocation: 'Bandra West, Mumbai',
    distanceKm: 12.5,
    status: status,
    bookingTime: '2026-09-18T10:30:00.000',
    activityTime: null,
    amount: amount,
    driverName: 'Test Driver',
    truckReg: 'MH02AB1234',
  );
}

void main() {
  testWidgets('TripSummaryCard renders route, amount and status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripSummaryCard(trip: _fakeTrip(), onTap: () {}),
        ),
      ),
    );

    expect(find.textContaining('BK-2481'), findsOneWidget);
    expect(find.text('Andheri East'), findsOneWidget);
    expect(find.text('Bandra West'), findsOneWidget);
    expect(find.text('₹1450'), findsOneWidget);
    expect(find.text('Delivered'), findsOneWidget);
    expect(find.textContaining('MH02AB1234'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TripSummaryCard shows pending state for active trips', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripSummaryCard(
            trip: _fakeTrip(status: 'accepted', amount: 900),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('₹900'), findsOneWidget);
    expect(find.text('In Progress'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TripSummaryCard fires onTap', (tester) async {
    var tapped = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TripSummaryCard(
            trip: _fakeTrip(),
            onTap: () => tapped++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TripSummaryCard));
    await tester.pump();

    expect(tapped, 1);
  });
}
