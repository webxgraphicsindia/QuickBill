// lib/widgets/ProductCard.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:quickbill/models/Product.dart';

import '../utils/TaxSettings.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: TaxSettings.isTaxBillingEnabled(),
      builder: (context, snapshot) {
        final showTaxInfo = snapshot.data ?? false;

        return Card(
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onEdit,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Image Placeholder
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: product.imageUrl != null
                            ? CachedNetworkImage(
                          imageUrl: product.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => const Center(
                            child: CircularProgressIndicator(),
                          ),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                        )
                            : const Icon(Icons.image, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Barcode: ${product.barcode}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _buildInfoChip(
                                  icon: Icons.currency_rupee,
                                  text: '${product.price.toStringAsFixed(2)}',
                                  color: Colors.blue[100]!,
                                ),
                                const SizedBox(width: 8),
                                _buildInfoChip(
                                  icon: Icons.inventory,
                                  text: '${product.stock} in stock',
                                  color: Colors.green[100]!,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (product.description?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        product.description!,
                        style: TextStyle(color: Colors.grey[700]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  // Tax Information Section (only shown if tax billing is enabled)
                  if (showTaxInfo && (product.gstRate != null || product.cgst != null))
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (product.gstRate != null)
                            _buildInfoChip(
                              icon: Icons.receipt,
                              text: 'GST: ${product.gstRate}%',
                              color: Colors.orange[100]!,
                            ),
                          if (product.cgst != null)
                            _buildInfoChip(
                              icon: Icons.receipt,
                              text: 'CGST: ${product.cgst}%',
                              color: Colors.purple[100]!,
                            ),
                          if (product.sgst != null)
                            _buildInfoChip(
                              icon: Icons.receipt,
                              text: 'SGST: ${product.sgst}%',
                              color: Colors.purple[100]!,
                            ),
                          if (product.igst != null)
                            _buildInfoChip(
                              icon: Icons.receipt,
                              text: 'IGST: ${product.igst}%',
                              color: Colors.purple[100]!,
                            ),
                          if (product.cess != null)
                            _buildInfoChip(
                              icon: Icons.receipt,
                              text: 'CESS: ${product.cess}%',
                              color: Colors.red[100]!,
                            ),
                          if (product.priceWithTax != null)
                            _buildInfoChip(
                              icon: Icons.currency_rupee,
                              text: 'Total: ${product.priceWithTax!.toStringAsFixed(2)}',
                              color: Colors.green[100]!,
                            ),
                        ],
                      ),
                    ),

                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip({required IconData icon, required String text, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}