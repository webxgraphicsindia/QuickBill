class Customer {
  final String id;
  final String name;
  final String mobile;
  final double totalSpent;
  final String? address;
  final int totalTransactions;
  final DateTime createdAt;
  final DateTime updatedAt;

  Customer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.totalSpent,
    this.address,
    required this.totalTransactions,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      totalSpent: double.tryParse(json['total_spent']?.toString() ?? '0') ?? 0,
      address: json['address']?.toString(),
      totalTransactions: int.tryParse(json['total_transactions']?.toString() ?? '0') ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}