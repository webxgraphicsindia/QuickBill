class Feedbackresponse{
  final bool success;
  final String? message;
  final dynamic data;
  final double? rating;
  final String? feedbackType;

  Feedbackresponse({
    required this.success,
    this.message,
    this.data,
    this.rating,
    this.feedbackType,
  });

  factory Feedbackresponse.fromJson(Map<String, dynamic> json) {
    return Feedbackresponse(
      success: json['success'] ?? false,
      message: json['message'],
      data: json['data'],
      rating: (json['rating'] as num?)?.toDouble(),
      feedbackType: json['feedback_type'],
    );
  }
}