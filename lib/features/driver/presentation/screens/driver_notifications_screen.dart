import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../client/data/client_booking_models.dart';
import '../../../client/presentation/controllers/client_notifications_controller.dart';

class DriverNotificationsScreen extends ConsumerStatefulWidget {
  const DriverNotificationsScreen({super.key});

  @override
  ConsumerState<DriverNotificationsScreen> createState() =>
      _DriverNotificationsScreenState();
}

class _DriverNotificationsScreenState
    extends ConsumerState<DriverNotificationsScreen> {
  bool _markingAllRead = false;

  Future<void> _refresh() async {
    ref.invalidate(clientNotificationsProvider);
    await ref.read(clientNotificationsProvider.future);
  }

  Future<void> _markAllRead() async {
    if (_markingAllRead) return;

    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    setState(() {
      _markingAllRead = true;
    });

    try {
      await ref
          .read(apiClientProvider)
          .markAllNotificationsRead(accessToken: session.tokens.accessToken);
      ref.invalidate(clientNotificationsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read.')),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _markingAllRead = false;
        });
      }
    }
  }

  Future<void> _openNotification(ClientNotification notification) async {
    final session = ref.read(authSessionProvider).valueOrNull;
    if (session == null) return;

    if (!notification.isRead) {
      try {
        await ref
            .read(apiClientProvider)
            .markNotificationRead(
              accessToken: session.tokens.accessToken,
              id: notification.id,
            );
      } catch (_) {
        // Keep the sheet working even if the read update fails.
      }
      ref.invalidate(clientNotificationsProvider);
    }

    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 54,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE1E5EB),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  notification.title.isEmpty
                      ? 'Notification'
                      : notification.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF101828),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  notification.message.isEmpty
                      ? 'No message available.'
                      : notification.message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF344054),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2FA56E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(clientNotificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FB),
        elevation: 0,
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: _markingAllRead ? null : _markAllRead,
            child: Text(
              _markingAllRead ? 'Saving...' : 'Mark all read',
              style: const TextStyle(color: Color(0xFF2FA56E)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: notificationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
            children: [
              _EmptyState(
                icon: Icons.notifications_off_outlined,
                title: 'Could not load notifications',
                subtitle: error.toString().replaceFirst('Exception: ', ''),
              ),
            ],
          ),
          data: (notifications) {
            if (notifications.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                children: const [
                  _EmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: 'No notifications yet',
                    subtitle:
                        'Trip updates, invoices, and account notices will appear here.',
                  ),
                ],
              );
            }

            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openNotification(notification),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: notification.isRead
                          ? Colors.white
                          : const Color(0xFFF7FBF9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE8EDF2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? const Color(0xFFF1F5F9)
                                : const Color(0xFFEFF6FF),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            notification.isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            color: notification.isRead
                                ? const Color(0xFF98A2B3)
                                : const Color(0xFF1F88C9),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notification.title.isEmpty
                                          ? 'Notification'
                                          : notification.title,
                                      style: Theme.of(context).textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF101828),
                                          ),
                                    ),
                                  ),
                                  if (!notification.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2FA56E),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                notification.message.isEmpty
                                    ? 'No message available.'
                                    : notification.message,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: const Color(0xFF667085),
                                      height: 1.4,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EDF2)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Color(0xFFF7FAFD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: const Color(0xFF98A2B3), size: 32),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF667085),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
