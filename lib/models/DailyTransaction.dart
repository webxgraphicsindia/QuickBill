
class DailyTransaction {
  final String date;
  final double amount;

  DailyTransaction({required this.date, required this.amount});

  factory DailyTransaction.fromJson(Map<String, dynamic> json) {
    return DailyTransaction(
      date: json['date'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }
}