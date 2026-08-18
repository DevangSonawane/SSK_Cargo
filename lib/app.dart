import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'core/router/app_router.dart';
import 'core/providers/app_providers.dart';
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
  StreamSubscription<Map<String, dynamic>>? _loginAttemptAlertSubscription;
  bool _showingLoginAttemptAlert = false;
  OverlayEntry? _loginAttemptAlertEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loginAttemptAlertSubscription = ref
        .read(appSocketServiceProvider)
        .loginAttemptAlertStream
        .listen(_handleLoginAttemptAlert);
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

  Future<void> _handleLoginAttemptAlert(Map<String, dynamic> payload) async {
    if (!mounted || _showingLoginAttemptAlert) {
      return;
    }

    _showingLoginAttemptAlert = true;
    try {
      final message = _loginAttemptAlertMessage(payload);
      final navigatorState = ref.read(rootNavigatorKeyProvider).currentState;
      final overlay = navigatorState?.overlay;
      if (overlay == null) {
        return;
      }

      _loginAttemptAlertEntry?.remove();
      _loginAttemptAlertEntry = OverlayEntry(
        builder: (overlayContext) {
          return Material(
            color: Colors.black.withValues(alpha: 0.42),
            child: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF3D6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shield_rounded,
                              color: Color(0xFFE3A008),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Login attempt blocked',
                            textAlign: TextAlign.center,
                            style: Theme.of(overlayContext).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF101828),
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: Theme.of(overlayContext).textTheme.bodyMedium
                                ?.copyWith(
                                  color: const Color(0xFF667085),
                                  height: 1.45,
                                ),
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: () {
                                _loginAttemptAlertEntry?.remove();
                                _loginAttemptAlertEntry = null;
                                _showingLoginAttemptAlert = false;
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF2D6EF2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                'OK',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
      overlay.insert(_loginAttemptAlertEntry!);
    } finally {
      if (_loginAttemptAlertEntry == null) {
        _showingLoginAttemptAlert = false;
      }
    }
  }

  String _loginAttemptAlertMessage(Map<String, dynamic> payload) {
    final message = payload['message']?.toString().trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'null') {
      return message;
    }

    return "Someone just tried to log in to your account from another device. If this wasn't you, please contact support.";
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
    _loginAttemptAlertSubscription?.cancel();
    _loginAttemptAlertEntry?.remove();
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
