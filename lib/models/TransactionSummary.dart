import 'package:intl/intl.dart';
import 'DailyTransaction.dart';

class TransactionSummary {
  final double todayTotal;
  final double weeklyTotal;
  final double monthlyTotal;
  final double yearlyTotal;
  final double FinalTotal;
  final List<Map<String, dynamic>> byPaymentMode;
  final List<DailyTransaction>? weeklyData;
  final List<DailyTransaction>? monthlyData;
  final List<DailyTransaction>? yearlyData;



  TransactionSummary({
    required this.todayTotal,
    required this.weeklyTotal,
    required this.monthlyTotal,
    required this.yearlyTotal,
    required this.byPaymentMode,
    required this.FinalTotal,
    this.weeklyData,
    this.monthlyData,
    this.yearlyData,
  });

  factory TransactionSummary.fromJson(Map<String, dynamic> json) {
    // Handle specific_day data if present
    final specificDay = json['specific_day'] is Map ? json['specific_day'] : null;
    final todayAmount = specificDay != null  ? (double.tryParse(specificDay['amount']?.toString() ?? '0') ?? 0.0) : (double.tryParse(json['today']?.toString() ?? '0') ?? 0.0 );

    // Process payment modes
    final paymentModes = (json['by_payment_mode'] is List
    ? json['by_payment_mode']
        : <dynamic>[]) as List;

    final paymentModeList = paymentModes.map((mode) {
    return {
    'payment_mode': mode['payment_mode']?.toString() ?? 'Unknown',
    'total': double.tryParse(mode['total']?.toString() ?? '0') ?? 0.0,
    };
    }).toList();

    return TransactionSummary(
    todayTotal: todayAmount,
    weeklyTotal: double.tryParse(json['week']?.toString() ?? '0') ?? 0.0,
    monthlyTotal: double.tryParse(json['month']?.toString() ?? '0') ?? 0.0,
    yearlyTotal: double.tryParse(json['year']?.toString() ?? '0') ?? 0.0,
    FinalTotal: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
    byPaymentMode: paymentModeList,
    );
  }
}