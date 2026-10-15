import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gadidost/features/auth/presentation/screens/delete_account_screen.dart';
import 'package:gadidost/l10n/app_localizations.dart';

AuthSession _session() => AuthSession(
  user: SskUser.fromJson({
    'id': 'user-1',
    'name': 'Driver Test',
    'email': 'driver.test1@gmail.com',
    'phone': '7418529630',
    'role': 'driver',
  }),
  tokens: AuthTokens.fromJson({'access_token': 'access-123'}),
);

class _Auth extends AuthController {
  _Auth(super.ref, super.apiClient) {
    state = AsyncData(_session());
  }
}

class _Api extends SskApiClient {
  _Api() : super(Dio());
  Map<String, dynamic>? posted;
  bool fail = false;

  @override
  Future<Map<String, dynamic>> requestAccountDeletion({
    required String accessToken,
    String? reason,
  }) async {
    posted = {'accessToken': accessToken, 'reason': reason};
    if (fail) throw const ApiException('Already requested', statusCode: 409);
    return {
      'success': true,
      'data': {'id': 'req-1', 'status': 'pending'},
    };
  }
}

Future<void> _pump(
  WidgetTester tester,
  _Api api, {
  AuthSession? session,
}) async {
  final router = GoRouter(
    initialLocation: '/delete-account',
    routes: [
      GoRoute(
        path: '/delete-account',
        builder: (_, _) => const DeleteAccountScreen(),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        authSessionProvider.overrideWith(
          (ref) => _Auth(ref, api)..state = AsyncData(session),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows verified account read-only, confirms, posts, succeeds', (
    tester,
  ) async {
    final api = _Api();
    await _pump(tester, api, session: _session());

    // Verified account details are shown, not editable.
    expect(find.text('Driver Test'), findsOneWidget);
    expect(find.text('driver.test1@gmail.com'), findsOneWidget);
    expect(find.text('7418529630'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // reason only

    // First Delete -> confirm dialog -> second Delete -> POST + success.
    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Delete'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete your account?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(api.posted?['accessToken'], 'access-123');
    expect(find.text('Request submitted'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows inline error when the request fails', (tester) async {
    final api = _Api()..fail = true;
    await _pump(tester, api, session: _session());

    await tester.ensureVisible(
      find.widgetWithText(ElevatedButton, 'Delete'),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Already requested'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
