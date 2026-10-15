import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/auth_models.dart';

// Inbox providers reload persisted rows; push payloads never become inbox rows.
final notificationRevisionProvider = StateProvider<int>((ref) => 0);

class FcmMessageSource {
  const FcmMessageSource({
    required this.foreground,
    required this.opened,
    required this.initial,
  });

  final Stream<RemoteMessage> foreground;
  final Stream<RemoteMessage> opened;
  final Future<RemoteMessage?> Function() initial;
}

final fcmMessageSourceProvider = Provider<FcmMessageSource>((ref) {
  final supported =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  return supported
      ? FcmMessageSource(
          foreground: FirebaseMessaging.onMessage,
          opened: FirebaseMessaging.onMessageOpenedApp,
          initial: () => FirebaseMessaging.instance.getInitialMessage(),
        )
      : FcmMessageSource(
          foreground: const Stream.empty(),
          opened: const Stream.empty(),
          initial: () async => null,
        );
});

class NotificationIntent {
  NotificationIntent(Map<String, dynamic> payload, {this.messageId})
    : data = {..._map(payload['meta']), ...payload};

  factory NotificationIntent.fromMessage(RemoteMessage message) =>
      NotificationIntent(message.data, messageId: message.messageId);

  final Map<String, dynamic> data;
  final String? messageId;

  String value(String key) {
    final text = data[key]?.toString().trim() ?? '';
    return text == 'null' ? '' : text;
  }

  static const routingKeys = [
    'driver_request_id',
    'job_request_id',
    'trip_id',
    'booking_id',
    'thread_id',
    'incident_id',
    'dispute_id',
  ];

  String? get targetKey {
    for (final key in routingKeys) {
      if (value(key).isNotEmpty) return key;
    }
    return null;
  }

  String get notificationId => value('notification_id');

  String get identity {
    if (notificationId.isNotEmpty) return 'notification:$notificationId';
    if (messageId?.isNotEmpty == true) return 'message:$messageId';
    final keys = data.keys.where((key) => key != 'meta').toList()..sort();
    return jsonEncode({for (final key in keys) key: data[key]});
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

class NotificationDestination {
  const NotificationDestination(this.location, {this.extra});
  final String location;
  final Object? extra;
}

class _PendingTap {
  _PendingTap(this.intent, this.userId);
  final NotificationIntent intent;
  String? userId;
}

/// Owns reception and tap intent lifetime, independently of token registration.
class FcmMessageService {
  FcmMessageService({
    required this.source,
    required this.resolve,
    required this.navigate,
    required this.present,
    required this.notificationsChanged,
  });

  final FcmMessageSource source;
  final Future<NotificationDestination> Function(
    NotificationIntent,
    AuthSession,
  )
  resolve;
  final void Function(NotificationDestination, NotificationIntent) navigate;
  final void Function(RemoteMessage) present;
  final void Function() notificationsChanged;
  final _pending = <_PendingTap>[];
  final _seenTaps = <String>{};
  final _seenForeground = <String>{};
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;
  AuthSession? _session;
  bool _ready = false;
  bool _started = false;
  bool _disposed = false;
  bool _processing = false;
  int _sessionGeneration = 0;

  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;
    _foreground = source.foreground.listen(
      _receiveForeground,
      onError: _logError,
    );
    _opened = source.opened.listen(_receiveTap, onError: _logError);
    try {
      final message = await source.initial();
      if (!_disposed && message != null) _receiveTap(message);
    } catch (error) {
      _logError(error);
    }
  }

  void setSession(AuthSession? session, {required bool navigationReady}) {
    if (_disposed) return;
    if (_session?.user.id != session?.user.id) {
      ++_sessionGeneration;
      _pending.removeWhere(
        (tap) =>
            session != null &&
            tap.userId != null &&
            tap.userId != session.user.id,
      );
    }
    _session = session;
    _ready = navigationReady && session != null;
    unawaited(_drain());
  }

  bool _remember(Set<String> seen, String id) {
    if (!seen.add(id)) return false;
    if (seen.length > 128) seen.remove(seen.first);
    return true;
  }

  void _receiveForeground(RemoteMessage message) {
    if (_disposed || _session == null) return;
    final intent = NotificationIntent.fromMessage(message);
    if (!_remember(_seenForeground, intent.identity)) return;
    notificationsChanged();
    // Always presented — FCM-vs-socket dedup lives in the app layer
    // (RecentAlertDedup), mirroring the web FcmBridge seen-request set.
    present(message);
  }

  void _receiveTap(RemoteMessage message) {
    if (_disposed) return;
    final intent = NotificationIntent.fromMessage(message);
    enqueueIntent(intent);
  }

  /// System-notification (local push) tap while the app is alive.
  /// Same lifetime/queueing as an FCM tray tap.
  void receiveLocalTap(Map<String, dynamic> data) {
    if (_disposed) return;
    enqueueIntent(NotificationIntent(data));
  }

  void enqueueIntent(NotificationIntent intent) {
    if (!_remember(_seenTaps, intent.identity)) return;
    _pending.add(_PendingTap(intent, _session?.user.id));
    if (_pending.length > 32) _pending.removeAt(0);
    unawaited(_drain());
  }

  Future<void> _drain() async {
    if (_processing || _disposed || !_ready || _session == null) return;
    _processing = true;
    try {
      while (!_disposed && _ready && _session != null && _pending.isNotEmpty) {
        final tap = _pending.first;
        final session = _session!;
        tap.userId ??= session.user.id;
        final generation = _sessionGeneration;
        final destination = await resolve(tap.intent, session);
        if (_disposed) return;
        // Authentication may change while resolving models over the network.
        if (generation != _sessionGeneration) {
          if (_session != null && tap.userId != _session!.user.id) {
            _pending.remove(tap);
          }
          continue;
        }
        if (!_ready) return; // Keep the intent until navigation resumes.
        _pending.remove(tap);
        navigate(destination, tap.intent);
        notificationsChanged();
      }
    } catch (error) {
      // Retain pending intent; retry when session/navigation next becomes ready.
      _logError(error);
    } finally {
      _processing = false;
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _pending.clear();
    unawaited(_foreground?.cancel());
    unawaited(_opened?.cancel());
  }

  void _logError(Object error) {
    developer.log(
      'FCM message handling failed (${error.runtimeType})',
      name: 'SSK.Push',
    );
  }
}
