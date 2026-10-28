import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../network/api_client.dart';

/// The client-role verification lock's app-wide state (web `KycStatusContext`
/// parity). Unlike the driver/broker gate — which only blocks *job
/// acceptance* — an unverified client loses almost the whole app: bookings,
/// tracking, wallet, addresses, payment methods, monthly hiring and
/// notifications all redirect to the client verification screen, leaving
/// only Home, Profile, Chat and the verification screen itself reachable.
///
/// The server enforces the same rule regardless of app behavior
/// (`POST /api/bookings` answers `403 KYC_VERIFICATION_REQUIRED`), so this
/// provider is UX: cached once per access token, refreshed after
/// verification actions, never re-fetched on every navigation.
class ClientKycGateState {
  const ClientKycGateState({this.status = 'pending', this.loading = false});

  /// Raw `kyc_status` from `GET /api/kyc/status`, lower-cased.
  /// `pending | submitted | verified | rejected`.
  final String status;

  /// True while the per-session fetch is in flight. `redirectToVerify`
  /// waits for it rather than firing a false redirect on a cold start.
  final bool loading;

  bool get verified => status.trim().toLowerCase() == 'verified';
}

class ClientKycGateController extends StateNotifier<ClientKycGateState> {
  ClientKycGateController(this._read) : super(const ClientKycGateState());

  final Ref _read;
  String? _loadedForToken;
  int _loadToken = 0;

  /// Loads the status at most once per access token (web `fetched ONCE per
  /// authenticated session`). Subsequent calls are no-ops; use [refresh]
  /// after a verification action. Falls through to allow access when the
  /// fetch fails — the server-side 403 remains the backstop.
  Future<void> ensureLoaded({bool force = false}) async {
    final session = _read.read(authSessionProvider).valueOrNull;
    final token = session?.tokens.accessToken ?? '';
    if (token.isEmpty) {
      _loadedForToken = null;
      state = const ClientKycGateState(status: 'pending');
      return;
    }
    if (!force && _loadedForToken == token) {
      return;
    }
    final loadToken = ++_loadToken;
    state = ClientKycGateState(status: state.status, loading: true);
    try {
      final response = await _read
          .read(apiClientProvider)
          .getKycStatus(accessToken: token);
      if (loadToken != _loadToken) {
        return;
      }
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final status = data['kyc_status']?.toString().trim().toLowerCase();
      _loadedForToken = token;
      state = ClientKycGateState(
        status: status == null || status.isEmpty ? 'pending' : status,
      );
    } catch (_) {
      if (loadToken != _loadToken) {
        return;
      }
      // Not verified yet is the safe assumption; a retry happens on demand
      // (the blocked view exposes one) rather than locking the app forever.
      state = const ClientKycGateState(status: 'pending');
    }
  }

  /// Re-fetches immediately — called after every verification action, and
  /// when the server answers 403 KYC_VERIFICATION_REQUIRED (web
  /// refreshKycStatus()) because a cached "verified" quietly expired or the
  /// backend reset the account.
  Future<void> refresh() => ensureLoaded(force: true);
}

final clientKycGateProvider =
    StateNotifierProvider<ClientKycGateController, ClientKycGateState>((ref) {
      return ClientKycGateController(ref);
    });
