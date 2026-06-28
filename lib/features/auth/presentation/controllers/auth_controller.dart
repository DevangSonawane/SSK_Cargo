import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/auth_models.dart';

final authSessionProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  return AuthController(ref.read(apiClientProvider));
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._apiClient) : super(const AsyncData<AuthSession?>(null));

  final SskApiClient _apiClient;

  AuthSession? get session => state.valueOrNull;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading<AuthSession?>();
    try {
      final response = await _apiClient.login(email: email, password: password);
      final session = AuthSession.fromLoginResponse(response);
      state = AsyncData<AuthSession?>(session);
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
      final response = await _apiClient.googleLogin(idToken: idToken, role: role);
      final session = AuthSession.fromLoginResponse(response);
      state = AsyncData<AuthSession?>(session);
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
        await _apiClient.logout(
          refreshToken: currentSession.tokens.refreshToken,
          allDevices: allDevices,
        );
      } catch (_) {
        // Clear local state even if the server already expired the token.
      }
    }
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
