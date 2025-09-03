class Product {
  final String id;
  final String name;
  final String barcode;
  final String? description;
  final double price;
  final int stock;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? gstRate;
  final double? cgst;
  final double? sgst;
  final double? igst;
  final double? cess;
  final double? priceWithTax;

  Product({
    required this.id,
    required this.name,
    required this.barcode,
    this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.gstRate,
    this.cgst,
    this.sgst,
    this.igst,
    this.cess,
    this.priceWithTax,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // Check if tax_details exists and use those values if available
    final taxDetails = json['tax_details'] as Map<String, dynamic>?;

    return Product(
      id: json['id'].toString(),
      name: json['name'],
      barcode: json['barcode'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      stock: int.parse(json['stock'].toString()),
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      gstRate: taxDetails?['gst_rate'] != null
          ? double.parse(taxDetails!['gst_rate'].toString())
          : json['gst_rate'] != null
          ? double.parse(json['gst_rate'].toString())
          : null,
      cgst: taxDetails?['cgst'] != null
          ? double.parse(taxDetails!['cgst'].toString())
          : json['cgst'] != null
          ? double.parse(json['cgst'].toString())
          : null,
      sgst: taxDetails?['sgst'] != null
          ? double.parse(taxDetails!['sgst'].toString())
          : json['sgst'] != null
          ? double.parse(json['sgst'].toString())
          : null,
      igst: taxDetails?['igst'] != null
          ? double.parse(taxDetails!['igst'].toString())
          : json['igst'] != null
          ? double.parse(json['igst'].toString())
          : null,
      cess: taxDetails?['cess'] != null
          ? double.parse(taxDetails!['cess'].toString())
          : json['cess'] != null
          ? double.parse(json['cess'].toString())
          : null,
      priceWithTax: taxDetails?['price_with_tax'] != null
          ? double.parse(taxDetails!['price_with_tax'].toString())
          : json['price_with_tax'] != null
          ? double.parse(json['price_with_tax'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'description': description,
      'price': price,
      'stock': stock,
      if (imageUrl != null) 'image_url': imageUrl,
      if (gstRate != null) 'gst_rate': gstRate,
      if (cgst != null) 'cgst': cgst,
      if (sgst != null) 'sgst': sgst,
      if (igst != null) 'igst': igst,
      if (cess != null) 'cess': cess,
      if (priceWithTax != null) 'price_with_tax': priceWithTax,
    };
  }
}