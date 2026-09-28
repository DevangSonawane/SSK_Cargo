import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../network/api_client.dart';

final kycStatusProvider = FutureProvider<String>((ref) async {
  final session = ref.watch(authSessionProvider).valueOrNull;
  if (session == null) {
    return 'pending';
  }

  final response = await ref
      .read(apiClientProvider)
      .getKycStatus(accessToken: session.tokens.accessToken);
  final data = (response['data'] as Map<String, dynamic>?) ?? const {};
  final status = data['kyc_status']?.toString().trim().toLowerCase();
  return status == null || status.isEmpty ? 'pending' : status;
});
