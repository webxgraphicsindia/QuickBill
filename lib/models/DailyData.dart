class DailyData {
  final String day;
  final double amount;
  final DateTime? date;

  DailyData({
    required this.day,
    required this.amount,
    this.date,          // Add this
  });

  factory DailyData.fromJson(Map<String, dynamic> json) {
    return DailyData(
      day: json['day'] ?? '',

      amount: json['amount']?.toDouble() ?? 0.0,
    );
  }
}