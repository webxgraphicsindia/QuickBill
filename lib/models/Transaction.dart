// transaction.dart
import 'TransactionItem.dart';

class Transaction {
  final String id;
  final DateTime createdAt;
  final String status;
  final String paymentMode;
  final double totalPrice;
  final double discount;
  final double finalAmount;
  final List<TransactionItem> items;
  final double totalTax;
  final double totalCgst;
  final double totalSgst;
  final double totalIgst;
  final double totalCess;

  Transaction({
    required this.id,
    required this.createdAt,
    this.status = 'completed',
    required this.paymentMode,
    required this.totalPrice,
    this.discount = 0.0,
    required this.finalAmount,
    required this.items,
    required this.totalTax,
    required this.totalCgst,
    required this.totalSgst,
    required this.totalIgst,
    required this.totalCess,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id']?.toString() ?? '',
      createdAt: DateTime.parse(json['created_at']?.toString() ?? DateTime.now().toString()),
      status: json['status']?.toString() ?? 'completed',
      paymentMode: json['payment_mode']?.toString() ?? 'cash',
      totalPrice: double.tryParse(json['total_price']?.toString() ?? '0') ?? 0.0,
      discount: double.tryParse(json['discount']?.toString() ?? '0') ?? 0.0,
      finalAmount: double.tryParse(json['final_amount']?.toString() ?? '0') ?? 0.0,
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => TransactionItem.fromJson(item))
          .toList() ?? [],
      totalTax: double.tryParse(json['total_tax']?.toString() ?? '0') ?? 0.0,
      totalCgst: double.tryParse(json['total_cgst']?.toString() ?? '0') ?? 0.0,
      totalSgst: double.tryParse(json['total_sgst']?.toString() ?? '0') ?? 0.0,
      totalIgst: double.tryParse(json['total_igst']?.toString() ?? '0') ?? 0.0,
      totalCess: double.tryParse(json['total_cess']?.toString() ?? '0') ?? 0.0,
    );
  }

  Transaction copyWith({
    String? status,
  }) {
    return Transaction(
      id: id,
      createdAt: createdAt,
      status: status ?? this.status,
      paymentMode: paymentMode,
      totalPrice: totalPrice,
      discount: discount,
      finalAmount: finalAmount,
      items: items,
      totalTax: totalTax,
      totalCgst: totalCgst,
      totalSgst: totalSgst,
      totalIgst: totalIgst,
      totalCess: totalCess,
    );
  }
}

class TransactionItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  TransactionItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product']?['name']?.toString() ?? 'Unknown Product',
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
    );
  }
}