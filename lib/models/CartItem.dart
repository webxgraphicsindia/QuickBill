class CartItem {
  final String productId;
  final String name;
  final String? imageUrl;
  final double price;
  final int quantity;
  final double? cgst;
  final double? sgst;
  final double? igst;
  final double? cess;

  CartItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageUrl,
    this.cgst,
    this.sgst,
    this.igst,
    this.cess,
  });

  // Add empty constructor
  CartItem.empty()
      : productId = '',
        name = '',
        price = 0.0,
        quantity = 0,
        imageUrl = null,
        cgst = null,
        sgst = null,
        igst = null,
        cess = null;

  // Add copyWith method
  CartItem copyWith({
    String? productId,
    String? name,
    String? imageUrl,
    double? price,
    int? quantity,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      productId: json['product_id']?.toString() ?? '',
      name: json['product']?['name']?.toString() ?? 'Unknown Product',
      price: double.tryParse(json['product']?['price']?.toString() ?? '0') ?? 0.0,
      quantity: int.tryParse(json['quantity']?.toString() ?? '0') ?? 0,
      imageUrl: json['product']?['image_url']?.toString(),
      cgst: double.tryParse(json['product']?['cgst']?.toString() ?? '0'),
      sgst: double.tryParse(json['product']?['sgst']?.toString() ?? '0'),
      igst: double.tryParse(json['product']?['igst']?.toString() ?? '0'),
      cess: double.tryParse(json['product']?['cess']?.toString() ?? '0'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'quantity': quantity,
      'price': price,
    };
  }
}