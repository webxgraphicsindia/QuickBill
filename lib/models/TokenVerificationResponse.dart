class TokenVerificationResponse {
  final bool isValid;
  final bool expiresSoon;
  final String? message;

  TokenVerificationResponse({
    required this.isValid,
    this.expiresSoon = false,
    this.message,
  });
}