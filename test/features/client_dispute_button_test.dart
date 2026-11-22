import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/theme/app_theme.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gadidost/features/client/presentation/screens/tracking_details_screen.dart';
import 'package:gadidost/features/client/presentation/widgets/client_flow_widgets.dart';
import 'package:gadidost/l10n/app_localizations.dart';

class _Auth extends AuthController {
  _Auth(super.ref, super.apiClient, [AuthSession? session]) {
    state = AsyncData<AuthSession?>(session);
  }
}

/// Fails every API call instantly like an offline phone, so the screen keeps
/// the booking it was opened with.
class _Offline extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );
  }
}

/// Real fonts so text measures like the device (the default test font is
/// wider and would overflow the layout).
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

TrackingDemoShipment ship(String status) => TrackingDemoShipment(
  packageName: 'Steel coils',
  trackingId: 'BKG-2048',
  fromLocation: 'Andheri East, Mumbai',
  toLocation: 'Hinjewadi, Pune',
  status: status,
  customerName: 'Client',
  weight: '3 tons',
  timeline: const [],
  amount: 18500,
  amountPaid: 18500,
  paymentStatus: 'paid',
  bookingId: 'b-2048',
  bookingStatus: status,
  ratingStars: 5,
);

Future<void> pumpShip(
  WidgetTester tester,
  String status, {
  bool signedIn = false,
}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final api = SskApiClient(Dio()..interceptors.add(_Offline()));
  final session = signedIn
      ? AuthSession.fromLoginResponse({
          'data': {
            'user': {'id': 'client-1', 'role': 'client'},
            'tokens': {'access_token': 'test'},
          },
        })
      : null;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authSessionProvider.overrideWith((ref) => _Auth(ref, api, session)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: TrackingDetailsScreen(shipment: ship(status)),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  setUpAll(_loadFonts);
  final l10n = lookupAppLocalizations(const Locale('en'));
  Finder dispute() => find.text(l10n.raiseDispute);

  // Web parity: BookingDetail.jsx isDisputable =
  // !["Requested", "Cancelled"].includes(booking.status).
  for (final status in ['confirmed', 'in_transit', 'delivered', 'completed']) {
    testWidgets('$status booking offers Raise dispute', (tester) async {
      await pumpShip(tester, status);
      await tester.scrollUntilVisible(
        dispute(),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(dispute(), findsOneWidget);
    });
  }

  for (final status in ['pending', 'cancelled']) {
    testWidgets('$status booking hides Raise dispute', (tester) async {
      await pumpShip(tester, status);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -3000));
      await tester.pump();
      expect(dispute(), findsNothing);
    });
  }

  testWidgets('tapping it opens the dispute form', (tester) async {
    await pumpShip(tester, 'delivered', signedIn: true);
    await tester.scrollUntilVisible(
      dispute(),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(dispute());
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text(l10n.disputeDescriptionHint), findsOneWidget);
  });
}
