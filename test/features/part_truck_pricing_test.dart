// Web parity (BookTruck.jsx): Part Truck bookings are priced through
// POST /api/bookings/quote with truck_category "part", and a booking is never
// created on a missing/stale quote. Drives the real booking screen from item
// details to the Part Truck card and records every request it sends.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/providers/app_providers.dart';
import 'package:gadidost/core/theme/app_theme.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gadidost/features/client/presentation/widgets/client_flow_widgets.dart';
import 'package:gadidost/l10n/app_localizations.dart';

class _Auth extends AuthController {
  _Auth(super.ref, super.apiClient, AuthSession session) {
    state = AsyncData<AuthSession?>(session);
  }
}

/// Fake backend: answers the booking flow's calls, records them all.
class _Backend extends Interceptor {
  _Backend({this.quoteTotal = 5400});

  final double quoteTotal;
  final requests = <RequestOptions>[];

  Iterable<RequestOptions> calls(String method, String path) =>
      requests.where((r) => r.method == method && r.path == path);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    requests.add(options);
    Map<String, dynamic> data = {'success': true, 'data': <String, dynamic>{}};
    if (options.path == '/api/bookings/quote') {
      data = {
        'success': true,
        'data': {'total': quoteTotal},
      };
    } else if (options.path == '/api/bookings' && options.method == 'POST') {
      data = {
        'success': true,
        'data': {
          'booking': {'id': 'b-1', 'booking_number': 'BKG-1'},
        },
      };
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

Future<void> _loadFonts() async {
  final inter = FontLoader('Inter');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    inter.addFont(rootBundle.load('assets/fonts/inter/Inter-$w.ttf'));
  }
  await inter.load();
  final lucide = FontLoader('packages/flutter_lucide/lucide')
    ..addFont(rootBundle.load('packages/flutter_lucide/lib/fonts/lucide.ttf'));
  await lucide.load();
}

Future<_Backend> _pumpToSearchMode(
  WidgetTester tester, {
  double quoteTotal = 5400,
  double startAmount = 0,
  bool partTruck = true,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);

  final backend = _Backend(quoteTotal: quoteTotal);
  final api = SskApiClient(Dio()..interceptors.add(backend));
  final session = AuthSession.fromLoginResponse({
    'data': {
      'user': {'id': 'client-1', 'role': 'client', 'kyc_status': 'verified'},
      'tokens': {'access_token': 'test'},
    },
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authSessionProvider.overrideWith((ref) => _Auth(ref, api, session)),
        // Booking flow hides the bottom nav in initState; start hidden so
        // the test's first mount doesn't trip Riverpod's build-time guard.
        bottomNavVisibleProvider.overrideWith((ref) => false),
      ],
      child: MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        // Opened via Navigator.push like the real app (client_home_screen),
        // not as `home:` — the screen updates a provider in initState.
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => BookingLocationScreen(
                      tripType: TripType.interCity,
                      skipLocationStep: true,
                      initialBookingData: BookingData(
                        from: 'Andheri East, Mumbai',
                        to: 'Hinjewadi, Pune',
                        tripType: TripType.interCity,
                        pickupLat: 19.1136,
                        pickupLng: 72.8697,
                        dropLat: 18.5913,
                        dropLng: 73.7389,
                        pickupPincode: '400069',
                        dropPincode: '411057',
                        distance: 148,
                        amount: startAmount,
                        // Part Truck is chosen on the client home screen, which opens
                        // this screen already in Part mode (as the real app does).
                        searchMode: partTruck
                            ? BookingSearchMode.partLoad
                            : BookingSearchMode.truck,
                        truckCategory: partTruck ? 'part' : '',
                      ),
                    ),
                  ),
                ),
                child: const Text('open-booking'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('open-booking'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  return backend;
}

Future<void> _fillItemDetailsAndContinue(WidgetTester tester) async {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), 'EWB123456789'); // E-Way Bill No.
  await tester.enterText(fields.at(1), '7'); // Material weight
  await tester.pump();
  await tester.tap(find.text(l10n.clientBookingStepNext).last);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 200));
  }
}

void main() {
  setUpAll(_loadFonts);
  final l10n = lookupAppLocalizations(const Locale('en'));

  testWidgets('Part Truck is quoted as "part" and booked at that price', (
    tester,
  ) async {
    final backend = await _pumpToSearchMode(tester, quoteTotal: 5400);
    await _fillItemDetailsAndContinue(tester);
    backend.requests.clear();

    await tester.tap(find.text('Find Part Truck'));
    await _settle(tester);

    final quotes = backend.calls('POST', '/api/bookings/quote').toList();
    expect(quotes, isNotEmpty, reason: 'Part Truck must be priced first');
    final quote = quotes.last.data as Map;
    expect(quote['truck_category'], 'part');
    expect(quote.containsKey('truck_type'), isFalse);
    expect(quote['distance'], 148);

    final creates = backend.calls('POST', '/api/bookings').toList();
    expect(creates, hasLength(1));
    final booking = creates.single.data as Map;
    expect(booking['truck_category'], 'part');
    expect(booking['search_mode'], 'part_load');
    expect(booking['amount'], 5400, reason: 'was ₹0 before the fix');

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('no booking is created when no price comes back', (tester) async {
    final backend = await _pumpToSearchMode(tester, quoteTotal: 0);
    await _fillItemDetailsAndContinue(tester);
    backend.requests.clear();

    await tester.tap(find.text('Find Part Truck'));
    await _settle(tester);

    expect(backend.calls('POST', '/api/bookings/quote'), isNotEmpty);
    expect(backend.calls('POST', '/api/bookings'), isEmpty);
    expect(find.text(l10n.quoteNotReady), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Find Truck re-prices an unquoted amount before booking', (
    tester,
  ) async {
    // Opened with a leftover amount that was never quoted for this route.
    final backend = await _pumpToSearchMode(
      tester,
      quoteTotal: 7200,
      startAmount: 999,
      partTruck: false,
    );
    await _fillItemDetailsAndContinue(tester);
    backend.requests.clear();

    await tester.tap(find.text(l10n.findTruck).last);
    await _settle(tester);

    final quotes = backend.calls('POST', '/api/bookings/quote').toList();
    expect(quotes, hasLength(1));
    expect((quotes.single.data as Map)['truck_category'], isNot('part'));
    final creates = backend.calls('POST', '/api/bookings').toList();
    expect(creates, hasLength(1));
    expect((creates.single.data as Map)['amount'], 7200);

    await tester.pumpWidget(const SizedBox());
  });
}
