import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../network/api_client.dart';
import 'locale_provider.dart';

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
///
/// A sticky "verified" flag is cached per user id in SharedPreferences
/// (web `gadidosti-client` fix parity). On a later app launch that cached
/// value is trusted immediately — no spinner, no false block view — while
/// the fresh fetch still runs in the background and corrects it if the real
/// status changed (e.g. an admin reverted the user). A failed fetch never
/// blanks the last-known status out.
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
  ClientKycGateController(this._read) : super(const ClientKycGateState()) {
    // Seed synchronously so the very first frame after a cold start already
    // reflects a previously confirmed "verified" instead of flashing the
    // verification block.
    final userId = _currentUserId();
    if (userId.isNotEmpty && _cachedVerified(userId)) {
      state = const ClientKycGateState(status: 'verified');
    }
  }

  static const _cacheKeyPrefix = 'client_kyc_verified_';

  final Ref _read;
  String? _loadedForToken;
  int _loadToken = 0;

  String _currentUserId() =>
      _read.read(authSessionProvider).valueOrNull?.user.id ?? '';

  bool _cachedVerified(String userId) {
    try {
      return _read
              .read(sharedPreferencesProvider)
              .getBool('$_cacheKeyPrefix$userId') ??
          false;
    } catch (_) {
      return false;
    }
  }

  void _writeCache(String userId, bool verified) {
    if (userId.isEmpty) return;
    try {
      final prefs = _read.read(sharedPreferencesProvider);
      final key = '$_cacheKeyPrefix$userId';
      if (verified) {
        prefs.setBool(key, true);
      } else {
        prefs.remove(key);
      }
    } catch (_) {}
  }

  /// Loads the status at most once per access token (web `fetched ONCE per
  /// authenticated session`). Subsequent calls are no-ops; use [refresh]
  /// after a verification action. A cached "verified" for this user is
  /// shown straight away and the fetch only ever *updates* it; a failed
  /// fetch keeps the last-known status — the server-side 403 remains the
  /// backstop.
  Future<void> ensureLoaded({bool force = false}) async {
    final session = _read.read(authSessionProvider).valueOrNull;
    final token = session?.tokens.accessToken ?? '';
    final userId = session?.user.id ?? '';
    if (token.isEmpty) {
      _loadedForToken = null;
      state = const ClientKycGateState(status: 'pending');
      return;
    }
    if (!force && _loadedForToken == token) {
      return;
    }
    final loadToken = ++_loadToken;
    final cachedVerified = userId.isNotEmpty && _cachedVerified(userId);
    if (cachedVerified) {
      // Trust the sticky flag; revalidate silently in the background.
      state = const ClientKycGateState(status: 'verified');
    } else {
      state = ClientKycGateState(status: state.status, loading: true);
    }
    try {
      final response = await _read
          .read(apiClientProvider)
          .getKycStatus(accessToken: token);
      if (loadToken != _loadToken) {
        return;
      }
      final data = (response['data'] as Map<String, dynamic>?) ?? const {};
      final status = data['kyc_status']?.toString().trim().toLowerCase();
      final resolved = status == null || status.isEmpty ? 'pending' : status;
      _loadedForToken = token;
      _writeCache(userId, resolved == 'verified');
      state = ClientKycGateState(status: resolved);
    } catch (_) {
      if (loadToken != _loadToken) {
        return;
      }
      // Keep the last-known value: a cached "verified" stays verified; an
      // unverified user stays blocked, with a retry on demand (the blocked
      // view exposes one) rather than locking the app forever.
      state = ClientKycGateState(
        status: cachedVerified ? 'verified' : state.status,
      );
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
