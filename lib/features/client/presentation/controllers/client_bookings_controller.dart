import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/client_booking_models.dart';

typedef ClientBookingsQuery = ({String? status, int page, int limit});

final clientBookingsProvider = FutureProvider.autoDispose
    .family<ClientBookingPage, ClientBookingsQuery>((ref, query) async {
      final session = ref.watch(authSessionProvider).valueOrNull;
      if (session == null) {
        throw StateError('No active session');
      }

      final response = await ref
          .watch(apiClientProvider)
          .getBookings(
            accessToken: session.tokens.accessToken,
            status: query.status,
            page: query.page,
            limit: query.limit,
          );

      return ClientBookingPage.fromJson(response);
    });

final clientPricingProvider = FutureProvider.autoDispose<ClientPricingConfig?>((
  ref,
) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    return null;
  }

  try {
    final response = await ref
        .watch(apiClientProvider)
        .getAdminPricing(accessToken: session.tokens.accessToken);
    return ClientPricingConfig.fromJson(response);
  } catch (_) {
    return null;
  }
});
