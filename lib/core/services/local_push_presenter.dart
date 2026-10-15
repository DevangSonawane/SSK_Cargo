import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Foreground system notifications (tray / heads-up / banner), not SnackBars.
///
/// Background/killed pushes are shown by the OS itself from the FCM
/// `notification` block with zero app code. In the foreground the OS shows
/// nothing, so every alert below is rendered here as a real local
/// notification instead: FCM-owned pushes (trip, payment, booking, kyc,
/// dispute, incident, general) and socket-owned pushes (negotiation, chat,
/// part-load joins — the web apps' toast+modal parity).
///
/// FCM-vs-socket doubles are collapsed by [RecentAlertDedup]: both channels
/// describe the same server-side row within seconds of each other, so the
/// second presentation of the same correlation key inside a short window is
/// dropped. Distinct rows always have distinct keys and all show.

const String pushChannelId = 'ssk_updates';
const String pushChannelName = 'Booking & trip updates';
const String chatChannelId = 'ssk_chat';
const String chatChannelName = 'Messages';

/// Short-lived "already showed this" memory shared by both push channels.
class RecentAlertDedup {
  RecentAlertDedup({Duration window = const Duration(seconds: 30)})
    : _window = window;

  final Duration _window;
  final Map<String, DateTime> _shownAt = {};

  /// Returns true when [key] may be presented (first time, or the window
  /// expired). Returns false when the same key was presented recently.
  bool noteShown(String key, [DateTime? now]) {
    final at = now ?? DateTime.now();
    _shownAt.removeWhere((_, time) => at.difference(time) > _window);
    if (_shownAt.containsKey(key)) return false;
    _shownAt[key] = at;
    if (_shownAt.length > 256) _shownAt.remove(_shownAt.keys.first);
    return true;
  }
}

/// Correlation key shared by the FCM and socket paths for the same event.
/// Same row/event -> same key (deduped); different rows -> different keys.
String pushCorrelationKey(Map<String, dynamic> data) {
  for (final key in [
    'driver_request_id',
    'job_request_id',
    'trip_join_request_id',
    'join_request_id',
  ]) {
    final value = data[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && value.toLowerCase() != 'null') {
      return 'request:$value';
    }
  }
  final thread = data['thread_id']?.toString().trim() ?? '';
  if (thread.isNotEmpty && thread.toLowerCase() != 'null') {
    final message = data['message']?.toString().trim() ?? '';
    final sender = (
      data['senderId'] ?? data['sender_id'] ?? data['senderName'] ?? '',
    ).toString().trim();
    return 'thread:$thread:$sender:$message'.trim();
  }
  final notificationId = data['notification_id']?.toString().trim() ?? '';
  if (notificationId.isNotEmpty) return 'notification:$notificationId';
  final messageId = data['message_id']?.toString().trim() ?? '';
  if (messageId.isNotEmpty) return 'message:$messageId';
  return 'payload:${jsonEncode(data).hashCode}';
}

/// Stable Android notification id so a re-shown row replaces itself.
int pushLocalId(Map<String, dynamic> data) =>
    pushCorrelationKey(data).hashCode & 0x7fffffff;

String encodePushPayload(Map<String, dynamic> data) {
  final flat = <String, String>{};
  data.forEach((key, value) {
    if (value == null) return;
    final text = value.toString();
    if (text.isEmpty || text == 'null') return;
    flat[key] = text.length > 1500 ? text.substring(0, 1500) : text;
  });
  return jsonEncode(flat);
}

Map<String, dynamic> decodePushPayload(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    // Corrupt payload — fall back to notification history.
  }
  return {};
}

/// Interface so widget tests can substitute a recording fake.
abstract class PushPresenter {
  Future<void> init({required void Function(Map<String, dynamic>) onTap});
  Future<void> showSystem({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    bool chat = false,
  });
}

class LocalPushPresenter implements PushPresenter {
  LocalPushPresenter([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  @override
  Future<void> init({required void Function(Map<String, dynamic>) onTap}) async {
    try {
      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          onTap(decodePushPayload(response.payload));
        },
      );
      const updates = AndroidNotificationChannel(
        pushChannelId,
        pushChannelName,
        importance: Importance.high,
      );
      const chat = AndroidNotificationChannel(
        chatChannelId,
        chatChannelName,
        importance: Importance.high,
      );
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await android?.createNotificationChannel(updates);
      await android?.createNotificationChannel(chat);
    } catch (error) {
      developer.log(
        'Local push init failed (${error.runtimeType})',
        name: 'SSK.Push',
      );
    }
  }

  @override
  Future<void> showSystem({
    required String title,
    required String body,
    required Map<String, dynamic> payload,
    bool chat = false,
  }) async {
    if (title.isEmpty && body.isEmpty) return;
    try {
      final details = NotificationDetails(
        android: AndroidNotificationDetails(
          chat ? chatChannelId : pushChannelId,
          chat ? chatChannelName : pushChannelName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      );
      await _plugin.show(
        id: pushLocalId(payload),
        title: title.isEmpty ? 'SSK' : title,
        body: body,
        notificationDetails: details,
        payload: encodePushPayload(payload),
      );
    } catch (error) {
      developer.log(
        'Local push show failed (${error.runtimeType})',
        name: 'SSK.Push',
      );
    }
  }
}

final pushPresenterProvider = Provider<PushPresenter>((ref) {
  final presenter = LocalPushPresenter();
  ref.onDispose(() {});
  return presenter;
});
