import 'User.dart';

class GetProfileResponse {
  final bool success;
  final String? message;
  final User? user;

  GetProfileResponse({
    required this.success,
    this.message,
    this.user,
  });

  factory GetProfileResponse.fromJson(Map<String, dynamic> json) {
    return GetProfileResponse(
      success: json['success'] ?? false,
      message: json['message'],
      user: json['data'] != null && json['data']['user'] != null
          ? User.fromJson(json['data']['user'])
          : null,
    );
  }
}