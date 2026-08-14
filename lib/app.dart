import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'core/router/app_router.dart';
import 'core/providers/driver_location_tracker_provider.dart';
import 'core/providers/driver_tracking_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_models.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';

class SSKApp extends ConsumerStatefulWidget {
  const SSKApp({super.key});

  @override
  ConsumerState<SSKApp> createState() => _SSKAppState();
}

class _SSKAppState extends ConsumerState<SSKApp>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncDriverTracking());
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncDriverTracking(restart: true));
    }
  }

  Future<void> _syncDriverTracking({bool restart = false}) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    final tracker = ref.read(driverLocationTrackerProvider);
    final tripSession = ref.read(driverTripSessionProvider);
    final activeTripId =
        (tripSession?.tripId ?? ref.read(driverActiveTripIdProvider) ?? '')
            .trim();
    final isTrackingEnabled = ref.read(driverTrackingEnabledProvider);

    if (session == null || session.user.role.trim().toLowerCase() != 'driver') {
      await tracker.stopTracking();
      if (ref.read(driverActiveTripIdProvider) != null) {
        ref.read(driverActiveTripIdProvider.notifier).state = null;
      }
      if (ref.read(driverTripSessionProvider) != null) {
        ref.read(driverTripSessionProvider.notifier).state = null;
      }
      return;
    }

    tracker.setActiveTripId(activeTripId);

    if (!isTrackingEnabled) {
      await tracker.stopTracking();
      return;
    }

    final message = restart
        ? await tracker.restartTracking()
        : tracker.isRunning
        ? null
        : await tracker.startTracking(tripId: activeTripId);
    if (message != null) {
      _showTrackingMessage(message);
    }
  }

  void _showTrackingMessage(String message) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: 'Settings',
          onPressed: () => Geolocator.openLocationSettings(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession?>>(
      authSessionProvider,
      (previous, next) {
        final previousSession = previous?.valueOrNull;
        final nextSession = next.valueOrNull;
        if (previousSession?.user.id == nextSession?.user.id) {
          return;
        }
        unawaited(_syncDriverTracking());
      },
    );
    ref.listen<bool>(driverTrackingEnabledProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      unawaited(_syncDriverTracking());
    });
    ref.listen<String?>(driverActiveTripIdProvider, (previous, next) {
      if (previous == next) {
        return;
      }
      final tracker = ref.read(driverLocationTrackerProvider);
      tracker.setActiveTripId(next);
    });
    ref.listen<DriverTripSession?>(
      driverTripSessionProvider,
      (previous, next) {
        if (previous?.tripId == next?.tripId &&
            previous?.status == next?.status &&
            previous?.paymentStatus == next?.paymentStatus &&
            previous?.bookingId == next?.bookingId) {
          return;
        }
        unawaited(_syncDriverTracking());
      },
    );

    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SSK Cargo',
      theme: AppTheme.light,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
    );
  }
}
