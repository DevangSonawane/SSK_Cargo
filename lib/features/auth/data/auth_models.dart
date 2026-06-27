class SskUser {
  const SskUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    required this.isPhoneVerified,
    required this.isEmailVerified,
    required this.profileImage,
    required this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SskUser.fromJson(Map<String, dynamic> json) {
    return SskUser(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString(),
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'client',
      status: json['status']?.toString() ?? 'active',
      isPhoneVerified: json['is_phone_verified'] == true,
      isEmailVerified: json['is_email_verified'] == true,
      profileImage: json['profile_image']?.toString(),
      lastLoginAt: _parseDateTime(json['last_login_at']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  final String id;
  final String name;
  final String? email;
  final String phone;
  final String role;
  final String status;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final String? profileImage;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get displayName => name.trim().isEmpty ? 'User' : name.trim();
}

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token']?.toString() ?? '',
      refreshToken: json['refresh_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      expiresIn: json['expires_in']?.toString(),
    );
  }

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final String? expiresIn;
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.tokens,
    this.isNewUser = false,
    this.needsPhone = false,
  });

  factory AuthSession.fromLoginResponse(Map<String, dynamic> json) {
    final data = _asMap(json['data']);
    return AuthSession(
      user: SskUser.fromJson(_asMap(data['user'])),
      tokens: AuthTokens.fromJson(_asMap(data['tokens'])),
      isNewUser: data['is_new_user'] == true,
      needsPhone: data['needs_phone'] == true,
    );
  }

  factory AuthSession.fromProfileResponse({
    required Map<String, dynamic> profile,
    required AuthTokens tokens,
  }) {
    final data = _asMap(profile['data']);
    return AuthSession(
      user: SskUser.fromJson(_asMap(data['user'])),
      tokens: tokens,
    );
  }

  final SskUser user;
  final AuthTokens tokens;
  final bool isNewUser;
  final bool needsPhone;
}

DateTime? _parseDateTime(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return DateTime.tryParse(text);
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  return <String, dynamic>{};
}
