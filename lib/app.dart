import 'dart:async';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:gadidost/core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:gadidost/l10n/app_localizations.dart';

import 'core/router/app_router.dart';
import 'core/network/api_client.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/app_socket_service.dart';
import 'core/services/fcm_message_service.dart';
import 'core/services/local_push_presenter.dart';
import 'core/services/notification_destination_resolver.dart';
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
  StreamSubscription<Map<String, dynamic>>? _driverRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _jobRequestSubscription;
  StreamSubscription<Map<String, dynamic>>? _tripJoinRequestSubscription;
  StreamSubscription<String?>? _unauthorizedSubscription;
  bool _handlingUnauthorized = false;
  bool _showingLoginAttemptAlert = false;
  Future<bool>? _trackingConsentFuture;
  bool _trackingConsentDeclined = false;
  OverlayEntry? _loginAttemptAlertEntry;
  late final FcmMessageService _pushMessages;
  late final GoRouter _pushRouter;
  late final PushPresenter _pushPresenter;
  final RecentAlertDedup _pushDedup = RecentAlertDedup();
  bool _pushStateScheduled = false;

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
    _pushRouter = ref.read(appRouterProvider);
    _pushPresenter = ref.read(pushPresenterProvider);
    unawaited(_pushPresenter.init(onTap: _handleLocalPushTap));
    _pushMessages = FcmMessageService(
      source: ref.read(fcmMessageSourceProvider),
      resolve: NotificationDestinationResolver(
        ref.read(apiClientProvider),
      ).resolve,
      navigate: _openPushDestination,
      present: _presentForegroundPush,
      notificationsChanged: _refreshNotificationHistory,
    );
    _pushRouter.routerDelegate.addListener(_schedulePushState);
    unawaited(_pushMessages.start());
    _schedulePushState();
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
    // Foreground has no system tray; driver/job pushes are also suppressed
    // in FcmMessageService (socket owns presentation), so toast here on the
    // created event or the user sees nothing until they open the list.
    _driverRequestSubscription = socketService.driverRequestStream.listen(
      _handleNewBookingRequest,
    );
    _jobRequestSubscription = socketService.jobRequestStream.listen(
      _handleNewBookingRequest,
    );
    _tripJoinRequestSubscription = socketService.tripJoinRequestStream.listen(
      _handleNewBookingRequest,
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

  void _refreshNotificationHistory() {
    if (!mounted) return;
    ref.read(notificationRevisionProvider.notifier).state++;
  }

  void _schedulePushState() {
    if (!mounted || _pushStateScheduled) return;
    _pushStateScheduled = true;
    // Login sets auth before its own context.go; wait for that navigation and
    // the navigator's first frame so it cannot overwrite a cold-start tap.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pushStateScheduled = false;
      if (!mounted) return;
      final auth = ref.read(authSessionProvider);
      final path = _pushRouter.state.uri.path;
      final ready =
          !auth.isLoading &&
          !_handlingUnauthorized &&
          !{'/splash', '/login', '/signup'}.contains(path) &&
          ref.read(rootNavigatorKeyProvider).currentState != null &&
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
      _pushMessages.setSession(auth.valueOrNull, navigationReady: ready);
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  /// Foreground FCM -> real system notification (tray/heads-up/banner).
  /// The OS shows nothing on its own while the app is open, so without this
  /// every trip/payment/booking/kyc/dispute/incident push would be invisible
  /// until the user opens the bell. Same-row doubles with the socket channel
  /// are collapsed via [_pushDedup] (web FcmBridge seen-request parity).
  void _presentForegroundPush(RemoteMessage message) {
    if (!mounted) return;
    if (ref.read(authSessionProvider).valueOrNull == null) return;
    final intent = NotificationIntent(message.data);
    if (!_pushDedup.noteShown(pushCorrelationKey(intent.data))) {
      _refreshNotificationHistory();
      return;
    }
    _refreshNotificationHistory();
    final title =
        message.notification?.title ??
        message.data['title']?.toString() ??
        '';
    final body =
        message.notification?.body ?? message.data['body']?.toString() ?? '';
    if (title.isEmpty && body.isEmpty) return;
    unawaited(
      _pushPresenter.showSystem(
        title: title,
        body: body,
        payload: intent.data,
        chat: intent.value('thread_id').isNotEmpty,
      ),
    );
  }

  /// Tap on a system notification shown while the app is alive — same
  /// lifetime/queueing as an FCM tray tap (waits for login + navigation).
  void _handleLocalPushTap(Map<String, dynamic> data) {
    if (!mounted || data.isEmpty) return;
    if (ref.read(authSessionProvider).valueOrNull == null) return;
    _pushMessages.receiveLocalTap(data);
  }

  void _openPushDestination(
    NotificationDestination destination,
    NotificationIntent intent,
  ) {
    if (!mounted) return;
    if (!notificationDestinationIsOpen(
      destination,
      _pushRouter.state.uri.path,
      _pushRouter.state.extra,
    )) {
      unawaited(
        _pushRouter
            .push<void>(destination.location, extra: destination.extra)
            .catchError((Object error) {
              developer.log(
                'Push navigation failed (${error.runtimeType})',
                name: 'SSK.Push',
              );
            }),
      );
    }
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session != null && intent.notificationId.isNotEmpty) {
      unawaited(_markPushRead(intent.notificationId, session));
    }
  }

  Future<void> _markPushRead(String id, AuthSession session) async {
    try {
      await ref
          .read(apiClientProvider)
          .markNotificationRead(
            accessToken: session.tokens.accessToken,
            id: id,
          );
      if (mounted &&
          ref.read(authSessionProvider).valueOrNull?.user.id ==
              session.user.id) {
        _refreshNotificationHistory();
      }
    } catch (error) {
      developer.log(
        'Push mark-read failed (${error.runtimeType})',
        name: 'SSK.Push',
      );
    }
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
    _pushMessages.setSession(
      ref.read(authSessionProvider).valueOrNull,
      navigationReady: false,
    );
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
          SnackBar(content: Text(l10n.appSignedInRetry)),
        );
      }
    } finally {
      _handlingUnauthorized = false;
      _schedulePushState();
    }
  }

  void _handleChatMessage(Map<String, dynamic> payload) {
    _incrementChatUnreadCount(payload);
    final l10n = _l10n;
    final senderFallback = l10n.appChatSupportFallback;
    final text = _chatPreview(payload['message']?.toString() ?? '');
    if (text.isEmpty) return;
    final title = l10n.appNewMessageFrom(
      payload['senderName']?.toString() ?? senderFallback,
    );
    final threadId =
        payload['threadId']?.toString() ??
        payload['thread_id']?.toString() ??
        '';
    final sender =
        payload['senderId']?.toString() ??
        payload['sender_id']?.toString() ??
        '';
    if (!_pushDedup.noteShown(
      'thread:$threadId:$sender:$text'.trim(),
    )) {
      return;
    }
    unawaited(
      _pushPresenter.showSystem(
        title: title,
        body: text,
        payload: {
          if (threadId.trim().isNotEmpty) 'thread_id': threadId.trim(),
          'message': text,
          if (sender.trim().isNotEmpty) 'senderId': sender.trim(),
        },
        chat: true,
      ),
    );
  }

  void _handleNewBookingRequest(Map<String, dynamic> payload) {
    if (!mounted) return;
    if (ref.read(authSessionProvider).valueOrNull == null) return;
    // Server rooms already scope delivery (driver/job rooms, trip parties),
    // so any created/updated event here is meant for this user regardless of
    // role — client haggling, driver offers, broker assignments alike. Shown
    // as a real system notification, deduped against the FCM channel.
    final event = payload['socketEvent']?.toString() ?? '';
    final created =
        event == 'driver-request-created' ||
        event == 'job-request-created' ||
        event == 'trip-join-request-created';
    final updated =
        event == 'driver-request-updated' ||
        event == 'job-request-updated' ||
        event == 'trip-join-request-updated';
    if (!created && !updated) return;
    final booking = payload['bookingNumber']?.toString().trim() ?? '';
    final reference = _requestRef(payload);
    final id = booking.isNotEmpty ? booking : reference;
    if (event.startsWith('trip-join-request')) {
      final joinId = payload['id']?.toString().trim() ?? '';
      final routeData = {
        if (joinId.isNotEmpty) 'trip_join_request_id': joinId,
      };
      if (!_pushDedup.noteShown(pushCorrelationKey(routeData))) {
        _refreshNotificationHistory();
        return;
      }
      _refreshNotificationHistory();
      unawaited(
        _pushPresenter.showSystem(
          title: created ? 'New Trip Request' : 'Trip Request Update',
          body: id.isEmpty ? 'A trip request changed.' : id,
          payload: routeData,
        ),
      );
      return;
    }
    final requestId = payload['id']?.toString().trim() ?? '';
    final routeKey = event.startsWith('job-request')
        ? 'job_request_id'
        : 'driver_request_id';
    final routeData = {
      if (requestId.isNotEmpty) routeKey: requestId,
      if (booking.isNotEmpty) 'booking_id': booking,
    };
    if (!_pushDedup.noteShown(pushCorrelationKey(routeData))) {
      _refreshNotificationHistory();
      return;
    }
    _refreshNotificationHistory();
    if (created) {
      final client = payload['clientName']?.toString().trim() ?? '';
      final amount = payload['amount']?.toString().trim() ?? '';
      final detail = [
        id,
        client,
        amount.isEmpty ? '' : '₹$amount',
      ].where((part) => part.isNotEmpty).join(' · ');
      unawaited(
        _pushPresenter.showSystem(
          title: 'New Booking Request',
          body: detail.isEmpty ? 'A new request arrived.' : detail,
          payload: routeData,
        ),
      );
    } else {
      final status = _requestStatus(payload);
      unawaited(
        _pushPresenter.showSystem(
          title: 'Request $status',
          body: id.isEmpty ? 'A request changed.' : '$id · $status',
          payload: routeData,
        ),
      );
    }
  }

  String _requestRef(Map<String, dynamic> payload) {
    for (final key in [
      'booking_number',
      'bookingId',
      'booking_id',
      'tripId',
      'trip_id',
      'id',
    ]) {
      final value = payload[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  String _requestStatus(Map<String, dynamic> payload) {
    if (payload['driverTimedOut'] == true ||
        payload['driver_timed_out'] == true) {
      return 'Expired';
    }
    final status = (payload['status']?.toString() ?? '').trim().toLowerCase();
    return switch (status) {
      'accepted' || 'confirmed' => 'Accepted',
      'declined' || 'cancelled' || 'canceled' || 'rejected' => 'Declined',
      'expired' || 'timed_out' || 'timeout' => 'Expired',
      '' => 'Updated',
      _ => status.length > 24 ? 'Updated' : 'Updated: $status',
    };
  }

  void _handleChatEscalated(Map<String, dynamic> payload) {
    _incrementChatUnreadCount(payload);
    final l10n = _l10n;
    final booking = payload['bookingNumber']?.toString();
    final byName = payload['byName']?.toString() ?? l10n.appChatClientFallback;
    final suffix = booking == null || booking.isEmpty
        ? ''
        : l10n.appNewChatBookingSuffix(booking);
    final message = '${l10n.appNewChatRequestFrom(byName)}$suffix';
    if (!_pushDedup.noteShown('escalated:$booking:$byName')) return;
    unawaited(
      _pushPresenter.showSystem(
        title: l10n.appNewChatRequestTitle,
        body: message,
        payload: {
          if (booking != null && booking.isNotEmpty) 'booking_id': booking,
          'message': message,
        },
        chat: true,
      ),
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _pushMessages.setSession(
      ref.read(authSessionProvider).valueOrNull,
      navigationReady: false,
    );
    _schedulePushState();
    if (state == AppLifecycleState.resumed) {
      unawaited(_syncDriverTracking());
      unawaited(_refreshChatUnreadCount());
    }
  }

  Future<bool> _ensureTrackingConsent(String userId) async {
    final preferences = ref.read(sharedPreferencesProvider);
    final key = 'driver_background_location_consent_v1_$userId';
    if (preferences.getBool(key) == true) return true;
    if (_trackingConsentDeclined) return false;
    final pending = _trackingConsentFuture;
    if (pending != null) return pending;
    final dialogContext = ref.read(rootNavigatorKeyProvider).currentContext;
    if (dialogContext == null || !dialogContext.mounted) return false;

    final l10n = _l10n;
    final consent =
        showDialog<bool>(
          context: dialogContext,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Text(l10n.driverTrackingDisclosureTitle),
            content: Text(l10n.driverTrackingDisclosureBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.continueAction),
              ),
            ],
          ),
        ).then((accepted) async {
          if (accepted == true) {
            await preferences.setBool(key, true);
            return true;
          }
          // Do not repeatedly prompt after the driver declines. Going online
          // again or signing in again permits a fresh explanation.
          _trackingConsentDeclined = true;
          return false;
        });
    _trackingConsentFuture = consent;
    try {
      return await consent;
    } finally {
      _trackingConsentFuture = null;
    }
  }

  Future<void> _syncDriverTracking() async {
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

    // Native location services must start while an activity is visible.
    // An already-running stream continues when the app is backgrounded.
    if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    if (!await _ensureTrackingConsent(session.user.id) || !mounted) return;
    final currentSession = ref.read(authSessionProvider).valueOrNull;
    if (currentSession?.user.id != session.user.id ||
        currentSession?.user.role.trim().toLowerCase() != 'driver' ||
        !ref.read(driverTrackingEnabledProvider) ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    final currentTrip =
        ref.read(driverTripSessionProvider)?.tripId ??
        ref.read(driverActiveTripIdProvider);
    final message = await tracker.startTracking(tripId: currentTrip);
    if (message != null && mounted) {
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
          onPressed: () async {
            final permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.deniedForever) {
              await Geolocator.openAppSettings();
            } else {
              await Geolocator.openLocationSettings();
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pushRouter.routerDelegate.removeListener(_schedulePushState);
    _pushMessages.dispose();
    _loginAttemptAlertSubscription?.cancel();
    _chatMessageSubscription?.cancel();
    _chatEscalatedSubscription?.cancel();
    _driverRequestSubscription?.cancel();
    _jobRequestSubscription?.cancel();
    _tripJoinRequestSubscription?.cancel();
    _unauthorizedSubscription?.cancel();
    _loginAttemptAlertEntry?.remove();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<AuthSession?>>(authSessionProvider, (previous, next) {
      // Invalidate any model resolution immediately at an auth boundary.
      _pushMessages.setSession(next.valueOrNull, navigationReady: false);
      _schedulePushState();
      final previousSession = previous?.valueOrNull;
      final nextSession = next.valueOrNull;
      if (previousSession?.user.id == nextSession?.user.id) {
        return;
      }
      _trackingConsentDeclined = false;
      unawaited(_syncDriverTracking());
      unawaited(_refreshChatUnreadCount());
    });
    ref.listen<bool>(driverTrackingEnabledProvider, (previous, next) {
      if (next) _trackingConsentDeclined = false;
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
