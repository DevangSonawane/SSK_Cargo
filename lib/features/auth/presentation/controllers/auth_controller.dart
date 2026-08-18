import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/services/client_push_notification_service.dart';
import '../../../../core/services/app_socket_service.dart';
import '../../../../core/providers/driver_tracking_state_provider.dart';
import '../../data/auth_models.dart';

final authSessionProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
      return AuthController(ref, ref.read(apiClientProvider));
    });

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._ref, this._apiClient)
    : super(const AsyncData<AuthSession?>(null));

  final Ref _ref;
  final SskApiClient _apiClient;

  AuthSession? get session => state.valueOrNull;

  void bootstrapSession(AuthSession session) {
    state = AsyncData<AuthSession?>(session);
    unawaited(
      _ref.read(clientPushNotificationServiceProvider).syncForSession(session),
    );
    unawaited(
      _ref.read(appSocketServiceProvider).connect(session.tokens.accessToken),
    );
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
    state = const AsyncLoading<AuthSession?>();
    try {
      final response = await _apiClient.login(email: email, password: password);
      final session = AuthSession.fromLoginResponse(response);
      state = AsyncData<AuthSession?>(session);
      unawaited(
        _ref
            .read(clientPushNotificationServiceProvider)
            .syncForSession(session),
      );
      unawaited(
        _ref.read(appSocketServiceProvider).connect(session.tokens.accessToken),
      );
      return session;
    } catch (error, stackTrace) {
      state = AsyncError<AuthSession?>(error, stackTrace);
      rethrow;
    }
  }

  Future<AuthSession> loginWithGoogle({
    required String idToken,
    required String role,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    try {
      final response = await _apiClient.googleLogin(
        idToken: idToken,
        role: role,
      );
      final session = AuthSession.fromLoginResponse(response);
      state = AsyncData<AuthSession?>(session);
      unawaited(
        _ref
            .read(clientPushNotificationServiceProvider)
            .syncForSession(session),
      );
      unawaited(
        _ref.read(appSocketServiceProvider).connect(session.tokens.accessToken),
      );
      return session;
    } catch (error, stackTrace) {
      state = AsyncError<AuthSession?>(error, stackTrace);
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
    final currentSession = session;
    if (currentSession != null) {
      try {
        await _ref
            .read(clientPushNotificationServiceProvider)
            .clearForSession(currentSession);
      } catch (_) {
        // Clear local state even if push token cleanup fails.
      }
      try {
        await _apiClient.logout(
          refreshToken: currentSession.tokens.refreshToken,
          allDevices: allDevices,
        );
      } catch (_) {
        // Clear local state even if the server already expired the token.
      }
    }
    _ref.read(appSocketServiceProvider).reset();
    state = const AsyncValue.data(null);
  }

  Future<void> forceLocalLogout() async {
    _ref.read(appSocketServiceProvider).reset();
    _ref.read(driverOnlineProvider.notifier).state = false;
    _ref.read(driverActiveTripIdProvider.notifier).state = null;
    _ref.read(driverTripSessionProvider.notifier).state = null;
    state = const AsyncValue.data(null);
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
