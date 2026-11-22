import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

/// Web parity (client `ChatUnreadContext.jsx` / broker-driver
/// `useUnreadChatCount.jsx`): the unread badge is re-fetched from
/// `GET /api/chat/unread-count` every 20s, and right after a thread is marked
/// read — the server's count is the source of truth, never a local tally.
const kChatUnreadPollInterval = Duration(seconds: 20);

/// The chat thread currently on screen (null when no chat is open). Messages
/// arriving for it are read immediately, so they never bump the badge.
final openChatThreadIdProvider = StateProvider<String?>((ref) => null);

final chatUnreadRefresherProvider = Provider<ChatUnreadRefresher>(
  ChatUnreadRefresher.new,
);

class ChatUnreadRefresher {
  ChatUnreadRefresher(this._ref);

  final Ref _ref;

  /// Pulls the real unread count into [chatUnreadCountProvider].
  /// Best-effort: a failed call keeps the current badge.
  Future<void> refresh() async {
    final session = _ref.read(authSessionProvider).valueOrNull;
    if (session == null) {
      _ref.read(chatUnreadCountProvider.notifier).state = 0;
      return;
    }
    try {
      final response = await _ref
          .read(apiClientProvider)
          .getUnreadChatCount(accessToken: session.tokens.accessToken);
      final data = response['data'];
      final rawCount = data is Map
          ? data['unreadCount'] ?? data['count']
          : null;
      final count = rawCount is num
          ? rawCount.toInt()
          : int.tryParse(rawCount?.toString() ?? '') ?? 0;
      _ref.read(chatUnreadCountProvider.notifier).state = count < 0 ? 0 : count;
    } catch (_) {
      // Badges must never interrupt the app; the next poll retries.
    }
  }

  /// True when [payload] belongs to the chat the user is reading right now.
  bool isForOpenThread(Map<String, dynamic> payload) {
    final open = _ref.read(openChatThreadIdProvider);
    if (open == null || open.isEmpty) return false;
    final threadId = (payload['threadId'] ?? payload['thread_id'])?.toString();
    return threadId == open;
  }
}
