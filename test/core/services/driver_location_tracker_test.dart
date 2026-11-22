import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gadidost/app.dart';
import 'package:gadidost/core/router/app_router.dart';
import 'package:gadidost/core/providers/app_providers.dart';
import 'package:gadidost/core/providers/driver_tracking_state_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gadidost/core/network/api_client.dart';
import 'package:gadidost/core/providers/driver_location_tracker_provider.dart';
import 'package:gadidost/core/providers/locale_provider.dart';
import 'package:gadidost/core/services/driver_location_tracker.dart';
import 'package:gadidost/features/auth/data/auth_models.dart';
import 'package:gadidost/features/auth/presentation/controllers/auth_controller.dart';

class _LocationPlatform extends GeolocatorPlatform {
  final positions = StreamController<Position>.broadcast();
  final fix = Completer<Position>();
  Completer<LocationPermission>? permissionGate;
  LocationPermission permission = LocationPermission.whileInUse;
  LocationSettings? streamSettings;
  int streamsStarted = 0;
  int permissionRequests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => permission;
  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return permissionGate?.future ?? permission;
  }

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) =>
      fix.future;
  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streamsStarted++;
    streamSettings = locationSettings;
    return positions.stream;
  }
}

class _Api extends SskApiClient {
  _Api() : super(Dio());
  int driverUpdates = 0;
  final tripUpdates = <String>[];

  @override
  Future<Map<String, dynamic>> getUnreadChatCount({
    required String accessToken,
  }) async => {
    'data': {'unreadCount': 0},
  };

  @override
  Future<Map<String, dynamic>> updateDriverLocation({
    required String accessToken,
    required double lat,
    required double lng,
  }) async {
    driverUpdates++;
    return {};
  }

  @override
  Future<Map<String, dynamic>> updateTripLocation({
    required String accessToken,
    required String tripId,
    required double lat,
    required double lng,
  }) async {
    tripUpdates.add(tripId);
    return {};
  }
}

// Set session state without starting push, sockets, or location prefetch.
class _Auth extends AuthController {
  _Auth(super.ref, super.apiClient, AuthSession session) {
    state = AsyncData(session);
  }
}

Position _position() => Position(
  latitude: 19.07,
  longitude: 72.87,
  timestamp: DateTime.now(),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GeolocatorPlatform original;
  late _LocationPlatform platform;
  late _Api api;
  late ProviderContainer container;
  late DriverLocationTracker tracker;

  setUp(() async {
    original = GeolocatorPlatform.instance;
    platform = _LocationPlatform();
    GeolocatorPlatform.instance = platform;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    api = _Api();
    final session = AuthSession.fromLoginResponse({
      'data': {
        'user': {'id': 'driver-1', 'role': 'driver'},
        'tokens': {'access_token': 'test-access'},
      },
    });
    container = ProviderContainer(
      overrides: [
        apiClientProvider.overrideWithValue(api),
        sharedPreferencesProvider.overrideWithValue(preferences),
        authSessionProvider.overrideWith((ref) => _Auth(ref, api, session)),
      ],
    );
    tracker = container.read(driverLocationTrackerProvider);
  });

  tearDown(() async {
    await tracker.stopTracking();
    if (!platform.fix.isCompleted) platform.fix.complete(_position());
    await Future<void>.delayed(Duration.zero);
    await platform.positions.close();
    container.dispose();
    GeolocatorPlatform.instance = original;
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'starts Android foreground stream without waiting for a GPS fix',
    () async {
      expect(await tracker.startTracking(tripId: 'trip-1'), isNull);
      expect(tracker.isRunning, isTrue);
      expect(platform.fix.isCompleted, isFalse);
      final settings = platform.streamSettings! as AndroidSettings;
      expect(settings.foregroundNotificationConfig?.enableWakeLock, isTrue);
      expect(settings.foregroundNotificationConfig?.setOngoing, isTrue);
      platform.positions.add(_position());
      await Future<void>.delayed(Duration.zero);
      expect(api.driverUpdates, 1);
      expect(api.tripUpdates, ['trip-1']);
    },
  );

  test('iOS stream enables background updates and visible indicator', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tracker.startTracking();
    final settings = platform.streamSettings! as AppleSettings;
    expect(settings.allowBackgroundLocationUpdates, isTrue);
    expect(settings.showBackgroundLocationIndicator, isTrue);
    expect(settings.pauseLocationUpdatesAutomatically, isFalse);
  });

  test('concurrent starts share one permission prompt and stream', () async {
    platform.permission = LocationPermission.denied;
    platform.permissionGate = Completer<LocationPermission>();
    final first = tracker.startTracking(tripId: 'old-trip');
    final second = tracker.startTracking(tripId: 'new-trip');
    await Future<void>.delayed(Duration.zero);
    expect(platform.permissionRequests, 1);
    platform.permissionGate!.complete(LocationPermission.whileInUse);
    await Future.wait([first, second]);
    expect(platform.streamsStarted, 1);
    expect(tracker.activeTripId, 'new-trip');
  });

  test(
    'stopping while a permission prompt is open prevents late startup',
    () async {
      platform.permission = LocationPermission.denied;
      platform.permissionGate = Completer<LocationPermission>();
      final start = tracker.startTracking();
      await Future<void>.delayed(Duration.zero);
      await tracker.stopTracking();
      platform.permissionGate!.complete(LocationPermission.whileInUse);
      await start;
      expect(platform.streamsStarted, 0);
      expect(tracker.isRunning, isFalse);
    },
  );

  test('stopped tracker ignores a late GPS fix and stream events', () async {
    await tracker.startTracking(tripId: 'trip-1');
    await tracker.stopTracking();
    platform.fix.complete(_position());
    platform.positions.add(_position());
    await Future<void>.delayed(Duration.zero);
    expect(api.driverUpdates, 0);
    expect(api.tripUpdates, isEmpty);
  });

  test('stream errors clear running state so resume can recover', () async {
    await tracker.startTracking();
    platform.positions.addError(Exception('GPS disabled'));
    await Future<void>.delayed(Duration.zero);
    expect(tracker.isRunning, isFalse);
    await tracker.startTracking();
    expect(platform.streamsStarted, 2);
    expect(tracker.isRunning, isTrue);
  });

  test('denied permission does not start background tracking', () async {
    platform.permission = LocationPermission.deniedForever;
    expect(await tracker.startTracking(), contains('permanently denied'));
    expect(platform.streamsStarted, 0);
  });

  Future<void> showDriverApp(WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = null;
    final router = GoRouter(
      navigatorKey: container.read(rootNavigatorKeyProvider),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('Driver')),
        ),
      ],
    );
    final appContainer = ProviderContainer(
      parent: container,
      overrides: [appRouterProvider.overrideWithValue(router)],
    );
    addTearDown(appContainer.dispose);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: appContainer, child: const SSKApp()),
    );
    await tester.pumpAndSettle();
    addTearDown(router.dispose);
  }

  testWidgets(
    'tracking starts only after disclosure; backgrounding keeps stream',
    (tester) async {
      await showDriverApp(tester);
      expect(find.text('Share driver location'), findsOneWidget);
      expect(platform.streamsStarted, 0);
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      expect(platform.streamsStarted, 1);
      expect(
        container
            .read(sharedPreferencesProvider)
            .getBool('driver_background_location_consent_v1_driver-1'),
        isTrue,
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(tracker.isRunning, isTrue);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(platform.streamsStarted, 1);
      container.read(driverOnlineProvider.notifier).state = false;
      await tester.pumpAndSettle();
      expect(tracker.isRunning, isFalse);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('declining disclosure prevents location access', (tester) async {
    await showDriverApp(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(platform.streamsStarted, 0);
    expect(platform.permissionRequests, 0);
    expect(
      container
          .read(sharedPreferencesProvider)
          .getBool('driver_background_location_consent_v1_driver-1'),
      isNull,
    );
    await tester.pumpWidget(const SizedBox());
  });

  group('web parity: publish throttle + heartbeat', () {
    Position at(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

    test(
      'stationary fixes inside 3s are throttled, 50m move is sent',
      () async {
        await tracker.startTracking(tripId: 'trip-1');
        platform.positions.add(at(19.07, 72.87));
        await Future<void>.delayed(Duration.zero);
        expect(api.driverUpdates, 1);

        // Same spot, immediately again: dropped (< 3s, < 50m).
        platform.positions.add(at(19.07, 72.87));
        await Future<void>.delayed(Duration.zero);
        expect(api.driverUpdates, 1);

        // ~111m north: sent at once even though < 3s passed.
        platform.positions.add(at(19.071, 72.87));
        await Future<void>.delayed(Duration.zero);
        expect(api.driverUpdates, 2);
        expect(api.tripUpdates, ['trip-1', 'trip-1']);
      },
    );

    test('3s floor matches web MIN_INTERVAL_MS', () {
      expect(
        DriverLocationTracker.minPublishInterval,
        const Duration(seconds: 3),
      );
      expect(DriverLocationTracker.minPublishDistanceMeters, 50);
    });

    test('heartbeat re-sends last fix with no new GPS events', () async {
      final previous = DriverLocationTracker.heartbeatInterval;
      DriverLocationTracker.heartbeatInterval = const Duration(
        milliseconds: 40,
      );
      addTearDown(() => DriverLocationTracker.heartbeatInterval = previous);

      await tracker.startTracking(tripId: 'trip-9');
      platform.positions.add(at(19.07, 72.87));
      await Future<void>.delayed(Duration.zero);
      expect(api.driverUpdates, 1);

      // No new positions — only the heartbeat can produce more updates.
      await Future<void>.delayed(const Duration(milliseconds: 130));
      expect(api.driverUpdates, greaterThanOrEqualTo(3));
      expect(api.tripUpdates.every((id) => id == 'trip-9'), isTrue);
      expect(api.tripUpdates.length, api.driverUpdates);

      // Stopping cancels the heartbeat.
      await tracker.stopTracking();
      final afterStop = api.driverUpdates;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(api.driverUpdates, afterStop);
    });

    test('heartbeat sends nothing before the first fix', () async {
      final previous = DriverLocationTracker.heartbeatInterval;
      DriverLocationTracker.heartbeatInterval = const Duration(
        milliseconds: 30,
      );
      addTearDown(() => DriverLocationTracker.heartbeatInterval = previous);

      await tracker.startTracking();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(api.driverUpdates, 0);
    });
  });
}
