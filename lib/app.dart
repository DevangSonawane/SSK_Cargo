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
import 'features/part_load/part_load_alert.dart';
import 'features/part_load/part_load_api.dart';
import 'features/part_load/part_load_driver_inbox_screen.dart';
import 'features/part_load/part_load_models.dart';

class SSKApp extends ConsumerStatefulWidget {
  const SSKApp({super.key});

  @override
  ConsumerState<SSKApp> createState() => _SSKAppState();
}

class _SSKAppState extends ConsumerState<SSKApp> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<Map<String, dynamic>>? _loginAttemptAlertSubscription;
  StreamSubscription<Map<String, dynamic>>? _partLoadAlertSubscription;
  Timer? _partLoadPollTimer;
  OverlayEntry? _partLoadAlertEntry;
  StreamSubscription<Map<String, dynamic>>? _chatMessageSubscription;
  StreamSubscription<Map<String, dynamic>>? _chatEscalatedSubscription;
  StreamSubscription<String?>? _unauthorizedSubscription;
  bool _handlingUnauthorized = false;
  bool _showingLoginAttemptAlert = false;
  OverlayEntry? _loginAttemptAlertEntry;

  /// Localizations for code that runs outside a widget `build`. Prefers the
  /// messenger's context (which sits under the localizations delegates) and
  /// falls back to a direct lookup for the current app locale.
  AppLocalizations get _l10n {
    final messengerContext = _messengerKey.currentContext;
    final fromContext = messengerContext == null
        ? null
        : AppLocalizations.of(messengerContext);
    return fromContext ?? lookupAppLocalizations(ref.read(localeProvider));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loginAttemptAlertSubscription = ref
        .read(appSocketServiceProvider)
        .loginAttemptAlertStream
        .listen(_handleLoginAttemptAlert);
    // Part-Load: global incoming-request alert for drivers/brokers — the
    // banner shows above ANY screen (tracking included) so a driving driver
    // never has to go hunting in the inbox tab.
    _partLoadAlertSubscription = ref
        .read(appSocketServiceProvider)
        .tripJoinRequestStream
        .listen(_handlePartLoadEvent);
    // Safety net beneath the socket: a missed push (blip while driving)
    // must never hide a request. Polls quietly; the banner only
    // rebuilds when the queue actually changes.
    _partLoadPollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      unawaited(_pollPartLoadInbox());
    });
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
    final l10n = _l10n;
    final senderFallback = l10n.appChatSupportFallback;
    final text = _chatPreview(payload['message']?.toString() ?? '');
    final title = l10n.appNewMessageFrom(
      payload['senderName']?.toString() ?? senderFallback,
    );
    _showChatMessage(
      title: title,
      message: text,
    );
  }

  void _handleChatEscalated(Map<String, dynamic> payload) {
    _incrementChatUnreadCount(payload);
    final l10n = _l10n;
    final booking = payload['bookingNumber']?.toString();
    final byName = payload['byName']?.toString() ?? l10n.appChatClientFallback;
    final suffix = booking == null || booking.isEmpty
        ? ''
        : l10n.appNewChatBookingSuffix(booking);
    _showChatMessage(
      title: l10n.appNewChatRequestTitle,
      message: '${l10n.appNewChatRequestFrom(byName)}$suffix',
    );
  }

  PartLoadJoinRequest? _parsePartLoadEvent(Map<String, dynamic> payload) {
    Map<String, dynamic> req = payload;
    final data = payload['data'];
    if (data is Map) {
      final m = data.cast<String, dynamic>();
      if (m['request'] is Map) {
        req = (m['request'] as Map).cast<String, dynamic>();
      }
    } else if (payload['request'] is Map) {
      req = (payload['request'] as Map).cast<String, dynamic>();
    }
    try {
      final parsed = PartLoadJoinRequest.fromJson(req);
      return parsed.id.isEmpty ? null : parsed;
    } catch (_) {
      return null;
    }
  }

  void _handlePartLoadEvent(Map<String, dynamic> payload) {
    if (!mounted) return;
    final req = _parsePartLoadEvent(payload);
    if (req == null) return;
    // Drivers and brokers only — the client has its own waiting UI.
    final role =
        (ref.read(authSessionProvider).valueOrNull?.user.role ?? '')
            .trim()
            .toLowerCase();
    if (role != 'driver' && role != 'broker') {
      if (!req.isPending) {
        ref.read(partLoadAlertQueueProvider.notifier).resolve(req.id);
        _refreshPartLoadBanner();
      }
      return;
    }
    if (req.isPending) {
      ref.read(partLoadAlertQueueProvider.notifier).push(req);
      HapticFeedback.heavyImpact();
      _refreshPartLoadBanner();
    } else {
      ref.read(partLoadAlertQueueProvider.notifier).resolve(req.id);
      _refreshPartLoadBanner();
    }
  }

  Future<void> _pollPartLoadInbox() async {
    if (!mounted) return;
    final session = ref.read(authSessionProvider).valueOrNull;
    final role = (session?.user.role ?? '').trim().toLowerCase();
    if (session == null || (role != 'driver' && role != 'broker')) return;
    try {
      final items = await ref
          .read(partLoadApiProvider)
          .listInbox(accessToken: session.tokens.accessToken);
      if (!mounted) return;
      final queue = ref.read(partLoadAlertQueueProvider.notifier);
      final before =
          ref.read(partLoadAlertQueueProvider).queue.map((r) => r.id).toSet();
      final pendingIds = <String>{};
      for (final req in items) {
        if (req.id.isEmpty || !req.isPending) continue;
        pendingIds.add(req.id);
        queue.push(req);
      }
      for (final id in before) {
        if (!pendingIds.contains(id)) queue.resolve(id);
      }
      final after =
          ref.read(partLoadAlertQueueProvider).queue.map((r) => r.id).toSet();
      if (before.length != after.length ||
          !before.containsAll(after) ||
          !after.containsAll(before)) {
        if (after.difference(before).isNotEmpty) {
          HapticFeedback.heavyImpact();
        }
        _refreshPartLoadBanner();
      }
    } catch (_) {
      // Silent — socket and manual refresh still cover it.
    }
  }

  void _refreshPartLoadBanner() {
    if (!mounted) return;
    final navigatorState = ref.read(rootNavigatorKeyProvider).currentState;
    final overlay = navigatorState?.overlay;
    _partLoadAlertEntry?.remove();
    _partLoadAlertEntry = null;
    if (overlay == null) return;
    final queue = ref.read(partLoadAlertQueueProvider).queue;
    if (queue.isEmpty) return;
    final latest = queue.last;
    final extra = queue.length - 1;
    _partLoadAlertEntry = OverlayEntry(
      builder: (overlayContext) {
        // Positioned is mandatory: a bare child gets fullscreen
        // constraints from the overlay Stack and stretches edge to edge.
        return Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: PartLoadAlertBanner(
            request: latest,
            extraCount: extra,
            onView: () {
              ref
                  .read(partLoadAlertQueueProvider.notifier)
                  .dismiss(latest.id);
              _refreshPartLoadBanner();
              ref
                  .read(rootNavigatorKeyProvider)
                  .currentState
                  ?.push(
                    MaterialPageRoute(
                      builder: (_) => const PartLoadDriverInboxScreen(),
                    ),
                  );
            },
            onDismiss: () {
              ref
                  .read(partLoadAlertQueueProvider.notifier)
                  .dismiss(latest.id);
              _refreshPartLoadBanner();
            },
            onExpire: () {
              ref
                  .read(partLoadAlertQueueProvider.notifier)
                  .resolve(latest.id);
              _refreshPartLoadBanner();
            },
          ),
        );
      },
    );
    overlay.insert(_partLoadAlertEntry!);
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
      final message = _loginAttemptAlertMessage(payload, _l10n);

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
    Map<String, dynamic> payload,
    AppLocalizations l10n,
  ) {
    final message = payload['message']?.toString().trim();
    if (message != null &&
        message.isNotEmpty &&
        message.toLowerCase() != 'null') {
      return message;
    }

    return l10n.appLoginAttemptBlockedBody;
  }

  void _showTrackingMessage(String message) {
    final messenger = _messengerKey.currentState;
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: _l10n.appTrackingSettingsAction,
          onPressed: () => Geolocator.openLocationSettings(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _partLoadAlertSubscription?.cancel();
    _partLoadPollTimer?.cancel();
    _partLoadAlertEntry?.remove();
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
      // Different user (login/logout/switch): pending alerts belong to
      // the previous account — clear them and drop the banner.
      ref.read(partLoadAlertQueueProvider.notifier).clear();
      _partLoadAlertEntry?.remove();
      _partLoadAlertEntry = null;
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
