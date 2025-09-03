import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  final int quantity;
  final Function(int) onChanged;
  final bool isLoading;

  const QuantitySelector({
    Key? key,
    required this.quantity,
    required this.onChanged,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: isLoading ? null : () => onChanged(quantity - 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: isLoading ? Colors.grey : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: isLoading
                ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : Text(
              quantity.toString(),
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: isLoading ? null : () => onChanged(quantity + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: isLoading ? Colors.grey : null,
          ),
        ],
      ),
    );
  }
}