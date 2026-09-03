import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/chat_models.dart';
import '../widgets/booking_chat_view.dart';

class ChatListScreen extends ConsumerStatefulWidget {
  const ChatListScreen({super.key, required this.audience});

  final ChatAudience audience;

  @override
  ConsumerState<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends ConsumerState<ChatListScreen> {
  late Future<List<ChatThreadSummary>> _threadsFuture;

  @override
  void initState() {
    super.initState();
    _threadsFuture = _loadThreads();
  }

  Future<List<ChatThreadSummary>> _loadThreads() async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return const <ChatThreadSummary>[];
    final response = await ref
        .read(apiClientProvider)
        .getChatThreads(accessToken: session.tokens.accessToken);
    final data = chatAsMap(response['data']);
    final rawThreads = data?['threads'] ?? response['threads'];
    if (rawThreads is! Iterable) return const <ChatThreadSummary>[];
    return rawThreads
        .map(chatAsMap)
        .whereType<Map<String, dynamic>>()
        .map(ChatThreadSummary.fromJson)
        .toList();
  }

  void _retry() {
    setState(() {
      _threadsFuture = _loadThreads();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isClient = widget.audience == ChatAudience.client;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<ChatThreadSummary>>(
        future: _threadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.refresh_rounded,
              message: "Couldn't load your chats",
              action: TextButton(onPressed: _retry, child: const Text('Retry')),
            );
          }
          final threads = snapshot.data ?? const <ChatThreadSummary>[];
          if (threads.isEmpty) {
            return const _EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              message: 'No chats yet',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _retry(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: threads.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final thread = threads[index];
                return _ChatThreadTile(
                  thread: thread,
                  displayName: thread.displayNameFor(widget.audience),
                  onTap: () => context.push(
                    isClient
                        ? '/chats/${thread.bookingId}'
                        : widget.audience == ChatAudience.broker
                        ? '/broker/chats/${thread.bookingId}'
                        : '/driver/chats/${thread.bookingId}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailScreen extends ConsumerWidget {
  const ChatDetailScreen({
    super.key,
    required this.bookingId,
    required this.audience,
  });

  final String bookingId;
  final ChatAudience audience;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).valueOrNull;
    if (session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isClient = audience == ChatAudience.client;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(isClient ? 'Booking chat' : 'Client chat'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: BookingChatView(
            bookingId: bookingId,
            accessToken: session.tokens.accessToken,
            currentUserId: session.user.id,
            allowBotActions: isClient,
          ),
        ),
      ),
    );
  }
}

class _ChatThreadTile extends StatelessWidget {
  const _ChatThreadTile({
    required this.thread,
    required this.displayName,
    required this.onTap,
  });

  final ChatThreadSummary thread;
  final String displayName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 23,
                backgroundColor: const Color(0xFFEAF7F0),
                foregroundColor: const Color(0xFF2FA56E),
                child: Text(chatInitials(displayName)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Text(
                          chatRelativeLabel(thread.lastMessageAt),
                          style: const TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${thread.bookingLabel}  •  ${thread.lastMessage.isEmpty ? 'No messages yet' : thread.lastMessage}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        fontSize: 12,
                      ),
                    ),
                    if (thread.isLocked || thread.stage == 'bot') ...[
                      const SizedBox(height: 7),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (thread.isLocked)
                            const _StatusChip(label: 'Closed'),
                          if (thread.stage == 'bot')
                            const _StatusChip(
                              label: 'Not yet connected',
                              amber: true,
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (thread.unreadCount > 0) ...[
                const SizedBox(width: 8),
                CircleAvatar(
                  radius: 10,
                  backgroundColor: const Color(0xFF1F88C9),
                  child: Text(
                    thread.unreadCount > 9 ? '9+' : '${thread.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.amber = false});

  final String label;
  final bool amber;

  @override
  Widget build(BuildContext context) {
    final color = amber ? const Color(0xFFB54708) : const Color(0xFF667085);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: amber ? const Color(0xFFFFFAEB) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 36, color: const Color(0xFFD0D5DD)),
          const SizedBox(height: 10),
          Text(message, style: const TextStyle(color: Color(0xFF98A2B3))),
          ?action,
        ],
      ),
    );
  }
}
