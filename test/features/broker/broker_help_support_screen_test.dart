import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/providers/locale_provider.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';
import 'package:gadidost/features/broker/presentation/screens/broker_help_support_screen.dart';
import 'package:gadidost/features/broker/presentation/screens/broker_profile_screen.dart';
import 'package:gadidost/l10n/app_localizations.dart';

Map<String, dynamic> _page({
  String content = '<p>Contact our broker team.</p>',
}) => {
  'success': true,
  'data': {
    'page': {'title': 'Broker support contacts', 'content': content},
  },
};

Future<void> _pump(
  WidgetTester tester,
  Future<Map<String, dynamic>> Function() respond,
) async {
  final dio = Dio();
  addTearDown(() => dio.close());
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        expect(options.method, 'GET');
        expect(options.path, '/api/legal-pages/broker/contact_support');
        expect(options.headers['Authorization'], isNull);
        handler.resolve(
          Response(requestOptions: options, data: await respond()),
        );
      },
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [apiClientProvider.overrideWithValue(SskApiClient(dio))],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BrokerHelpSupportScreen(),
      ),
    ),
  );
}

void main() {
  testWidgets('broker profile Help & Support opens the page and back returns', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final dio = Dio();
    final api = SskApiClient(dio);
    addTearDown(() => dio.close());
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) =>
            handler.resolve(Response(requestOptions: options, data: _page())),
      ),
    );
    final router = GoRouter(
      initialLocation: '/broker/profile',
      routes: [
        GoRoute(
          path: '/broker/profile',
          builder: (_, _) => const BrokerProfileScreen(),
        ),
        GoRoute(
          path: '/broker/help-support',
          builder: (_, _) => const BrokerHelpSupportScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiClientProvider.overrideWithValue(api),
          sharedPreferencesProvider.overrideWithValue(preferences),
          authSessionProvider.overrideWith((ref) => AuthController(ref, api)),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Help & Support'), 300);
    await tester.tap(find.text('Help & Support'));
    await tester.pumpAndSettle();
    expect(find.byType(BrokerHelpSupportScreen), findsOneWidget);
    expect(find.text('Broker support contacts'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.byType(BrokerProfileScreen), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/broker/profile');
  });

  testWidgets('loads broker HTML from the public React support endpoint', (
    tester,
  ) async {
    final response = Completer<Map<String, dynamic>>();
    await _pump(tester, () => response.future);
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    response.complete(
      _page(content: '<h2>Trip help</h2><p>Call our team.</p>'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Broker support contacts'), findsOneWidget);
    expect(find.text('Trip help', findRichText: true), findsOneWidget);
    expect(find.text('Call our team.', findRichText: true), findsOneWidget);
  });

  testWidgets('retries a failed API response and renders the recovered page', (
    tester,
  ) async {
    var requests = 0;
    await _pump(tester, () async {
      requests++;
      return requests == 1 ? {'success': false} : _page();
    });
    await tester.pumpAndSettle();
    expect(
      find.textContaining('Could not load support information'),
      findsOneWidget,
    );
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(requests, 2);
    expect(find.text('Broker support contacts'), findsOneWidget);
  });

  testWidgets('missing page offers retry instead of showing blank content', (
    tester,
  ) async {
    await _pump(tester, () async => {'success': true, 'data': {}});
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    expect(find.byType(HtmlWidget), findsNothing);
  });

  testWidgets('empty published content shows coming soon', (tester) async {
    await _pump(tester, () async => _page(content: '  '));
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('launches support contact links and reports launcher failures', (
    tester,
  ) async {
    final launched = <String>[];
    var canLaunch = true;
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      if (call.method == 'launch') {
        launched.add((call.arguments as Map)['url'] as String);
        return canLaunch;
      }
      return false;
    });
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      );
    });
    await _pump(tester, () async => _page());
    await tester.pumpAndSettle();
    final open = tester.widget<HtmlWidget>(find.byType(HtmlWidget)).onTapUrl!;
    for (final url in [
      'tel:+911234567890',
      'mailto:support@example.com',
      'https://example.com/support',
    ]) {
      await open(url);
    }
    expect(launched, [
      'tel:+911234567890',
      'mailto:support@example.com',
      'https://example.com/support',
    ]);
    canLaunch = false;
    await open('tel:+911234567890');
    await tester.pump();
    expect(
      find.text('Could not open this link. Please try again.'),
      findsOneWidget,
    );
  });
}
