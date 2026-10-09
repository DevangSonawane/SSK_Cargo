// Shared Part-Load providers so the standalone inbox screen, the broker
// tab and the driver home tab all read the same list (single fetch while
// multiple widgets watch). Mirrors web Requests.jsx: 30s poll + socket.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/presentation/controllers/auth_controller.dart';
import 'part_load_api.dart';
import 'part_load_models.dart';

final partLoadInboxProvider =
    FutureProvider.autoDispose<List<PartLoadJoinRequest>>((ref) async {
  final token =
      ref.watch(authSessionProvider).valueOrNull?.tokens.accessToken ?? '';
  if (token.isEmpty) return const [];
  return ref.watch(partLoadApiProvider).listInbox(accessToken: token);
});

/// Pending (actionable) shared-load requests — drives tab badges.
final partLoadPendingCountProvider = Provider.autoDispose<int>((ref) {
  final items = ref.watch(partLoadInboxProvider).valueOrNull;
  if (items == null) return 0;
  return items.where((r) => r.isPending).length;
});
