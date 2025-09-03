/*
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quickbill/models/CartItem.dart';
import 'package:quickbill/constants/colors.dart';
import 'package:quickbill/api/API.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final List<CartItem> existingItems;

  const BarcodeScannerScreen({
    Key? key,
    this.existingItems = const [],
  }) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<CartItem> _scannedItems = [];
  bool _isLoading = false;
  bool _scanningEnabled = true;
  Timer? _scanCooldownTimer;

  @override
  void initState() {
    super.initState();
    _scannedItems = List.from(widget.existingItems);
    _loadSound();
  }

  Future<void> _loadSound() async {
    await _audioPlayer.setSource(AssetSource('lib/assets/audio/beep.mp3'));
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    _scanCooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _playBeep() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      print("Error playing sound: $e");
    }
  }

  Future<void> _handleBarcode(Barcode barcode) async {
    if (!_scanningEnabled || _isLoading) return;

    final String? barcodeValue = barcode.rawValue;
    if (barcodeValue == null || barcodeValue.isEmpty) return;

    setState(() {
      _scanningEnabled = false;
      _isLoading = true;
    });

    try {
      // Check if product already exists in the list
      final existingIndex = _scannedItems.indexWhere(
            (item) => item.productId == barcodeValue,
      );

      if (existingIndex >= 0) {
        // Increment quantity if product exists
        setState(() {
          _scannedItems[existingIndex] = _scannedItems[existingIndex].copyWith(
            quantity: _scannedItems[existingIndex].quantity + 1,
          );
        });
      } else {
        // Fetch product details from API
        final product = await apiServices.getProductByBarcode(barcodeValue);
        if (product != null) {
          setState(() {
            _scannedItems.add(CartItem(
              productId: product.id,
              name: product.name,
              price: product.price,
              quantity: 1,
              imageUrl: product.imageUrl,
            ));
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product not found for barcode: $barcodeValue')),
          );
          return;
        }
      }

      await _playBeep();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      // Start cooldown timer to prevent multiple scans of same barcode
      _scanCooldownTimer?.cancel();
      _scanCooldownTimer = Timer(const Duration(milliseconds: 500), () {
        setState(() {
          _scanningEnabled = true;
          _isLoading = false;
        });
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      if (_scannedItems[index].quantity > 1) {
        _scannedItems[index] = _scannedItems[index].copyWith(
          quantity: _scannedItems[index].quantity - 1,
        );
      } else {
        _scannedItems.removeAt(index);
      }
    });
  }

  void _addItem(int index) {
    setState(() {
      _scannedItems[index] = _scannedItems[index].copyWith(
        quantity: _scannedItems[index].quantity + 1,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller.cameraFacingState,
              builder: (context, state, child) {
                switch (state) {
                  case CameraFacing.front:
                    return const Icon(Icons.camera_front);
                  case CameraFacing.back:
                    return const Icon(Icons.camera_rear);
                }
              },
            ),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                MobileScanner(
                  controller: _controller,
                  onDetect: (barcode, args) {
                    _handleBarcode(barcode);
                  },
                ),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: _buildScannedItemsList(),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildScannedItemsList() {
    if (_scannedItems.isEmpty) {
      return const Center(
        child: Text(
          'No products scanned yet',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _scannedItems.length,
      itemBuilder: (context, index) {
        final item = _scannedItems[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: item.imageUrl != null
                ? Image.network(
              item.imageUrl!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            )
                : const Icon(Icons.shopping_basket, size: 40),
            title: Text(item.name),
            subtitle: Text('₹${item.price.toStringAsFixed(2)}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => _removeItem(index),
                ),
                Text(item.quantity.toString()),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _addItem(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: BorderSide(color: AppColors.primaryColor),
              ),
              child: const Text('CANCEL'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _scannedItems.isEmpty
                  ? null
                  : () => Navigator.pop(context, _scannedItems),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('PROCEED TO BILL'),
            ),
          ),
        ],
      ),
    );
  }
}*/
