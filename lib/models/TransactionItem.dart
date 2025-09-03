
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
      productId: json['product_id'],
      productName: json['product']['name'] ?? 'Unknown Product',
      quantity: json['quantity'],
      price: json['price'].toDouble(),
    );
  }
}