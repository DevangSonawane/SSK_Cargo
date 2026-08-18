import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'core/router/app_router.dart';
import 'core/services/app_socket_service.dart';
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

class _SSKAppState extends ConsumerState<SSKApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<Map<String, dynamic>>? _sessionTerminatedSubscription;
  bool _handlingSessionTermination = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionTerminatedSubscription = ref
        .read(appSocketServiceProvider)
        .sessionTerminatedStream
        .listen(_handleSessionTerminated);
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

  Future<void> _handleSessionTerminated(Map<String, dynamic> payload) async {
    if (!mounted || _handlingSessionTermination) {
      return;
    }

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      return;
    }

    _handlingSessionTermination = true;
    try {
      final message = _sessionTerminationMessage(payload);
      final loginRoute = switch (session.user.role.trim().toLowerCase()) {
        'driver' => '/driver/login',
        'broker' => '/broker/login',
        _ => '/login',
      };

      await ref.read(authSessionProvider.notifier).forceLocalLogout();

      final messenger = _messengerKey.currentState;
      messenger?.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFFE23A4B),
          duration: const Duration(seconds: 4),
        ),
      );

      if (mounted) {
        ref.read(appRouterProvider).go(loginRoute);
      }
    } finally {
      _handlingSessionTermination = false;
    }
  }

  String _sessionTerminationMessage(Map<String, dynamic> payload) {
    final message = payload['message']?.toString().trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'null') {
      return message;
    }

    return 'Your account was used to log in on another device. You have been logged out here.';
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
    _sessionTerminatedSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession?>>(authSessionProvider, (previous, next) {
      final previousSession = previous?.valueOrNull;
      final nextSession = next.valueOrNull;
      if (previousSession?.user.id == nextSession?.user.id) {
        return;
      }
      unawaited(_syncDriverTracking());
    });
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
    ref.listen<DriverTripSession?>(driverTripSessionProvider, (previous, next) {
      if (previous?.tripId == next?.tripId &&
          previous?.status == next?.status &&
          previous?.paymentStatus == next?.paymentStatus &&
          previous?.bookingId == next?.bookingId) {
        return;
      }
      unawaited(_syncDriverTracking());
    });

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
