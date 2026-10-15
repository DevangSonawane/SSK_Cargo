import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/client_push_notification_service.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../../../core/providers/user_location_provider.dart';
import '../../data/auth_models.dart';

final authSessionProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
      final pushService = ref.read(clientPushNotificationServiceProvider);
      ref.onDispose(() => unawaited(pushService.clearForSession()));
      return AuthController(ref, ref.read(apiClientProvider));
    });

/// Last session-death message from the server (force-reset / expiry),
/// shown once on the login screen after a global 401 logout.
final authExpiredMessageProvider = StateProvider<String?>((ref) => null);

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._ref, this._apiClient)
    : super(const AsyncData<AuthSession?>(null));

  final Ref _ref;
  final SskApiClient _apiClient;
  int _sessionRevision = 0;

  AuthSession? get session => state.valueOrNull;

  /// A Flutter driver being locally "online" is not enough for the backend's
  /// nearby-driver matching. Mirror the web driver's login behavior by making
  /// the driver available server-side as soon as a driver session starts.
  ///
  /// Location tracking remains subject to the driver's consent and device GPS
  /// permission; the app-level tracking listener starts that flow separately.
  /// Availability is deliberately best-effort so a transient failure never
  /// prevents authentication or navigation.
  void _activateDriverForBookings(AuthSession session) {
    if (session.user.role.trim().toLowerCase() != 'driver') {
      return;
    }

    _ref.read(driverOnlineProvider.notifier).state = true;
    unawaited(_setDriverAvailable(session.tokens.accessToken));
  }

  Future<void> _setDriverAvailable(String accessToken) async {
    try {
      await _apiClient.updateDriverStatus(
        accessToken: accessToken,
        status: 'available',
      );
    } catch (_) {
      // The location tracker and the user's Online toggle will retry this.
    }
  }

  void bootstrapSession(AuthSession session) {
    ++_sessionRevision;
    state = AsyncData<AuthSession?>(session);
    _activateDriverForBookings(session);
    unawaited(
      _ref.read(clientPushNotificationServiceProvider).syncForSession(session),
    );
    unawaited(
      _ref.read(appSocketServiceProvider).connect(session.tokens.accessToken),
    );
    // Prefetch GPS in the background so client booking / map screens open
    // instantly. Non-blocking — never delays navigation.
    // Drivers see the background tracking disclosure before any GPS prompt.
    if (session.user.role.trim().toLowerCase() != 'driver') {
      unawaited(_ref.read(userLocationProvider.notifier).prefetch());
    }
  }

  void debugSetSession(AuthSession session) {
    if (!kDebugMode) {
      return;
    }
    bootstrapSession(session);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final revision = ++_sessionRevision;
    unawaited(
      _ref.read(clientPushNotificationServiceProvider).clearForSession(),
    );
    state = const AsyncLoading<AuthSession?>();
    try {
      final response = await _apiClient.login(email: email, password: password);
      if (!mounted || revision != _sessionRevision) {
        throw StateError('Sign-in superseded by a session change');
      }
      final session = AuthSession.fromLoginResponse(response);
      state = AsyncData<AuthSession?>(session);
      _activateDriverForBookings(session);
      unawaited(
        _ref
            .read(clientPushNotificationServiceProvider)
            .syncForSession(session),
      );
      unawaited(
        _ref.read(appSocketServiceProvider).connect(session.tokens.accessToken),
      );
      // Drivers see the background tracking disclosure before any GPS prompt.
      if (session.user.role.trim().toLowerCase() != 'driver') {
        unawaited(_ref.read(userLocationProvider.notifier).prefetch());
      }
      return session;
    } catch (error, stackTrace) {
      if (mounted && revision == _sessionRevision) {
        state = AsyncError<AuthSession?>(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<AuthSession> loginWithGoogle({
    required String idToken,
    required String role,
  }) async {
    final revision = ++_sessionRevision;
    unawaited(
      _ref.read(clientPushNotificationServiceProvider).clearForSession(),
    );
    state = const AsyncLoading<AuthSession?>();
    try {
      final response = await _apiClient.googleLogin(
        idToken: idToken,
        role: role,
      );
      if (!mounted || revision != _sessionRevision) {
        throw StateError('Sign-in superseded by a session change');
      }
      final session = AuthSession.fromLoginResponse(response);
      state = AsyncData<AuthSession?>(session);
      _activateDriverForBookings(session);
      unawaited(
        _ref
            .read(clientPushNotificationServiceProvider)
            .syncForSession(session),
      );
      unawaited(
        _ref.read(appSocketServiceProvider).connect(session.tokens.accessToken),
      );
      // Drivers see the background tracking disclosure before any GPS prompt.
      if (session.user.role.trim().toLowerCase() != 'driver') {
        unawaited(_ref.read(userLocationProvider.notifier).prefetch());
      }
      return session;
    } catch (error, stackTrace) {
      if (mounted && revision == _sessionRevision) {
        state = AsyncError<AuthSession?>(error, stackTrace);
      }
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    required String role,
  }) async {
    await _apiClient.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
      role: role,
    );
  }

  Future<void> logout({bool allDevices = false}) async {
    final revision = ++_sessionRevision;
    final currentSession = session;
    await _ref.read(clientPushNotificationServiceProvider).clearForSession();
    if (currentSession != null) {
      try {
        await _apiClient.logout(
          refreshToken: currentSession.tokens.refreshToken,
          allDevices: allDevices,
        );
      } catch (_) {
        // Clear local state even if the server already expired the token.
      }
    }
    if (!mounted || revision != _sessionRevision) return;
    _ref.read(appSocketServiceProvider).reset();
    _ref.read(userLocationProvider.notifier).clear();
    state = const AsyncValue.data(null);
  }

  Future<void> forceLocalLogout() async {
    ++_sessionRevision;
    unawaited(
      _ref.read(clientPushNotificationServiceProvider).clearForSession(),
    );
    _ref.read(appSocketServiceProvider).reset();
    _ref.read(userLocationProvider.notifier).clear();
    _ref.read(driverOnlineProvider.notifier).state = false;
    _ref.read(driverActiveTripIdProvider.notifier).state = null;
    _ref.read(driverTripSessionProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }

  /// Silently exchanges the refresh token for fresh tokens (web
  /// `AuthContext.refreshTokens` parity). Deliberately does NOT clear the
  /// session on failure — the caller (session-expired sheet) needs the stale
  /// session left in place so the user keeps their place while re-logging
  /// in inline. Returns true when the session was refreshed.
  Future<bool> refreshTokens() async {
    final revision = _sessionRevision;
    final currentSession = session;
    final refreshToken = currentSession?.tokens.refreshToken ?? '';
    if (refreshToken.isEmpty) return false;
    try {
      final response = await _apiClient.refreshSession(
        refreshToken: refreshToken,
      );
      if (!mounted || revision != _sessionRevision) return false;
      final data = response['data'];
      final map = data is Map<String, dynamic> ? data : response;
      final tokensJson = map['tokens'];
      if (tokensJson is! Map<String, dynamic>) return false;
      final tokens = AuthTokens.fromJson(tokensJson);
      if (tokens.accessToken.isEmpty) return false;
      final refreshed = AuthSession(user: currentSession!.user, tokens: tokens);
      state = AsyncData<AuthSession?>(refreshed);
      _ref.read(clientPushNotificationServiceProvider).updateSession(refreshed);
      unawaited(
        _ref
            .read(appSocketServiceProvider)
            .ensureConnected(accessToken: tokens.accessToken),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<AuthSession> refreshProfile() async {
    final currentSession = session;
    if (currentSession == null) {
      throw StateError('No active session');
    }

    final response = await _apiClient.getProfile(
      accessToken: currentSession.tokens.accessToken,
    );
    final refreshed = AuthSession.fromProfileResponse(
      profile: response,
      tokens: currentSession.tokens,
    );
    state = AsyncData<AuthSession?>(refreshed);
    return refreshed;
  }

  Future<AuthSession> updateProfile({
    required String name,
    required String email,
    String? phone,
    String? profileImage,
    String? address,
  }) async {
    final currentSession = session;
    if (currentSession == null) {
      throw StateError('No active session');
    }

    final response = await _apiClient.updateProfile(
      accessToken: currentSession.tokens.accessToken,
      name: name,
      email: email,
      phone: phone,
      profileImage: profileImage,
      address: address,
    );
    final updated = AuthSession.fromProfileResponse(
      profile: response,
      tokens: currentSession.tokens,
    );
    state = AsyncData<AuthSession?>(updated);
    return updated;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentSession = session;
    if (currentSession == null) {
      throw StateError('No active session');
    }

    await _apiClient.changePassword(
      accessToken: currentSession.tokens.accessToken,
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
