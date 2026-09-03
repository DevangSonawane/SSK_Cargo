import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../../../../core/network/api_client.dart';
import '../../data/chat_models.dart';

class BookingChatView extends ConsumerStatefulWidget {
  const BookingChatView({
    super.key,
    required this.bookingId,
    required this.accessToken,
    required this.currentUserId,
    this.allowBotActions = true,
    this.readOnly = false,
  });

  final String bookingId;
  final String accessToken;
  final String currentUserId;
  final bool allowBotActions;
  final bool readOnly;

  @override
  ConsumerState<BookingChatView> createState() => _BookingChatViewState();
}

class _BookingChatViewState extends ConsumerState<BookingChatView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  final Map<String, bool> _typingUsers = <String, bool>{};
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  Map<String, dynamic>? _thread;
  bool _loading = true;
  bool _loadError = false;
  bool _sending = false;
  bool _actionLoading = false;
  io.Socket? _socket;
  Timer? _typingTimer;

  bool get _isLocked {
    return chatReadBool(_thread, const ['isLocked', 'is_locked']);
  }

  bool get _canSend {
    if (_thread == null) return false;
    if (_isLocked) return false;
    if (widget.readOnly) return false;
    final canSend = chatReadBool(_thread, const ['canSend', 'can_send']);
    return canSend || _thread!.containsKey('canSend') == false;
  }

  bool get _stageIsBot =>
      chatReadString(_thread, const ['stage']).toLowerCase() == 'bot';

  List<ChatQuickReply> get _quickReplies {
    if (!_stageIsBot || _isLocked || !widget.allowBotActions) {
      return const <ChatQuickReply>[];
    }
    if (_messages.isEmpty) return const <ChatQuickReply>[];
    return chatMessageMeta(_messages.last).quickReplies;
  }

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _socket?.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChat() async {
    setState(() {
      _loading = true;
      _loadError = false;
    });

    try {
      final api = ref.read(apiClientProvider);
      final threadResponse = await api.getChatThread(
        accessToken: widget.accessToken,
        bookingId: widget.bookingId,
      );
      final thread = chatThreadFromResponse(threadResponse);
      final threadId = chatReadString(thread, const [
        'id',
        'thread_id',
        'threadId',
      ]);
      if (threadId.isEmpty) {
        throw StateError('Chat thread unavailable');
      }

      final messagesResponse = await api.getChatMessages(
        accessToken: widget.accessToken,
        threadId: threadId,
        limit: 50,
      );
      final messages = chatMessagesFromResponse(messagesResponse);

      if (!mounted) return;
      setState(() {
        _thread = thread;
        _messages = messages;
      });

      if (!widget.readOnly) {
        await api.markChatThreadRead(
          accessToken: widget.accessToken,
          threadId: threadId,
        );
      }
      await _connectSocket(threadId);
      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _connectSocket(String threadId) async {
    final baseUrl = ref.read(dioProvider).options.baseUrl;
    final socket = io.io(
      baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling'])
          .setAuth({'token': widget.accessToken})
          .disableAutoConnect()
          .build(),
    );

    socket.onConnect((_) {
      socket.emit('join-thread', {'threadId': threadId});
    });

    socket.on('new-message', (payload) {
      final message = chatMessageFromPayload(payload);
      if (message == null ||
          chatReadString(message, const ['threadId', 'thread_id']).trim() !=
              threadId) {
        return;
      }

      final messageId = chatReadString(message, const [
        'id',
        'message_id',
        'uuid',
      ]);
      if (messageId.isNotEmpty &&
          _messages.any(
            (item) =>
                chatReadString(item, const ['id', 'message_id', 'uuid']) ==
                messageId,
          )) {
        return;
      }

      if (!mounted) return;
      setState(() {
        final messageText = chatReadString(message, const [
          'message',
          'body',
          'content',
          'text',
        ]);
        final senderId = chatReadString(message, const [
          'senderId',
          'sender_id',
          'user_id',
        ]);
        final withoutPendingEcho = _messages.where((item) {
          final pendingId = chatReadString(item, const [
            'id',
            'message_id',
            'uuid',
          ]);
          return !(pendingId.startsWith('local-') &&
              chatReadString(item, const [
                    'senderId',
                    'sender_id',
                    'user_id',
                  ]) ==
                  senderId &&
              chatReadString(item, const [
                    'message',
                    'body',
                    'content',
                    'text',
                  ]) ==
                  messageText);
        }).toList();
        _messages = [...withoutPendingEcho, message];
        final senderRole = chatReadString(message, const [
          'senderRole',
          'sender_role',
        ]).toLowerCase();
        if (senderRole == 'broker' ||
            senderRole == 'driver' ||
            senderRole == 'admin') {
          _thread = <String, dynamic>{...?_thread, 'stage': 'human'};
        }
      });

      if (!widget.readOnly &&
          chatReadString(message, const ['senderId', 'sender_id', 'user_id']) !=
              widget.currentUserId) {
        socket.emit('read', {'threadId': threadId});
      }

      _scrollToBottom();
    });

    socket.on('typing', (payload) {
      final data = chatAsMap(payload);
      if (data == null) return;
      final userId = chatReadString(data, const ['userId', 'user_id']);
      if (userId.isEmpty || userId == widget.currentUserId) return;
      final isTyping = chatReadBool(data, const ['isTyping', 'is_typing']);
      if (!mounted) return;
      setState(() {
        _typingUsers[userId] = isTyping;
      });
    });

    socket.on('read-receipt', (payload) {
      final data = chatAsMap(payload);
      if (data == null) return;
      final userId = chatReadString(data, const ['userId', 'user_id']);
      if (userId.isEmpty || userId == widget.currentUserId) return;
      if (!mounted) return;
      setState(() {
        _messages = _messages
            .map(
              (message) =>
                  chatReadString(message, const [
                        'senderId',
                        'sender_id',
                        'user_id',
                      ]) ==
                      widget.currentUserId
                  ? {...message, 'readAt': DateTime.now().toIso8601String()}
                  : message,
            )
            .toList();
      });
    });

    socket.onConnectError((error) {
      debugPrint('[BookingChat] connect error: $error');
    });

    socket.connect();

    _socket?.dispose();
    _socket = socket;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendMessage() async {
    final socket = _socket;
    final threadId = chatReadString(_thread, const [
      'id',
      'thread_id',
      'threadId',
    ]);
    final message = _messageController.text.trim();
    if (socket == null ||
        threadId.isEmpty ||
        message.isEmpty ||
        _sending ||
        !_canSend) {
      return;
    }

    final localMessageId = 'local-${DateTime.now().microsecondsSinceEpoch}';
    setState(() {
      _sending = true;
      _messages = [
        ..._messages,
        {
          'id': localMessageId,
          'threadId': threadId,
          'senderId': widget.currentUserId,
          'senderName': 'You',
          'senderRole': 'client',
          'message': message,
          'createdAt': DateTime.now().toIso8601String(),
        },
      ];
    });
    _messageController.clear();
    _scrollToBottom();

    socket.emitWithAck(
      'send-message',
      {'threadId': threadId, 'message': message},
      ack: (ack) {
        if (!mounted) return;
        final success = ack is Map ? ack['success'] != false : true;
        setState(() {
          _sending = false;
        });
        if (success) {
          if (ack is Map && ack['botMessage'] != null) {
            setState(() {
              _thread = <String, dynamic>{...?_thread, 'stage': 'human'};
            });
          }
        } else {
          setState(() {
            _messages = _messages
                .where(
                  (item) =>
                      chatReadString(item, const [
                        'id',
                        'message_id',
                        'uuid',
                      ]) !=
                      localMessageId,
                )
                .toList();
          });
          final ackMap = chatAsMap(ack);
          final messageText = ackMap?['message']?.toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                messageText?.isNotEmpty == true
                    ? messageText!
                    : 'Message could not be sent.',
              ),
            ),
          );
        }
      },
    );
  }

  Future<void> _handleBotAction(String actionId) async {
    final threadId = chatReadString(_thread, const [
      'id',
      'thread_id',
      'threadId',
    ]);
    if (!_canSend ||
        threadId.isEmpty ||
        _actionLoading ||
        !widget.allowBotActions) {
      return;
    }

    setState(() {
      _actionLoading = true;
    });

    try {
      final response = await ref
          .read(apiClientProvider)
          .postChatBotAction(
            accessToken: widget.accessToken,
            threadId: threadId,
            actionId: actionId,
          );
      if (!mounted) return;
      final success = response['success'] != false;
      if (!success) {
        final messageText = response['message']?.toString();
        if (messageText != null && messageText.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(messageText)));
        }
        setState(() {
          _thread = <String, dynamic>{...?_thread, 'stage': 'human'};
        });
        return;
      }
      final escalated = response['data'] is Map
          ? chatReadBool(chatAsMap(response['data']), const ['escalated'])
          : false;
      if (escalated) {
        setState(() {
          _thread = <String, dynamic>{...?_thread, 'stage': 'human'};
        });
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionLoading = false;
        });
      }
    }
  }

  void _handleTyping(String value) {
    final socket = _socket;
    final threadId = chatReadString(_thread, const [
      'id',
      'thread_id',
      'threadId',
    ]);
    if (socket == null || threadId.isEmpty) {
      return;
    }

    socket.emit('typing', {'threadId': threadId, 'isTyping': true});
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1500), () {
      socket.emit('typing', {'threadId': threadId, 'isTyping': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isLocked = _isLocked;

    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _loadError
              ? Center(
                  child: Text(
                    'Could not load this chat.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                )
              : _messages.isEmpty
              ? Center(
                  child: Text(
                    'No messages yet.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF667085),
                    ),
                  ),
                )
              : ListView.separated(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _ChatMessageBubble(
                      message: message,
                      currentUserId: widget.currentUserId,
                    );
                  },
                ),
        ),
        if (_typingUsers.values.any((value) => value))
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 2, top: 2),
              child: Text(
                'Typing...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF667085),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
        const SizedBox(height: 10),
        if (isLocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFD),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE8EDF2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Color(0xFF98A2B3),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'This trip is complete — the chat has closed.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF667085),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_quickReplies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final quickReply in _quickReplies)
                    OutlinedButton(
                      onPressed: _actionLoading
                          ? null
                          : () => _handleBotAction(quickReply.id),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2FA56E),
                        side: const BorderSide(color: Color(0xFFB6E7CC)),
                        backgroundColor: const Color(0xFFEFFAF3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      child: Text(quickReply.label),
                    ),
                ],
              ),
            ),
          ),
        if (!widget.readOnly && !isLocked)
          Padding(
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 0 : 2),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    onChanged: _handleTyping,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FilledButton(
                    onPressed: _sending ? null : _sendMessage,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      backgroundColor: const Color(0xFF2FA56E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ChatMessageBubble extends StatelessWidget {
  const _ChatMessageBubble({
    required this.message,
    required this.currentUserId,
  });

  final Map<String, dynamic> message;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final isMine =
        chatReadString(message, const ['senderId', 'sender_id', 'user_id']) ==
        currentUserId;
    final isBot =
        chatReadString(message, const [
          'senderRole',
          'sender_role',
        ]).toLowerCase() ==
        'bot';
    final createdAt = chatReadDateTime(message, const [
      'createdAt',
      'created_at',
    ]);
    final messageText = chatReadString(message, const [
      'message',
      'body',
      'content',
      'text',
    ]);
    final senderName = chatReadString(message, const [
      'senderName',
      'sender_name',
      'name',
    ]);
    final isRead =
        chatReadDateTime(message, const ['readAt', 'read_at']) != null;

    return Row(
      mainAxisAlignment: isMine
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isMine
                  ? const Color(0xFF2FA56E)
                  : isBot
                  ? const Color(0xFFF3F0FF)
                  : const Color(0xFFF5F7FB),
              borderRadius: BorderRadius.circular(18).copyWith(
                bottomRight: Radius.circular(isMine ? 6 : 18),
                bottomLeft: Radius.circular(isMine ? 18 : 6),
              ),
              border: isBot && !isMine
                  ? Border.all(color: const Color(0xFFE0D7FF))
                  : null,
            ),
            child: Column(
              crossAxisAlignment: isMine
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (!isMine && isBot)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.smart_toy_outlined,
                        size: 14,
                        color: Color(0xFF7F56D9),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SSK Assistant',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(0xFF7F56D9),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                else if (!isMine && senderName.isNotEmpty)
                  Text(
                    senderName,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF667085),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if ((!isMine && (isBot || senderName.isNotEmpty)))
                  const SizedBox(height: 4),
                Text(
                  messageText.isEmpty ? 'Message' : messageText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMine ? Colors.white : const Color(0xFF101828),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  chatTimeLabel(createdAt),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isMine
                        ? Colors.white70
                        : isBot
                        ? const Color(0xFF9B8CDC)
                        : const Color(0xFF98A2B3),
                    fontSize: 10,
                  ),
                ),
                if (isMine && isRead)
                  Text(
                    'Read',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
