class AuthToken {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final DateTime expiresAt;

  AuthToken({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.expiresAt,
  });

  factory AuthToken.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int;
    final expiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    
    return AuthToken(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'],
      tokenType: json['token_type'] ?? 'Bearer',
      expiresIn: expiresIn,
      expiresAt: expiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'token_type': tokenType,
      'expires_in': expiresIn,
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isExpiringSoon => DateTime.now().add(const Duration(minutes: 5)).isAfter(expiresAt);

  String get authorizationHeader => '$tokenType $accessToken';
}

class LoginRequest {
  final String username;
  final String password;
  final String grantType;
  final String clientId;
  final String clientSecret;
  final bool isEmployee;

  LoginRequest({
    required this.username,
    required this.password,
    this.grantType = 'password',
    required this.clientId,
    required this.clientSecret,
    this.isEmployee = true,
  });

  Map<String, String> toFormData() {
    return {
      'grant_type': grantType,
      'username': username,
      'password': password,
      'client_id': clientId,
      'client_secret': clientSecret,
      'app_nhan_vien': isEmployee.toString()
    };
  }
}

class RefreshTokenRequest {
  final String refreshToken;
  final String grantType;
  final String clientId;
  final String clientSecret;

  RefreshTokenRequest({
    required this.refreshToken,
    this.grantType = 'refresh_token',
    required this.clientId,
    required this.clientSecret,
  });

  Map<String, String> toFormData() {
    return {
      'grant_type': grantType,
      'refresh_token': refreshToken,
      'client_id': clientId,
      'client_secret': clientSecret,
    };
  }
}