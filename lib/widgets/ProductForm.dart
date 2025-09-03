// lib/widgets/ProductForm.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:quickbill/models/Product.dart';
import 'package:quickbill/utils/TaxSettings.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onCancel;

  const ProductForm({
    Key? key,
    this.product,
    required this.onSubmit,
    required this.onCancel,
  }) : super(key: key);

  @override
  _ProductFormState createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _barcodeController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  // GST
  late TextEditingController _gstRateController;
  late TextEditingController _cgstController;
  late TextEditingController _sgstController;
  late TextEditingController _igstController;
  late TextEditingController _cessController;

  bool _taxBillingEnabled = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _barcodeController = TextEditingController(text: widget.product?.barcode ?? '');
    _descriptionController = TextEditingController(text: widget.product?.description ?? '');
    _priceController = TextEditingController(text: widget.product?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.product?.stock.toString() ?? '');

    // GST
    _gstRateController = TextEditingController(
        text: widget.product?.gstRate?.toString() ?? '');
    _cgstController = TextEditingController(
        text: widget.product?.cgst?.toString() ?? '');
    _sgstController = TextEditingController(
        text: widget.product?.sgst?.toString() ?? '');
    _igstController = TextEditingController(
        text: widget.product?.igst?.toString() ?? '');
    _cessController = TextEditingController(
        text: widget.product?.cess?.toString() ?? '');

    _loadTaxSettings();
  }

  Future<void> _loadTaxSettings() async {
    final isEnabled = await TaxSettings.isTaxBillingEnabled();
    setState(() {
      _taxBillingEnabled = isEnabled;
    });
  }

  Future<void> _scanBarcode() async {
    // Show a dialog with the scanner
    await showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            SizedBox(
              height: 300,
              child: MobileScanner(
                controller: MobileScannerController(
                  detectionSpeed: DetectionSpeed.normal,
                  facing: CameraFacing.back,
                  torchEnabled: false,
                ),
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context); // Close the scanner
                      setState(() {
                        _barcodeController.text = barcode.rawValue!;
                      });
                      break;
                    }
                  }
                },
              ),
            ),
            Positioned(
              right: 16,
              top: 16,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _barcodeController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();

    // GST
    _gstRateController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _igstController.dispose();
    _cessController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter product name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _barcodeController,
              decoration: InputDecoration(
                labelText: 'Barcode',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _scanBarcode,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter or scan barcode';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter price';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stockController,
              decoration: const InputDecoration(
                labelText: 'Stock Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter stock quantity';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid quantity';
                }
                return null;
              },
            ),

            // Only show tax fields if tax billing is enabled
            if (_taxBillingEnabled) ...[
              const SizedBox(height: 16),
              const Text('Tax Information (Optional)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              // GST Rate
              TextFormField(
                controller: _gstRateController,
                decoration: const InputDecoration(
                  labelText: 'GST Rate (%)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),

              const SizedBox(height: 8),

              // Individual GST Components
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cgstController,
                      decoration: const InputDecoration(
                        labelText: 'CGST (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sgstController,
                      decoration: const InputDecoration(
                        labelText: 'SGST (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _igstController,
                      decoration: const InputDecoration(
                        labelText: 'IGST (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _cessController,
                      decoration: const InputDecoration(
                        labelText: 'CESS (%)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: widget.onCancel,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      final formData = {
                        'name': _nameController.text,
                        'barcode': _barcodeController.text,
                        'description': _descriptionController.text,
                        'price': double.parse(_priceController.text),
                        'stock': int.parse(_stockController.text),
                      };

                      // Add GST fields only if tax billing is enabled and fields are not empty
                      if (_taxBillingEnabled) {
                        if (_gstRateController.text.isNotEmpty) {
                          formData['gst_rate'] = double.parse(_gstRateController.text);
                        }
                        if (_cgstController.text.isNotEmpty) {
                          formData['cgst'] = double.parse(_cgstController.text);
                        }
                        if (_sgstController.text.isNotEmpty) {
                          formData['sgst'] = double.parse(_sgstController.text);
                        }
                        if (_igstController.text.isNotEmpty) {
                          formData['igst'] = double.parse(_igstController.text);
                        }
                        if (_cessController.text.isNotEmpty) {
                          formData['cess'] = double.parse(_cessController.text);
                        }
                      }

                      widget.onSubmit(formData);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(widget.product == null ? 'Add Product' : 'Update Product'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}