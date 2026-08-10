import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';

final clientNotificationsProvider =
    FutureProvider.autoDispose<List<ClientNotification>>((ref) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getNotifications(accessToken: session.tokens.accessToken, limit: 25);
      return _clientNotificationsFromResponse(response);
    });

List<ClientNotification> _clientNotificationsFromResponse(
  Map<String, dynamic> response,
) {
  final data = response['data'];
  final payload = data is Map<String, dynamic> ? data : response;

  final items =
      payload['notifications'] ??
      payload['items'] ??
      payload['results'] ??
      payload['rows'] ??
      payload['data'];

  final list = items is List
      ? items
      : data is List
      ? data
      : const <dynamic>[];

  return list
      .whereType<Map<String, dynamic>>()
      .map(ClientNotification.fromJson)
      .where((notification) => notification.id.isNotEmpty)
      .toList();
}
