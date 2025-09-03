class TokenRefreshResponse {
  final bool success;
  final String? accessToken;
  final String? refreshToken;
  final String? message;

  TokenRefreshResponse({
    required this.success,
    this.accessToken,
    this.refreshToken,
    this.message,
  });
}