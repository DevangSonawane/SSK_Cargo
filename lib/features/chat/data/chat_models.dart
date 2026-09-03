enum ChatAudience { client, broker, driver }

class ChatThreadSummary {
  const ChatThreadSummary({
    required this.raw,
    required this.threadId,
    required this.bookingId,
    required this.bookingNumber,
    required this.bookingStatus,
    required this.stage,
    required this.isLocked,
    required this.pickup,
    required this.drop,
    required this.clientId,
    required this.clientName,
    required this.brokerId,
    required this.brokerName,
    required this.driverId,
    required this.driverName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.lastSenderId,
    required this.lastSenderRole,
    required this.unreadCount,
  });

  final Map<String, dynamic> raw;
  final String threadId;
  final String bookingId;
  final String bookingNumber;
  final String bookingStatus;
  final String stage;
  final bool isLocked;
  final String pickup;
  final String drop;
  final String clientId;
  final String clientName;
  final String brokerId;
  final String brokerName;
  final String driverId;
  final String driverName;
  final String lastMessage;
  final DateTime? lastMessageAt;
  final String lastSenderId;
  final String lastSenderRole;
  final int unreadCount;

  factory ChatThreadSummary.fromJson(Map<String, dynamic> json) {
    return ChatThreadSummary(
      raw: json,
      threadId: chatReadString(json, const ['threadId', 'thread_id', 'id']),
      bookingId: chatReadString(json, const ['bookingId', 'booking_id']),
      bookingNumber: chatReadString(json, const [
        'bookingNumber',
        'booking_number',
      ]),
      bookingStatus: chatReadString(json, const [
        'bookingStatus',
        'booking_status',
      ]),
      stage: chatReadString(json, const ['stage']).toLowerCase(),
      isLocked: chatReadBool(json, const ['isLocked', 'is_locked']),
      pickup: chatReadString(json, const ['pickup']),
      drop: chatReadString(json, const ['drop', 'destination']),
      clientId: chatReadString(json, const ['clientId', 'client_id']),
      clientName: chatReadString(json, const ['clientName', 'client_name']),
      brokerId: chatReadString(json, const ['brokerId', 'broker_id']),
      brokerName: chatReadString(json, const ['brokerName', 'broker_name']),
      driverId: chatReadString(json, const ['driverId', 'driver_id']),
      driverName: chatReadString(json, const ['driverName', 'driver_name']),
      lastMessage: chatReadString(json, const ['lastMessage', 'last_message']),
      lastMessageAt: chatReadDateTime(json, const [
        'lastMessageAt',
        'last_message_at',
      ]),
      lastSenderId: chatReadString(json, const [
        'lastSenderId',
        'last_sender_id',
      ]),
      lastSenderRole: chatReadString(json, const [
        'lastSenderRole',
        'last_sender_role',
      ]).toLowerCase(),
      unreadCount: chatReadInt(json, const ['unreadCount', 'unread_count']),
    );
  }

  String get bookingLabel =>
      bookingNumber.isNotEmpty ? bookingNumber : bookingId;

  String get clientDisplayName => clientName.isNotEmpty ? clientName : 'Client';

  String get staffDisplayName => clientName.isNotEmpty ? clientName : 'Client';

  String displayNameFor(ChatAudience audience) {
    if (audience == ChatAudience.client) {
      final candidate = driverName.isNotEmpty
          ? driverName
          : brokerName.isNotEmpty
          ? brokerName
          : 'Support';
      return candidate;
    }
    return clientDisplayName;
  }

  String get otherPartyLabel {
    return driverName.isNotEmpty
        ? driverName
        : brokerName.isNotEmpty
        ? brokerName
        : 'Support';
  }
}

class ChatMessageMeta {
  const ChatMessageMeta({required this.raw, required this.quickReplies});

  final Map<String, dynamic> raw;
  final List<ChatQuickReply> quickReplies;
}

class ChatQuickReply {
  const ChatQuickReply({required this.id, required this.label});

  final String id;
  final String label;
}

Map<String, dynamic>? chatAsMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String chatReadString(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return '';
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty && text.toLowerCase() != 'null') {
      return text;
    }
  }
  return '';
}

bool chatReadBool(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return false;
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final text = value.trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      if (text == 'false' || text == '0' || text == 'no') return false;
    }
  }
  return false;
}

int chatReadInt(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return 0;
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
    }
  }
  return 0;
}

DateTime? chatReadDateTime(Map<String, dynamic>? json, List<String> keys) {
  if (json == null) return null;
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
    }
  }
  return null;
}

Map<String, dynamic>? chatThreadFromResponse(Map<String, dynamic> response) {
  final data = chatAsMap(response['data']);
  final directThread = chatAsMap(response['thread']);
  final thread =
      chatAsMap(data?['thread']) ??
      chatAsMap(data?['chatThread']) ??
      directThread ??
      data;
  return thread;
}

List<Map<String, dynamic>> chatMessagesFromResponse(
  Map<String, dynamic> response,
) {
  final data = chatAsMap(response['data']);
  final items =
      data?['messages'] ??
      data?['items'] ??
      data?['results'] ??
      response['messages'] ??
      response['items'] ??
      response['results'] ??
      data;

  final Iterable<dynamic> list =
      (items is Iterable
              ? items
              : data is Iterable
              ? data
              : const <dynamic>[])
          as Iterable<dynamic>;

  return list.whereType<Map<String, dynamic>>().toList();
}

Map<String, dynamic>? chatMessageFromPayload(Object? payload) {
  if (payload is Map<String, dynamic>) return payload;
  if (payload is Map) return payload.cast<String, dynamic>();
  return null;
}

ChatMessageMeta chatMessageMeta(Map<String, dynamic>? message) {
  final raw = chatAsMap(message?['meta']) ?? const <String, dynamic>{};
  final quickRepliesRaw = raw['quickReplies'];
  final quickReplies = <ChatQuickReply>[];
  if (quickRepliesRaw is Iterable) {
    for (final item in quickRepliesRaw) {
      final map = chatAsMap(item);
      if (map == null) continue;
      final id = chatReadString(map, const ['id', 'actionId', 'action_id']);
      final label = chatReadString(map, const ['label', 'title', 'name']);
      if (id.isEmpty || label.isEmpty) continue;
      quickReplies.add(ChatQuickReply(id: id, label: label));
    }
  }
  return ChatMessageMeta(raw: raw, quickReplies: quickReplies);
}

String chatTimeLabel(DateTime? value) {
  if (value == null) return '';
  final local = value.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String chatRelativeLabel(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value);
  final minutes = diff.inMinutes;
  if (minutes < 1) return 'now';
  if (minutes < 60) return '${minutes}m';
  final hours = diff.inHours;
  if (hours < 24) return '${hours}h';
  final days = diff.inDays;
  if (days == 1) return 'Yesterday';
  if (days < 7) return '${days}d';
  final local = value.toLocal();
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${local.day.toString().padLeft(2, '0')} ${months[local.month - 1]}';
}

String chatInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final buffer = StringBuffer();
  for (final part in parts.take(2)) {
    buffer.write(part.isEmpty ? '' : part[0]);
  }
  final text = buffer.toString().toUpperCase();
  return text.isEmpty ? '?' : text;
}
