import "../models/User.dart";

class LoginResponse {
  final bool success;
  final String? message;
  final String? token;
  final String? refreshToken;
  final User? user;
  final int? statusCode; // Add status code for specific handling

  LoginResponse({
    required this.success,
    this.message,
    this.token,
    this.refreshToken,
    this.user,
    this.statusCode,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: json['data']['token'],  // Updated to match your response structure
      user: json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
      // Note: Your response doesn't show refreshToken, adjust if needed
      refreshToken: json['data']['refresh_token'], // If available
    );
  }
}