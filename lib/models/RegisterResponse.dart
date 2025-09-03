import '';
import 'User.dart';
class RegisterResponse {
  final bool success;
  final String? token;
  final User? user;
  final String message;
  final bool requiresVerification;
  final String? verificationToken;
  final Map<String, dynamic>? errors; // For validation errors
  final int? statusCode; // Add status code for specific handling

  RegisterResponse({
    required this.success,
    this.token,
    this.user,
    required this.message,
    this.requiresVerification = false,
    this.verificationToken,
    this.statusCode,
    this.errors,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      success: json['success'] ?? false,
      token: json['data']['token'] ?? json['access_token'],
      user: json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
      message: json['message'] ?? 'Registration successful',
      requiresVerification: json['requires_verification'] ?? false,
      verificationToken: json['verification_token'],
    );
  }
}