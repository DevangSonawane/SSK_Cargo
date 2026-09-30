import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ssk/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ssk/l10n/app_localizations.dart';

import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/app_socket_service.dart';
import 'core/providers/driver_location_tracker_provider.dart';
import 'core/providers/driver_tracking_state_provider.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_models.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/session_expired_sheet.dart';

class SSKApp extends ConsumerStatefulWidget {
  const SSKApp({super.key});

  @override
  ConsumerState<SSKApp> createState() => _SSKAppState();
}

class _SSKAppState extends ConsumerState<SSKApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<Map<String, dynamic>>? _loginAttemptAlertSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatEscalatedSubscription;
  StreamSubscription<String?>? _unauthorizedSubscription;
  bool _handlingUnauthorized = false;
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
    final socketService = ref.read(appSocketServiceProvider);
    _chatMessageSubscription = socketService.chatMessageStream.listen(
      _handleChatMessage,
    );
    _chatEscalatedSubscription = socketService.chatEscalatedStream.listen(
      _handleChatEscalated,
    );
    // Any authenticated call coming back 401 means the session died
    // server-side (admin/broker reset, all-devices logout, expiry).
    _unauthorizedSubscription = unauthorizedStream.listen((message) {
      unawaited(_handleUnauthorized(message));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_syncDriverTracking());
      unawaited(_refreshChatUnreadCount());
    });
  }

  Future<void> _refreshChatUnreadCount() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      ref.read(chatUnreadCountProvider.notifier).state = 0;
      return;
    }
    try {
      final response = await ref
          .read(apiClientProvider)
          .getUnreadChatCount(accessToken: session.tokens.accessToken);
      final data = response['data'];
      final rawCount = data is Map
          ? data['unreadCount'] ?? data['count']
          : null;
      final count = rawCount is num
          ? rawCount.toInt()
          : int.tryParse(rawCount?.toString() ?? '') ?? 0;
      if (mounted) {
        ref.read(chatUnreadCountProvider.notifier).state = count;
      }
    } catch (_) {
      // Chat badges are best-effort and should not interrupt app startup.
    }
  }

  Future<void> _handleUnauthorized(String? serverMessage) async {
    if (!mounted || _handlingUnauthorized) return;
    // No session (or already logged out): nothing to do, and this also
    // stops loops from in-flight calls racing the logout.
    if (ref.read(authSessionProvider).valueOrNull == null) return;
    _handlingUnauthorized = true;
    try {
      // Web parity (SessionExpiredModal): the access token expiring is
      // routine — silently refresh first and keep the user exactly where
      // they are (socket reconnects on the fresh token inside refreshTokens).
      final refreshed = await ref
          .read(authSessionProvider.notifier)
          .refreshTokens();
      if (refreshed) return;
      // Only the real "session expired" case pops the inline re-login sheet
      // over the current page — deliberately no logout/redirect, so the
      // user never loses their place.
      final navigatorContext = ref
          .read(rootNavigatorKeyProvider)
          .currentContext;
      if (navigatorContext == null || !navigatorContext.mounted) return;
      final signedIn = await showSessionExpiredSheet(
        navigatorContext,
        message: serverMessage,
      );
      if (signedIn && mounted && navigatorContext.mounted) {
        final l10n = AppLocalizations.of(navigatorContext)!;
        _messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(l10n.appSignedInRetry),
          ),
        );
      }
    } finally {
      _handlingUnauthorized = false;
    }
  }

  void _handleChatMessage(Map<String, dynamic> payload) {
    _incrementChatUnreadCount(payload);
    final messengerContext = _messengerKey.currentContext;
    final l10n = messengerContext == null
        ? null
        : AppLocalizations.of(messengerContext);
    final senderFallback = l10n?.appChatSupportFallback ?? 'Support';
    final text = _chatPreview(payload['message']?.toString() ?? '');
    final title = l10n == null
        ? 'New message from ${payload['senderName']?.toString() ?? senderFallback}'
        : l10n.appNewMessageFrom(
            payload['senderName']?.toString() ?? senderFallback,
          );
    _showChatMessage(
      title: title,
      message: text,
    );
  }

  void _handleChatEscalated(Map<String, dynamic> payload) {
    _incrementChatUnreadCount(payload);
    final messengerContext = _messengerKey.currentContext;
    final l10n = messengerContext == null
        ? null
        : AppLocalizations.of(messengerContext);
    final booking = payload['bookingNumber']?.toString();
    final byFallback = l10n?.appChatClientFallback ?? 'a client';
    final byName = payload['byName']?.toString() ?? byFallback;
    if (l10n == null) {
      final suffix = booking == null || booking.isEmpty
          ? ''
          : ' - Booking #$booking';
      _showChatMessage(
        title: 'New chat request',
        message: 'New chat request from $byName$suffix',
      );
      return;
    }
    final suffix = booking == null || booking.isEmpty
        ? ''
        : l10n.appNewChatBookingSuffix(booking);
    _showChatMessage(
      title: l10n.appNewChatRequestTitle,
      message: '${l10n.appNewChatRequestFrom(byName)}$suffix',
    );
  }

  void _incrementChatUnreadCount(Map<String, dynamic> payload) {
    final session = ref.read(authSessionProvider).valueOrNull;
    final senderId = payload['senderId']?.toString();
    if (session != null && senderId == session.user.id) return;
    final current = ref.read(chatUnreadCountProvider);
    ref.read(chatUnreadCountProvider.notifier).state = current + 1;
  }

  String _chatPreview(String text) {
    final normalized = text.trim();
    if (normalized.length <= 80) return normalized;
    return '${normalized.substring(0, 80)}...';
  }

  void _showChatMessage({required String title, required String message}) {
    if (!mounted || message.isEmpty) return;
    _messengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncDriverTracking(restart: true));
      unawaited(_refreshChatUnreadCount());
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
      final navigatorState = ref.read(rootNavigatorKeyProvider).currentState;
      final overlay = navigatorState?.overlay;
      if (overlay == null) {
        return;
      }
      final overlayContext = navigatorState?.context;
      final l10n = overlayContext == null
          ? null
          : AppLocalizations.of(overlayContext);
      final message = _loginAttemptAlertMessage(payload, l10n);

      _loginAttemptAlertEntry?.remove();
      _loginAttemptAlertEntry = OverlayEntry(
        builder: (overlayContext) {
          final dialogL10n = AppLocalizations.of(overlayContext)!;
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
                              AppIcons.shield_rounded,
                              color: Color(0xFFE3A008),
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            dialogL10n.appLoginAttemptBlockedTitle,
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
                              child: Text(
                                dialogL10n.appOkButton,
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

  String _loginAttemptAlertMessage(
      Map<String, dynamic> payload, AppLocalizations? l10n) {
    final message = payload['message']?.toString().trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'null') {
      return message;
    }

    return l10n?.appLoginAttemptBlockedBody ??
        "Someone just tried to log in to your account from another device. If this wasn't you, please contact support.";
  }

  void _showTrackingMessage(String message) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    final actionLabel = messenger.context.mounted
        ? AppLocalizations.of(messenger.context)?.appTrackingSettingsAction ??
            'Settings'
        : 'Settings';
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: actionLabel,
          onPressed: () => Geolocator.openLocationSettings(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loginAttemptAlertSubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _chatEscalatedSubscription?.cancel();
    _unauthorizedSubscription?.cancel();
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
      unawaited(_refreshChatUnreadCount());
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
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'SSK Cargo',
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      scaffoldMessengerKey: _messengerKey,
      routerConfig: router,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final systemBars = SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarContrastEnforced: false,
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: systemBars,
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
